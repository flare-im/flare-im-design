import SwiftUI

/// Plugin page host — a full-screen page for a plugin's `page` contribution (the red packet wallet and its history,
/// a list). Spec: Message/PluginPage (`FlarePluginPage`), `spec/plugin-view-vectors.json` rules.page, pageRows,
/// pagePaging and pageFilters; docs/design/red-packet-v5-roles-and-wallet.md §3.2.
///
/// - Heading: the view's title, else `title` (an unavailable page has none, so the host's stays); `onBack` draws the
///   back key.
/// - States: with no view, a spinner while `loading` (or before anything arrived), else the host's `error` and the
///   retry key. `view.available` false: the kit empty state with the reason's words (``PluginUnavailableReason``),
///   and the retry key only when the catalog was unreachable — no refresh, filters, load more or actions.
/// - The page: a refresh that failed (`error` while a view shows) as a danger banner, the filter tabs, the view drawn
///   by an embedded ``PluginView`` — the detail sheet's renderer, so blocks, menu actions (keys after the footer
///   actions), forms and settling behave the same; rows draw as a list with their badges, once per key — and a
///   full-width "load more" while `view.nextCursor` is set, asked once per cursor as in ``PluginDetailSheetView``. Pull
///   to refresh on touch, a refresh key in the header on a pointer (macOS, iPad).
/// - Filters: the select inputs the rows block lists (every input when it lists none) are kit filter tabs, all first.
///   The host owns the values (`filters`); choosing another tab calls `onFilter` with them updated (that input set,
///   or removed for all), and the host reads the first page again, as a refresh. The tabs wait while the page
///   refreshes or loads more.
/// - Actions: every action run on the page — a footer or menu key, a choices submit, a row key, after its
///   confirmation and form — calls `onAction(id, payload)` with the page, the view's `data`, and the row, selection
///   or form values it carries: the core SDK's page action request, which the host passes on as it is (a page target
///   opens the next page with the outcome's payload as its arguments).
/// - Paging: `onLoadMore(cursor)` asks for the next page; the host passes back the merged view from the core SDK
///   (the new rows and entries after the shown ones, data kept). The kit merges nothing.
///
/// The host fetches: `onRefresh`, `onRetry`, `onLoadMore` and `onFilter` are requests; the kit calls nothing and
/// draws nothing the view does not declare.
public struct FlarePluginPage: View {
    private let page: PluginPageRef
    private let title: String?
    private let view: PluginPageViewModel?
    private let filters: [String: PluginJSONValue]
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
    private let onFilter: (([String: PluginJSONValue]) -> Void)?
    private let onAction: ((String, PluginPageActionPayload) -> Void)?
    private var appearance: FlarePluginPageAppearance = .document
    private let clock: PluginViewClock
    /// The cursor asked for and not answered yet.
    @State private var paging = PluginDetailPaging()
    /// The host's `refreshing`, read by a pull that waits for it to clear.
    @State private var refreshInFlight = false
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - page: The page shown; every action run on it carries it.
    ///   - view: The core SDK's `pluginPage` result; nil while the first load runs. After `onLoadMore` pass the merged
    ///     view, after a refresh or a filter change the one read again.
    ///   - filters: The filter values applied, by input id (what the host passed to `pluginPage` as filters).
    public init(page: PluginPageRef, title: String? = nil, view: PluginPageViewModel? = nil,
                filters: [String: PluginJSONValue] = [:], loading: Bool = false, error: String? = nil,
                refreshing: Bool = false, loadingMore: Bool = false,
                resolveUser: (@Sendable (String) async -> PluginUser?)? = nil, viewerId: String? = nil,
                busyActionId: String? = nil, actionError: String? = nil, formErrors: [PluginFormError] = [],
                members: [PluginMember] = [], settleToken: Int = 0,
                onBack: (() -> Void)? = nil, onRefresh: (() -> Void)? = nil, onRetry: (() -> Void)? = nil,
                onLoadMore: ((String) -> Void)? = nil, onFilter: (([String: PluginJSONValue]) -> Void)? = nil,
                onAction: ((String, PluginPageActionPayload) -> Void)? = nil,
                appearance: FlarePluginPageAppearance = .document) {
        self.init(page: page, title: title, view: view, filters: filters, loading: loading, error: error,
                  refreshing: refreshing, loadingMore: loadingMore, resolveUser: resolveUser, viewerId: viewerId,
                  busyActionId: busyActionId, actionError: actionError, formErrors: formErrors, members: members,
                  settleToken: settleToken, onBack: onBack, onRefresh: onRefresh, onRetry: onRetry,
                  onLoadMore: onLoadMore, onFilter: onFilter, onAction: onAction, clock: .system)
        self.appearance = appearance
    }

    /// The page at a fixed clock — how the tests pin `now` and the zone of the rows' time cells.
    init(page: PluginPageRef, title: String?, view: PluginPageViewModel?, filters: [String: PluginJSONValue],
         loading: Bool, error: String?, refreshing: Bool, loadingMore: Bool,
         resolveUser: (@Sendable (String) async -> PluginUser?)?, viewerId: String?, busyActionId: String?,
         actionError: String?, formErrors: [PluginFormError], members: [PluginMember], settleToken: Int,
         onBack: (() -> Void)?, onRefresh: (() -> Void)?, onRetry: (() -> Void)?, onLoadMore: ((String) -> Void)?,
         onFilter: (([String: PluginJSONValue]) -> Void)?, onAction: ((String, PluginPageActionPayload) -> Void)?,
         clock: PluginViewClock) {
        self.page = page; self.title = title; self.view = view; self.filters = filters
        self.loading = loading; self.error = error; self.refreshing = refreshing; self.loadingMore = loadingMore
        self.resolveUser = resolveUser; self.viewerId = viewerId; self.busyActionId = busyActionId
        self.actionError = actionError; self.formErrors = formErrors; self.members = members
        self.settleToken = settleToken
        self.onBack = onBack; self.onRefresh = onRefresh; self.onRetry = onRetry; self.onLoadMore = onLoadMore
        self.onFilter = onFilter; self.onAction = onAction; self.clock = clock
        self._refreshInFlight = State(initialValue: refreshing)
    }

