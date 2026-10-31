#if os(macOS)
import AppKit
#endif
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// MessageList `menu` (``FlareMessageMenuSource``): the long-press sheet and the pointer menu are drawn from one set of
/// entries, a missing snapshot reads "正在读取…" and asks the host, and rows coming on screen are prefetched.
final class MessageMenuSourceTests: XCTestCase {
    private let zh = FlareStrings()
    private let report = FlareMessageMenuEntry(id: "report", label: "举报", icon: "report", group: .destructive)

    private func message(_ id: String, _ text: String = "你好") -> FlareMessageData {
        FlareMessageData(id: id, senderId: "u", senderName: "U", content: FlareTextContent(text))
    }

    private func source(_ snapshots: [String: FlareMessageActionAvailability], prefetched: @escaping ([String]) -> Void = { _ in },
                        performed: @escaping (String, String) -> Void = { _, _ in }) -> FlareMessageMenuSource {
        let report = report
        return FlareMessageMenuSource(availability: { snapshots[$0.id] }, prefetch: prefetched, hiddenActions: ["pinSelf"],
                                      extraActions: { $0.senderId == "me" ? [] : [report] },
                                      perform: { performed($0.id, $1) })
    }

    private let snapshot = FlareMessageActionAvailability(canReply: true, canForward: true, canCopy: true,
                                                          canDelete: true, canPin: true)

    func testBothMenusAreTheSheetsEntryFunction() throws {
        let menu = source(["m": snapshot])
        let entries = try XCTUnwrap(menu.entries(for: message("m"), strings: zh))
        XCTAssertEqual(entries, messageMenuEntries(snapshot, strings: zh, hidden: ["pinSelf"], extra: [report],
                                                   content: FlareTextContent("你好")))
        XCTAssertFalse(entries.contains { $0.id == "pinSelf" }, "hidden actions are left out")
        XCTAssertEqual(entries.last?.id, "report", "extra actions follow")
        let pointer = menu.pointerSections(for: message("m"), strings: zh)
        XCTAssertEqual(pointer, messageMenuGroups(entries).map { $0.map(FlareMessageMenuSource.PointerItem.entry) },
                       "the same entries, groups and order as the sheet")
        XCTAssertEqual(pointer.last?.compactMap { if case .entry(let e) = $0 { return e.id }; return nil },
                       ["delete", "report"])
        XCTAssertEqual(FlareMessageMenuSource.role(entries.first { $0.id == "delete" }!), .destructive)
        XCTAssertNil(FlareMessageMenuSource.role(entries[0]))
        #if os(macOS)
        XCTAssertTrue(FlareMessageMenuSource.pointerIdiom, "macOS is a pointer")
        #endif
        XCTAssertFalse(FlareMessageMenuSource.longPressOpensSheet(pointerMenu: true), "the pointer menu takes the long press")
        XCTAssertTrue(FlareMessageMenuSource.longPressOpensSheet(pointerMenu: false))
    }

    /// The sheet the list opens draws the same entries, in order, and sends the choice to `perform`.
    @MainActor
    func testTheSheetDrawsTheSameEntriesAndPerformsTheChoice() throws {
        var performed: [String] = []
        var closed = 0
        let menu = source(["m": snapshot], performed: { performed.append("\($0):\($1)") })
        let sheet = MessageListView.menuSheet(message("m"), menu: menu, onReact: nil, done: { closed += 1 })
        let entries = try XCTUnwrap(menu.entries(for: message("m"), strings: zh))
        let view = try sheet.inspect()
        let labels = view.findAll(ViewType.Button.self).compactMap { try? $0.accessibilityLabel().string() }
        XCTAssertEqual(labels, messageMenuGroups(entries).flatMap { $0 }.map(\.label))
        try view.find(button: report.label).tap()
        XCTAssertEqual(performed, ["m:report"])
        XCTAssertEqual(closed, 1, "the sheet closes before the action runs")
    }

    /// The host's entries are asked for per message: "report" on someone else's message only, in both menus.
    @MainActor
    func testTheHostsEntriesFollowTheMessage() throws {
        let menu = source(["m": snapshot, "mine": snapshot])
        let own = FlareMessageData(id: "mine", senderId: "me", senderName: "Me", content: FlareTextContent("你好"))
        XCTAssertFalse(try XCTUnwrap(menu.entries(for: own, strings: zh)).contains { $0.id == "report" })
        XCTAssertTrue(try XCTUnwrap(menu.entries(for: message("m"), strings: zh)).contains { $0.id == "report" })
        let sheet = try MessageListView.menuSheet(own, menu: menu, onReact: nil, done: {}).inspect()
        XCTAssertThrowsError(try sheet.find(button: report.label), "the sheet draws the same entries")
    }

