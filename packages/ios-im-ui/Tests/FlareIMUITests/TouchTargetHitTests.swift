#if os(macOS)
import AppKit
import SwiftUI
import XCTest
@testable import FlareIMUI

/// The 44pt touch target is a hit area, not only a frame: a click inside the target but outside what
/// the control draws reaches the button, and a click past the target does not. The control is hosted
/// in a borderless window and clicked with real mouse events; SwiftUI hit-tests a button by its
/// label's frame on macOS as on iOS.
final class TouchTargetHitTests: XCTestCase {
    private let side: CGFloat = 200

    /// Taps the button `make` builds, centred in the window, at `offset` from the centre.
    @MainActor
    private func taps(at offset: CGPoint, _ make: (@escaping () -> Void) -> AnyView) -> Int {
        final class Counter { var value = 0 }
        let counter = Counter()
        _ = NSApplication.shared
        let size = NSSize(width: side, height: side)
        let host = NSHostingView(rootView: make({ counter.value += 1 }).frame(width: side, height: side))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        // AppKit window coordinates start at the bottom left.
        let point = NSPoint(x: side / 2 + offset.x, y: side / 2 - offset.y)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            guard let event = NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
                                                 timestamp: ProcessInfo.processInfo.systemUptime,
                                                 windowNumber: window.windowNumber, context: nil,
                                                 eventNumber: 0, clickCount: 1, pressure: 1) else { return -1 }
            window.sendEvent(event)
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return counter.value
    }

    @MainActor
    func testACompactKeyTakesTapsAcrossItsWholeTargetAndNoFurther() {
        let key: (@escaping () -> Void) -> AnyView = { action in
            AnyView(Button(action: action) { Color.red.frame(width: 16, height: 16).flareTouchTarget() }
                .buttonStyle(.plain)
                .flareCompactLayout(width: 16, height: 16))
        }
        XCTAssertEqual(taps(at: CGPoint(x: 0, y: 0), key), 1, "on the key")
        XCTAssertEqual(taps(at: CGPoint(x: 19, y: 0), key), 1, "beside the key, inside its 44pt target")
        XCTAssertEqual(taps(at: CGPoint(x: 0, y: -19), key), 1, "above the key, inside its 44pt target")
        XCTAssertEqual(taps(at: CGPoint(x: 30, y: 0), key), 0, "past the target")
    }

    @MainActor
    func testTheSmallIconButtonTakesTapsOutsideItsDisc() {
        let button: (@escaping () -> Void) -> AnyView = { action in
            AnyView(IconButtonView(icon: "close", accessibilityLabel: "Close", size: .sm,
                                   action: action))
        }
        XCTAssertEqual(taps(at: CGPoint(x: 19, y: 0), button), 1, "the 30pt disc has a 44pt target")
        XCTAssertEqual(taps(at: CGPoint(x: 27, y: 0), button), 0, "past the target")
    }

    /// Why ``View/flareTouchTarget(alignment:)`` grows the label: a larger background behind it is drawn
    /// but never hit.
    @MainActor
    func testATargetLaidBehindTheLabelIsNotHit() {
        let behind: (@escaping () -> Void) -> AnyView = { action in
            AnyView(Button(action: action) {
                Color.red.frame(width: 16, height: 16)
                    .background(Color.clear.frame(width: 44, height: 44).contentShape(Rectangle()))
            }.buttonStyle(.plain))
        }
        XCTAssertEqual(taps(at: CGPoint(x: 0, y: 0), behind), 1)
        XCTAssertEqual(taps(at: CGPoint(x: 19, y: 0), behind), 0)
    }
}
#endif
