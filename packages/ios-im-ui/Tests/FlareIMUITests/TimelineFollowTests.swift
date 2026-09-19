import SwiftUI
import XCTest
@testable import FlareIMUI

/// K1: the timeline opens at the newest message and follows it (Vue `MessageList.vue` tail follow).
final class TimelineFollowTests: XCTestCase {
    private func message(_ id: String, sender: String = "peer") -> FlareMessageData {
        FlareMessageData(id: id, senderId: sender, senderName: sender, content: FlareTextContent("message \(id)"))
    }

    func testTheWindowOfThePreviousIdsTellsMessagesAddedAboveFromMessagesAddedBelow() {
        XCTAssertEqual(TimelineFollow.window(from: ["b", "c"], to: ["a", "b", "c", "d", "e"])?.prepended, 1)
        XCTAssertEqual(TimelineFollow.window(from: ["b", "c"], to: ["a", "b", "c", "d", "e"])?.appended, 2)
        XCTAssertEqual(TimelineFollow.window(from: ["a"], to: ["a", "b"])?.appended, 1)
        XCTAssertEqual(TimelineFollow.window(from: ["b"], to: ["a", "b"])?.prepended, 1)
        XCTAssertNil(TimelineFollow.window(from: [], to: ["a"]), "the first messages are not a change of a window")
        XCTAssertNil(TimelineFollow.window(from: ["a", "pending"], to: ["a", "sent"]), "a replaced message is no window")
        XCTAssertNil(TimelineFollow.window(from: ["a", "b"], to: ["a", "b"]), "nothing added")
        // The first id may repeat before the real window starts.
        XCTAssertEqual(TimelineFollow.window(from: ["a", "b"], to: ["a", "x", "a", "b", "c"])?.prepended, 2)
    }

    func testAReaderWhoLeavesTheBottomBrowsesAndCountsTheMessagesBelow() {
        var follow = TimelineFollow()
        XCTAssertTrue(follow.atBottom)
        XCTAssertTrue(follow.followTail)
        follow.sync(distanceToBottom: TimelineFollow.stickyDistance, tailId: "m3")
        XCTAssertTrue(follow.atBottom, "80pt above the end still counts as the bottom")
        follow.sync(distanceToBottom: 400, tailId: "m3")
        XCTAssertFalse(follow.atBottom)
        XCTAssertFalse(follow.followTail)
        XCTAssertEqual(follow.anchorTailId, "m3")

        let messages = ["m1", "m2", "m3", "m4", "m5"].map { message($0) }
        XCTAssertEqual(follow.pendingBelowCount(messages), 2)
        XCTAssertFalse(follow.followsAppended(includingOwn: false), "others' messages leave the reader")
        XCTAssertTrue(follow.followsAppended(includingOwn: true), "an own message brings the list down")

        follow.sync(distanceToBottom: 0, tailId: "m5")
        XCTAssertTrue(follow.followTail)
        XCTAssertEqual(follow.pendingBelowCount(messages), 0, "back at the bottom nothing is below")
    }

    func testContentGrowingUnderAFollowingReaderIsNotTheReaderLeaving() {
        var follow = TimelineFollow()
        follow.sync(distanceToBottom: 0, tailId: "m1")
        // A message arrived and pushed the end below the viewport before the list went down to it.
        follow.sync(distanceToBottom: 120, tailId: "m2")
        XCTAssertTrue(follow.followTail)
        XCTAssertTrue(follow.followsAppended(includingOwn: false))
        // Scrolling up with nothing new is leaving.
        follow.sync(distanceToBottom: 500, tailId: "m2")
        XCTAssertFalse(follow.followTail)
        XCTAssertEqual(follow.anchorTailId, "m2")
        follow.reachedBottom(tailId: "m2")
        XCTAssertTrue(follow.atBottom && follow.followTail)
        XCTAssertNil(follow.anchorTailId)
    }

