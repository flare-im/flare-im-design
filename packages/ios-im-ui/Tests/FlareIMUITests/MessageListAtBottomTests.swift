import CoreGraphics
import Foundation
import SwiftUI
import XCTest
@testable import FlareIMUI

/// Whether the reader is at the bottom (`spec/message-list-paging-vectors.json` `atBottom`): the shared steps on the
/// list's report. The hosted tests below run the same rules on the component.
final class MessageListAtBottomTests: XCTestCase {
    private struct Table: Decodable {
        struct Group: Decodable {
            struct Step: Decodable {
                let `do`: String
                let fromBottom: CGFloat?
                let reports: Bool?
            }
            struct Case: Decodable {
                let id: String
                let steps: [Step]
            }
            let within: CGFloat
            let cases: [Case]
        }
        let atBottom: Group
    }

    private func table() throws -> Table.Group {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/message-list-paging-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url)).atBottom
    }

    func testTheBottomIsWithinTheDistanceTheTableNames() throws {
        let group = try table()
        XCTAssertEqual(FlareMessageListPaging.bottomWithin, group.within)
        XCTAssertEqual(TimelineFollow.stickyDistance, group.within)
        XCTAssertGreaterThanOrEqual(group.cases.count, 18)
    }

    func testTheReportTellsWhatTheTableSays() throws {
        for vector in try table().cases {
            var report = FlareMessageListPaging.BottomReport()
            let told: [Bool?] = try vector.steps.map { step in
                switch step.do {
                case "layout": return report.layout(fromBottom: try XCTUnwrap(step.fromBottom))
                case "replaced": return report.replaced()
                case "jumpedToLatest": return report.jumpedToLatest()
                case "located": return report.located()
                case "readerMoved": return report.readerMoved()
                case "wentToLatest": return report.wentToLatest()
                case "emptied": return report.emptied()
                case "anotherConversation": report.anotherConversation(); return nil
                default: XCTFail("unknown step \(step.do)"); return nil
                }
            }
            XCTAssertEqual(told, vector.steps.map(\.reports), vector.id)
        }
    }

    /// The rows tell the report which change they were: a replacement, the latest window asked for, or the reader's
    /// own message added at the end; the newest row of a replaced window is not the reader's arrival, even when theirs.
    func testTheRowsSayWhichChangeTheReportReads() {
        func rows(_ ids: [String], own: Set<String> = []) -> [TimelineFollow.Row] {
            ids.map { TimelineFollow.Row(id: $0, own: own.contains($0)) }
        }
        var follow = TimelineFollow()
        var paging = TimelinePaging()
        _ = paging.rowsChanged(from: ["a", "b"], to: TimelinePagingRows(rows: rows(["a", "b", "c"], own: ["c"]), detached: false), follow: &follow)
        XCTAssertEqual(paging.bottomStep, .ownArrived)
        _ = paging.rowsChanged(from: ["a", "b", "c"], to: TimelinePagingRows(rows: rows(["a", "b", "c", "d"]), detached: false), follow: &follow)
        XCTAssertEqual(paging.bottomStep, .none)
        _ = paging.rowsChanged(from: ["a", "b", "c", "d"], to: TimelinePagingRows(rows: rows(["x", "y"], own: ["y"]), detached: true), follow: &follow)
        XCTAssertEqual(paging.bottomStep, .replaced)
        paging.jumpRequested = true
        _ = paging.rowsChanged(from: ["x", "y"], to: TimelinePagingRows(rows: rows(["p", "q"]), detached: false), follow: &follow)
        XCTAssertEqual(paging.bottomStep, .jumpedToLatest)
    }
}

#if os(macOS)
import AppKit

/// The same rules on a hosted list, scrolled with wheel events the scroll view handles as the reader's own.
final class MessageListAtBottomHostedTests: XCTestCase {
    private final class Timeline: ObservableObject {
        @Published var messages: [FlareMessageData]
        @Published var windowId: String? = "timeline:1"
        /// Every answer the list told, in order.
        var told: [Bool] = []
        init(_ messages: [FlareMessageData]) { self.messages = messages }
    }