    func testWithoutASnapshotThePointerMenuIsOneLoadingItem() {
        let menu = source([:])
        XCTAssertNil(menu.entries(for: message("m"), strings: zh))
        XCTAssertEqual(menu.pointerSections(for: message("m"), strings: zh), [[.loading]])
        XCTAssertEqual(zh.messageMenuLoading, "正在读取…")
        XCTAssertEqual(FlareStrings.english.messageMenuLoading, "Loading…")
    }

    /// Ids asked for in one turn of the run loop go out in one call; an id is asked once until it settles.
    func testThePrefetcherBatchesAndAsksOnce() {
        var calls: [[String]] = []
        let prefetcher = FlareMessageMenuPrefetcher()
        let record: ([String]) -> Void = { calls.append($0) }
        prefetcher.request("a", record)
        prefetcher.request("b", record)
        prefetcher.request("a", record)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(calls, [["a", "b"]])
        prefetcher.request("a", record)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(calls.count, 1, "still waiting for a's snapshot")
        prefetcher.settle("a")
        prefetcher.request("a", record)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(calls, [["a", "b"], ["a"]])
    }

    /// A menu asked for without a snapshot asks again even while an earlier request waits: that request may have
    /// failed, or its snapshot lapsed since. A row coming on screen still asks once.
    func testAMenuAskedForWithoutASnapshotAlwaysAsks() {
        var calls: [[String]] = []
        let prefetcher = FlareMessageMenuPrefetcher()
        let record: ([String]) -> Void = { calls.append($0) }
        prefetcher.request("a", record)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        prefetcher.ask("a", record)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(calls, [["a"], ["a"]], "the menu's ask is not swallowed as a repeat")
        prefetcher.request("a", record)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(calls.count, 2, "a row coming on screen still waits for the asked snapshot")
    }

    /// Messages whose snapshot arrived are settled; the ones still waiting stay asked for.
    func testArrivedSnapshotsSettleTheirRequests() {
        var calls: [[String]] = []
        let prefetcher = FlareMessageMenuPrefetcher()
        let record: ([String]) -> Void = { calls.append($0) }
        prefetcher.request("a", record)
        prefetcher.request("b", record)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        prefetcher.settleArrived { $0 == "a" }
        prefetcher.request("a", record)
        prefetcher.request("b", record)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(calls, [["a", "b"], ["a"]])
    }

    #if os(macOS)
    /// Laid out for real: the rows on screen without a snapshot are asked for in one call, the one with a snapshot is
    /// not, and a notice row never is.
    @MainActor
    func testRowsComingOnScreenArePrefetched() {
        _ = NSApplication.shared
        var calls: [[String]] = []
        let notice = FlareMessageData(id: "n", senderId: "system", senderName: "", content: FlareNotificationContent("x"))
        let list = MessageListView(messages: [message("a"), message("b"), notice], currentUserId: "me",
                                   menu: source(["b": snapshot], prefetched: { calls.append($0) }))
        let size = NSSize(width: 400, height: 600)
        let host = NSHostingView(rootView: list.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(calls.flatMap { $0 }.sorted(), ["a"])
        XCTAssertEqual(calls.count, 1)
    }

    /// Laid out for real: a row whose snapshot arrived is settled when the list redraws with it, so once the snapshot
    /// lapses and the row comes back without one it is asked for again instead of being swallowed as a repeat.
    @MainActor
    func testARowWhoseSnapshotArrivedIsAskedForAgainAfterItLapses() {
        _ = NSApplication.shared
        var calls: [[String]] = []
        let model = MenuHostModel()
        let report = report
        let screen = MenuHostScreen(model: model) { snapshots in
            FlareMessageMenuSource(availability: { snapshots[$0.id] }, prefetch: { calls.append($0) },
                                   extraActions: { _ in [report] }, perform: { _, _ in })
        }
        let size = NSSize(width: 400, height: 600)
        let host = NSHostingView(rootView: screen.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        func settle() {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.4))
            host.layoutSubtreeIfNeeded()
        }
        model.messages = [message("a")]
        settle()
        XCTAssertEqual(calls, [["a"]], "on screen without a snapshot: asked for")
        model.snapshots = ["a": snapshot]
        settle()
        model.snapshots = [:]
        model.messages = []
        settle()
        model.messages = [message("a")]
        settle()
        XCTAssertEqual(calls, [["a"], ["a"]], "back on screen after the snapshot lapsed: asked for again")
    }

    /// The titles an open menu shows, a disabled one marked, separators left out.
    private static func titles(_ menu: NSMenu) -> [String] {
        menu.items.filter { !$0.isSeparatorItem }.map { $0.title + ($0.isEnabled ? "" : " (off)") }
    }