    func testRowChangesOpenAtTheNewestFollowAppendsAndKeepPrepends() {
        func rows(_ ids: [String], own: Set<String> = []) -> [TimelineFollow.Row] {
            ids.map { TimelineFollow.Row(id: $0, own: own.contains($0)) }
        }
        var follow = TimelineFollow()
        XCTAssertTrue(follow.rowsChanged(from: [], to: rows(["a", "b"])), "the first rows open at the newest")
        XCTAssertTrue(follow.rowsChanged(from: ["a", "b"], to: rows(["a", "b", "c"])), "at the bottom an append follows")
        follow.sync(distanceToBottom: 900, tailId: "c")
        XCTAssertFalse(follow.rowsChanged(from: ["a", "b", "c"], to: rows(["a", "b", "c", "d"])), "scrolled up: others' rows wait")
        XCTAssertFalse(follow.rowsChanged(from: ["a", "b", "c", "d"], to: rows(["z", "a", "b", "c", "d"])), "older rows keep the position")
        XCTAssertTrue(follow.rowsChanged(from: ["z", "a", "b", "c", "d"], to: rows(["z", "a", "b", "c", "d", "e"], own: ["e"])),
                      "the reader's own row brings the list down")
        XCTAssertTrue(follow.rowsChanged(from: ["a", "pending"], to: rows(["a", "sent"], own: ["sent"])),
                      "a replaced newest row counts as added")
        XCTAssertFalse(follow.rowsChanged(from: ["a"], to: []))
        XCTAssertEqual(follow, TimelineFollow(), "no rows start over")
    }

    func testAnUnloadedAnchorCountsNothing() {
        var follow = TimelineFollow()
        follow.sync(distanceToBottom: 900, tailId: "gone")
        XCTAssertEqual(follow.pendingBelowCount([message("a"), message("b")]), 0)
    }
}

#if os(macOS)
import AppKit

/// The same rules on a hosted list, scrolled with wheel events the scroll view handles as the reader's own.
final class TimelineFollowHostedTests: XCTestCase {
    private final class Timeline: ObservableObject {
        @Published var messages: [FlareMessageData]
        /// The count on the scroll-to-latest key, as the list last reported it (zero: no key).
        var belowCount = 0
        init(_ messages: [FlareMessageData]) { self.messages = messages }
    }

    private struct Host: View {
        @ObservedObject var timeline: Timeline
        var body: some View {
            MessageListView(messages: timeline.messages, currentUserId: "me", conversationId: "c1")
                .environment(\.flareTimelineBelowCountObserver) { [timeline] count in timeline.belowCount = count }
        }
    }

    private static let size = NSSize(width: 360, height: 480)
    private static let today = Int64(Date().timeIntervalSince1970 * 1000)

    private static func message(_ index: Int, sender: String = "peer") -> FlareMessageData {
        FlareMessageData(id: "m\(index)", senderId: sender, senderName: sender,
                         content: FlareTextContent("message number \(index)"), sentAtMs: today + Int64(index))
    }

    private struct Hosted {
        let window: NSWindow
        let scroll: NSScrollView
        /// How far the end of the content is below the visible rect.
        var distanceToBottom: CGFloat {
            (scroll.documentView?.frame.height ?? 0) - scroll.contentView.bounds.maxY
        }
        var contentHeight: CGFloat { scroll.documentView?.frame.height ?? 0 }
    }

    private static func findScroll(_ view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        for sub in view.subviews { if let scroll = findScroll(sub) { return scroll } }
        return nil
    }

    private static func spin(_ seconds: TimeInterval = 0.4) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    @MainActor
    private func host(_ timeline: Timeline, legacy: Bool) throws -> Hosted {
        _ = NSApplication.shared
        let root = Host(timeline: timeline)
            .environment(\.flareLegacyTimelineScrolling, legacy)
            .frame(width: Self.size.width, height: Self.size.height)
        let host = NSHostingView(rootView: root)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(Self.size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        Self.spin(0.6)
        let scroll = try XCTUnwrap(Self.findScroll(host), "the timeline scrolls")
        return Hosted(window: window, scroll: scroll)
    }

    /// Scrolls towards older messages as a wheel or trackpad would.
    private func scrollUp(_ hosted: Hosted, by points: Int32) {
        for _ in 0..<max(1, points / 100) {
            guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
                                      wheel1: 100, wheel2: 0, wheel3: 0).flatMap(NSEvent.init(cgEvent:)) else { return }
            hosted.scroll.scrollWheel(with: event)
            Self.spin(0.02)
        }
        Self.spin()
    }

