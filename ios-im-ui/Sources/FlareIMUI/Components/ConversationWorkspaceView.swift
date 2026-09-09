import SwiftUI

// MARK: - Contract

/// Which pane a state / retry belongs to.
public enum FlareWorkspacePaneKey: String, Sendable, CaseIterable { case list, chat, detail }

/// Host-reported load status of a single pane. Panes are independent: a failing
/// timeline never degrades an inbox that already loaded.
public enum FlareWorkspacePaneStatus: String, Sendable, CaseIterable { case ready, loading, empty, failure }

/// What a pane actually renders.
public enum FlareWorkspacePaneRender: String, Sendable { case content, skeleton, empty, failure }

/// Tone of the workspace-wide banner (offline / reconnecting / session expired).
public enum FlareWorkspaceBannerTone: String, Sendable, CaseIterable { case info, warning, error, success }

/// One pane's host-reported state.
public struct FlareWorkspacePaneState: Sendable, Equatable {
    /// Defaults to `.ready`.
    public var status: FlareWorkspacePaneStatus
    /// User-facing text: the empty explanation, or the failure cause.
    public var message: String?
    /// Recovery action label. Without it no button is offered, only the reason.
    public var actionLabel: String?

    public init(status: FlareWorkspacePaneStatus = .ready, message: String? = nil, actionLabel: String? = nil) {
        self.status = status; self.message = message; self.actionLabel = actionLabel
    }
}

/// Cross-pane notice rendered above all three panes.
public struct FlareWorkspaceBanner: Sendable, Equatable {
    public var message: String
    public var tone: FlareWorkspaceBannerTone
    public var actionLabel: String?

    public init(message: String, tone: FlareWorkspaceBannerTone = .info, actionLabel: String? = nil) {
        self.message = message; self.tone = tone; self.actionLabel = actionLabel
    }
}

/// Map a host pane state onto what to render. A missing state and `.ready` both
/// fall back to the host content: an unresolved status must never blank a pane
/// or fake an empty list.
public func paneRender(_ state: FlareWorkspacePaneState?) -> FlareWorkspacePaneRender {
    switch state?.status {
    case .loading: return .skeleton
    case .empty: return .empty
    case .failure: return .failure
    default: return .content
    }
}

