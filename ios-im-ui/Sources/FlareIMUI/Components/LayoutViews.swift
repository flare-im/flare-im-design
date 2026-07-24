import SwiftUI

/// Which pane shows when collapsed to a single column. Spec union for ResponsiveLayout.
public enum FlarePane: Sendable { case list, chat, detail }

/// Adaptive application shell — side rail on wide, bottom bar on narrow.
/// Spec: Layout/AppShell (`AppShellView`).
public struct AppShellView<Content: View>: View {
    private let items: [FlareNavItem]
    private let activeKey: String
    private let onNavigate: ((String) -> Void)?
    private let content: Content
    @Environment(\.colorScheme) private var scheme

    public init(items: [FlareNavItem], activeKey: String, onNavigate: ((String) -> Void)? = nil,
                @ViewBuilder content: () -> Content) {
        self.items = items; self.activeKey = activeKey; self.onNavigate = onNavigate; self.content = content()
    }

    public var body: some View {
        GeometryReader { geo in
            if geo.size.width > 600 {
                HStack(spacing: 0) {
                    VStack(spacing: 6) { ForEach(items) { navButton($0) } }
                        .padding(.vertical, FlareSizes.spacingMd).padding(.horizontal, 6)
                        .background(FlareColors.of(scheme).bgSecondary)
                    content
                }
            } else {
                VStack(spacing: 0) {
                    content.frame(maxHeight: .infinity)
                    HStack { ForEach(items) { Spacer(); navButton($0); Spacer() } }
                        .background(FlareColors.of(scheme).bgPrimary)
                        .overlay(Divider(), alignment: .top)
                }
            }
        }
    }

    private func navButton(_ item: FlareNavItem) -> some View {
        let colors = FlareColors.of(scheme)
        let active = item.key == activeKey
        return Button { onNavigate?(item.key) } label: {
            VStack(spacing: 2) {
                Image(systemName: item.systemImage).font(.system(size: 20))
                    .overlay(alignment: .topTrailing) {
                        if item.badge > 0 {
                            Text(item.badge > 99 ? "99+" : "\(item.badge)")
                                .font(.system(size: 9)).foregroundColor(.white)
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Capsule().fill(colors.error)).offset(x: 8, y: -6)
                        }
                    }
                Text(item.label).font(.system(size: 11))
            }
            .foregroundColor(active ? colors.primary : colors.textTertiary)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

/// Adaptive conversation layout — phone single / tablet dual / desktop triple.
/// Spec: Layout/ResponsiveLayout (`ResponsiveLayoutView`).
public struct ResponsiveLayoutView: View {
    private let list: AnyView
    private let chat: AnyView
    private let detail: AnyView?
    private let activePane: FlarePane
    private let onPaneChange: ((FlarePane) -> Void)?
    private let listWidth: CGFloat
    private let detailWidth: CGFloat
    @Environment(\.colorScheme) private var scheme

    public init(activePane: FlarePane = .list, onPaneChange: ((FlarePane) -> Void)? = nil,
                listWidth: CGFloat = 300, detailWidth: CGFloat = 320,
                list: AnyView, chat: AnyView, detail: AnyView? = nil) {
        self.activePane = activePane; self.onPaneChange = onPaneChange
        self.listWidth = listWidth; self.detailWidth = detailWidth
        self.list = list; self.chat = chat; self.detail = detail
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            if w >= 1100, let detail {
                HStack(spacing: 0) {
                    list.frame(width: listWidth)
                    Divider()
                    chat.frame(maxWidth: .infinity)
                    Divider()
                    detail.frame(width: detailWidth)
                }
            } else if w >= 680 {
                HStack(spacing: 0) {
                    list.frame(width: listWidth)
                    Divider()
                    chat.frame(maxWidth: .infinity)
                }
            } else {
                singlePane
            }
        }
    }

    @ViewBuilder
    private var singlePane: some View {
        if activePane == .list {
            list
        } else {
            VStack(spacing: 0) {
                HStack {
                    Button { onPaneChange?(.list) } label: {
                        Label("返回", systemImage: "chevron.left").foregroundColor(FlareColors.of(scheme).primary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(FlareSizes.spacingSm)
                .overlay(Divider(), alignment: .bottom)
                if activePane == .detail, let detail { detail } else { chat }
            }
        }
    }
}
