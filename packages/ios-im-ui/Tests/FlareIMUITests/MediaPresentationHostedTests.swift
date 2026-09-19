#if os(macOS)
import AppKit
import SwiftUI
import XCTest
@testable import FlareIMUI

/// End to end on a hosted view: clicking an image body with no host media handler presents the kit
/// viewer (a sheet on the macOS host, the full-screen cover on iOS — the same presentation state).
final class MediaPresentationHostedTests: XCTestCase {
    /// Hosts `view` in a titled window, clicks `at` (from the top left; the centre by default), and returns
    /// how many sheets the window shows.
    @MainActor
    private func sheetsAfterClicking(_ view: some View, size: NSSize = NSSize(width: 320, height: 320),
                                     at point: CGPoint? = nil) throws -> Int {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer {
            window.sheets.forEach { window.endSheet($0) }
            window.orderOut(nil)
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        XCTAssertTrue(window.sheets.isEmpty, "nothing is presented before the click")

        // AppKit window coordinates start at the bottom left.
        let target = point.map { NSPoint(x: $0.x, y: size.height - $0.y) } ?? NSPoint(x: size.width / 2, y: size.height / 2)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: target, modifierFlags: [],
                                                         timestamp: ProcessInfo.processInfo.systemUptime,
                                                         windowNumber: window.windowNumber, context: nil,
                                                         eventNumber: 0, clickCount: 1, pressure: 1))
            window.sendEvent(event)
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        let deadline = Date().addingTimeInterval(1.5)
        while window.sheets.isEmpty && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return window.sheets.count
    }

    @MainActor
    func testClickingAnImageBodyPresentsTheKitViewer() throws {
        let image = FlareImageContent(url: "https://invalid.invalid/full.jpg", alt: "海边")
        XCTAssertEqual(try sheetsAfterClicking(MessageContentView(content: image)), 1, "the kit viewer is presented")
    }

    @MainActor
    func testClickingAnImageInTheListPresentsTheListViewer() throws {
        // An outgoing image: chromeless, 240 x 180, trailing inside the 12pt row padding, below the date
        // pill — and at the *bottom* of the viewport, because the timeline opens at the newest message
        // (K1), not at the top.
        let message = FlareMessageData(id: "m1", senderId: "me", senderName: "Me",
                                       content: FlareImageContent(url: "https://invalid.invalid/full.jpg", alt: "海边"),
                                       sentAtMs: Int64(Date().timeIntervalSince1970 * 1000))
        let list = MessageListView(messages: [message], currentUserId: "me")
        XCTAssertEqual(try sheetsAfterClicking(list, size: NSSize(width: 320, height: 600), at: CGPoint(x: 188, y: 480)), 1)
    }

    @MainActor
    func testClickingAnImageBodyWithAHostHandlerPresentsNothing() throws {
        final class Counter { var taps = 0 }
        let counter = Counter()
        let image = FlareImageContent(url: "https://invalid.invalid/full.jpg", alt: "海边")
        let view = MessageContentView(content: image, onMediaAction: { _ in counter.taps += 1 })
        XCTAssertEqual(try sheetsAfterClicking(view), 0, "the host handler keeps control")
        XCTAssertEqual(counter.taps, 1)
    }
}
#endif
