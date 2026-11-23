package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.rememberUpdatedState
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import kotlinx.coroutines.delay
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.Dp

/** What a plugin page shows (spec rules.page): the first load, its failure, an unavailable page, or the view. */
internal enum class PluginPagePhase { Loading, Error, Unavailable, Loaded }

/**
 * A view, once there is one, is the page — available or not. Before it: the failure (with retry) once the load has
 * stopped, else the spinner, whether or not the host said it is loading.
 */
internal fun pluginPagePhase(loading: Boolean, error: String?, view: PluginPageViewModel?): PluginPagePhase = when {
    view != null -> if (view.view.available) PluginPagePhase.Loaded else PluginPagePhase.Unavailable
    !error.isNullOrEmpty() && !loading -> PluginPagePhase.Error
    else -> PluginPagePhase.Loading
}

/** The heading: the view's title, else the host's (an unavailable page has no title, so the host's stays). */
internal fun pluginPageTitle(view: PluginPageViewModel?, title: String?): String = pluginDetailHeading(view?.view, title)

/**
 * The tabs a page draws (spec rules.pageTabs): an available view's, when it has 2 or more; without a view, the [last]
 * ones drawn with [page] selected when it is one of them; else none.
 */
internal fun pluginPageTabs(view: PluginPageViewModel?, page: String, last: List<PluginPageTab>): List<PluginPageTab> = when {
    view != null -> view.tabs.takeIf { view.view.available && it.size >= 2 }.orEmpty()
    last.any { it.page == page } -> last.map { it.copy(selected = it.page == page) }
    else -> emptyList()
}

/** The page a chosen segment opens: an unselected tab's; the selected one opens nothing. */
internal fun pluginPageTabChoice(tabs: List<PluginPageTab>, index: Int): String? = tabs.getOrNull(index)?.takeUnless { it.selected }?.page

/** An unavailable page says why: the reason's copy, or the kit's empty text when the view names none. */
internal fun pluginPageUnavailableText(view: PluginViewModel, strings: FlareStrings): String =
    view.unavailableReason?.let { PluginViewFormat.reasonText(it, strings) } ?: strings.pluginViewEmpty

/** Only an unreachable catalog is worth asking again. */
internal fun pluginPageUnavailableRetry(view: PluginViewModel): Boolean =
    view.unavailableReason == PluginUnavailableReason.CatalogUnreachable

/** A loaded page refreshes when the host handles it; the other states draw no refresh. */
internal fun pluginPageRefreshes(phase: PluginPagePhase, handled: Boolean): Boolean = handled && phase == PluginPagePhase.Loaded

/** Pull to refresh is a touch gesture; a fine pointer gets a refresh key in the header instead. */
internal fun pluginPageRefreshKey(pointer: FlarePointerKind, canRefresh: Boolean): Boolean =
    canRefresh && pointer == FlarePointerKind.Fine

/** One tab of a page filter: a choice's value, or null for all. */
internal data class PluginPageFilterTab(val value: String?, val label: String)

/** One select filter of a page (spec rules.pageFilters): its tabs, all first, and the selected value (null: all). */
internal data class PluginPageFilter(val input: PluginInput, val tabs: List<PluginPageFilterTab>, val selected: String?)

/**
 * A page's select filters: with a rows block, the view's filter inputs of kind select, each with all and then its
 * choices; selected is the host's value when it is one of the choices, else all. No rows block: none.
 */
internal fun pluginPageFilters(view: PluginViewModel, filters: Map<String, Any?>, all: String): List<PluginPageFilter> {
    if (view.blocks.none { it is PluginRowsBlock }) return emptyList()
    return PluginViewFormat.filterInputs(view)
        .filter { it.kind == PluginInputKind.Select && !it.choices.isNullOrEmpty() }
        .map { input ->
            val choices = input.choices.orEmpty()
            val value = filters[input.id] as? String
            PluginPageFilter(
                input = input,
                tabs = listOf(PluginPageFilterTab(null, all)) + choices.map { PluginPageFilterTab(it.value, it.label) },
                selected = value?.takeIf { v -> choices.any { it.value == v } },
            )
        }
}

