import SwiftUI

/// A paged detail's state: the cursor asked for and not answered yet, so the same page is never asked for twice.
struct PluginDetailPaging: Equatable, Sendable {
    private(set) var requested: String?

    func key(cursor: String?, loadingMore: Bool) -> PluginDetailSheetView.LoadMore {
        PluginDetailSheetView.loadMore(cursor: cursor, requested: requested, loadingMore: loadingMore)
    }

    /// A tap on the key: the cursor to ask for, or nil while the key is off.
    mutating func tap(cursor: String?, loadingMore: Bool) -> String? {
        guard case .ready(let next) = key(cursor: cursor, loadingMore: loadingMore) else { return nil }
        requested = next
        return next
    }

    /// The host stopped loading, settled an action or reported a failure: the key may be tried again.
    mutating func release() { requested = nil }
}

/// "See all" of a plugin card: the detail view (core SDK `plugin_detail`) as an embedded ``PluginView``. Spec:
/// Overlay/PluginDetailSheet (`PluginDetailSheetView`).
///
/// The host presents it inside `flareBottomSheet(isPresented:title:)` with ``heading(view:title:)`` as the sheet's
/// title (the view's title, else the card's). While `loading` (or before a view arrives) it shows a spinner named by
/// `loading`; with `error` the host's text and the retry key (`onRetry`); otherwise the view without a card shell or
/// title row, whose blocks, actions and forms behave as on the card.
///
/// `viewerId` goes to the embedded view: the viewer's entries in a grouped list carry the "我" tag. The view's menu
/// actions are keys after its footer actions (the sheet has no title row of the view's).
///
/// Actions run from the detail: `busyActionId`, `actionError` (the view's error), `formErrors`, `members` and
/// `settleToken` go to the embedded ``PluginView`` unchanged, so such an action spins, fails, collects its form and
/// settles inside the sheet. The host keeps them apart from the card's own busy and error, so a failure in the
/// detail never lands on the card below. `error` stays the loading failure (with retry).
///
/// Pages: a view with `nextCursor` ends with "load more", which calls `onLoadMore(cursor)`; the host fetches the next
/// page and hands back the merged view (the core SDK merges; the kit never does). The key spins while `loadingMore`,
/// and from the tap until the merged view moves the cursor on, the host stops loading or reports a failure
/// (`actionError`, `settleToken`), so it never sends the same page twice.
public struct PluginDetailSheetView: View {
    private let title: String?
    private let view: PluginViewModel?
    private let loading: Bool
    private let error: String?
    private let resolveUser: (@Sendable (String) async -> PluginUser?)?
    private let viewerId: String?
    private let busyActionId: String?
    private let actionError: String?
    private let formErrors: [PluginFormError]
    private let members: [PluginMember]
    private let settleToken: Int
    private let loadingMore: Bool
    private let onLoadMore: ((String) -> Void)?
    private let onRetry: (() -> Void)?
    private let onAction: ((String, PluginActionPayload) -> Void)?
    /// The cursor asked for and not answered yet.
    @State private var paging = PluginDetailPaging()
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(title: String? = nil, view: PluginViewModel? = nil, loading: Bool = false, error: String? = nil,
                resolveUser: (@Sendable (String) async -> PluginUser?)? = nil, viewerId: String? = nil,
                busyActionId: String? = nil,
                actionError: String? = nil, formErrors: [PluginFormError] = [], members: [PluginMember] = [],
                settleToken: Int = 0, loadingMore: Bool = false,
                onRetry: (() -> Void)? = nil, onAction: ((String, PluginActionPayload) -> Void)? = nil,
                onLoadMore: ((String) -> Void)? = nil) {
        self.title = title; self.view = view; self.loading = loading; self.error = error
        self.resolveUser = resolveUser; self.viewerId = viewerId; self.busyActionId = busyActionId
        self.actionError = actionError; self.formErrors = formErrors; self.members = members
        self.settleToken = settleToken; self.loadingMore = loadingMore
        self.onRetry = onRetry; self.onAction = onAction; self.onLoadMore = onLoadMore
    }

    /// The key at the foot of a paged detail.
    enum LoadMore: Equatable { case hidden, ready(String), loading }

    /// No cursor (or a blank one): the last page, no key. Otherwise it spins while the host loads, or while the
    /// cursor asked for is still the view's.
    static func loadMore(cursor: String?, requested: String?, loadingMore: Bool) -> LoadMore {
        guard let cursor, !cursor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .hidden }
        return loadingMore || requested == cursor ? .loading : .ready(cursor)
    }

    /// The sheet's title: the view's, else the host's.
    public static func heading(view: PluginViewModel?, title: String?) -> String {
        if let viewTitle = view?.title, !viewTitle.isEmpty { return viewTitle }
        return title ?? ""
    }

    enum Phase: Equatable { case loading, error, loaded }

    /// What the sheet shows: loading wins, then the error, then the view; nothing yet is still loading.
    static func phase(loading: Bool, error: String?, view: PluginViewModel?) -> Phase {
        if loading { return .loading }
        if let error, !error.isEmpty { return .error }
        return view == nil ? .loading : .loaded
    }

    @ViewBuilder private func loadMoreKey(_ state: LoadMore) -> some View {
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

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Group {
            switch Self.phase(loading: loading, error: error, view: view) {
            case .loading:
                ProgressView()
                    .tint(colors.primaryText)
                    .frame(maxWidth: .infinity, minHeight: 120)
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
                                   embedded: true,
                                   resolveUser: resolveUser, members: members, formErrors: formErrors,
                                   settleToken: settleToken, onAction: onAction)
                        loadMoreKey(paging.key(cursor: view.nextCursor, loadingMore: loadingMore))
                    }
                }
            }
        }
        // A failure or the host stopping frees the key for another try; a merged page moves the cursor on.
        .onChange(of: loadingMore) { loading in if !loading { paging.release() } }
        .onChange(of: settleToken) { _ in paging.release() }
        .onChange(of: actionError) { next in if !(next ?? "").isEmpty { paging.release() } }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.top, FlareSizes.spacingMd).padding(.bottom, FlareSizes.spacingXl)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Self.heading(view: view, title: title))
    }
}
