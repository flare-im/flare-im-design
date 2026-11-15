import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FullScreenView as a whole layer and its presenter: the content and its name, the ground tokens, the content
/// filling the screen, and the presenter leaving the page alone while closed. Spec: Overlay/FullScreen.
final class FullScreenViewTests: XCTestCase {
    private let s = FlareStrings()

    @MainActor
    func testTheContentShowsAndTheLayerIsNamedByItsLabel() throws {
        let named = FullScreenView(label: "Camera", onClose: {}) { Text("Viewfinder") }
        XCTAssertNoThrow(try named.inspect().find(text: "Viewfinder"))
        XCTAssertNoThrow(try named.inspect().find(viewWithAccessibilityLabel: "Camera"))
        let unnamed = FullScreenView(onClose: {}) { Text("Viewfinder") }
        XCTAssertNoThrow(try unnamed.inspect().find(viewWithAccessibilityLabel: s.modalLabel),
                         "without a label the kit's modal name")
    }

    @MainActor
    func testTheContentKeepsItsOwnChrome() throws {
        var cancelled = 0
        let screen = FullScreenView(label: "Document", onClose: {}) {
            ButtonView(label: s.cancel, variant: .quiet, size: .md) { cancelled += 1 }
        }
        try screen.inspect().find(button: s.cancel).tap()
        XCTAssertEqual(cancelled, 1)
        XCTAssertThrowsError(try screen.inspect().find(button: s.close),
                             "the kit adds no close button: the content owns its chrome")
    }

    func testTheGroundIsThePageGroundOrTheMediaStage() {
        for scheme in [ColorScheme.light, .dark] {
            let colors = FlareColors.of(scheme)
            XCTAssertEqual(FlareOverlayRules.fullScreenGround(.surface, colors: colors), colors.bgPrimary)
            XCTAssertEqual(FlareOverlayRules.fullScreenGround(.stage, colors: colors), colors.mediaStage)
        }
    }

    func testEscapeClosesUnlessTheLayerIsLocked() {
        let open = FlareOverlayRules.dismissAllowed(dismissible: true, busy: false, locked: false)
        XCTAssertEqual(FlareOverlayRules.escape(showBack: false, dismissAllowed: open), .close)
        let held = FlareOverlayRules.dismissAllowed(dismissible: true, busy: false, locked: true)
        XCTAssertEqual(FlareOverlayRules.escape(showBack: false, dismissAllowed: held), .none)
        let fixed = FlareOverlayRules.dismissAllowed(dismissible: false, busy: false, locked: false)
        XCTAssertEqual(FlareOverlayRules.escape(showBack: false, dismissAllowed: fixed), .none)
    }

    // MARK: Rendered (macOS)

    #if os(macOS)
    @MainActor
    private func render<V: View>(_ view: V, size: CGSize) -> NSWindow {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        host.layoutSubtreeIfNeeded()
        return window
    }

    private final class Seen { var frame: CGRect = .zero; var appeared = 0 }

    private struct FrameProbe: View {
        let seen: Seen
        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .task(id: proxy.frame(in: .global)) { seen.frame = proxy.frame(in: .global) }
                    .onAppear { seen.appeared += 1 }
            }
        }
    }

    @MainActor
    func testTheContentFillsTheWholeLayer() {
        let seen = Seen()
        let size = CGSize(width: 800, height: 600)
        let window = render(FullScreenView(ground: .stage, onClose: {}) { FrameProbe(seen: seen) }, size: size)
        defer { window.close() }
        XCTAssertEqual(seen.frame.width, size.width, accuracy: 0.5)
        XCTAssertEqual(seen.frame.height, size.height, accuracy: 0.5)
    }

    @MainActor
    func testAClosedPresenterShowsOnlyThePage() {
        let seen = Seen()
        struct Item: Identifiable { let id: Int }
        let page = Text("Page")
            .flareFullScreen(isPresented: .constant(false), label: "Camera") { FrameProbe(seen: seen) }
            .flareFullScreen(item: .constant(Item?.none), label: "Document") { _ in FrameProbe(seen: seen) }
        let window = render(page, size: CGSize(width: 400, height: 300))
        defer { window.close() }
        XCTAssertEqual(seen.appeared, 0, "nothing of the layer is built while it is closed")
    }
    #endif
}