/** The host's filters with [inputId] set to [value], or without it for all (null); the others stay. */
internal fun pluginPageFilterValues(filters: Map<String, Any?>, inputId: String, value: String?): Map<String, Any?> =
    LinkedHashMap(filters).apply { if (value == null) remove(inputId) else put(inputId, value) }

/** A tab chosen: the filters to ask for, or null — the selected tab again, or tabs that wait while the page reloads. */
internal fun pluginPageFilterChoice(filter: PluginPageFilter, value: String?, busy: Boolean, filters: Map<String, Any?>): Map<String, Any?>? =
    if (busy || value == filter.selected) null else pluginPageFilterValues(filters, filter.input.id, value)

/** Window effects requested by a trusted page presentation; the host restores its previous window state. */
data class PluginSurfaceHints(val secure: Boolean = false, val maxBrightness: Boolean = false)

internal fun pluginPageSurfaceHints(view: PluginPageViewModel?): PluginSurfaceHints {
    val presentation = view?.view?.takeIf { it.available }?.presentation
    if (presentation?.get("renderer") != "flare.qr") return PluginSurfaceHints()
    val props = presentation["props"] as? Map<*, *>
    return PluginSurfaceHints(secure = props?.get("ttlMs") is Number, maxBrightness = true)
}

internal fun flarePluginMayRefresh(visible: Boolean, foreground: Boolean, loading: Boolean, refreshing: Boolean, busy: Boolean, interaction: Boolean): Boolean =
    visible && foreground && !loading && !refreshing && !busy && !interaction

internal fun pluginPageRefreshInterval(previous: Long?, view: PluginPageViewModel?): Long? = when {
    view == null -> previous
    view.view.unavailableReason == PluginUnavailableReason.CatalogUnreachable -> view.refreshMs ?: previous
    else -> view.refreshMs
}

