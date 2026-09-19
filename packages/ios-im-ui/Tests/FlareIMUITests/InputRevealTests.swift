#if os(macOS)
import AppKit
#endif
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-045: every app wrote its own password unmask key beside the kit's field. The field owns it now:
/// `revealable` draws the key, the kit names it (显示密码 / 隐藏密码), and only a single-line, enabled,
/// secure field can offer it — whether the value is showing is the field's own, never reported to the host.
final class InputRevealTests: XCTestCase {
    private let s = FlareStrings()

    @MainActor
    private func field(secure: Bool = true, revealable: Bool = true, multiline: Bool = false,
                       disabled: Bool = false, text: String = "hunter2") -> InputView {
        InputView(text: .constant(text), multiline: multiline, disabled: disabled, secure: secure,
                  revealable: revealable)
    }

    @MainActor
    private func revealKey(_ view: some View) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: {
            let name = try $0.accessibilityLabel().string()
            return name == s.inputReveal || name == s.inputHide
        })
    }

    func testTheStringsTableNamesBothSidesOfTheKey() {
        XCTAssertEqual(s.inputReveal, "显示密码")
        XCTAssertEqual(s.inputHide, "隐藏密码")
    }

    @MainActor
    func testOnlyASingleLineEnabledSecureFieldOffersTheKey() throws {
        XCTAssertNoThrow(try revealKey(field()), "a secure revealable field draws the key")
        XCTAssertThrowsError(try revealKey(field(revealable: false)),
                             "a secure field the host did not mark revealable stays masked")
        XCTAssertThrowsError(try revealKey(field(secure: false)), "there is nothing to unmask on a plain field")
        XCTAssertThrowsError(try revealKey(field(multiline: true)), "a masked field is single line")
        XCTAssertThrowsError(try revealKey(field(disabled: true)), "a disabled field has no keys")
    }

    @MainActor
    func testTheKeyStartsClosedNamesWhatItWillDoAndIsATouchTarget() throws {
        let view = field()
        let key = try revealKey(view)
        XCTAssertEqual(try key.accessibilityLabel().string(), s.inputReveal)
        let frame = try key.labelView().find(ViewType.Image.self).flexFrame()
        XCTAssertGreaterThanOrEqual(frame.minWidth, FlareSizes.touchTargetMin, "the key is a touch target wide")
        XCTAssertGreaterThanOrEqual(frame.minHeight, FlareSizes.touchTargetMin)
        XCTAssertNoThrow(try view.inspect().find(ViewType.SecureField.self), "the value starts masked")
        XCTAssertThrowsError(try view.inspect().find(ViewType.TextField.self))
    }

    @MainActor
    func testTheClearKeyIsATouchTargetToo() throws {
        let clearable = InputView(text: .constant("Ada"), clearable: true)
        let key = try clearable.inspect().find(ViewType.Button.self, where: {
            try $0.accessibilityLabel().string() == s.clear
        })
        let frame = try key.labelView().find(ViewType.Image.self).flexFrame()
        XCTAssertGreaterThanOrEqual(frame.minWidth, FlareSizes.touchTargetMin)
        XCTAssertGreaterThanOrEqual(frame.minHeight, FlareSizes.touchTargetMin)
    }

#if os(macOS)
    /// End to end on a hosted window, because the unmasked state is the field's own `@State`: the key is
    /// really pressed and the platform field really changes — AppKit draws a secure field while the value
    /// is masked and a plain one once it is not.
    @MainActor
    func testPressingTheKeyReallyUnmasksTheFieldAndMasksItAgain() throws {
        _ = NSApplication.shared
        let size = NSSize(width: 320, height: 80)
        let host = NSHostingView(rootView: field().frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        XCTAssertTrue(drawsSecureField(host), "the value starts masked")

        // The key is the trailing control: a touch target wide, inside the field's horizontal padding.
        let key = NSPoint(x: size.width - FlareSizes.spacingMd - FlareSizes.touchTargetMin / 2, y: size.height / 2)
        try press(key, in: window, host: host)
        XCTAssertFalse(drawsSecureField(host), "the key unmasked the value")
        XCTAssertTrue(classes(host).contains("AppKitTextField"), "and the plain field is drawn in its place")

        try press(key, in: window, host: host)
        XCTAssertTrue(drawsSecureField(host), "pressing it again masks the value")
    }

    @MainActor
    private func classes(_ view: NSView) -> [String] {
        [String(describing: type(of: view))] + view.subviews.flatMap { classes($0) }
    }

    @MainActor
    private func drawsSecureField(_ host: NSView) -> Bool { classes(host).contains("AppKitSecureTextField") }

    @MainActor
    private func press(_ point: NSPoint, in window: NSWindow, host: NSView) throws {
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
                                                         timestamp: ProcessInfo.processInfo.systemUptime,
                                                         windowNumber: window.windowNumber, context: nil,
                                                         eventNumber: 0, clickCount: 1, pressure: 1))
            window.sendEvent(event)
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    }
#endif
}
