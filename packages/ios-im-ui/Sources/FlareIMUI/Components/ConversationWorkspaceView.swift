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
    /// Second line under an empty explanation — what the user can do about it.
    public var description: String?
    /// Label of the one action this state offers: retry on a failure, the next
    /// step on an empty pane. Without it no button is offered, only the reason.
    public var actionLabel: String?

    public init(status: FlareWorkspacePaneStatus = .ready, message: String? = nil,
                description: String? = nil, actionLabel: String? = nil) {
        self.status = status; self.message = message
        self.description = description; self.actionLabel = actionLabel
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

/// Whether an empty pane offers a next step. Same three conditions as a retry —
/// the state, a non-blank label and a host handler — because an empty list whose
/// only affordance does nothing is worse than one with no affordance at all.
public func paneEmptyActionVisible(_ state: FlareWorkspacePaneState?, hasAction: Bool) -> Bool {
    guard hasAction, paneRender(state) == .empty, let label = state?.actionLabel else { return false }
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

/// One pane's four outcomes, in one place: host content, a skeleton while it
/// loads, an explanation when it is empty, a reason plus recovery when it failed.
///
/// Both `ConversationWorkspaceView` and `WorkspaceFrameView` render their panes
/// through it, so the inbox and a settings surface fail the same way instead of
/// two dialects of "something went wrong".
public struct WorkspacePaneView: View {
    private let state: FlareWorkspacePaneState
    private let skeleton: SkeletonVariant
    private let skeletonRows: Int
    /// Semantic kit icon name (``flareIconNames``) for the pane's empty state.
    private let emptyIcon: String
    private let emptyText: String
    private let failureText: String
    private let loadingText: String
    private let onRetry: (() -> Void)?
    private let onEmptyAction: (() -> Void)?
    private let content: AnyView

    public init(state: FlareWorkspacePaneState,
                skeleton: SkeletonVariant = .conversation,
                skeletonRows: Int = 6,
                emptyIcon: String = "folder",
                emptyText: String = "",
                failureText: String = "",
                loadingText: String = "",
                onRetry: (() -> Void)? = nil,
                onEmptyAction: (() -> Void)? = nil,
                content: AnyView) {
        self.state = state; self.skeleton = skeleton; self.skeletonRows = skeletonRows
        self.emptyIcon = emptyIcon; self.emptyText = emptyText
        self.failureText = failureText; self.loadingText = loadingText
        self.onRetry = onRetry; self.onEmptyAction = onEmptyAction; self.content = content
    }

    /// Host text wins; the kit's default only fills a blank.
    static func text(_ value: String?, _ fallback: String) -> String {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return fallback }
        return value
    }

    public var body: some View {
        switch paneRender(state) {
        case .content:
            return content
        case .skeleton:
            // A labelled skeleton — never an empty list pretending there is nothing to show.
            return AnyView(
                VStack {
                    SkeletonView(variant: skeleton, rows: skeletonRows)
                    Spacer(minLength: 0)
                }
                .padding(FlareSizes.spacingLg)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(loadingText)
                .accessibilityAddTraits(.updatesFrequently)
            )
        case .empty:
            let action = paneEmptyActionVisible(state, hasAction: onEmptyAction != nil)
            return AnyView(
                EmptyStateView(title: Self.text(state.message, emptyText),
                               description: state.description,
                               actionText: action ? state.actionLabel : nil,
                               icon: emptyIcon,
                               onAction: action ? onEmptyAction : nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        case .failure:
            let retry = paneRetryVisible(state, hasRetry: onRetry != nil)
            return AnyView(
                VStack {
                    StatusBannerView(text: Self.text(state.message, failureText), tone: .danger,
                                     actionText: retry ? state.actionLabel : nil,
                                     onAction: retry ? onRetry : nil)
                    Spacer(minLength: 0)
                }
                .padding(FlareSizes.spacingLg)
            )
        }
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
    private let backLabel: String?
    private let onLayoutChange: ((FlareWorkspacePresentation) -> Void)?
    private let listState: FlareWorkspacePaneState
    private let chatState: FlareWorkspacePaneState
    private let detailState: FlareWorkspacePaneState
    private let banner: FlareWorkspaceBanner?
    private let onRetry: ((FlareWorkspacePaneKey) -> Void)?
    private let onEmptyAction: ((FlareWorkspacePaneKey) -> Void)?
    private let onBannerAction: (() -> Void)?
    private let listEmptyText: String?
    private let chatEmptyText: String?
    private let detailEmptyText: String?
    private let listFailureText: String?
    private let chatFailureText: String?
    private let detailFailureText: String?
    private let listLoadingText: String?
    private let chatLoadingText: String?
    private let detailLoadingText: String?

    @Environment(\.flareStrings) private var strings

    public init(activePane: FlarePane = .list,
                onPaneChange: ((FlarePane) -> Void)? = nil,
                listWidth: CGFloat = FlareSizes.primaryPaneDefaultWidth,
                detailWidth: CGFloat = FlareSizes.detailPaneDefaultWidth,
                hideMobileBar: Bool = false,
                backLabel: String? = nil,
                onLayoutChange: ((FlareWorkspacePresentation) -> Void)? = nil,
                listState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
                chatState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
                detailState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
                banner: FlareWorkspaceBanner? = nil,
                onRetry: ((FlareWorkspacePaneKey) -> Void)? = nil,
                onEmptyAction: ((FlareWorkspacePaneKey) -> Void)? = nil,
                onBannerAction: (() -> Void)? = nil,
                listEmptyText: String? = nil,
                chatEmptyText: String? = nil,
                detailEmptyText: String? = nil,
                listFailureText: String? = nil,
                chatFailureText: String? = nil,
                detailFailureText: String? = nil,
                listLoadingText: String? = nil,
                chatLoadingText: String? = nil,
                detailLoadingText: String? = nil,
                list: AnyView, chat: AnyView, detail: AnyView? = nil) {
        self.activePane = activePane; self.onPaneChange = onPaneChange
        self.listWidth = listWidth; self.detailWidth = detailWidth
        self.hideMobileBar = hideMobileBar; self.backLabel = backLabel
        self.onLayoutChange = onLayoutChange
        self.listState = listState; self.chatState = chatState; self.detailState = detailState
        self.banner = banner; self.onRetry = onRetry; self.onEmptyAction = onEmptyAction
        self.onBannerAction = onBannerAction
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
        case .chat: return "comment"
        case .detail: return "info"
        case .list: return "chats"
        }
    }

    private func pane(_ key: FlareWorkspacePaneKey, content: AnyView, state: FlareWorkspacePaneState,
                      emptyText: String, failureText: String, loadingText: String, rows: Int) -> AnyView {
        AnyView(WorkspacePaneView(
            state: state,
            skeleton: paneSkeletonVariant(key),
            skeletonRows: rows,
            emptyIcon: emptyIcon(key),
            emptyText: emptyText,
            failureText: failureText,
            loadingText: loadingText,
            onRetry: onRetry.map { handler in { handler(key) } },
            onEmptyAction: onEmptyAction.map { handler in { handler(key) } },
            content: content
        ))
    }

    /// Copy in effect: an explicit parameter wins, otherwise the `flareStrings` provider.
    struct Copy {
        let backLabel, listEmptyText, chatEmptyText, detailEmptyText: String
        let listFailureText, chatFailureText, detailFailureText, listLoadingText: String
        let chatLoadingText, detailLoadingText: String
    }
    func resolveCopy(_ strings: FlareStrings) -> Copy {
        Copy(
            backLabel: backLabel ?? strings.back,
            listEmptyText: listEmptyText ?? strings.noConversations,
            chatEmptyText: chatEmptyText ?? strings.conversationWorkspaceChatEmpty,
            detailEmptyText: detailEmptyText ?? strings.conversationWorkspaceDetailEmpty,
            listFailureText: listFailureText ?? strings.conversationWorkspaceListFailure,
            chatFailureText: chatFailureText ?? strings.conversationWorkspaceChatFailure,
            detailFailureText: detailFailureText ?? strings.conversationWorkspaceDetailFailure,
            listLoadingText: listLoadingText ?? strings.conversationWorkspaceListLoading,
            chatLoadingText: chatLoadingText ?? strings.conversationWorkspaceChatLoading,
            detailLoadingText: detailLoadingText ?? strings.conversationWorkspaceDetailLoading
        )
    }
    private var copy: Copy { resolveCopy(strings) }

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
                hideMobileBar: hideMobileBar, backLabel: copy.backLabel,
                onLayoutChange: onLayoutChange,
                list: pane(.list, content: list, state: listState,
                           emptyText: copy.listEmptyText, failureText: copy.listFailureText,
                           loadingText: copy.listLoadingText, rows: 6),
                chat: pane(.chat, content: chat, state: chatState,
                           emptyText: copy.chatEmptyText, failureText: copy.chatFailureText,
                           loadingText: copy.chatLoadingText, rows: 5),
                // The detail pane must exist whenever it has something to say: with a
                // nil slot but a non-ready state the host has no content yet — which is
                // exactly when the loading / empty / failure panel is the point.
                detail: (detail != nil || detailState.status != .ready)
                    ? pane(.detail, content: detail ?? AnyView(EmptyView()), state: detailState,
                           emptyText: copy.detailEmptyText, failureText: copy.detailFailureText,
                           loadingText: copy.detailLoadingText, rows: 1)
                    : nil
            )
        }
    }
}