/**
 * Plugin page host — a full-screen page for a plugin's `page` contribution (the red packet wallet and its history, any
 * plugin list). Spec: Message/PluginPage (`PluginPage`), docs/design/red-packet-v5-roles-and-wallet.md §3.2; facts in
 * spec/plugin-view-vectors.json (rules.page, pageRows, pagePaging, pageFilters).
 *
 * The kit [FlareScreen] with the heading (the view's title, else [title]; an unavailable page keeps [title]) and, with
 * [onBack], the back key (the platform back does the same). States: before the first view a spinner, or once the load
 * stopped with [error] the host's text and a retry key ([onRetry]); an unavailable view (`available` false) the kit
 * empty state with the reason's copy, a retry key only for `catalog_unreachable`, and nothing else; a loaded view:
 * a danger banner when [error] reports a failed refresh, the select filters, the view drawn by the embedded
 * [PluginView] document renderer (blocks, menu actions as keys, forms and settling behave as in [PluginDetailSheet];
 * rows as a list, each key once) and a full-width "load more" while `view.nextCursor` is set.
 *
 * - [page] is the page shown. Every action run on it — a view action, a menu action, a choices submit, a row action,
 *   after its confirm and form — emits `onAction(id, PluginPageActionPayload)`: the page, `view.data` when the view has
 *   it, the row's key and input, the selection and the form values, which is the core SDK's page action request, so the
 *   host passes it through and routes the outcome. [busyActionId], [actionError], [formErrors], [members] and
 *   [settleToken] go to the view unchanged.
 * - Paging: load more asks [onLoadMore] once per cursor and spins while [loadingMore] (or until the host settles, fails
 *   or stops loading); the host passes back the merged view from the core SDK (the kit merges nothing, and draws a row
 *   key once whatever arrives).
 * - Filters: each select input the rows block lists is a [FilterTabs] row named by its label, all first; the selected
 *   tab is [filters] (the host owns them). Choosing another tab emits [onFilter] with the filters updated; the host reads
 *   the first page with them and passes back the view and the filters. The tabs wait while [refreshing] or
 *   [loadingMore].
 * - Refresh (R1, R4 of docs/plugin-experience.md): pull down on touch, or the header's refresh key on a fine pointer,
 *   only on a loaded data page ([pluginPageIsDataPage]); while [refreshing] a 2-high bar under the header, the body
 *   kept. [onRefresh] says why: pull, key, timer (a pending result, and the page's own interval without
 *   [onAutoRefresh]) and action — an action this page ran settled with no error and no form errors while the page is
 *   visible. `return` is the host's own: it reads a page again when the page above it pops.
 * - Actions (R2): each top-level action is placed by its role and the page archetype ([pluginPagePlan]): an overview's
 *   quick keys in its card and its list cards, a task's bar (pinned on a phone), a records page's header key, commands
 *   and more card; danger last. A page whose one form is its editor draws it inline ([pluginPageInlineFormActionId]).
 * - States (R8): the first load draws nothing for 300 ms, then a skeleton; a load failure is a full-page empty state
 *   with retry; [offline] keeps the view, says so under the header and holds every action; an action failure is a
 *   closable banner at the top. A result block (R7) draws [FlareResultView] whose done key calls [onDone].
 * - Appearance (R12): [appearance] absent derives it from the view's structure ([pluginPageAppearance]).
 *
 * - Upgrade required ([PluginUnavailableReason.UpgradeRequired]): the whole page is [FlarePluginUpgradeNotice] (page)
 *   with the page's title, and the update key when [upgradeStatus] says a build is offered and [onUpdate] is set.
 * - Image and QR blocks: [resolveImage] and [onQrRefresh] go to the view ([PluginView]).
 * - Red packet pages (§11): a view whose renderer is `redPacket.compose`, `redPacket.detail` or `redPacket.review` and that reads
 *   ([redPacketPagePlan]) draws [RedPacketPage]; the actions it does not run stay below as plain keys.
 *
 * The host fetches everything — refresh, retry, load more and filter are requests; the kit calls nothing — and the kit
 * draws nothing the view does not declare. The page is a lazy list, so long ledgers stay cheap.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FlarePluginPage(
    page: PluginPageRef,
    title: String? = null,
    view: PluginPageViewModel? = null,
    /** The page's applied filter values by input id (what the host passed to the core SDK as filters). */
    filters: Map<String, Any?> = emptyMap(),
    loading: Boolean = false,
    error: String? = null,
    refreshing: Boolean = false,
    loadingMore: Boolean = false,
    pagingToken: Int = 0,
    resolveUser: (suspend (String) -> PluginUser?)? = null,
    /** The viewer's user id: entries of that user carry the "me" tag. */
    viewerId: String? = null,
    busyActionId: String? = null,
    actionError: String? = null,
    formErrors: List<PluginFormError> = emptyList(),
    members: List<PluginMember> = emptyList(),
    settleToken: Int = 0,
    onBack: (() -> Unit)? = null,
    /** Read the page again, and why (R4). A lambda that ignores the reason still compiles (`onRefresh = { … }`). */
    onRefresh: ((PluginRefreshReason) -> Unit)? = null,
    onRetry: (() -> Unit)? = null,
    onLoadMore: ((String) -> Unit)? = null,
    /** A filter tab was chosen: the host's filters updated; the host reads the first page with them. */
    onFilter: ((Map<String, Any?>) -> Unit)? = null,
    /** Absent: derived from the view (R12); [FlarePluginPageAppearance.Document] turns the derivation off. */
    appearance: FlarePluginPageAppearance? = null,
    contentMaxWidth: Dp? = FlareSizes.directoryContentMaxWidth,
    fileStates: Map<String, PluginFileState> = emptyMap(),
    onFileAction: ((PluginFileAction) -> Unit)? = null,
    membersLoading: Boolean = false,
    membersError: String? = null,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    membersRevision: Int = 0,
    /** The conversation's group size counting the viewer (the host's own group data): the red packet page's 「本群共 N 人」. */
    memberCount: Int? = null,
    providerName: String? = null,
    encodePluginCode: (suspend (pluginId: String, token: String) -> String)? = null,
    onSurfaceHints: ((PluginSurfaceHints) -> Unit)? = null,
    visible: Boolean = true,
    automaticRefreshing: Boolean = false,
    onAutoRefresh: (() -> Unit)? = null,
    onAction: ((String, PluginPageActionPayload) -> Unit)? = null,
    /** `update.plugin_upgrade_status` for the page's `minBuild`, on an upgrade-required page. */
    upgradeStatus: PluginUpgradeStatus? = null,
    upgradeBusy: Boolean = false,
    /** Opens the update flow ([FlarePluginUpgradeNotice]). */
    onUpdate: (() -> Unit)? = null,
    resolveImage: (suspend (PluginImageSource) -> String?)? = null,
    onQrRefresh: ((PluginQrRefresh) -> Unit)? = null,
    /** Location inputs: the host's fix, a running locate or a failure, by input id. */
    locationStates: Map<String, PluginLocationState> = emptyMap(),
    /** A location input's locate or clear key: the host runs the page's locationOnce action into the input. */
    onLocationAction: ((PluginLocationAction) -> Unit)? = null,
    /** What the host has for each protected media item, by item id (the read's https grant address). */
    protectedMedia: Map<String, PluginProtectedMediaState> = emptyMap(),
    /** A protected media read: the host runs and audits it, then fills [protectedMedia] ([FlarePluginProtectedMedia.url]). */
    onProtectedMediaRead: ((PluginProtectedMediaRead) -> Unit)? = null,
    /** The host is offline: the view stays as last read, a warning under the header, every action held (R8). */
    offline: Boolean = false,
    /** A result page's done key (R7): the host pops back to the page that started the flow and reads it again, else closes. */
    onDone: (() -> Unit)? = null,
    /**
     * A tab other than the shown page was chosen (spec rules.pageTabs): the host replaces the shown page on its stack with
     * that page (same plugin, arguments and conversation; no new back step) and reads it.
     */
    onTab: ((String) -> Unit)? = null,
    /** The host's memory of this page on its stack (dropped when the page leaves it): the red packet composer's draft. */
    contentState: MutableMap<String, Any?>? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    var interval by remember(page) { mutableStateOf<Long?>(null) }
    var interactionActive by remember(page) { mutableStateOf(false) }
    LaunchedEffect(view) { interval = pluginPageRefreshInterval(interval, view) }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    var resumed by remember(lifecycle) { mutableStateOf(lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) }
    DisposableEffect(lifecycle) {
        val observer = LifecycleEventObserver { _, _ -> resumed = lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED) }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }
    val mayTick by rememberUpdatedState(flarePluginMayRefresh(visible, resumed, loading, refreshing, loadingMore || busyActionId != null, interactionActive))
    val autoRefresh by rememberUpdatedState(onAutoRefresh ?: onRefresh?.let { refresh -> { refresh(PluginRefreshReason.Timer) } })
    val refreshNow by rememberUpdatedState(onRefresh)
    val shownNow by rememberUpdatedState(visible && resumed)
    LaunchedEffect(page, interval, visible, resumed) {
        val period = interval ?: return@LaunchedEffect
        if (!visible || !resumed) return@LaunchedEffect
        while (true) { delay(period); if (mayTick) autoRefresh?.invoke() }
    }
    val surfaceHints = pluginPageSurfaceHints(view)
    val emitHints by rememberUpdatedState(onSurfaceHints)
    SideEffect { emitHints?.invoke(surfaceHints) }
    DisposableEffect(page) { onDispose { emitHints?.invoke(PluginSurfaceHints()) } }
    val visualRefreshing = refreshing && !automaticRefreshing
    val heading = pluginPageTitle(view, title)
    // rules.pageTabs: sibling pages as a segmented control; until the chosen page has a view the last tabs stay.
    var lastTabs by remember { mutableStateOf<List<PluginPageTab>>(emptyList()) }
    val tabs = pluginPageTabs(view, page.page, lastTabs)
    LaunchedEffect(view) { pluginPageTabs(view, page.page, emptyList()).takeIf { it.isNotEmpty() }?.let { lastTabs = it } }
    val phase = pluginPagePhase(loading, error, view)
    val shownView = view?.view?.takeIf { phase == PluginPagePhase.Loaded }
    val resolvedAppearance = pluginPageAppearance(appearance, shownView)
    val inlineFormId = shownView?.let { pluginPageInlineFormActionId(it, onAction != null) }
        ?.takeIf { resolvedAppearance == FlarePluginPageAppearance.Document }
    val plan = shownView?.takeIf { resolvedAppearance == FlarePluginPageAppearance.Document }?.let { pluginPagePlan(it, inlineFormId) }
    val dataPage = shownView != null && (resolvedAppearance == FlarePluginPageAppearance.Account ||
        (plan != null && plan.result == null && pluginPageIsDataPage(shownView, plan.places.archetype)))
    // R7: a pending result reads itself again every 3 s for at most 60 s after it first showed pending.
    val result = plan?.result
    val pollStart = remember(page) { arrayOf<Long?>(null) }
    LaunchedEffect(result?.state, visible, resumed) {
        if (result == null || !pluginResultPolls(result)) { pollStart[0] = null; return@LaunchedEffect }
        val start = pollStart[0] ?: System.currentTimeMillis().also { pollStart[0] = it }
        while (System.currentTimeMillis() - start < PLUGIN_RESULT_POLL_FOR_MS) {
            delay(PLUGIN_RESULT_POLL_MS)
            if (mayTick) autoRefresh?.invoke()
        }
    }
    // R8: the first load draws nothing for 300 ms, then the skeleton.
    var skeleton by remember(page) { mutableStateOf(false) }
    LaunchedEffect(page, phase == PluginPagePhase.Loading) {
        skeleton = false
        if (phase == PluginPagePhase.Loading) { delay(PLUGIN_SKELETON_DELAY_MS); skeleton = true }
    }
    // The records header key runs through the view (confirm, form, then the action).
    var headerRun by remember(page) { mutableStateOf<PluginExternalRun?>(null) }
    // The cursor asked for and not answered yet: the same page is never asked for twice.
    var paging by remember { mutableStateOf(PluginDetailPaging()) }
    // 5.8: the list asked for a next page at least once (its end then reads "that's everything").
    var pagedOnce by remember(page) { mutableStateOf(false) }
    PluginOnChange(loadingMore) { _, more -> if (!more) paging = paging.released() }
    PluginOnChange(settleToken) { _, _ -> paging = paging.released() }
    PluginOnChange(pagingToken) { _, _ -> paging = paging.released() }
    PluginOnChange(actionError) { _, next -> if (!next.isNullOrEmpty()) paging = paging.released() }
    PluginOnChange(error) { _, next -> if (!next.isNullOrEmpty()) paging = paging.released() }
    // A refresh reads the first page again and may bring the same cursor back (spec rules.pagePaging).
    PluginOnChange(refreshing) { before, now -> if (before && !now) paging = paging.released() }
    val refreshes = pluginPageRefreshes(phase, onRefresh != null) && dataPage
    val refreshKey = pluginPageRefreshKey(flarePlatform().capabilities.pointer, refreshes)
    val headerKey = plan?.places?.header?.firstOrNull()?.takeIf { onAction != null && shownView?.let(PluginViewFormat::readOnly) != true }
    val listState = rememberLazyListState()
    // R1: the body's sides are 2xl on a wide window, lg on a phone.
    val phone = flareCompactOverlays()
    val side = if (phone) FlareSizes.spacingLg else FlareSizes.spacing2xl
    val padding = PaddingValues(start = side, end = side, top = FlareSizes.spacingMd, bottom = FlareSizes.spacingXl)
    // R3: development warnings name the plugin and the page.
    androidx.compose.runtime.CompositionLocalProvider(LocalPluginWarnScope provides "${page.pluginId} ${page.page}") {
    FlareScreen(
        title = heading.ifEmpty { null },
        surface = if (resolvedAppearance == FlarePluginPageAppearance.Account) FlareScreenSurface.Surface else FlareScreenSurface.Canvas,
        onBack = onBack,
        scroll = false,
        contentMaxWidth = contentMaxWidth,
        actions = if (!refreshKey && headerKey == null) null else ({
            Row(verticalAlignment = Alignment.CenterVertically) {
                // R2.3: a records page's primary is the header's text key on a phone, a secondary sm key on a wide window;
                // R2.5: an action that says why it cannot run waits (the reason reads under the header).
                headerKey?.let { action ->
                    Button(label = action.label, variant = if (phone) FlareButtonVariant.Text else FlareButtonVariant.Secondary, size = FlareControlSize.Sm,
                        appearance = if (phone) FlareButtonAppearance.Text else FlareButtonAppearance.Standard, maintainTouchTarget = true,
                        loading = busyActionId == action.id,
                        disabled = offline || action.disabledReason != null || (busyActionId != null && busyActionId != action.id),
                        onClick = { headerRun = PluginExternalRun(action.id, (headerRun?.token ?: 0) + 1) })
                }
                if (refreshKey) FlareIconControl(label = strings.pluginPageRefresh, onClick = { onRefresh?.invoke(PluginRefreshReason.Key) }, enabled = !refreshing) {
                    FlareIcon("refresh", size = FlareSizes.iconSizeMd, tint = colors.textSecondary)
                }
            }
        }),
    ) {
        val body: @Composable () -> Unit = {
            Column(Modifier.fillMaxSize().semantics { paneTitle = heading }) {
                // R1: refreshing draws a 2-high bar under the header and keeps the body.
                PluginRefreshBar(visualRefreshing)
                if (tabs.isNotEmpty()) SegmentedControl(
                    options = tabs.map { it.label },
                    selectedIndex = tabs.indexOfFirst { it.selected },
                    onSelect = { index -> pluginPageTabChoice(tabs, index)?.let { onTab?.invoke(it) } },
                    modifier = Modifier.fillMaxWidth()
                        .padding(start = side, end = side, top = FlareSizes.spacingMd)
                        .semantics { contentDescription = heading },
                )
                // R8: offline keeps the view and says so under the header.
                if (offline && view != null) Box(Modifier.fillMaxWidth().padding(horizontal = side, vertical = FlareSizes.spacingSm)) {
                    StatusBanner(text = strings.pluginViewOffline, tone = FlareStatusTone.Warning)
                }
                // R2.5: why the header's key waits, under the header.
                headerKey?.disabledReason?.let { reason ->
                    PluginCaption(reason, Modifier.padding(horizontal = side, vertical = FlareSizes.spacingXs), align = TextAlign.End)
                }
                providerName?.takeIf { it.isNotBlank() }?.let { provider ->
                    Text(strings.scanProvidedBy.replace("{name}", provider), color = colors.textSecondary,
                        modifier = Modifier.fillMaxWidth().padding(horizontal = side, vertical = FlareSizes.spacingSm))
                }
                Box(Modifier.weight(1f)) {
                when (phase) {
                    // R8: nothing for 300 ms, then the records skeleton (no view yet says which archetype it is).
                    PluginPagePhase.Loading -> Box(Modifier.fillMaxWidth().padding(padding).semantics { contentDescription = strings.loading }) {
                        if (skeleton) Skeleton(SkeletonVariant.List, rows = PLUGIN_RECORDS_SKELETON_ROWS, still = flareReducedMotion())
                    }
                    // R8: a load failure without a view is a full-page empty state with the host's text and retry.
                    PluginPagePhase.Error -> Column(
                        Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(padding)
                            .semantics { liveRegion = LiveRegionMode.Assertive },
                    ) {
                        EmptyState(
                            title = strings.pluginViewLoadFailedTitle, description = error.orEmpty(), icon = "error",
                            tone = FlareEmptyStateTone.Error,
                            actions = { Button(label = strings.retry, variant = FlareButtonVariant.Secondary, disabled = onRetry == null,
                                onClick = { onRetry?.invoke() }) },
                        )
                    }
                    PluginPagePhase.Unavailable -> view?.let { shown ->
                        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(padding)) {
                            if (shown.view.upgradeRequired) FlarePluginUpgradeNotice(
                                FlarePluginUpgradeVariant.Page, title = heading, status = upgradeStatus, busy = upgradeBusy, onUpdate = onUpdate,
                            ) else EmptyState(
                                title = pluginPageUnavailableText(shown.view, strings),
                                icon = "info",
                                actions = if (!pluginPageUnavailableRetry(shown.view)) null else ({
                                    Button(label = strings.retry, variant = FlareButtonVariant.Secondary, disabled = onRetry == null,
                                        onClick = { onRetry?.invoke() })
                                }),
                            )
                        }
                    }
                    PluginPagePhase.Loaded -> view?.let { loaded ->
                        // §11: a redPacket.compose / .detail / .review view that reads draws the kit's red packet page;
                        // the actions it does not run stay below as plain keys.
                        val packet = remember(loaded.view) { redPacketPagePlan(loaded.view) }
                        val pageFilters = pluginPageFilters(loaded.view, filters, strings.pluginViewAll)
                        val filtersBusy = loading || visualRefreshing || loadingMore
                        val more = paging.key(loaded.view.nextCursor, loadingMore)
                        val failed = error?.takeIf { it.isNotEmpty() }
                        val list = PluginViewList(
                            state = listState,
                            contentPadding = padding,
                            header = {
                                // A refresh that failed while the view shows.
                                if (failed != null) item(key = "page:banner") {
                                    Box(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingMd)) {
                                        StatusBanner(text = failed, tone = FlareStatusTone.Danger,
                                            actionText = strings.retry.takeIf { onRefresh != null && !refreshing },
                                            onAction = onRefresh?.takeUnless { refreshing }?.let { refresh -> { refresh(PluginRefreshReason.Key) } })
                                    }
                                }
                                if (pageFilters.isNotEmpty()) item(key = "page:filters") {
                                    Column(
                                        Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingMd),
                                        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                                    ) {
                                        pageFilters.forEach { filter -> PluginPageFilterRow(filter, filtersBusy, filters, onFilter) }
                                    }
                                }
                                if (packet != null) item(key = "page:red-packet") {
                                    RedPacketPage(
                                        plan = packet, view = loaded.view, busyActionId = busyActionId, refreshing = visualRefreshing,
                                        error = actionError, formErrors = formErrors, settleToken = settleToken,
                                        members = members, membersLoading = membersLoading, membersError = membersError,
                                        membersRevision = membersRevision, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry,
                                        resolveUser = resolveUser, onBack = onBack, contentState = contentState, memberCount = memberCount,
                                        onRefresh = { reason -> if (reason != PluginRefreshReason.Action || shownNow) refreshNow?.invoke(reason) },
                                        onAction = onAction?.takeUnless { offline }?.let { emit ->
                                            { id: String, payload: PluginActionPayload -> emit(id, PluginPageActionPayload.of(page, loaded, payload)) }
                                        },
                                    )
                                }
                            },
                            footer = {
                                // 5.8: once the list has paged, its end says so.
                                // Not "page:more": that is the view's more-actions card, and a lazy list throws on a repeated key.
                                if (more != PluginDetailLoadMore.Hidden || pagedOnce) item(key = "page:load-more") {
                                    PluginLoadMoreKey(more, onLoadMore.takeUnless { loading || refreshing }, end = pagedOnce) { cursor ->
                                        if (loading || refreshing) return@PluginLoadMoreKey null
                                        val (next, asked) = paging.tap(cursor, loadingMore)
                                        paging = next
                                        if (asked != null) pagedOnce = true
                                        asked
                                    }
                                }
                            },
                        )
                        val actions = pluginDetailActionState(busyActionId, actionError, formErrors, members, settleToken)
                        if (resolvedAppearance == FlarePluginPageAppearance.Account) {
                            AccountViewContent(pluginAccountDocument(loaded.view), actions.busyActionId, actions.error, actions.formErrors,
                                actions.members, actions.settleToken, onAction?.let { emit ->
                                    { id, payload -> emit(id, PluginPageActionPayload.of(page, loaded, payload)) }
                                }, list, contentMaxWidth = null, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision, fileStates = fileStates, onFileAction = onFileAction,
                                offline = offline, resolveUser = resolveUser, viewerId = viewerId)
                        } else
                        PluginViewContent(
                            view = packet?.let { redPacketPageRemainder(loaded.view, it) } ?: redPacketPlainView(loaded.view),
                            showError = packet == null,
                            icon = null, busy = false, busyActionId = actions.busyActionId, error = actions.error,
                            embedded = true, inset = PluginViewInset.None, resolveUser = resolveUser, members = actions.members, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision,
                            formErrors = actions.formErrors, settleToken = actions.settleToken, displayName = null, viewerId = viewerId,
                            quote = null,
                            onAction = onAction?.let { emit ->
                                { id: String, payload: PluginActionPayload -> emit(id, PluginPageActionPayload.of(page, loaded, payload)) }
                            },
                            onOpenDetail = null,
                            list = list,
                            fileStates = fileStates, onFileAction = onFileAction,
                            encodeQr = encodePluginCode?.let { encode -> { token -> encode(page.pluginId, token) } },
                            qrReceivedAtNanos = loaded.receivedAtNanos,
                            onInteractionChanged = { interactionActive = it },
                            resolveImage = resolveImage, onQrRefresh = onQrRefresh,
                            locationStates = locationStates, onLocationAction = onLocationAction, protectedMedia = protectedMedia, onProtectedMediaRead = onProtectedMediaRead,
                            actionLayout = PluginViewActionLayout.Page,
                            inlineFormActionId = inlineFormId,
                            offline = offline,
                            onDone = onDone,
                            externalRun = headerRun,
                            // R4: a clean settle reads the page again, only while it is the page shown.
                            onSettled = { refreshNow?.invoke(PluginRefreshReason.Action) },
                            visible = shownNow,
                            onClearFilters = onFilter?.takeIf { pageFilters.any { it.selected != null } && !filtersBusy }?.let { emit ->
                                { emit(pageFilters.fold(filters) { values, filter -> pluginPageFilterValues(values, filter.input.id, null) }) }
                            },
                        )
                    }
                }
                }
            }
        }
        if (refreshes) {
            // The pull only asks; the bar under the header shows the read (R1), so the pull indicator retracts.
            PullToRefreshBox(isRefreshing = false, onRefresh = { onRefresh?.invoke(PluginRefreshReason.Pull) }, modifier = Modifier.fillMaxSize()) { body() }
        } else {
            body()
        }
    }
    }
}

/** One select filter as a [FilterTabs] row: all first, then the choices; the tabs wait while the page reloads. */
@Composable
private fun PluginPageFilterRow(
    filter: PluginPageFilter,
    busy: Boolean,
    filters: Map<String, Any?>,
    onFilter: ((Map<String, Any?>) -> Unit)?,
) {
    // Tabs are keyed by position: all is the first, and a choice's value never has to double as a key.
    val selected = filter.tabs.indexOfFirst { it.value == filter.selected }.coerceAtLeast(0)
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
    Text(filter.input.label, color = flareColors().textSecondary, fontSize = FlareSizes.fontSizeSm)
    FilterTabs(
        options = filter.tabs.mapIndexed { i, tab -> FlareFilterTabOption(i.toString(), tab.label) },
        selected = selected.toString(),
        onSelect = { key ->
            val tab = key.toIntOrNull()?.let { filter.tabs.getOrNull(it) } ?: return@FilterTabs
            pluginPageFilterChoice(filter, tab.value, busy, filters)?.let { onFilter?.invoke(it) }
        },
        enabled = !busy && onFilter != null,
        label = filter.input.label,
    )
    }
}
