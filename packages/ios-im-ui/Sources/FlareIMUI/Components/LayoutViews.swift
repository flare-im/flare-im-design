import SwiftUI

/// Which pane shows when collapsed to a single column. Spec union for ResponsiveLayout.
public enum FlarePane: Sendable { case list, chat, detail }

/// Adaptive conversation layout — one pane, the list beside the chat, or list + chat + detail. How many
/// fit is the kit's one pane rule (``resolvePaneMode(width:hasDetail:textScale:navigationWidth:primaryWidth:detailWidth:)``)
/// on the width the layout is given. Spec: Layout/ResponsiveLayout (`ResponsiveLayoutView`).
public struct ResponsiveLayoutView: View {
    private let list: AnyView
    private let chat: AnyView
    private let detail: AnyView?
    private let activePane: FlarePane
    private let onPaneChange: ((FlarePane) -> Void)?
    private let listWidth: CGFloat
    private let detailWidth: CGFloat
    private let hideMobileBar: Bool
    private let backLabel: String?
    private let onLayoutChange: ((FlareWorkspacePresentation) -> Void)?
    @ScaledMetric(relativeTo: .body) private var readingUnit: CGFloat = 16
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(activePane: FlarePane = .list, onPaneChange: ((FlarePane) -> Void)? = nil,
                listWidth: CGFloat = FlareSizes.primaryPaneDefaultWidth,
                detailWidth: CGFloat = FlareSizes.detailPaneDefaultWidth,
                hideMobileBar: Bool = false, backLabel: String? = nil,
                onLayoutChange: ((FlareWorkspacePresentation) -> Void)? = nil,
                list: AnyView, chat: AnyView, detail: AnyView? = nil) {
        self.activePane = activePane; self.onPaneChange = onPaneChange
        self.listWidth = max(0, listWidth); self.detailWidth = max(0, detailWidth)
        self.list = list; self.chat = chat; self.detail = detail
        self.hideMobileBar = hideMobileBar; self.backLabel = backLabel
        self.onLayoutChange = onLayoutChange
    }

    public var body: some View {
        GeometryReader { geo in
            let paneMode = resolvePaneMode(width: geo.size.width, hasDetail: detail != nil, textScale: readingUnit / 16,
                                           primaryWidth: listWidth, detailWidth: detailWidth)
            Group {
                if paneMode == .triplePane, let detail {
                    HStack(spacing: 0) {
                        list.frame(width: listWidth)
                        Divider()
                        chat.frame(maxWidth: .infinity)
                        Divider()
                        detail.frame(width: detailWidth)
                    }
                } else if paneMode == .dualPane {
                    HStack(spacing: 0) {
                        list.frame(width: listWidth)
                        Divider()
                        if activePane == .detail, let detail { detail.frame(maxWidth: .infinity) }
                        else { chat.frame(maxWidth: .infinity) }
                    }
                } else {
                    singlePane
                }
            }
            // The chat or the detail in the list's place is a page beyond the destination's root.
            .flareDestinationDepth(paneMode == .singlePane && activePane != .list)
            // A detail that is not beside the chat takes a pane's place when the host opens it.
            .modifier(ReportWorkspacePresentation(
                presentation: FlareWorkspacePresentation(
                    paneMode: paneMode,
                    detail: paneMode == .triplePane ? .inline : detail != nil ? .route : .hidden),
                onLayoutChange: onLayoutChange))
        }
    }

    @ViewBuilder
    private var singlePane: some View {
        if activePane == .list {
            list
        } else {
            VStack(spacing: 0) {
                if !hideMobileBar && onPaneChange != nil { HStack {
                    Button { onPaneChange?(activePane == .detail ? .chat : .list) } label: {
                        // The 44pt target belongs to the label: a plain button is hit by its label only.
                        Label(backLabel ?? strings.back, systemImage: flareIconSymbol("back"))
                            .foregroundColor(FlareColors.of(scheme, brand: flareBrandTheme).primary)
                            .flareTouchTarget(alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(FlareSizes.spacingSm)
                .overlay(Divider(), alignment: .bottom) }
                if activePane == .detail, let detail { detail } else { chat }
            }
        }
    }
}