    /// Clicks the scroll-to-latest key's arrow: the trailing 30pt disc of the key laid at the list's bottom trailing
    /// corner, inside the 16pt inset.
    private func clickScrollToLatest(_ hosted: Hosted) throws {
        let point = NSPoint(x: Self.size.width - FlareSizes.spacingLg - 6 - 15, y: FlareSizes.spacingLg + 21)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
                                                         timestamp: ProcessInfo.processInfo.systemUptime,
                                                         windowNumber: hosted.window.windowNumber, context: nil,
                                                         eventNumber: 0, clickCount: 1, pressure: 1))
            hosted.window.sendEvent(event)
            Self.spin(0.05)
        }
        Self.spin(0.8)
    }

    @MainActor
    private func checkOpensAtTheNewestMessage(legacy: Bool) throws {
        let timeline = Timeline((0..<60).map { Self.message($0) })
        let hosted = try host(timeline, legacy: legacy)
        defer { hosted.window.orderOut(nil) }
        XCTAssertGreaterThan(hosted.contentHeight, 2 * hosted.scroll.contentView.bounds.height, "more messages than fit")
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2, "opens at the newest message, not the oldest")
    }

    @MainActor func testTheTimelineOpensAtTheNewestMessage() throws { try checkOpensAtTheNewestMessage(legacy: false) }
    @MainActor func testTheIOS16TimelineOpensAtTheNewestMessage() throws { try checkOpensAtTheNewestMessage(legacy: true) }

    @MainActor
    private func checkFollowing(legacy: Bool) throws {
        let timeline = Timeline((0..<60).map { Self.message($0) })
        let hosted = try host(timeline, legacy: legacy)
        defer { hosted.window.orderOut(nil) }

        // At the bottom, a message from someone else stays in view.
        timeline.messages.append(Self.message(60))
        Self.spin()
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2, "an appended message at the bottom stays in view")
        XCTAssertEqual(timeline.belowCount, 0, "no key at the bottom")

        // Scrolled up, others' messages leave the reader where they are and are counted.
        scrollUp(hosted, by: 1_200)
        let offset = hosted.scroll.contentView.bounds.origin.y
        XCTAssertGreaterThan(hosted.distanceToBottom, 600)
        timeline.messages.append(contentsOf: [Self.message(61), Self.message(62)])
        Self.spin()
        XCTAssertEqual(hosted.scroll.contentView.bounds.origin.y, offset, accuracy: 2, "the list does not move")
        XCTAssertEqual(timeline.belowCount, 2, "the key counts the messages below")

        // Older messages added above keep the visible message in place.
        let belowBefore = hosted.distanceToBottom
        timeline.messages.insert(contentsOf: (-20..<0).map { Self.message($0) }, at: 0)
        Self.spin(0.8)
        XCTAssertEqual(hosted.distanceToBottom, belowBefore, accuracy: 4, "loading older keeps the reading position")
        XCTAssertEqual(timeline.belowCount, 2)

        // The reader's own message brings the list down.
        timeline.messages.append(Self.message(63, sender: "me"))
        Self.spin(0.8)
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2, "an own message goes to the newest message")
        XCTAssertEqual(timeline.belowCount, 0)
    }

    @MainActor func testAppendedMessagesFollowAtTheBottomAndWaitBelowAReaderWhoScrolledUp() throws {
        try checkFollowing(legacy: false)
    }

    @MainActor func testTheIOS16TimelineFollowsTheSameRules() throws { try checkFollowing(legacy: true) }

    @MainActor
    func testTheScrollToLatestKeyGoesToTheNewestMessage() throws {
        let timeline = Timeline((0..<60).map { Self.message($0) })
        let hosted = try host(timeline, legacy: false)
        defer { hosted.window.orderOut(nil) }
        scrollUp(hosted, by: 1_500)
        timeline.messages.append(Self.message(60))
        Self.spin()
        XCTAssertEqual(timeline.belowCount, 1)
        XCTAssertGreaterThan(hosted.distanceToBottom, 600)
        try clickScrollToLatest(hosted)
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2)
        XCTAssertEqual(timeline.belowCount, 0, "the key goes away at the bottom")
    }
}
#endif