    /// The page's heading: the view's title, else the host's.
    public static func heading(view: PluginPageViewModel?, title: String?) -> String {
        PluginDetailSheetView.heading(view: view?.view, title: title)
    }

    enum Phase: Equatable { case loading, error, unavailable, loaded }

    /// A view is shown (or, unavailable, says why); without one an error that is not being retried is the error, and
    /// anything else is still loading.
    static func phase(loading: Bool, error: String?, view: PluginPageViewModel?) -> Phase {
        if let view { return view.available ? .loaded : .unavailable }
        if !loading, let error, !error.isEmpty { return .error }
        return .loading
    }

    /// The refresh key belongs to the header on a pointer; touch pulls to refresh.
    static var refreshKeyInHeader: Bool { FlareMessageMenuSource.pointerIdiom }

    private var phase: Phase { Self.phase(loading: loading, error: error, view: view) }

    /// Only a shown page refreshes.
    private var canRefresh: Bool { onRefresh != nil && phase == .loaded }

    /// The filters wait while the page is read again or grows.
    private var filtersWaiting: Bool { refreshing || loadingMore }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let screen = FlareScreen(title: Self.heading(view: view, title: title), onBack: onBack, surface: .surface,
                                 actions: headerActions) {
            pageBody(colors)
        }
        Group {
            if canRefresh, !Self.refreshKeyInHeader {
                screen.refreshable { await pull() }
            } else {
                screen
            }
        }
        // A failure, the host stopping or a page read again frees the load-more key; a merged page moves it on.
        .onChange(of: loadingMore) { loading in if !loading { paging.release() } }
        .onChange(of: settleToken) { _ in paging.release() }
        .onChange(of: actionError) { next in if !(next ?? "").isEmpty { paging.release() } }
        .onChange(of: refreshing) { next in
            refreshInFlight = next
            if !next { paging.release() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Self.heading(view: view, title: title))
    }

    /// The pointer's refresh key, spinning while the host refreshes.
    private var headerActions: AnyView? {
        guard canRefresh, Self.refreshKeyInHeader else { return nil }
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
        switch phase {
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
                retryKey
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FlareSizes.spacingXl)
        case .unavailable:
            if let view {
                EmptyStateView(title: PluginPageRules.unavailableText(view.view, strings), icon: "info",
                               actions: PluginPageRules.unavailableRetry(view.view) ? AnyView(retryKey) : nil)
                    .frame(maxWidth: .infinity)
            }
        case .loaded:
            if let view {
                VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    if let error, !error.isEmpty {
                        StatusBannerView(text: error, tone: .danger)
                    }
                    filterRows(view.view)
                    if appearance == .account || view.view.presentation?.renderer == "account" {
                        FlareAccountView(view: view.view, busyActionId: busyActionId, error: actionError,
                                         formErrors: formErrors, members: members, settleToken: settleToken,
                                         onAction: pageAction(view))
                    } else {
                    PluginView(view: view.view, icon: nil, viewerId: viewerId, busy: false, busyActionId: busyActionId,
                               error: actionError, embedded: true, resolveUser: resolveUser, members: members,
                               formErrors: formErrors, settleToken: settleToken, onAction: pageAction(view),
                               onOpenDetail: nil, clock: clock, users: [:])
                    }
                    loadMoreKey(paging.key(cursor: view.nextCursor, loadingMore: loadingMore))
                }
                .padding(.horizontal, FlareSizes.spacingLg)
                .padding(.top, FlareSizes.spacingMd)
                .padding(.bottom, FlareSizes.spacingXl)
            }
        }
    }

    private var retryKey: some View {
        ButtonView(label: strings.retry, variant: .secondary, disabled: onRetry == nil) { onRetry?() }
    }

    /// The embedded view's actions as page actions: the page and the view's data go with each.
    private func pageAction(_ view: PluginPageViewModel) -> ((String, PluginActionPayload) -> Void)? {
        guard let onAction else { return nil }
        let page = page
        return { id, payload in onAction(id, PluginPageActionPayload(page: page, view: view, payload: payload)) }
    }

    /// One kit filter tab row per select filter, named by its input's label; all is the empty key (a choice's value
    /// never is).
    @ViewBuilder private func filterRows(_ view: PluginViewModel) -> some View {
        let rows = PluginPageRules.filters(view, values: filters, all: strings.pluginViewAll)
        if !rows.isEmpty {
            let off = filtersWaiting || onFilter == nil
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                ForEach(rows) { filter in
                    FilterTabsView(options: filter.tabs.map { FlareFilterTabOption(value: $0.value ?? "", label: $0.label) },
                                   selection: .constant(filter.selected ?? ""), enabled: !off,
                                   onChange: { key in choose(filter, key) })
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(filter.input.label)
                }
            }
        }
    }

    private func choose(_ filter: PluginPageFilter, _ key: String) {
        guard !filtersWaiting,
              let next = PluginPageRules.choose(filter, value: key.isEmpty ? nil : key, in: filters) else { return }
        onFilter?(next)
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
