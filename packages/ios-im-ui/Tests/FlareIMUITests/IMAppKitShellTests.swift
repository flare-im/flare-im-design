import SwiftUI
import XCTest
@testable import FlareIMUI

#if os(macOS)
import AppKit

/// The shell contract (FR-095): the shell measures its own box, keeps every destination it has shown, and steps its
/// phone navigation aside while the active destination shows a page beyond its root. Hosted in a real window: the
/// shell reads its box through a GeometryReader, which an inspected view does not lay out.
final class IMAppKitShellTests: XCTestCase {
    private static let groups = [FlareApplicationNavigationGroup(id: "main", items: [
        .init(id: "chats", label: "Chats", icon: "chats", order: 0),
        .init(id: "contacts", label: "Contacts", icon: "people", order: 1),
    ])]

    private final class Model: ObservableObject {
        @Published var width: CGFloat
        @Published var active: String
        @Published var page = false
        @Published var pane: FlareApplicationWorkspacePane = .primary
        var appeared: [String] = []
        var navigation: [Bool] = []
        init(width: CGFloat, active: String) { self.width = width; self.active = active }
    }

    /// A destination that says when it came into the hierarchy.
    private struct Probe: View {
        let id: String
        let model: Model
        var body: some View { Text(id).onAppear { model.appeared.append(id) } }
    }

    private struct Host<Destination: View>: View {
        @ObservedObject var model: Model
        let destination: (String, Model) -> Destination
        var body: some View {
            IMAppKitView(groups: IMAppKitShellTests.groups, activeID: model.active, onNavigate: { model.active = $0 },
                         destination: { AnyView(destination($0, model)) })
                .environment(\.flareShellNavigationProbe, { model.navigation.append($0) })
                .frame(width: model.width, height: 800)
        }
    }

    private static func spin(_ seconds: TimeInterval = 0.4) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    @MainActor
    private func show<Destination: View>(_ model: Model, _ destination: @escaping (String, Model) -> Destination) -> NSWindow {
        _ = NSApplication.shared
        let size = NSSize(width: 1700, height: 800)
        let view = NSHostingView(rootView: Host(model: model, destination: destination))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = view
        view.setFrameSize(size)
        window.orderFront(nil)
        Self.spin()
        return window
    }

    @MainActor
    func testItKeepsEveryDestinationItHasShownAcrossSwitchesAndModes() {
        let model = Model(width: 1200, active: "chats")
        let window = show(model) { id, model in Probe(id: id, model: model) }
        model.active = "contacts"
        Self.spin()
        model.active = "chats"
        Self.spin()
        // A phone-width box moves the navigation under the destinations; they are not rebuilt.
        model.width = 390
        Self.spin()
        window.orderOut(nil)
        XCTAssertEqual(model.appeared, ["chats", "contacts"])
    }

    @MainActor
    func testThePhoneNavigationStepsAsideForAPageWithAWayBack() {
        let model = Model(width: 390, active: "contacts")
        let window = show(model) { id, model in
            FlareScreen(title: id, onBack: model.page ? {} : nil) { Text(id) }
        }
        XCTAssertEqual(model.navigation.last, true, "a destination root keeps the navigation")
        model.page = true
        Self.spin()
        XCTAssertEqual(model.navigation.last, false, "a page with a way back hides it")
        model.page = false
        Self.spin()
        XCTAssertEqual(model.navigation.last, true)
        // A wider box keeps its rail beside the page.
        model.page = true
        model.width = 1200
        Self.spin()
        window.orderOut(nil)
        XCTAssertEqual(model.navigation.last, true)
    }

    @MainActor
    func testAFrameInsideAPhoneShellShowsOnePaneAndAChatInTheListsPlaceIsAPage() {
        let model = Model(width: 390, active: "chats")
        var reports: [FlareWorkspacePresentation] = []
        let window = show(model) { _, model in
            AppLayoutView(activePane: model.pane, primary: AnyView(Text("Conversation list")),
                          content: AnyView(Text("Message timeline")),
                          onLayoutChange: { reports.append($0) })
        }
        XCTAssertEqual(reports.last?.paneMode, .singlePane, "the shell's mode reached the frame")
        XCTAssertEqual(model.navigation.last, true)
        model.pane = .content
        Self.spin()
        window.orderOut(nil)
        XCTAssertEqual(model.navigation.last, false)
    }

    /// A frame takes the mode of the shell it is in: 500 on its own is a phone, which draws no navigation, but inside a
    /// desktop shell the frame lays out as a desktop and keeps the navigation it was given.
    @MainActor
    func testAFrameTakesTheModeOfTheShellItIsIn() {
        _ = NSApplication.shared
        var seen: [String] = []
        let shell = DesktopAppShellView(groups: Self.groups, activeID: "chats", responsiveMode: .desktop,
                                        onNavigate: { _ in },
                                        content: AnyView(AppLayoutView(
                                            navigation: AnyView(Text("frame navigation").onAppear { seen.append("navigation") }),
                                            content: AnyView(Text("Message timeline").onAppear { seen.append("content") }))))
        let size = NSSize(width: 800, height: 600)
        let view = NSHostingView(rootView: shell.frame(width: 800, height: 600))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = view
        view.setFrameSize(size)
        window.orderFront(nil)
        Self.spin()
        window.orderOut(nil)
        XCTAssertTrue(seen.contains("content"))
        XCTAssertTrue(seen.contains("navigation"), "a desktop frame draws the navigation it was given")
    }
}
#endif
