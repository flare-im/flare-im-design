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
/// - Upgrade required (``PluginUnavailableReason/upgradeRequired``): the whole page is ``FlarePluginUpgradeNotice``
///   (page) with the page's title, the update key when `upgradeStatus` says a build is offered and `onUpdate` is set.
/// - Image and QR blocks: `resolveImage` and `onQrRefresh` go to the view (``PluginView``).
/// - Paging: `onLoadMore(cursor)` asks for the next page; the host passes back the merged view from the core SDK
///   (the new rows and entries after the shown ones, data kept). The kit merges nothing.
///
/// The host fetches: `onRefresh`, `onRetry`, `onLoadMore` and `onFilter` are requests; the kit calls nothing and
/// draws nothing the view does not declare.
///
/// docs/plugin-experience.md §2: actions draw by the page's archetype (R2: overview quick keys and list cards, a
/// task's bottom bar pinned on touch, a records page's header key; ``PluginViewActionLayout/page``); the refresh key
/// and pull only on a data page, a 2-high bar while refreshing (R1); after an action settles cleanly the kit asks for
/// a read (`onRefresh(.action)`, R4); `appearance` nil derives the account appearance from the view's structure
/// (R12); a result block draws ``FlareResultView`` and polls while pending (R7); nothing for 300 ms then a skeleton,
/// a failed first read as an empty state with retry, `offline` as a warning banner with every action disabled, an
/// action failure as a dismissible banner (R8).
public struct FlarePluginPage: View {
    private var providerName: String? = nil
    private var visible = true
    private var encodeQr: (@Sendable (String) async throws -> String)? = nil
    private var onSurfaceHints: ((FlareScanSurfaceHints) -> Void)? = nil
    @State private var refreshInterval: Int?
    @State private var automaticRefresh = false
    @Environment(\.scenePhase) private var scenePhase
    private let page: PluginPageRef
    private let title: String?
    private let view: PluginPageViewModel?
    private let filters: [String: PluginJSONValue]
    private let loading: Bool
    private let error: String?
    private let refreshing: Bool
    private let loadingMore: Bool
    private let pagingToken: Int
    private let resolveUser: (@Sendable (String) async -> PluginUser?)?
    private let viewerId: String?
    private let busyActionId: String?
    private let actionError: String?
    private let formErrors: [PluginFormError]
    private let members: [PluginMember]
    private let membersLoading: Bool
    private let membersRevision: Int
    private let membersError: String?
    private let onMemberSearch: ((String) -> Void)?
    private let onMembersRetry: (() -> Void)?
    private let settleToken: Int
    private let onBack: (() -> Void)?
    /// A read the page asks for, with why (R1 pull and key, R4 action, R7 and `refreshMs` timer).
    private let onRefresh: ((PluginRefreshReason) -> Void)?
    private let onRetry: (() -> Void)?
    private let onLoadMore: ((String) -> Void)?
    private let onFilter: (([String: PluginJSONValue]) -> Void)?
    private let fileStates: [String: PluginFileState]
    private let onFileAction: ((PluginFileAction) -> Void)?
    private let onAction: ((String, PluginPageActionPayload) -> Void)?
    private var appearance: FlarePluginPageAppearance?
    /// The conversation's group size counting the viewer (the host's own group data): the red packet page's 「本群共 N 人」.
    private var memberCount: Int?
    private var offline = false
    private var onDone: (() -> Void)?
    /// §4.7: an unselected tab chosen — the host replaces this page with that sibling page (same plugin, arguments and
    /// conversation, no new back step) and reads it.
    private var onTab: ((String) -> Void)?
    /// The tabs last drawn, kept while a chosen tab's page loads (spec rules.pageTabs).
    @State private var lastTabs: [PluginPageTab] = []
    /// The header key and the bottom bar the embedded view hands up (R2.2, R2.3).
    @State private var chrome: PluginPageChrome?
    /// The page's own form's submit key, pinned on touch (R6).
    @State private var formSubmit: PluginFormSubmit?
    /// R8: the skeleton waits 300 ms.
    @State private var skeletonDue = false
    /// R8: the action failure the viewer closed.
    @State private var dismissedError: String?
    /// An action form is open below: it shows the action's failure, so the page shows no banner for it.
    @State private var formOpen = false
    /// 5.8: the page asked for a next page at least once: no cursor left then reads "没有更多了".
    @State private var pagedOnce = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var upgradeStatus: PluginUpgradeStatus?
    private var upgradeBusy = false
    private var onUpdate: (() -> Void)?
    private var resolveImage: (@Sendable (PluginImageSource) async -> URL?)?
    private var onQrRefresh: ((PluginQrRefresh) -> Void)?
    private var locationStates: [String: PluginLocationState] = [:]
    private var onLocationAction: ((PluginLocationAction) -> Void)?
    private var protectedMedia: [String: PluginProtectedMediaState] = [:]
    private var onProtectedMediaRead: ((PluginProtectedMediaRead) -> Void)?
    private let contentMaxWidth: CGFloat?
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
    ///   - locationStates: Location inputs: the host's fix, a running locate or a failure, by input id.
    ///   - onLocationAction: A location input's locate or clear key: the host runs the page's locationOnce action into
    ///     the input and passes its fix back in `locationStates`; on clear it drops that input's state.
    ///   - protectedMedia: What the host has for each protected media item, by item id: the read's address (the
    ///     server's https grant address), a running read or a failure.
    ///   - onProtectedMediaRead: A protected media read (with its reason when the block asks one): the host runs and
    ///     audits it, then fills `protectedMedia` with ``FlarePluginProtectedMedia/url(result:urlPath:)``.
    public init(page: PluginPageRef, title: String? = nil, view: PluginPageViewModel? = nil,
                filters: [String: PluginJSONValue] = [:], loading: Bool = false, error: String? = nil,
                refreshing: Bool = false, loadingMore: Bool = false, pagingToken: Int = 0,
                resolveUser: (@Sendable (String) async -> PluginUser?)? = nil, viewerId: String? = nil,
                busyActionId: String? = nil, actionError: String? = nil, formErrors: [PluginFormError] = [],
                members: [PluginMember] = [], membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
                memberCount: Int? = nil,
                onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil, settleToken: Int = 0,
                onBack: (() -> Void)? = nil, onRefresh: ((PluginRefreshReason) -> Void)? = nil, onRetry: (() -> Void)? = nil,
                onLoadMore: ((String) -> Void)? = nil, onFilter: (([String: PluginJSONValue]) -> Void)? = nil,
                fileStates: [String: PluginFileState] = [:], onFileAction: ((PluginFileAction) -> Void)? = nil,
                onAction: ((String, PluginPageActionPayload) -> Void)? = nil,
                appearance: FlarePluginPageAppearance? = nil,
                contentMaxWidth: CGFloat? = FlareSizes.directoryContentMaxWidth,
                providerName: String? = nil, visible: Bool = true,
                encodeQr: (@Sendable (String) async throws -> String)? = nil,
                onSurfaceHints: ((FlareScanSurfaceHints) -> Void)? = nil,
                upgradeStatus: PluginUpgradeStatus? = nil, upgradeBusy: Bool = false, onUpdate: (() -> Void)? = nil,
                resolveImage: (@Sendable (PluginImageSource) async -> URL?)? = nil,
                onQrRefresh: ((PluginQrRefresh) -> Void)? = nil,
                locationStates: [String: PluginLocationState] = [:],
                onLocationAction: ((PluginLocationAction) -> Void)? = nil,
                protectedMedia: [String: PluginProtectedMediaState] = [:],
                onProtectedMediaRead: ((PluginProtectedMediaRead) -> Void)? = nil,
                offline: Bool = false, onDone: (() -> Void)? = nil, onTab: ((String) -> Void)? = nil) {
        self.init(page: page, title: title, view: view, filters: filters, loading: loading, error: error,
                  refreshing: refreshing, loadingMore: loadingMore, pagingToken: pagingToken, resolveUser: resolveUser, viewerId: viewerId,
                  busyActionId: busyActionId, actionError: actionError, formErrors: formErrors, members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry,
                  settleToken: settleToken, onBack: onBack, onRefresh: onRefresh, onRetry: onRetry,
                  onLoadMore: onLoadMore, onFilter: onFilter, fileStates: fileStates, onFileAction: onFileAction, onAction: onAction, clock: .system, contentMaxWidth: contentMaxWidth)
        self.appearance = appearance; self.memberCount = memberCount
        self.providerName = providerName; self.visible = visible; self.encodeQr = encodeQr; self.onSurfaceHints = onSurfaceHints
        self.upgradeStatus = upgradeStatus; self.upgradeBusy = upgradeBusy; self.onUpdate = onUpdate
        self.resolveImage = resolveImage; self.onQrRefresh = onQrRefresh
        self.locationStates = locationStates; self.onLocationAction = onLocationAction
        self.protectedMedia = protectedMedia; self.onProtectedMediaRead = onProtectedMediaRead
        self.offline = offline; self.onDone = onDone; self.onTab = onTab
    }

