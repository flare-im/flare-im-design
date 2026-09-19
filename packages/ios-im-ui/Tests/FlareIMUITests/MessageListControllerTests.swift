#if os(macOS)
import AppKit
import SwiftUI
import XCTest
@testable import FlareIMUI

/// ``FlareMessageListController/scrollToMessage(_:)`` — the host's entrance to the list's own locate
/// path, hosted in a real window.
///
/// Whether a row ended up on screen is read off the window's own rendering, not off the view tree: an
/// inspected tree hands every `GeometryReader` a zero-size proxy, so nothing there can tell a row that
/// was scrolled to from one that was not. Each timeline below holds exactly one message from the
/// reader, and the outgoing bubble colour is the only thing painted in `messageOutgoingBackground` —
/// so counting the pixels drawn in that colour says whether that row is in the window, and where.
final class MessageListControllerTests: XCTestCase {
    private final class Timeline: ObservableObject {
        @Published var messages: [FlareMessageData]
        init(_ messages: [FlareMessageData]) { self.messages = messages }
    }

    private struct Host: View {
        @ObservedObject var timeline: Timeline
        let controller: FlareMessageListController
        let legacy: Bool
        var body: some View {
            MessageListView(messages: timeline.messages, currentUserId: "me", conversationId: "c1",
                            controller: controller)
                .environment(\.flareLegacyTimelineScrolling, legacy)
                .environment(\.colorScheme, .light)
        }
    }

    private static let size = NSSize(width: 360, height: 480)
    private static let today = Int64(Date().timeIntervalSince1970 * 1000)

    /// 80 messages from the other side, except the one at `own`, which is the reader's: that is the
    /// row these tests look for in the window.
    private static func timeline(own: Int, from first: Int = 0, count: Int = 80) -> [FlareMessageData] {
        (first..<(first + count)).map { index in
            FlareMessageData(id: "m\(index)", senderId: index == own ? "me" : "peer",
                             senderName: index == own ? "Me" : "peer",
                             content: FlareTextContent("message number \(index)"),
                             sentAtMs: today + Int64(index))
        }
    }

    private static func findScroll(_ view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        for sub in view.subviews { if let scroll = findScroll(sub) { return scroll } }
        return nil
    }

    private static func spin(_ seconds: TimeInterval = 0.5) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    /// Spins until `settled()` holds, or until the deadline. A scroll is asked for and then happens over
    /// however many passes the machine gives it: a fixed sleep is a guess that a loaded machine loses, and
    /// this test has been seen failing that way with two targets reporting the same offset.
    private static func spin(until settled: () -> Bool, timeout: TimeInterval = 4) {
        let deadline = Date().addingTimeInterval(timeout)
        while !settled(), Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    /// Spins until a scroll asked for from `before` has started and then stopped moving (FR-123, FR-149).
    /// It reads the scroll's own geometry and nothing else: drawing the window while the iOS 16 path is
    /// scrolling stops it where it is, so a condition that draws cannot be used to wait for one.
    private static func spinUntilSettled(from before: CGFloat, _ offset: () -> CGFloat, timeout: TimeInterval = 8) {
        let deadline = Date().addingTimeInterval(timeout)
        while offset() == before, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        // The scroll animates for `FlareMotion.normal`; a stall inside that window is the animation, not
        // its end. Spend it before looking for stillness, so a busy machine cannot make a pause look like
        // an arrival — which is how two targets came to report one offset.
        RunLoop.main.run(until: Date().addingTimeInterval(FlareMotion.normal + 0.2))
        // Half a second of no movement, not a third: a busy machine stalls an animation between frames, and
        // three samples of a stall read as "arrived" — which is how two targets came to report one offset.
        var last = offset()
        var still = 0
        while still < 5, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            let now = offset()
            still = now == last ? still + 1 : 0
            last = now
        }
    }

    private struct Hosted {
        let window: NSWindow
        let host: NSHostingView<AnyView>
        let scroll: NSScrollView
        /// How far the visible rect has been scrolled down from the oldest message.
        var offset: CGFloat { scroll.contentView.bounds.origin.y }
        var distanceToBottom: CGFloat {
            (scroll.documentView?.frame.height ?? 0) - scroll.contentView.bounds.maxY
        }
    }

