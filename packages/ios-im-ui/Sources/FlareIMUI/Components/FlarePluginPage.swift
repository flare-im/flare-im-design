import SwiftUI

/// Plugin page host — a full-screen page for a plugin's `page` contribution (red packet v5's wallet, a list).
/// Spec: Layout/PluginPage (`FlarePluginPage`), docs/design/red-packet-v5-roles-and-wallet.md §3.2.
///
/// The kit ``FlareScreen`` with the title (the view's, else `title`) and, with `onBack`, the back key; the view drawn
/// by an embedded ``PluginView`` — the detail sheet's document renderer, so blocks, menu actions (keys after the
/// footer actions), forms and settling behave the same; pull to refresh on touch and a refresh key in the header on a
/// pointer (macOS, iPad); and a full-width "load more" under the view while `view.nextCursor` is set, asked once per
/// cursor as in ``PluginDetailSheetView``.
///
/// The host fetches: `onRefresh`, `onRetry` and `onLoadMore` are requests, and the kit calls nothing. While `loading`
/// (or before the first view) a spinner stands in for the view; `error` without a view shows the host's text and the
/// retry key. `refreshing` keeps the refresh indicator until it clears. No placeholder buttons: what the view does not
/// declare is not drawn.
public struct FlarePluginPage: View {
    private let title: String?
    private let view: PluginViewModel?
    private let loading: Bool
    private let error: String?
    private let refreshing: Bool
    private let loadingMore: Bool
    private let resolveUser: (@Sendable (String) async -> PluginUser?)?
    private let viewerId: String?
    private let busyActionId: String?
    private let actionError: String?
    private let formErrors: [PluginFormError]
    private let members: [PluginMember]
    private let settleToken: Int
    private let onBack: (() -> Void)?
    private let onRefresh: (() -> Void)?
    private let onRetry: (() -> Void)?
    private let onLoadMore: ((String) -> Void)?
    private let onAction: ((String, PluginActionPayload) -> Void)?
    private let onOpenDetail: (() -> Void)?
    /// The cursor asked for and not answered yet.
    @State private var paging = PluginDetailPaging()
    /// The host's `refreshing`, read by a pull that waits for it to clear.
    @State private var refreshInFlight = false
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(title: String? = nil, view: PluginViewModel? = nil, loading: Bool = false, error: String? = nil,
                refreshing: Bool = false, loadingMore: Bool = false,
                resolveUser: (@Sendable (String) async -> PluginUser?)? = nil, viewerId: String? = nil,
                busyActionId: String? = nil, actionError: String? = nil, formErrors: [PluginFormError] = [],
                members: [PluginMember] = [], settleToken: Int = 0,
                onBack: (() -> Void)? = nil, onRefresh: (() -> Void)? = nil, onRetry: (() -> Void)? = nil,
                onLoadMore: ((String) -> Void)? = nil, onAction: ((String, PluginActionPayload) -> Void)? = nil,
                onOpenDetail: (() -> Void)? = nil) {
        self.title = title; self.view = view; self.loading = loading; self.error = error
        self.refreshing = refreshing; self.loadingMore = loadingMore; self.resolveUser = resolveUser
        self.viewerId = viewerId; self.busyActionId = busyActionId; self.actionError = actionError
        self.formErrors = formErrors; self.members = members; self.settleToken = settleToken
        self.onBack = onBack; self.onRefresh = onRefresh; self.onRetry = onRetry; self.onLoadMore = onLoadMore
        self.onAction = onAction; self.onOpenDetail = onOpenDetail
        self._refreshInFlight = State(initialValue: refreshing)
    }

    /// The page's title: the view's, else the host's.
    public static func heading(view: PluginViewModel?, title: String?) -> String {
        PluginDetailSheetView.heading(view: view, title: title)
    }

    enum Phase: Equatable { case loading, error, loaded }

