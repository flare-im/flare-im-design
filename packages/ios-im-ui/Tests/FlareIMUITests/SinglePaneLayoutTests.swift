import SwiftUI
import XCTest
@testable import FlareIMUI

/// B5.4 (FR-083, FR-095): a workspace shows the list beside the chat only while the chat keeps its
/// minimum width. Below navigation + list + chat minimum it shows one pane, keeps the rail, and a
/// detail becomes a page. The shared cases live in `spec/application-layout-vectors.json` and are read by
/// `LayoutPolicyTests`; these name the rule's parts.
final class SinglePaneLayoutTests: XCTestCase {

    func testATabletTooNarrowForAUsableChatShowsOnePane() {
        // The rule, not a magic number: rail + list + the chat minimum.
        XCTAssertEqual(paneModeMinWidth(.dualPane, navigationWidth: resolveNavigationWidth(.tablet)), 752)
        // A host that gives its own column widths moves the threshold with them.
        XCTAssertEqual(paneModeMinWidth(.dualPane, navigationWidth: 0, primaryWidth: 300), 660)
        // Only the chat grows with the text: 72 + 320 + 360 x 1.5.
        XCTAssertEqual(paneModeMinWidth(.dualPane, navigationWidth: 72, textScale: 1.5), 932)

        func paneMode(_ width: CGFloat, scale: CGFloat = 1, hasDetail: Bool = false,
                      navigation: CGFloat? = nil) -> FlareWorkspacePaneMode {
            resolveWorkspacePresentation(resolveApplicationResponsiveMode(width: width, textScale: scale),
                                         hasDetail: hasDetail, width: width, textScale: scale,
                                         navigationWidth: navigation).paneMode
        }
        XCTAssertEqual(paneMode(751), .singlePane)
        XCTAssertEqual(paneMode(752), .dualPane)
        // Without a navigation rail the same container fits two panes 72pt earlier.
        XCTAssertEqual(paneMode(700, navigation: 0), .dualPane)
        // A desktop sidebar (280) takes its room too: 280 + 320 + 360 = 960.
        XCTAssertEqual(paneMode(959), .singlePane)
        XCTAssertEqual(paneMode(1000), .dualPane)
        XCTAssertEqual(paneMode(1400, hasDetail: true), .triplePane)
        // A width the caller does not know keeps the old answer instead of collapsing on a guess.
        XCTAssertEqual(resolveWorkspacePresentation(.tablet).paneMode, .dualPane)
    }

    func testADetailIsAPageWhenOnlyOnePaneFits() {
        func detail(_ width: CGFloat) -> FlareWorkspaceDetailPresentation {
            resolveWorkspacePresentation(resolveApplicationResponsiveMode(width: width),
                                         hasDetail: true, width: width).detail
        }
        // One pane: the detail is a route the host pushes, never an overlay over a full-width pane.
        XCTAssertEqual(detail(700), .route)
        XCTAssertEqual(detail(800), .overlay)
    }

    // MARK: The layout itself
    //
    // These are hosted in a real window: the layout reads its own box through a GeometryReader, and an
    // inspected view has no geometry (ViewInspector hands the reader a zero-size proxy), so only a real
    // window can say which panes a width produces.
}

#if os(macOS)
import AppKit

final class SinglePaneLayoutHostedTests: XCTestCase {
    /// A pane that says when the layout actually rendered it.
    private struct Pane: View {
        let name: String
        let seen: (String) -> Void
        var body: some View { Text(name).frame(maxWidth: .infinity, maxHeight: .infinity).onAppear { seen(name) } }
    }

    private final class Rendered {
        var panes: [String] = []
        var reported: [FlareWorkspacePresentation] = []
    }

    private static func spin(_ seconds: TimeInterval = 0.4) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    /// Hosts the layout at `width` and returns what it drew and what it told the host.
    @MainActor
    private func host(width: CGFloat, hasDetail: Bool = false,
                      activePane: FlareApplicationWorkspacePane = .content) -> Rendered {
        _ = NSApplication.shared
        let rendered = Rendered()
        let seen: (String) -> Void = { rendered.panes.append($0) }
        // No shell: the layout resolves the mode from its own box.
        let layout = AppLayoutView(
            activePane: activePane,
            navigation: AnyView(Pane(name: "Rail", seen: seen).frame(width: FlareSizes.navigationRailWidth)),
            primary: AnyView(Pane(name: "List", seen: seen)),
            content: AnyView(Pane(name: "Chat", seen: seen)),
            detail: hasDetail ? AnyView(Pane(name: "Detail", seen: seen)) : nil,
            onLayoutChange: { rendered.reported.append($0) }
        )
        let size = NSSize(width: width, height: 800)
        let view = NSHostingView(rootView: layout.frame(width: width, height: 800))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = view
        view.setFrameSize(size)
        view.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        Self.spin(0.5)
        window.orderOut(nil)
        return rendered
    }