/// Whether the pane failure offers a recovery button. Needs all three: an actual
/// failure, a non-blank label, and a host handler — a button the host cannot
/// service is worse than no button.
public func paneRetryVisible(_ state: FlareWorkspacePaneState?, hasRetry: Bool) -> Bool {
    guard hasRetry, paneRender(state) == .failure else { return false }
    guard let label = state?.actionLabel else { return false }
    return !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

/// Whether the cross-pane banner shows at all. Blank or whitespace-only messages
/// are not a banner. Independent of pane state: an offline banner can sit above a
/// list that still reads fine from cache.
public func workspaceBannerVisible(_ banner: FlareWorkspaceBanner?) -> Bool {
    guard let banner else { return false }
    return !banner.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

/// Whether the banner's inline action renders (non-blank label + host handler).
public func workspaceBannerActionVisible(_ banner: FlareWorkspaceBanner?, hasAction: Bool) -> Bool {
    guard hasAction, workspaceBannerVisible(banner), let label = banner?.actionLabel else { return false }
    return !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

/// StatusBanner tone for a workspace tone; `error` is StatusBanner's `danger`.
public func workspaceBannerTone(_ tone: FlareWorkspaceBannerTone?) -> FlareStatusTone {
    switch tone {
    case .warning: return .warning
    case .error: return .danger
    case .success: return .success
    default: return .info
    }
}

/// Skeleton shape per pane: rows for the inbox, bubbles for the timeline, a card
/// for details.
public func paneSkeletonVariant(_ pane: FlareWorkspacePaneKey) -> SkeletonVariant {
    switch pane {
    case .chat: return .message
    case .detail: return .profile
    case .list: return .conversation
    }
}

// MARK: - View

/// The conversation workspace: `ResponsiveLayoutView` plus ONE place where every
/// pane resolves loading / empty / failure, so hosts stop re-writing a skeleton,
/// an empty card and an error card per app and per pane.
///
/// It owns no data and performs no side effect: pane content stays in `list` /
/// `chat` / `detail`, splitting and breakpoints stay in `ResponsiveLayoutView`,
/// recovery stays with the host via `onRetry`.
/// Spec: Layout/ConversationWorkspace (`ConversationWorkspaceView`).
public struct ConversationWorkspaceView: View {
    private let list: AnyView
    private let chat: AnyView
    private let detail: AnyView?
    private let activePane: FlarePane
    private let onPaneChange: ((FlarePane) -> Void)?
    private let listWidth: CGFloat
    private let detailWidth: CGFloat
    private let hideMobileBar: Bool
    private let backLabel: String
    private let listState: FlareWorkspacePaneState
    private let chatState: FlareWorkspacePaneState
    private let detailState: FlareWorkspacePaneState
    private let banner: FlareWorkspaceBanner?
    private let onRetry: ((FlareWorkspacePaneKey) -> Void)?
    private let onBannerAction: (() -> Void)?
    private let listEmptyText: String
    private let chatEmptyText: String
    private let detailEmptyText: String
    private let listFailureText: String
    private let chatFailureText: String
    private let detailFailureText: String
    private let listLoadingText: String
    private let chatLoadingText: String
    private let detailLoadingText: String

    public init(activePane: FlarePane = .list,
                onPaneChange: ((FlarePane) -> Void)? = nil,
                listWidth: CGFloat = FlareSizes.leftPanel,
                detailWidth: CGFloat = FlareSizes.rightPanel,
                hideMobileBar: Bool = false,
                backLabel: String = "Back",
                listState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
                chatState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
                detailState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
                banner: FlareWorkspaceBanner? = nil,
                onRetry: ((FlareWorkspacePaneKey) -> Void)? = nil,
                onBannerAction: (() -> Void)? = nil,
                listEmptyText: String = "暂无会话",
                chatEmptyText: String = "选择一个会话开始聊天",
                detailEmptyText: String = "暂无详情",
                listFailureText: String = "会话列表加载失败",
                chatFailureText: String = "消息加载失败",
                detailFailureText: String = "详情加载失败",
                listLoadingText: String = "正在加载会话列表",
                chatLoadingText: String = "正在加载消息",
                detailLoadingText: String = "正在加载详情",
                list: AnyView, chat: AnyView, detail: AnyView? = nil) {
        self.activePane = activePane; self.onPaneChange = onPaneChange
        self.listWidth = listWidth; self.detailWidth = detailWidth
        self.hideMobileBar = hideMobileBar; self.backLabel = backLabel
        self.listState = listState; self.chatState = chatState; self.detailState = detailState
        self.banner = banner; self.onRetry = onRetry; self.onBannerAction = onBannerAction
        self.listEmptyText = listEmptyText; self.chatEmptyText = chatEmptyText; self.detailEmptyText = detailEmptyText
        self.listFailureText = listFailureText; self.chatFailureText = chatFailureText; self.detailFailureText = detailFailureText
        self.listLoadingText = listLoadingText; self.chatLoadingText = chatLoadingText; self.detailLoadingText = detailLoadingText
        self.list = list; self.chat = chat; self.detail = detail
    }

    private static func text(_ value: String?, _ fallback: String) -> String {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return fallback }
        return value
    }

    private func emptyIcon(_ pane: FlareWorkspacePaneKey) -> String {
        switch pane {
        case .chat: return "bubble.left"
        case .detail: return "info.circle"
        case .list: return "bubble.left.and.bubble.right"
        }
    }

    private func pane(_ key: FlareWorkspacePaneKey, content: AnyView, state: FlareWorkspacePaneState,
                      emptyText: String, failureText: String, loadingText: String, rows: Int) -> AnyView {
        switch paneRender(state) {
        case .content:
            return content
        case .skeleton:
            // A labelled skeleton — never an empty list pretending there is nothing to show.
            return AnyView(
                VStack {
                    SkeletonView(variant: paneSkeletonVariant(key), rows: rows)
                    Spacer(minLength: 0)
                }
                .padding(FlareSizes.spacingLg)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(loadingText)
                .accessibilityAddTraits(.updatesFrequently)
            )
        case .empty:
            return AnyView(
                EmptyStateView(title: Self.text(state.message, emptyText), systemImage: emptyIcon(key))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        case .failure:
            let retry = paneRetryVisible(state, hasRetry: onRetry != nil)
            return AnyView(
                VStack {
                    StatusBannerView(text: Self.text(state.message, failureText), tone: .danger,
                                     actionText: retry ? state.actionLabel : nil,
                                     onAction: retry ? { onRetry?(key) } : nil)
                    Spacer(minLength: 0)
                }
                .padding(FlareSizes.spacingLg)
            )
        }
    }

    public var body: some View {
        let showBanner = workspaceBannerVisible(banner)
        let bannerAction = workspaceBannerActionVisible(banner, hasAction: onBannerAction != nil)
        return VStack(spacing: 0) {
            if showBanner, let banner {
                StatusBannerView(text: banner.message, tone: workspaceBannerTone(banner.tone),
                                 actionText: bannerAction ? banner.actionLabel : nil,
                                 onAction: bannerAction ? onBannerAction : nil)
                    .padding(FlareSizes.spacingSm)
                Divider()
            }
            ResponsiveLayoutView(
                activePane: activePane, onPaneChange: onPaneChange,
                listWidth: listWidth, detailWidth: detailWidth,
                hideMobileBar: hideMobileBar, backLabel: backLabel,
                list: pane(.list, content: list, state: listState,
                           emptyText: listEmptyText, failureText: listFailureText,
                           loadingText: listLoadingText, rows: 6),
                chat: pane(.chat, content: chat, state: chatState,
                           emptyText: chatEmptyText, failureText: chatFailureText,
                           loadingText: chatLoadingText, rows: 5),
                // The detail pane must exist whenever it has something to say: with a
                // nil slot but a non-ready state the host has no content yet — which is
                // exactly when the loading / empty / failure panel is the point.
                detail: (detail != nil || detailState.status != .ready)
                    ? pane(.detail, content: detail ?? AnyView(EmptyView()), state: detailState,
                           emptyText: detailEmptyText, failureText: detailFailureText,
                           loadingText: detailLoadingText, rows: 1)
                    : nil
            )
        }
    }
}