    /// Loading wins while there is no view; an error with no view to show is the error; a view is shown.
    static func phase(loading: Bool, error: String?, view: PluginViewModel?) -> Phase {
        if view != nil { return .loaded }
        if loading { return .loading }
        if let error, !error.isEmpty { return .error }
        return .loading
    }

    /// The refresh key belongs to the header on a pointer; touch pulls to refresh.
    static var refreshKeyInHeader: Bool { FlareMessageContextMenu.pointerIdiom }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let screen = FlareScreen(title: Self.heading(view: view, title: title), onBack: onBack, surface: .surface,
                                 actions: headerActions) {
            pageBody(colors)
        }
        Group {
            if onRefresh != nil, !Self.refreshKeyInHeader {
                screen.refreshable { await pull() }
            } else {
                screen
            }
        }
        // A failure or the host stopping frees the load-more key for another try; a merged page moves the cursor on.
        .onChange(of: loadingMore) { loading in if !loading { paging.release() } }
        .onChange(of: settleToken) { _ in paging.release() }
        .onChange(of: actionError) { next in if !(next ?? "").isEmpty { paging.release() } }
        .onChange(of: refreshing) { refreshInFlight = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Self.heading(view: view, title: title))
    }

    /// The pointer's refresh key, spinning while the host refreshes.
    private var headerActions: AnyView? {
        guard onRefresh != nil, Self.refreshKeyInHeader else { return nil }
        if refreshing {
            return AnyView(ProgressView().controlSize(.small).flareTouchTarget()
                .accessibilityLabel(strings.loading))
        }
        return AnyView(IconButtonView(icon: "refresh", accessibilityLabel: strings.pluginPageRefresh, action: onRefresh))
    }

    /// A pull asks the host and holds the indicator until `refreshing` has been set and cleared (or a short wait
    /// passed without the host ever setting it).
    private func pull() async {
        onRefresh?()
        var waited = 0
        while !Task.isCancelled {
            if !refreshInFlight, waited >= 3 { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
            waited += 1
        }
    }

    @ViewBuilder private func pageBody(_ colors: FlareColors) -> some View {
        switch Self.phase(loading: loading, error: error, view: view) {
        case .loading:
            ProgressView()
                .tint(colors.primaryText)
                .frame(maxWidth: .infinity, minHeight: 160)
                .accessibilityLabel(strings.loading)
        case .error:
            VStack(spacing: FlareSizes.spacingMd) {
                Text(error ?? "")
                    .font(.system(size: FlareSizes.fontSizeLg * textScale))
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                ButtonView(label: strings.retry, variant: .secondary, disabled: onRetry == nil) { onRetry?() }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FlareSizes.spacingXl)
        case .loaded:
            if let view {
                VStack(spacing: FlareSizes.spacingMd) {
                    PluginView(view: view, viewerId: viewerId, busyActionId: busyActionId, error: actionError,
                               embedded: true, resolveUser: resolveUser, members: members, formErrors: formErrors,
                               settleToken: settleToken, onAction: onAction, onOpenDetail: onOpenDetail)
                    loadMoreKey(paging.key(cursor: view.nextCursor, loadingMore: loadingMore))
                }
                .padding(.horizontal, FlareSizes.spacingLg)
                .padding(.top, FlareSizes.spacingMd)
                .padding(.bottom, FlareSizes.spacingXl)
            }
        }
    }

    @ViewBuilder private func loadMoreKey(_ state: PluginDetailSheetView.LoadMore) -> some View {
        switch state {
        case .hidden: EmptyView()
        case .ready(let cursor):
            ButtonView(label: strings.myInviteLoadMore, variant: .text, disabled: onLoadMore == nil, block: true) {
                if let asked = paging.tap(cursor: cursor, loadingMore: loadingMore) { onLoadMore?(asked) }
            }
        case .loading:
            ButtonView(label: strings.myInviteLoadMore, variant: .text, loading: true, block: true) {}
        }
    }
}