    @MainActor
    private func host(_ timeline: Timeline, _ controller: FlareMessageListController,
                      legacy: Bool = false) throws -> Hosted {
        _ = NSApplication.shared
        let root = AnyView(Host(timeline: timeline, controller: controller, legacy: legacy)
            .frame(width: Self.size.width, height: Self.size.height))
        let host = NSHostingView(rootView: root)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.colorSpace = .sRGB
        window.contentView = host
        host.setFrameSize(Self.size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        Self.spin(0.6)
        let scroll = try XCTUnwrap(Self.findScroll(host), "the timeline scrolls")
        return Hosted(window: window, host: host, scroll: scroll)
    }

    /// Where the reader's own bubble is drawn in the window: how many device pixels carry the outgoing
    /// bubble colour, and the middle of the band they cover, as a fraction of the window's height
    /// (0 at the top, 1 at the bottom).
    ///
    /// The bottom trailing corner is left out: the scroll-to-latest key's disc is `primary`, which is
    /// the same colour as an outgoing bubble, and it is up whenever the reader is not at the newest
    /// message — which is exactly the state these tests put the list in.
    @MainActor
    private func drawnSelfBubble(_ hosted: Hosted) throws -> (pixels: Int, centre: CGFloat) {
        let view = hosted.host
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let image = try XCTUnwrap(bitmap.cgImage)
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: width, height: height,
                                                  bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        let bubble = try XCTUnwrap(NSColor(FlareColors.of(.light).messageOutgoingBackground)
            .usingColorSpace(.sRGB))
        let target = (UInt8(round(bubble.redComponent * 255)), UInt8(round(bubble.greenComponent * 255)),
                      UInt8(round(bubble.blueComponent * 255)))
        let scale = CGFloat(width) / Self.size.width
        let keyLeft = Int((Self.size.width - 130) * scale), keyTop = Int((Self.size.height - 80) * scale)
        var pixels = 0
        var sum = 0
        for row in 0..<height {
            // The context drew the window bottom up; row 0 is the bottom of the window.
            let fromTop = height - 1 - row
            for column in 0..<width {
                let i = (row * width + column) * 4
                guard abs(Int(bytes[i]) - Int(target.0)) <= 3, abs(Int(bytes[i + 1]) - Int(target.1)) <= 3,
                      abs(Int(bytes[i + 2]) - Int(target.2)) <= 3, bytes[i + 3] > 200 else { continue }
                if column >= keyLeft && fromTop >= keyTop { continue }
                pixels += 1
                sum += fromTop
            }
        }
        return (pixels, pixels == 0 ? .nan : CGFloat(sum) / CGFloat(pixels) / CGFloat(height))
    }

    /// The bubble is on screen: a bubble covers thousands of device pixels, so anything above a
    /// thousand is the row and not an edge or a shadow.
    private static let onScreen = 1_000

    // MARK: - A loaded message

    @MainActor
    private func checkALoadedMessageIsBroughtIntoView(legacy: Bool) throws {
        let controller = FlareMessageListController()
        let hosted = try host(Timeline(Self.timeline(own: 10)), controller, legacy: legacy)
        defer { hosted.window.orderOut(nil) }

        // The list opens at the newest message, so the row asked for is far above the window.
        XCTAssertLessThanOrEqual(hosted.distanceToBottom, 2, "opens at the newest message")
        XCTAssertLessThan(try drawnSelfBubble(hosted).pixels, Self.onScreen, "the row asked for is not drawn yet")

        let atNewest = hosted.offset
        XCTAssertTrue(controller.scrollToMessage("m10"), "the list is drawing that message")
        Self.spinUntilSettled(from: atNewest, { hosted.offset })

        let drawn = try drawnSelfBubble(hosted)
        XCTAssertGreaterThan(drawn.pixels, Self.onScreen, "the row asked for is drawn in the window")
        XCTAssertGreaterThan(hosted.distanceToBottom, 2, "the list left the newest message")
    }

    @MainActor func testALoadedMessageIsAnsweredTrueAndBroughtIntoView() throws {
        try checkALoadedMessageIsBroughtIntoView(legacy: false)
    }

    @MainActor func testTheIOS16ListBringsALoadedMessageIntoViewTheSameWay() throws {
        try checkALoadedMessageIsBroughtIntoView(legacy: true)
    }

    /// Centred, like a tap on a loaded quote: the row lands in the middle of the window, not merely
    /// somewhere inside it.
    @MainActor
    func testTheRowLandsInTheMiddleOfTheWindow() throws {
        let controller = FlareMessageListController()
        let hosted = try host(Timeline(Self.timeline(own: 40)), controller)
        defer { hosted.window.orderOut(nil) }

        let atBottom = hosted.offset
        XCTAssertTrue(controller.scrollToMessage("m40"))
        Self.spinUntilSettled(from: atBottom, { hosted.offset })
        let drawn = try drawnSelfBubble(hosted)
        XCTAssertGreaterThan(drawn.pixels, Self.onScreen)
        XCTAssertEqual(drawn.centre, 0.5, accuracy: 0.12, "the row is centred in the window")
    }

    /// The list goes to the row that was asked for, not merely somewhere else: three targets, three
    /// offsets, in the order of the rows.
    @MainActor
    func testTheListGoesToTheRowThatWasAskedFor() throws {
        let controller = FlareMessageListController()
        let hosted = try host(Timeline(Self.timeline(own: 40)), controller)
        defer { hosted.window.orderOut(nil) }

        var offsets: [CGFloat] = []
        for index in [5, 40, 70] {
            let before = hosted.offset
            XCTAssertTrue(controller.scrollToMessage("m\(index)"))
            Self.spinUntilSettled(from: before, { hosted.offset })
            offsets.append(hosted.offset)
        }
        XCTAssertLessThan(offsets[0], offsets[1], "an older row sits above a newer one")
        XCTAssertLessThan(offsets[1], offsets[2])
        // The middle target is the reader's own row, and it is the one drawn once the list stops there.
        XCTAssertLessThan(try drawnSelfBubble(hosted).pixels, Self.onScreen, "m70 is a long way past m40")
    }

    // MARK: - A message the list does not have

    @MainActor
    func testAMessageTheListDoesNotHaveIsAnsweredFalseAndNothingMoves() throws {
        let controller = FlareMessageListController()
        let hosted = try host(Timeline(Self.timeline(own: 10)), controller)
        defer { hosted.window.orderOut(nil) }

        let atBottom = hosted.offset
        XCTAssertTrue(controller.scrollToMessage("m10"))
        Self.spinUntilSettled(from: atBottom, { hosted.offset })
        let offset = hosted.offset
        let drawn = try drawnSelfBubble(hosted).pixels

        XCTAssertFalse(controller.scrollToMessage("m900"), "that message is not in this window of history")
        XCTAssertFalse(controller.scrollToMessage(""), "a blank id asks for nothing")
        XCTAssertFalse(controller.scrollToMessage("   "))
        Self.spin(0.6)
        XCTAssertEqual(hosted.offset, offset, accuracy: 1, "the list did not move")
        XCTAssertEqual(try drawnSelfBubble(hosted).pixels, drawn, accuracy: 40, "the window did not change")
    }

    /// A message paged in answers true on the next ask: the handle carries the rows of the pass that
    /// drew them, not the rows of the pass that first attached it.
    @MainActor
    func testAMessagePagedInIsAnsweredTrue() throws {
        let controller = FlareMessageListController()
        let timeline = Timeline(Self.timeline(own: -1, from: 20, count: 60))
        let hosted = try host(timeline, controller)
        defer { hosted.window.orderOut(nil) }

        XCTAssertFalse(controller.scrollToMessage("m3"), "not paged in yet")
        timeline.messages.insert(contentsOf: Self.timeline(own: 3, from: 0, count: 20), at: 0)
        Self.spin(0.9)

        let beforeThird = hosted.offset
        XCTAssertTrue(controller.scrollToMessage("m3"), "the list is drawing it now")
        Self.spinUntilSettled(from: beforeThird, { hosted.offset })
        XCTAssertGreaterThan(try drawnSelfBubble(hosted).pixels, Self.onScreen, "the row paged in is drawn")
    }

    // MARK: - FR-114: either of a row's two ids

    /// The reader's own message is drawn under its client id while the core names it by the server's,
    /// and a quote points at it by the core's. A host hands the handle the id it was given, so both
    /// have to bring the same row into view — before this, the core id answered false for a message
    /// that was on screen.
    @MainActor
    func testEitherOfARowsTwoIdsBringsTheSameRowIntoView() throws {
        let controller = FlareMessageListController()
        var rows = Self.timeline(own: -1)
        rows[30] = FlareMessageData(id: "cli-30", senderId: "me", senderName: "Me",
                                    content: FlareTextContent("message number 30"), serverId: "srv-30",
                                    sentAtMs: Self.today + 30)
        let hosted = try host(Timeline(rows), controller)
        defer { hosted.window.orderOut(nil) }
        XCTAssertLessThan(try drawnSelfBubble(hosted).pixels, Self.onScreen, "the row asked for is not drawn yet")

        // Only that one row is the reader's, so seeing its bubble centred says the list went to it and
        // not merely somewhere. (Absolute offsets are not comparable across scrolls: a lazy stack
        // refines the heights above as it lays the rows out.)
        let atOpen = hosted.offset
        XCTAssertTrue(controller.scrollToMessage("srv-30"), "the id the core names that row by")
        Self.spinUntilSettled(from: atOpen, { hosted.offset })
        let byCoreId = try drawnSelfBubble(hosted)
        XCTAssertGreaterThan(byCoreId.pixels, Self.onScreen, "the row the core named is in the window")
        XCTAssertEqual(byCoreId.centre, 0.5, accuracy: 0.12, "centred, as a tap on a loaded quote is")

        // Away, then back by the id the list draws that row under: the same row, the same way.
        let atCoreId = hosted.offset
        XCTAssertTrue(controller.scrollToMessage("m0"))
        Self.spinUntilSettled(from: atCoreId, { hosted.offset })
        XCTAssertLessThan(try drawnSelfBubble(hosted).pixels, Self.onScreen, "the list left that row")
        let atOldest = hosted.offset
        XCTAssertTrue(controller.scrollToMessage("cli-30"), "the id the list draws that row under")
        Self.spinUntilSettled(from: atOldest, { hosted.offset })
        let byRowId = try drawnSelfBubble(hosted)
        XCTAssertGreaterThan(byRowId.pixels, Self.onScreen, "both ids reach the same row")
        XCTAssertEqual(byRowId.centre, 0.5, accuracy: 0.12)

        XCTAssertFalse(controller.scrollToMessage("srv-31"), "a core id no row carries is still not found")
        XCTAssertFalse(controller.scrollToMessage("m30"), "and neither is the id that row would have had")
    }

    // MARK: - Lifecycle

    @MainActor
    func testTheHandleAnswersFalseBeforeAndAfterTheListIsThere() throws {
        let controller = FlareMessageListController()
        // Before any list takes it: the host may ask first and build the list afterwards.
        XCTAssertFalse(controller.scrollToMessage("m10"), "no list is attached")

        let hosted = try host(Timeline(Self.timeline(own: 10)), controller)
        XCTAssertTrue(controller.scrollToMessage("m10"))
        Self.spin(0.6)

        // The list goes away: the handle stops answering for rows nobody is drawing.
        hosted.window.contentView = NSView(frame: NSRect(origin: .zero, size: Self.size))
        hosted.window.orderOut(nil)
        Self.spin(0.6)
        XCTAssertFalse(controller.scrollToMessage("m10"), "the list is gone")
    }

    /// A second list takes the handle over; the first one going away afterwards does not take the
    /// handle with it.
    @MainActor
    func testAListThatWentAwayDoesNotClearTheListThatTookOver() throws {
        let controller = FlareMessageListController()
        let first = try host(Timeline(Self.timeline(own: 10)), controller)
        let second = try host(Timeline(Self.timeline(own: 10)), controller)
        defer { second.window.orderOut(nil) }

        first.window.contentView = NSView(frame: NSRect(origin: .zero, size: Self.size))
        first.window.orderOut(nil)
        Self.spin(0.6)

        let atSecondBottom = second.offset
        XCTAssertTrue(controller.scrollToMessage("m10"), "the list that is still there answers")
        Self.spinUntilSettled(from: atSecondBottom, { second.offset })
        XCTAssertGreaterThan(try drawnSelfBubble(second).pixels, Self.onScreen)
    }
}
#endif