    /// The titles the pointer menu of `message` should show under `menu`.
    private func expectedTitles(_ menu: FlareMessageMenuSource, _ message: FlareMessageData) -> [String] {
        menu.pointerSections(for: message, strings: zh).flatMap { $0 }.map { item -> String in
            switch item {
            case .loading: return zh.messageMenuLoading + " (off)"
            case .entry(let entry): return entry.label + (entry.enabled ? "" : " (off)")
            }
        }
    }

    /// Laid out for real and opened with a secondary click: while the pointer menu is open, the snapshot arriving turns
    /// its loading entry into the entries, and a later snapshot narrows them, in the menu that is already open — it is
    /// not closed and opened again.
    @MainActor
    func testAnOpenPointerMenuFollowsTheSnapshot() throws {
        _ = NSApplication.shared
        let model = MenuHostModel()
        let report = report
        let source: ([String: FlareMessageActionAvailability]) -> FlareMessageMenuSource = { snapshots in
            FlareMessageMenuSource(availability: { snapshots[$0.id] }, prefetch: { _ in },
                                   extraActions: { _ in [report] }, perform: { _, _ in })
        }
        let screen = MenuHostScreen(model: model, menu: source)
        let size = NSSize(width: 400, height: 300)
        let host = NSHostingView(rootView: screen.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        model.messages = [message("a")]
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))

        let snapshot = snapshot
        let narrowed = FlareMessageActionAvailability(canReply: true, canCopy: true)
        var seen: [[String]] = []
        var opened: [ObjectIdentifier] = []
        func after(_ seconds: TimeInterval, _ run: @escaping () -> Void) {
            RunLoop.main.add(Timer(timeInterval: seconds, repeats: false) { _ in run() }, forMode: .common)
        }
        let observer = NotificationCenter.default.addObserver(
            forName: NSMenu.didBeginTrackingNotification, object: nil, queue: nil
        ) { note in
            guard let menu = note.object as? NSMenu else { return }
            opened.append(ObjectIdentifier(menu))
            guard opened.count == 1 else { return }
            seen.append(Self.titles(menu))
            after(0.3) {
                model.snapshots = ["a": snapshot]
                after(0.5) {
                    seen.append(Self.titles(menu))
                    model.snapshots = ["a": narrowed]
                    after(0.5) {
                        seen.append(Self.titles(menu))
                        menu.cancelTracking()
                    }
                }
            }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        // The row is at the bottom of the viewport, where the timeline opens: click up from there until it answers.
        var y: CGFloat = 8
        while opened.isEmpty && y < size.height {
            for type in [NSEvent.EventType.rightMouseDown, .rightMouseUp] {
                let event = try XCTUnwrap(NSEvent.mouseEvent(
                    with: type, location: NSPoint(x: 120, y: y), modifierFlags: [],
                    timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil,
                    eventNumber: 0, clickCount: 1, pressure: 1))
                window.sendEvent(event)
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            y += 12
        }
        let deadline = Date().addingTimeInterval(3)
        while seen.count < 3 && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }

        XCTAssertEqual(opened.count, 1, "one menu, opened once and never reopened")
        XCTAssertEqual(seen.count, 3)
        guard seen.count == 3 else { return }
        XCTAssertEqual(seen[0], [zh.messageMenuLoading + " (off)"], "without a snapshot: the loading entry")
        XCTAssertEqual(seen[1], expectedTitles(source(["a": snapshot]), message("a")),
                       "the snapshot arrived while the menu was open: its entries, in the open menu")
        XCTAssertEqual(seen[2], expectedTitles(source(["a": narrowed]), message("a")),
                       "a narrower snapshot: the actions the core no longer allows leave the open menu")
        XCTAssertFalse(seen[2].contains(zh.messageActionDelete), "delete left")
        XCTAssertTrue(seen[2].contains(zh.messageActionReply))
    }