    @MainActor
    func testItOpensAtOnePaneBelowTheWidthAndTwoPanesAboveIt() {
        // 700: the rail and the host's active pane; no list beside a chat that would be too narrow.
        let narrow = host(width: 700)
        XCTAssertTrue(narrow.panes.contains("Rail"), "the navigation rail stays")
        XCTAssertTrue(narrow.panes.contains("Chat"))
        XCTAssertFalse(narrow.panes.contains("List"), "one pane at a time below 752")

        // The pane that shows is the host's active one.
        let narrowList = host(width: 700, activePane: .primary)
        XCTAssertTrue(narrowList.panes.contains("List"))
        XCTAssertFalse(narrowList.panes.contains("Chat"))

        // 800: two panes, as before.
        let wide = host(width: 800)
        XCTAssertTrue(wide.panes.contains("List"))
        XCTAssertTrue(wide.panes.contains("Chat"))
    }

    @MainActor
    func testADetailIsAPageWhenOnlyOnePaneFitsAndAnOverlayWhenTwoDo() {
        // 800: the detail floats over the two panes, which are still there.
        let wide = host(width: 800, hasDetail: true, activePane: .detail)
        XCTAssertTrue(wide.panes.contains("Detail"))
        XCTAssertTrue(wide.panes.contains("Chat"))
        XCTAssertEqual(wide.reported.last, FlareWorkspacePresentation(paneMode: .dualPane, detail: .overlay))

        // 700: the detail is the page — nothing under it.
        let narrow = host(width: 700, hasDetail: true, activePane: .detail)
        XCTAssertTrue(narrow.panes.contains("Detail"))
        XCTAssertFalse(narrow.panes.contains("Chat"), "a route replaces the pane, it does not float over it")
        XCTAssertFalse(narrow.panes.contains("List"))
        XCTAssertEqual(narrow.reported.last, FlareWorkspacePresentation(paneMode: .singlePane, detail: .route))
    }

    /// Hosts the conversation layout at `width` and returns what it drew and what it told the host.
    @MainActor
    private func hostConversation(width: CGFloat) -> Rendered {
        _ = NSApplication.shared
        let rendered = Rendered()
        let seen: (String) -> Void = { rendered.panes.append($0) }
        let layout = ResponsiveLayoutView(
            activePane: .chat,
            onLayoutChange: { rendered.reported.append($0) },
            list: AnyView(Pane(name: "List", seen: seen)),
            chat: AnyView(Pane(name: "Chat", seen: seen))
        )
        let size = NSSize(width: width, height: 800)
        let view = NSHostingView(rootView: layout.frame(width: width, height: 800))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = view
        view.setFrameSize(size)
        view.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        Self.spin(0.5)
        window.orderOut(nil)
        return rendered
    }

    /// FR-110: the conversation layout asks the same rule (a 320 list beside a 360 chat, no 720 floor) and
    /// reports in the application frames' words.
    @MainActor
    func testTheConversationLayoutUsesTheSameRuleAndSaysSo() {
        let narrow = hostConversation(width: 679)
        XCTAssertTrue(narrow.panes.contains("Chat"))
        XCTAssertFalse(narrow.panes.contains("List"), "one short of a list and a usable chat")
        XCTAssertEqual(narrow.reported, [FlareWorkspacePresentation(paneMode: .singlePane, detail: .hidden)])

        let wide = hostConversation(width: 680)
        XCTAssertTrue(wide.panes.contains("List"), "the old 720 floor kept this at one pane")
        XCTAssertTrue(wide.panes.contains("Chat"))
        XCTAssertEqual(wide.reported, [FlareWorkspacePresentation(paneMode: .dualPane, detail: .hidden)])
    }

    private final class Width: ObservableObject {
        @Published var value: CGFloat
        init(_ value: CGFloat) { self.value = value }
    }

    private struct Resizable<Content: View>: View {
        @ObservedObject var width: Width
        let content: Content
        var body: some View { content.frame(width: width.value, height: 800) }
    }

    /// A change of panes is one report: the layout keeps one container, so the branch that appears does not
    /// report the same presentation a second time on top of the change.
    @MainActor
    func testAChangeOfPanesIsReportedOnce() {
        _ = NSApplication.shared
        let rendered = Rendered()
        let width = Width(679)
        let layout = ResponsiveLayoutView(
            activePane: .chat,
            onLayoutChange: { rendered.reported.append($0) },
            list: AnyView(Text("List")),
            chat: AnyView(Text("Chat"))
        )
        let size = NSSize(width: 900, height: 800)
        let view = NSHostingView(rootView: Resizable(width: width, content: layout))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = view
        view.setFrameSize(size)
        window.orderFront(nil)
        Self.spin(0.5)
        width.value = 680
        Self.spin(0.5)
        window.orderOut(nil)
        XCTAssertEqual(rendered.reported, [
            FlareWorkspacePresentation(paneMode: .singlePane, detail: .hidden),
            FlareWorkspacePresentation(paneMode: .dualPane, detail: .hidden),
        ])
    }

    @MainActor
    func testTheHostIsToldWhichPresentationIsInUse() {
        // Reported on the first resolution, without the host asking and without a width to read back.
        XCTAssertEqual(host(width: 700).reported.first,
                       FlareWorkspacePresentation(paneMode: .singlePane, detail: .hidden))
        XCTAssertEqual(host(width: 800).reported.first,
                       FlareWorkspacePresentation(paneMode: .dualPane, detail: .hidden))
        XCTAssertEqual(host(width: 390).reported.first,
                       FlareWorkspacePresentation(paneMode: .singlePane, detail: .hidden),
                       "a phone reports too")
    }
}
#endif
