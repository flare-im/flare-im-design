import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// DrawerView and ModalView as whole layers: header chrome, close / back intents, the dismiss locks, accessible
/// names, and (rendered on macOS) the panel's width and edge. Spec: Overlay/Drawer, Overlay/Modal.
final class DrawerModalViewTests: XCTestCase {
    private let s = FlareStrings()

    @MainActor
    private func button(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    // MARK: Drawer

    @MainActor
    func testDrawerHeaderClosesAndStepsBack() throws {
        var intents: [String] = []
        let drawer = DrawerView(title: "Group details", showBack: true, onBack: { intents.append("back") },
                                onClose: { intents.append("close") }) { Text("Members") }
        XCTAssertNoThrow(try drawer.inspect().find(text: "Group details"))
        XCTAssertNoThrow(try drawer.inspect().find(text: "Members"))
        try button(drawer, s.back).tap()
        try button(drawer, s.close).tap()
        XCTAssertEqual(intents, ["back", "close"])
    }

    @MainActor
    func testDrawerWithoutTitleActionsOrCloseDrawsNoHeader() throws {
        let drawer = DrawerView(label: "Profile", showClose: false, onClose: {}) { Text("Page with its own header") }
        XCTAssertThrowsError(try button(drawer, s.close))
        XCTAssertThrowsError(try button(drawer, s.back), "no back without showBack")
        XCTAssertNoThrow(try drawer.inspect().find(text: "Page with its own header"))
    }

    @MainActor
    func testDrawerSlotsAreDrawnInTheHeaderAndUnderTheContent() throws {
        let drawer = DrawerView(title: "Settings", actions: AnyView(Text("Edit")), footer: AnyView(Text("Sign out")),
                                onClose: {}) { Text("Rows") }
        XCTAssertNoThrow(try drawer.inspect().find(text: "Edit"))
        XCTAssertNoThrow(try drawer.inspect().find(text: "Sign out"))
    }

    @MainActor
    func testANonDismissibleDrawerDisablesItsCloseButton() throws {
        let locked = DrawerView(title: "Saving", dismissible: false, onClose: {}) { Text("Form") }
        XCTAssertTrue(try button(locked, s.close).isDisabled())
        let open = DrawerView(title: "Saving", onClose: {}) { Text("Form") }
        XCTAssertFalse(try button(open, s.close).isDisabled())
    }

    @MainActor
    func testTitleHiddenKeepsTheNameButDrawsNoHeading() throws {
        let drawer = DrawerView(title: "Contact", titleHidden: true, onClose: {}) { Text("Card") }
        XCTAssertThrowsError(try drawer.inspect().find(text: "Contact"))
        XCTAssertNoThrow(try button(drawer, s.close), "close still has its header row")
    }

    // MARK: Modal

    @MainActor
    func testModalHeaderFooterAndClose() throws {
        var closed = 0
        let modal = ModalView(title: "Search", actions: AnyView(Text("Filters")), footer: AnyView(Text("Done")),
                              onClose: { closed += 1 }) { Text("Results") }
        XCTAssertNoThrow(try modal.inspect().find(text: "Search"))
        XCTAssertNoThrow(try modal.inspect().find(text: "Filters"))
        XCTAssertNoThrow(try modal.inspect().find(text: "Done"))
        XCTAssertNoThrow(try modal.inspect().find(text: "Results"))
        try button(modal, s.close).tap()
        XCTAssertEqual(closed, 1)
    }

    @MainActor
    func testBusyOrNonDismissibleModalDisablesClose() throws {
        XCTAssertTrue(try button(ModalView(title: "Report", busy: true, onClose: {}) { Text("Form") }, s.close).isDisabled())
        XCTAssertTrue(try button(ModalView(title: "Report", dismissible: false, onClose: {}) { Text("Form") }, s.close).isDisabled())
        XCTAssertFalse(try button(ModalView(title: "Report", onClose: {}) { Text("Form") }, s.close).isDisabled())
    }

    @MainActor
    func testModalWithoutCloseOrTitleHasNoCloseButton() throws {
        let modal = ModalView(label: "Confirm", showClose: false, onClose: {}) { Text("Body") }
        XCTAssertThrowsError(try button(modal, s.close))
        XCTAssertNoThrow(try modal.inspect().find(text: "Body"))
    }

    // MARK: BottomSheet frame

    @MainActor
    func testBottomSheetTitleHiddenNamesTheSheetWithoutTheCaption() throws {
        let shown = BottomSheetView(title: "Actions") { Text("Copy") }
        XCTAssertNoThrow(try shown.inspect().find(text: "Actions"))
        let hidden = BottomSheetView(title: "Actions", titleHidden: true) { Text("Copy") }
        XCTAssertThrowsError(try hidden.inspect().find(text: "Actions"))
        XCTAssertEqual(try hidden.inspect().find(text: "Copy").string(), "Copy")
    }

    // MARK: Rendered (macOS)

    #if os(macOS)
    /// Renders `view` in a window of `size` and lets SwiftUI settle (preferences, onAppear state).
    @MainActor
    private func render<V: View>(_ view: V, size: CGSize, direction: LayoutDirection = .leftToRight) -> NSWindow {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: view.environment(\.layoutDirection, direction)
            .frame(width: size.width, height: size.height))
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

    private final class Seen { var frame: CGRect = .zero; var hits = 0 }

    private struct FrameProbe: View {
        let seen: Seen
        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .task(id: proxy.frame(in: .global)) { seen.frame = proxy.frame(in: .global) }
            }
        }
    }

    @MainActor
    func testDrawerPanelTakesTheTokenWidthAtTheEndEdge() {
        let seen = Seen()
        let window = render(DrawerView(showClose: false, onClose: {}) { FrameProbe(seen: seen) },
                            size: CGSize(width: 1024, height: 700))
        defer { window.close() }
        XCTAssertEqual(seen.frame.width, FlareSizes.componentSheetWidth, accuracy: 0.5)
        XCTAssertEqual(seen.frame.maxX, 1024, accuracy: 0.5, "an end drawer docks to the trailing edge")
    }

    @MainActor
    func testDrawerAtTheStartEdgeAndOnANarrowWindowKeepsAScrimStrip() {
        let start = Seen()
        let w1 = render(DrawerView(placement: .start, showClose: false, onClose: {}) { FrameProbe(seen: start) },
                        size: CGSize(width: 1024, height: 700))
        defer { w1.close() }
        XCTAssertEqual(start.frame.minX, 0, accuracy: 0.5, "a start drawer docks to the leading edge")
        let narrow = Seen()
        let w2 = render(DrawerView(showClose: false, onClose: {}) { FrameProbe(seen: narrow) },
                        size: CGSize(width: 390, height: 700))
        defer { w2.close() }
        XCTAssertEqual(narrow.frame.width, 390 - FlareSizes.touchTarget, accuracy: 0.5)
    }

    @MainActor
    func testModalBoxTakesTheDialogTokenWidthCentered() {
        let seen = Seen()
        let window = render(ModalView(showClose: false, scrollable: false, onClose: {}) {
            FrameProbe(seen: seen).frame(height: 120)
        }, size: CGSize(width: 1024, height: 700))
        defer { window.close() }
        // The body pads its content; the box around it is the token width, centered.
        XCTAssertEqual(seen.frame.width, FlareSizes.componentSheetDialogWidth - 2 * FlareSizes.spacingLg, accuracy: 0.5)
        XCTAssertEqual(seen.frame.midX, 512, accuracy: 0.5)
    }

    @MainActor
    func testFilledModalKeepsTheCappedHeight() {
        let seen = Seen()
        let window = render(ModalView(maxHeight: 400, fill: true, showClose: false, scrollable: false, onClose: {}) {
            FrameProbe(seen: seen)
        }, size: CGSize(width: 1024, height: 700))
        defer { window.close() }
        // No header: the body is the box less its bottom padding.
        XCTAssertEqual(seen.frame.height, 400 - FlareSizes.spacingLg, accuracy: 0.5)
    }

    @MainActor
    func testAConfirmationKeepsItsHeightInsideTheScrollingBody() {
        // The feedback's confirmation (its own ScrollView) inside a Modal's measuring body, as `auto` shows it on
        // a wide window: it must neither collapse nor take the whole cap.
        let seen = Seen()
        let window = render(ModalView(showClose: false, onClose: {}) {
            DangerConfirmView(title: "Leave group", description: "You will stop receiving its messages.",
                              target: "", onConfirm: {}, onCancel: {})
                .background(FrameProbe(seen: seen))
        }, size: CGSize(width: 1024, height: 700))
        defer { window.close() }
        XCTAssertGreaterThan(seen.frame.height, 2 * FlareSizes.touchTarget, "both buttons fit")
        XCTAssertLessThan(seen.frame.height, FlareOverlayRules.maxHeight(requested: nil, available: 700))
    }

    @MainActor
    func testContentLockDisablesTheScrimTapAndTheCloseButton() {
        final class Model: ObservableObject { @Published var locked = true }
        struct Host: View {
            @ObservedObject var model: Model
            let seen: Seen
            var body: some View {
                ModalView(title: "Saving", onClose: { seen.hits += 1 }) {
                    Text("Form").flareLayerDismissDisabled(model.locked)
                }
            }
        }
        let model = Model()
        let seen = Seen()
        let window = render(Host(model: model, seen: seen), size: CGSize(width: 800, height: 600))
        defer { window.close() }
        // A click on the scrim corner does nothing while the content holds the layer.
        click(window, at: CGPoint(x: 10, y: 10))
        XCTAssertEqual(seen.hits, 0)
        model.locked = false
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        click(window, at: CGPoint(x: 10, y: 10))
        XCTAssertEqual(seen.hits, 1, "the scrim closes once the lock is released")
    }

    @MainActor
    func testKitCompositesHoldTheLayerWhileBusy() {
        // The busy locks travel from the kit's own bodies, not from the presenter: a confirmation running its
        // action holds the Modal `auto` shows it in, a saving form holds the Drawer it sits in.
        final class Model: ObservableObject { @Published var busy = true }
        struct Host: View {
            @ObservedObject var model: Model
            let seen: Seen
            let drawer: Bool
            var body: some View {
                if drawer {
                    DrawerView(title: "Profile", onClose: { seen.hits += 1 }) {
                        FormSheetView(title: "Edit", confirmLabel: "Save", cancelLabel: "Cancel", busy: model.busy,
                                      onConfirm: {}, onClose: {}) { Text("Name") }
                    }
                } else {
                    ModalView(showClose: false, onClose: { seen.hits += 1 }) {
                        DangerConfirmView(title: "Leave group", description: "", target: "", busy: model.busy,
                                          onConfirm: {}, onCancel: {})
                    }
                }
            }
        }
        for drawer in [false, true] {
            let model = Model()
            let seen = Seen()
            let window = render(Host(model: model, seen: seen, drawer: drawer), size: CGSize(width: 1024, height: 700))
            // The drawer docks to the trailing edge, so the leading corner is scrim in both layers.
            click(window, at: CGPoint(x: 10, y: 10))
            XCTAssertEqual(seen.hits, 0, drawer ? "a saving form holds the drawer" : "a running confirmation holds the modal")
            model.busy = false
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            click(window, at: CGPoint(x: 10, y: 10))
            XCTAssertEqual(seen.hits, 1, "released once the work is done")
            window.close()
        }
    }

    @MainActor
    private func click(_ window: NSWindow, at point: CGPoint) {
        guard let view = window.contentView else { return }
        // AppKit window coordinates start at the bottom left.
        let location = NSPoint(x: point.x, y: view.bounds.height - point.y)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            if let event = NSEvent.mouseEvent(with: type, location: location, modifierFlags: [],
                                              timestamp: ProcessInfo.processInfo.systemUptime,
                                              windowNumber: window.windowNumber, context: nil, eventNumber: 0,
                                              clickCount: 1, pressure: 1) {
                window.sendEvent(event)
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
    #endif

    @MainActor
    func testPresentersBuild() {
        _ = Text("chat").flareDrawer(isPresented: .constant(false), title: "Details", compactFallback: .push) { Text("x") }
        _ = Text("chat").flareDrawer(item: .constant(Contact?.none), navigable: true) { contact in Text(contact.name) }
        _ = Text("chat").flareModal(isPresented: .constant(false), title: "Search", fill: true) { Text("x") }
        _ = Text("chat").flareModal(item: .constant(Contact?.none), busy: true) { contact in Text(contact.name) }
        _ = Text("chat").flareBottomSheet(isPresented: .constant(false), title: "Pick", presentation: .sheet,
                                          dismissible: false, size: .large) { Text("x") }
    }
}