    /// Laid out for real and opened with a secondary click: the host drops the open menu's snapshot (the message
    /// moved, or the snapshot grew old) and only redraws. The open menu turns to its loading entry and the list asks
    /// for that message itself — once, however often the host redraws meanwhile — and the answer changes the menu in
    /// place. A snapshot dropped again is asked for again; a closed menu asks for nothing.
    @MainActor
    func testAnOpenPointerMenuAsksAgainForASnapshotTheHostDrops() throws {
        _ = NSApplication.shared
        let model = MenuHostModel()
        let report = report
        var calls: [[String]] = []
        let source: ([String: FlareMessageActionAvailability]) -> FlareMessageMenuSource = { snapshots in
            FlareMessageMenuSource(availability: { snapshots[$0.id] }, prefetch: { calls.append($0) },
                                   extraActions: { _ in [report] }, perform: { _, _ in })
        }
        let screen = MenuHostScreen(model: model, menu: source)
        let size = NSSize(width: 400, height: 300)
        let host = NSHostingView(rootView: screen.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        let snapshot = snapshot
        model.snapshots = ["a": snapshot]
        model.messages = [message("a")]
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(calls, [], "on screen with a snapshot: nothing to ask")

        let unpinnable = FlareMessageActionAvailability(canReply: true, canCopy: true, canUnpin: true)
        var seen: [[String]] = []
        var asked: [[[String]]] = []
        var opened: [ObjectIdentifier] = []
        func after(_ seconds: TimeInterval, _ run: @escaping () -> Void) {
            RunLoop.main.add(Timer(timeInterval: seconds, repeats: false) { _ in run() }, forMode: .common)
        }
        let observer = NotificationCenter.default.addObserver(
            forName: NSMenu.didBeginTrackingNotification, object: nil, queue: nil
        ) { note in
            guard let menu = note.object as? NSMenu else { return }
            opened.append(ObjectIdentifier(menu))
            guard opened.count == 1 else { return }
            seen.append(Self.titles(menu))
            after(0.3) {
                // Pinned elsewhere: the host's snapshot no longer holds, so it drops it and redraws.
                model.snapshots = [:]
                after(0.5) {
                    seen.append(Self.titles(menu))
                    asked.append(calls)
                    // Redraws while the answer is on its way.
                    model.messages = [self.message("a")]
                    model.redraws += 1
                    after(0.3) {
                        model.redraws += 1
                        after(0.3) {
                            asked.append(calls)
                            model.snapshots = ["a": unpinnable]
                            after(0.5) {
                                seen.append(Self.titles(menu))
                                model.snapshots = [:]
                                after(0.5) {
                                    asked.append(calls)
                                    menu.cancelTracking()
                                }
                            }
                        }
                    }
                }
            }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        // The row is at the bottom of the viewport, where the timeline opens: click up from there until it answers.
        var y: CGFloat = 8
        while opened.isEmpty && y < size.height {
            for type in [NSEvent.EventType.rightMouseDown, .rightMouseUp] {
                let event = try XCTUnwrap(NSEvent.mouseEvent(
                    with: type, location: NSPoint(x: 120, y: y), modifierFlags: [],
                    timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil,
                    eventNumber: 0, clickCount: 1, pressure: 1))
                window.sendEvent(event)
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            y += 12
        }
        let deadline = Date().addingTimeInterval(6)
        while asked.count < 3 && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let closed = calls
        model.redraws += 1
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))

        XCTAssertEqual(opened.count, 1, "one menu, opened once and never reopened")
        XCTAssertEqual(seen.count, 3)
        XCTAssertEqual(asked.count, 3)
        guard seen.count == 3, asked.count == 3 else { return }
        XCTAssertEqual(seen[0], expectedTitles(source(["a": snapshot]), message("a")), "the snapshot's entries")
        XCTAssertEqual(seen[1], [zh.messageMenuLoading + " (off)"], "the snapshot dropped: the loading entry")
        XCTAssertEqual(asked[0], [["a"]], "the list asked for the open menu's message itself")
        XCTAssertEqual(asked[1], [["a"]], "redraws while it waits do not ask again")
        XCTAssertEqual(seen[2], expectedTitles(source(["a": unpinnable]), message("a")),
                       "the answer changes the open menu in place")
        XCTAssertTrue(seen[2].contains(zh.messageActionUnpin))
        XCTAssertFalse(seen[2].contains(zh.messageActionDelete))
        XCTAssertEqual(asked[2], [["a"], ["a"]], "dropped again: asked for again, once")
        XCTAssertEqual(calls, closed, "a closed menu asks for nothing")
    }
    #endif
}

#if os(macOS)
/// A host that redraws its list when its snapshots or messages change.
private final class MenuHostModel: ObservableObject {
    @Published var snapshots: [String: FlareMessageActionAvailability] = [:]
    @Published var messages: [FlareMessageData] = []
    /// Bumped for a redraw that changes nothing the menu reads.
    @Published var redraws = 0
}

private struct MenuHostScreen: View {
    @ObservedObject var model: MenuHostModel
    let menu: ([String: FlareMessageActionAvailability]) -> FlareMessageMenuSource
    var body: some View {
        let _ = model.redraws
        MessageListView(messages: model.messages, currentUserId: "me", menu: menu(model.snapshots))
    }
}
#endif