    /// The page at a fixed clock — how the tests pin `now` and the zone of the rows' time cells.
    init(page: PluginPageRef, title: String?, view: PluginPageViewModel?, filters: [String: PluginJSONValue],
         loading: Bool, error: String?, refreshing: Bool, loadingMore: Bool, pagingToken: Int = 0,
         resolveUser: (@Sendable (String) async -> PluginUser?)?, viewerId: String?, busyActionId: String?,
         actionError: String?, formErrors: [PluginFormError], members: [PluginMember], membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
                onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil, settleToken: Int,
         onBack: (() -> Void)?, onRefresh: ((PluginRefreshReason) -> Void)?, onRetry: (() -> Void)?, onLoadMore: ((String) -> Void)?,
         onFilter: (([String: PluginJSONValue]) -> Void)?,
         fileStates: [String: PluginFileState] = [:], onFileAction: ((PluginFileAction) -> Void)? = nil, onAction: ((String, PluginPageActionPayload) -> Void)?,
         clock: PluginViewClock, contentMaxWidth: CGFloat? = FlareSizes.directoryContentMaxWidth) {
        self.fileStates = fileStates; self.onFileAction = onFileAction
        self.contentMaxWidth = flareContentMaxWidth(contentMaxWidth)
        self.page = page; self.title = title; self.view = view; self.filters = filters
        self.loading = loading; self.error = error; self.refreshing = refreshing; self.loadingMore = loadingMore
        self.pagingToken = pagingToken
        self.resolveUser = resolveUser; self.viewerId = viewerId; self.busyActionId = busyActionId
        self.actionError = actionError; self.formErrors = formErrors; self.members = members
        self.membersLoading = membersLoading; self.membersRevision = membersRevision; self.membersError = membersError
        self.onMemberSearch = onMemberSearch; self.onMembersRetry = onMembersRetry
        self.settleToken = settleToken
        self.onBack = onBack; self.onRefresh = onRefresh; self.onRetry = onRetry; self.onLoadMore = onLoadMore
        self.onFilter = onFilter; self.onAction = onAction; self.clock = clock
        self._refreshInFlight = State(initialValue: refreshing)
    }