    private struct Host: View {
        @ObservedObject var timeline: Timeline
        let controller: FlareMessageListController
        var body: some View {
            MessageListView(messages: timeline.messages, currentUserId: "me", windowId: timeline.windowId,
                            onAtBottomChange: { [timeline] in timeline.told.append($0) },
                            conversationId: "c1", controller: controller)
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
        var distanceToBottom: CGFloat { (scroll.documentView?.frame.height ?? 0) - scroll.contentView.bounds.maxY }
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
    private func host(_ timeline: Timeline, controller: FlareMessageListController = FlareMessageListController()) throws -> Hosted {
        _ = NSApplication.shared
        let root = Host(timeline: timeline, controller: controller).frame(width: Self.size.width, height: Self.size.height)
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

    /// Scrolls as a wheel or trackpad would: positive towards older messages, negative towards newer.
    private func scroll(_ hosted: Hosted, by points: Int32) {
        for _ in 0..<max(1, abs(points) / 100) {
            guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
                                      wheel1: points > 0 ? 100 : -100, wheel2: 0, wheel3: 0).flatMap(NSEvent.init(cgEvent:))
            else { return }
            hosted.scroll.scrollWheel(with: event)
            Self.spin(0.02)
        }
        Self.spin()
    }

    @MainActor
    func testTheFirstLayoutTellsTheBottomOnce() throws {
        let timeline = Timeline((0..<60).map { Self.message($0) })
        let hosted = try host(timeline)
        defer { hosted.window.orderOut(nil) }
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2)
        XCTAssertEqual(timeline.told, [true])
    }

    @MainActor
    func testScrollingUpTellsFalseAndComingBackTellsTrue() throws {
        let timeline = Timeline((0..<60).map { Self.message($0) })
        let hosted = try host(timeline)
        defer { hosted.window.orderOut(nil) }
        scroll(hosted, by: 1_200)
        XCTAssertGreaterThan(hosted.distanceToBottom, FlareMessageListPaging.bottomWithin)
        XCTAssertEqual(timeline.told, [true, false])
        scroll(hosted, by: -3_000)
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2)
        XCTAssertEqual(timeline.told, [true, false, true])
    }

    @MainActor
    func testMessagesArrivingUnderAReaderAtTheBottomKeepThemThere() throws {
        let timeline = Timeline((0..<60).map { Self.message($0) })
        let hosted = try host(timeline)
        defer { hosted.window.orderOut(nil) }
        timeline.messages.append(Self.message(60))
        Self.spin()
        timeline.messages.append(contentsOf: [Self.message(61), Self.message(62)])
        Self.spin()
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2, "the list follows the new messages")
        XCTAssertEqual(timeline.told, [true])
    }

    @MainActor
    func testAWindowReplacedWithoutTheReaderAskingIsNotTheirBottomUntilTheyMoveIt() throws {
        let timeline = Timeline((100..<160).map { Self.message($0) })
        let hosted = try host(timeline)
        defer { hosted.window.orderOut(nil) }
        timeline.messages = (20..<80).map { Self.message($0) }
        timeline.windowId = "timeline:2"
        Self.spin(0.8)
        // The list opened the new window at its newest row; that is not the reader arriving there.
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2)
        XCTAssertEqual(timeline.told, [true, false])
        // The reader's own move, towards the newest row they are already at.
        scroll(hosted, by: -200)
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2)
        XCTAssertEqual(timeline.told, [true, false, true])
    }

    @MainActor
    func testALocateHoldsTheAnswerEvenAtTheLastRow() throws {
        let timeline = Timeline((0..<60).map { Self.message($0) })
        let controller = FlareMessageListController()
        let hosted = try host(timeline, controller: controller)
        defer { hosted.window.orderOut(nil) }
        XCTAssertTrue(controller.scrollToMessage("m59"))
        Self.spin(0.8)
        XCTAssertEqual(timeline.told, [true, false])
        timeline.messages.append(Self.message(60, sender: "me"))
        Self.spin(0.8)
        XCTAssertEqual(timeline.told, [true, false, true], "a message of the reader's own takes them to the newest row")
    }
}
#endif