    private func updateScanSurface() {
        let qr = visible && scenePhase == .active && view?.available == true && view?.view.presentation?.renderer == "flare.qr"
        onSurfaceHints?(FlareScanSurfaceHints(secure: qr && view?.view.presentation?.props["ttlMs"]?.numberValue != nil, maxBrightness: qr))
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

    /// R1: the body's side margin — 24 on a pointer (PC, iPad), 16 on a phone.
    static var pageMargin: CGFloat { refreshKeyInHeader ? FlareSizes.spacing2xl : FlareSizes.spacingLg }

    private var phase: Phase { Self.phase(loading: loading, error: error, view: view) }

    /// Only a shown data page refreshes (R1).
    private var canRefresh: Bool {
        guard onRefresh != nil, phase == .loaded, let view else { return false }
        return effectiveAppearance == .account
            || PluginExperienceRules.showsRefreshKey(view.view, inlineFormActionId: inlineFormActionId)
    }

    private var effectiveAppearance: FlarePluginPageAppearance {
        PluginExperienceRules.appearance(appearance, view?.view)
    }

    /// The page's own form shown in place (R6), on a document page.
    private var inlineFormActionId: String? {
        guard let view, effectiveAppearance == .document else { return nil }
        return PluginExperienceRules.pageInlineForm(view.view, hasAction: onAction != nil)
    }

    private func requestRefresh(_ reason: PluginRefreshReason) { onRefresh?(reason) }

    /// R7: the result shown is pending — the page reads again every 3 s for at most a minute.
    private var resultPending: Bool {
        guard let view, let result = PluginExperienceRules.resultBlock(view.view) else { return false }
        return !result.unmapped && result.state == "pending"
    }

    /// The filters wait while the page is read again or grows.
    private var filtersWaiting: Bool { loading || (refreshing && !automaticRefresh) || loadingMore }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let screen = FlareScreen(title: Self.heading(view: view, title: title), onBack: onBack, surface: .surface,
                                 actions: headerActions, contentMaxWidth: contentMaxWidth) {
            VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
                tabRow
                pageBody(colors)
            }
                .padding(.horizontal, Self.pageMargin)
                .padding(.top, FlareSizes.spacingMd)
                .padding(.bottom, FlareSizes.spacingXl)
        }
        .overlay(alignment: .top) {
            // R1: a 2-high bar under the header while a read the viewer asked for runs.
            if refreshing && !automaticRefresh && phase == .loaded {
                PluginRefreshBar(still: reduceMotion).padding(.top, FlareSizes.screenHeaderHeight)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if phase == .loaded, formSubmit != nil || !((chrome?.bar ?? []) + (chrome?.barSecondary ?? [])).isEmpty {
                bottomBar(chrome, colors)
            }
        }
        .onPreferenceChange(PluginPageChromeKey.self) { chrome = $0 }
        .onPreferenceChange(PluginFormSubmitKey.self) { formSubmit = $0 }
        .onPreferenceChange(PluginFormOpenKey.self) { formOpen = $0 }
        Group {
            if canRefresh, !Self.refreshKeyInHeader {
                screen.refreshable { await pull() }
            } else {
                screen
            }
        }
        // A failure, the host stopping or a page read again frees the load-more key; a merged page moves it on.
        .onChange(of: loadingMore) { loading in if !loading { paging.release() } }
        .onChange(of: settleToken) { _ in
            paging.release()
            dismissedError = nil
            // R4: a clean settle while the page shows asks for a read.
            let settle: PluginRefreshRules.Settle = !(actionError ?? "").isEmpty ? .error : !formErrors.isEmpty ? .formErrors : .ok
            if phase == .loaded, let reason = PluginRefreshRules.afterAction(settle, visible: visible) { requestRefresh(reason) }
        }
        .task(id: phase == .loading) {
            skeletonDue = false
            guard phase == .loading else { return }
            try? await Task.sleep(nanoseconds: UInt64(PluginExperienceRules.skeletonDelayMs) * 1_000_000)
            if !Task.isCancelled { skeletonDue = true }
        }
        .task(id: resultPending) {
            guard resultPending else { return }
            var waited = 0
            while !Task.isCancelled, waited < PluginExperienceRules.resultPollForMs {
                try? await Task.sleep(nanoseconds: UInt64(PluginExperienceRules.resultPollMs) * 1_000_000)
                waited += PluginExperienceRules.resultPollMs
                guard !Task.isCancelled else { return }
                if visible, !refreshing, !loading { automaticRefresh = true; requestRefresh(.timer) }
            }
        }
        .onChange(of: pagingToken) { _ in paging.release() }
        .onChange(of: actionError) { next in if !(next ?? "").isEmpty { paging.release() } }
        .onChange(of: error) { next in if !(next ?? "").isEmpty { paging.release() } }
        .onChange(of: refreshing) { next in
            refreshInFlight = next
            if !next { automaticRefresh = false }
            if !next { paging.release() }
        }
        .onAppear { keepTabs(view) }
        .onChange(of: view) { keepTabs($0) }
        .onAppear { updateScanSurface(); if let value = view?.refreshMs, (3000...60000).contains(value) { refreshInterval = value } }
        .onDisappear { onSurfaceHints?(FlareScanSurfaceHints(secure: false, maxBrightness: false)) }
        .onChange(of: view?.refreshMs) { value in if let value, (3000...60000).contains(value) { refreshInterval = value } }
        .onChange(of: view?.view.presentation) { _ in updateScanSurface() }
        .onChange(of: visible) { _ in updateScanSurface() }
        .onChange(of: scenePhase) { _ in updateScanSurface() }
        .task(id: refreshInterval) {
            guard let interval = refreshInterval else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000) } catch { return }
                guard !Task.isCancelled else { return }
                if flareScanPluginCanRefresh(visible: visible, foreground: scenePhase == .active,
                    loading: loading || loadingMore, refreshing: refreshing, busy: busyActionId != nil,
                    interaction: !(view?.view.inputs.isEmpty ?? true)) {
                    automaticRefresh = true; requestRefresh(.timer)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Self.heading(view: view, title: title))
    }

    /// The header: a records page's primary key (R2.3: a secondary key on a pointer, a text key on touch) and the
    /// pointer's refresh key (waiting while the host refreshes; the bar under the header shows it).
    private var headerActions: AnyView? {
        let keys = phase == .loaded ? chrome?.header ?? [] : []
        let refresh = canRefresh && Self.refreshKeyInHeader
        guard refresh || !keys.isEmpty else { return nil }
        return AnyView(HStack(spacing: FlareSizes.spacingXs) {
            if let chrome {
                ForEach(keys) { action in
                    ButtonView(label: action.label, variant: Self.refreshKeyInHeader ? .secondary : .text, size: .sm,
                               loading: chrome.busyActionId == action.id,
                               disabled: (chrome.locked && chrome.busyActionId != action.id) || action.disabledReason != nil,
                               maintainTouchTarget: true) { chrome.run(action) }
                }
            }
            if refresh {
                IconButtonView(icon: "refresh", accessibilityLabel: strings.pluginPageRefresh,
                               disabled: refreshing && !automaticRefresh) { requestRefresh(.key) }
            }
        })
    }

    /// R2.2 on touch: the task's keys pinned over the safe area — quiet secondaries over the full-width primary.
    private func bottomBar(_ chrome: PluginPageChrome?, _ colors: FlareColors) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            if let chrome, !chrome.barSecondary.isEmpty {
                HStack(spacing: FlareSizes.spacingSm) {
                    ForEach(chrome.barSecondary) { action in
                        ButtonView(label: action.label, variant: .quiet, loading: chrome.busyActionId == action.id,
                                   disabled: (chrome.locked && chrome.busyActionId != action.id) || action.disabledReason != nil,
                                   block: true) { chrome.run(action) }
                    }
                }
            }
            if let formSubmit {
                ButtonView(label: formSubmit.label, size: .lg, loading: formSubmit.busy,
                           disabled: formSubmit.disabled || offline, block: true, action: formSubmit.submit)
                if let caption = formSubmit.caption { PluginCaption(text: caption) }
            } else if let chrome {
                ForEach(chrome.bar) { action in
                    ButtonView(label: action.label, variant: action.style == .danger ? .danger : .primary, size: .lg,
                               loading: chrome.busyActionId == action.id,
                               disabled: (chrome.locked && chrome.busyActionId != action.id) || action.disabledReason != nil,
                               block: true) { chrome.run(action) }
                    if let reason = action.disabledReason { PluginCaption(text: reason) }
                }
            }
            if formSubmit != nil ? offline : chrome?.offline == true { PluginCaption(text: strings.pluginViewAvailableOnline) }
        }
        .padding(.horizontal, Self.pageMargin)
        .padding(.vertical, FlareSizes.spacingMd)
        .frame(maxWidth: contentMaxWidth ?? .infinity)
        .frame(maxWidth: .infinity)
        .background(colors.bgPrimary.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
    }

    /// The tabs drawn now (spec rules.pageTabs).
    private var tabs: [PluginPageTab] { PluginPageRules.tabs(view: view, page: page.page, last: lastTabs) }

    private func keepTabs(_ view: PluginPageViewModel?) {
        if let view, view.view.available, view.tabs.count >= 2 { lastTabs = view.tabs }
    }

    /// §4.7: the sibling pages as the kit segmented control (a tab list), above banners, filters and blocks.
    @ViewBuilder private var tabRow: some View {
        let tabs = self.tabs
        if tabs.count >= 2 {
            SegmentedControlView(options: tabs.map(\.label), selectedIndex: tabs.firstIndex(where: \.selected) ?? 0,
                                 onSelect: { index in
                                     if let next = PluginPageRules.tabChoice(tabs, index: index) { onTab?(next) }
                                 })
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Self.heading(view: view, title: title))
        }
    }

    /// A pull asks the host and holds the indicator until `refreshing` has been set and cleared (or a short wait
    /// passed without the host ever setting it).
    private func pull() async {
        requestRefresh(.pull)
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
            // R8: nothing for 300 ms, then the records skeleton (the archetype is unknown before a view).
            Group {
                if skeletonDue { SkeletonView(variant: .list, rows: 6, still: reduceMotion).padding(-FlareSizes.spacingLg) }
                else { Color.clear.frame(height: 160) }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(strings.pluginViewLoading)
        case .error:
            EmptyStateView(title: strings.pluginViewLoadFailedTitle, description: error, icon: "error",
                           actions: AnyView(retryKey))
                .frame(maxWidth: .infinity)
        case .unavailable:
            if let view, view.view.upgradeRequired {
                FlarePluginUpgradeNotice(variant: .page, title: Self.heading(view: view, title: title),
                                         status: upgradeStatus, busy: upgradeBusy, onUpdate: onUpdate)
                    .frame(maxWidth: .infinity)
            } else if let view {
                EmptyStateView(title: PluginPageRules.unavailableText(view.view, strings), icon: "info",
                               actions: PluginPageRules.unavailableRetry(view.view) ? AnyView(retryKey) : nil)
                    .frame(maxWidth: .infinity)
            }
        case .loaded:
            if let view {
                // §11: a red packet renderer the kit draws itself (it shows its own action errors).
                let redPacket = FlareRedPacketPagePlan.of(view.view)
                VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
                    if offline { StatusBannerView(text: strings.pluginViewOffline, tone: .warning) }
                    // R8: an action failure leads the page in a banner the viewer can close (the account view's too).
                    if let actionError, !actionError.isEmpty, actionError != dismissedError, redPacket == nil, !formOpen {
                        StatusBannerView(text: actionError, tone: .danger, dismissible: true,
                                         onDismiss: { dismissedError = actionError })
                    }
                    if let error, !error.isEmpty {
                        StatusBannerView(text: error, tone: .danger,
                                         actionText: canRefresh && !refreshing ? strings.retry : nil,
                                         onAction: !refreshing ? { requestRefresh(.key) } : nil)
                    }
                    if let providerName, !providerName.isEmpty { Text(strings.scanProvidedBy.replacingOccurrences(of: "{name}", with: providerName)).foregroundColor(colors.textSecondary) }
                    if let presentation = view.view.presentation, presentation.renderer == "flare.qr" {
                        FlarePluginQrView(token: presentation.props["token"]?.stringValue, ttlMs: presentation.props["ttlMs"]?.numberValue, caption: presentation.props["caption"]?.stringValue, encodeQr: encodeQr)
                    }
                    filterRows(view.view)
                    if let redPacket {
                        redPacketPage(redPacket, view)
                    } else if effectiveAppearance == .account {
                        FlareAccountView(view: view.view, busyActionId: busyActionId, error: actionError,
                                         formErrors: formErrors, members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry,  settleToken: settleToken,
                                         fileStates: fileStates, onFileAction: onFileAction, offline: offline,
                                         resolveUser: resolveUser, viewerId: viewerId, onAction: pageAction(view))
                            .accountContentWidth(contentMaxWidth)
                            .accountErrorShownAbove()
                            .environment(\.flarePluginClearFilters, clearFilters(view.view))
                    } else {
                    PluginView(view: view.view, icon: nil, viewerId: viewerId, busy: false, busyActionId: busyActionId,
                               error: actionError, embedded: true, actionLayout: .page, showError: false,
                               inlineFormActionId: inlineFormActionId,
                               resolveUser: resolveUser, members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry,
                               formErrors: formErrors, settleToken: settleToken, fileStates: fileStates, onFileAction: onFileAction, onAction: pageAction(view),
                               onOpenDetail: nil, clock: clock, users: [:], resolveImage: resolveImage,
                               onQrRefresh: onQrRefresh)
                        .hostCapabilities(locationStates: locationStates, onLocationAction: onLocationAction,
                                          protectedMedia: protectedMedia, onProtectedMediaRead: onProtectedMediaRead)
                        .pageState(offline: offline, onDone: onDone)
                        .environment(\.flarePluginClearFilters, clearFilters(view.view))
                    }
                    loadMoreKey(paging.key(cursor: view.nextCursor, loadingMore: loadingMore))
                    if view.nextCursor == nil, pagedOnce { PluginCaption(text: strings.pluginViewEndOfList).frame(maxWidth: .infinity) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // R3: a development warning names the plugin and the page before the value's place.
                .environment(\.flarePluginScope, "\(page.pluginId) \(page.page) ")
            }
        }
    }

    /// The red packet page, and under it, as a list, the page's actions it does not run (cancel, recovery).
    @ViewBuilder private func redPacketPage(_ plan: FlareRedPacketPagePlan, _ view: PluginPageViewModel) -> some View {
        let run = pageAction(view)
        RedPacketPageView(plan: plan, view: view.view, busyActionId: busyActionId, refreshing: refreshing, offline: offline,
                          actionError: actionError, formErrors: formErrors, settleToken: settleToken, members: members,
                          memberCount: memberCount,
                          membersLoading: membersLoading, membersError: membersError, membersRevision: membersRevision,
                          onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry, resolveUser: resolveUser,
                          onAction: { id, payload in run?(id, payload) }, onRefresh: onRefresh, onBack: onBack)
        let owned = Set(plan.ownedActionIds)
        let rest = PluginViewModel(available: true, title: "", actions: view.view.actions.filter { !owned.contains($0.id) },
                                   inputs: view.view.inputs, menuActions: view.view.menuActions.filter { !owned.contains($0.id) },
                                   unavailableReason: view.view.unavailableReason)
        if !rest.actions.isEmpty || !rest.menuActions.isEmpty {
            PluginView(view: rest, viewerId: viewerId, busyActionId: busyActionId, error: actionError, embedded: true,
                       actionLayout: .list, showError: false, resolveUser: resolveUser, formErrors: formErrors,
                       settleToken: settleToken, onAction: run)
                .pageState(offline: offline, onDone: onDone)
        }
    }

    private var retryKey: some View {
        ButtonView(label: strings.retry, variant: .secondary, disabled: onRetry == nil) { onRetry?() }
    }

    /// 5.8: the empty state's "清除筛选" — every filter back to all; nil when no filter is set.
    private func clearFilters(_ view: PluginViewModel) -> (() -> Void)? {
        guard let onFilter, let next = PluginPageRules.cleared(
            PluginPageRules.filters(view, values: filters, all: strings.pluginViewAll), in: filters) else { return nil }
        return { if !filtersWaiting { onFilter(next) } }
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
                    Text(filter.input.label).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(FlareColors.of(scheme, brand: flareBrandTheme).textSecondary)
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
            // 5.8: a full-width secondary key.
            ButtonView(label: strings.pluginViewLoadMore, variant: .secondary, disabled: onLoadMore == nil || loading || refreshing, block: true) {
                guard !loading, !refreshing else { return }
                if let asked = paging.tap(cursor: cursor, loadingMore: loadingMore) { pagedOnce = true; onLoadMore?(asked) }
            }
        case .loading:
            ButtonView(label: strings.pluginViewLoadMore, variant: .secondary, loading: true, block: true) {}
        }
    }
}

/// R1: the 2-high progress bar under the header while a page refreshes; a still half bar under reduce motion.
struct PluginRefreshBar: View {
    let still: Bool
    @State private var moving = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        GeometryReader { geo in
            Capsule().fill(FlareColors.of(scheme, brand: flareBrandTheme).primary)
                .frame(width: geo.size.width / 2, height: 2)
                .offset(x: still ? 0 : (moving ? geo.size.width : -geo.size.width / 2))
                .animation(still ? nil : FlareMotion.refreshLoopAnimation.repeatForever(autoreverses: false), value: moving)
        }
        .frame(height: 2)
        .clipped()
        .onAppear { if !still { moving = true } }
        .accessibilityHidden(true)
    }
}
