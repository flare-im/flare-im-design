package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
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
 * - Refresh: pull down on touch, or the header's refresh key on a fine pointer, on a loaded page only; the indicator
 *   stays while [refreshing].
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
    resolveUser: (suspend (String) -> PluginUser?)? = null,
    /** The viewer's user id: entries of that user carry the "me" tag. */
    viewerId: String? = null,
    busyActionId: String? = null,
    actionError: String? = null,
    formErrors: List<PluginFormError> = emptyList(),
    members: List<PluginMember> = emptyList(),
    settleToken: Int = 0,
    onBack: (() -> Unit)? = null,
    onRefresh: (() -> Unit)? = null,
    onRetry: (() -> Unit)? = null,
    onLoadMore: ((String) -> Unit)? = null,
    /** A filter tab was chosen: the host's filters updated; the host reads the first page with them. */
    onFilter: ((Map<String, Any?>) -> Unit)? = null,
    appearance: FlarePluginPageAppearance = FlarePluginPageAppearance.Document,
    onAction: ((String, PluginPageActionPayload) -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val heading = pluginPageTitle(view, title)
    val phase = pluginPagePhase(loading, error, view)
    // The cursor asked for and not answered yet: the same page is never asked for twice.
    var paging by remember { mutableStateOf(PluginDetailPaging()) }
    PluginOnChange(loadingMore) { _, more -> if (!more) paging = paging.released() }
    PluginOnChange(settleToken) { _, _ -> paging = paging.released() }
    PluginOnChange(actionError) { _, next -> if (!next.isNullOrEmpty()) paging = paging.released() }
    // A refresh reads the first page again and may bring the same cursor back (spec rules.pagePaging).
    PluginOnChange(refreshing) { before, now -> if (before && !now) paging = paging.released() }
    val refreshes = pluginPageRefreshes(phase, onRefresh != null)
    val refreshKey = pluginPageRefreshKey(flarePlatform().capabilities.pointer, refreshes)
    val listState = rememberLazyListState()
    val padding = PaddingValues(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = FlareSizes.spacingXl)
    FlareScreen(
        title = heading.ifEmpty { null },
        onBack = onBack,
        scroll = false,
        actions = if (!refreshKey) null else ({
            FlareIconControl(label = strings.pluginPageRefresh, onClick = { onRefresh?.invoke() }, enabled = !refreshing) {
                if (refreshing) CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeMd), color = colors.primaryText, strokeWidth = 2.dp)
                else FlareIcon("refresh", size = FlareSizes.iconSizeMd, tint = colors.textSecondary)
            }
        }),
    ) {
        val body: @Composable () -> Unit = {
            Box(Modifier.fillMaxSize().semantics { paneTitle = heading }) {
                when (phase) {
                    PluginPagePhase.Loading -> Box(Modifier.fillMaxWidth().heightIn(min = 160.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(FlareSizes.iconSizeLg).semantics { contentDescription = strings.loading },
                            color = colors.primaryText, strokeWidth = 2.dp,
                        )
                    }
                    PluginPagePhase.Error -> Column(
                        Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(padding).padding(vertical = FlareSizes.spacingXl),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
                    ) {
                        Text(error.orEmpty(), color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center,
                            modifier = Modifier.semantics { liveRegion = LiveRegionMode.Assertive })
                        Button(label = strings.retry, variant = FlareButtonVariant.Secondary, disabled = onRetry == null,
                            onClick = { onRetry?.invoke() })
                    }
                    PluginPagePhase.Unavailable -> view?.let { shown ->
                        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(padding)) {
                            EmptyState(
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
                        val pageFilters = pluginPageFilters(loaded.view, filters, strings.pluginViewAll)
                        val filtersBusy = refreshing || loadingMore
                        val more = paging.key(loaded.view.nextCursor, loadingMore)
                        val failed = error?.takeIf { it.isNotEmpty() }
                        val list = PluginViewList(
                            state = listState,
                            contentPadding = padding,
                            header = {
                                // A refresh that failed while the view shows.
                                if (failed != null) item(key = "page:banner") {
                                    Box(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingMd)) {
                                        StatusBanner(text = failed, tone = FlareStatusTone.Danger)
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
                            },
                            footer = {
                                if (more != PluginDetailLoadMore.Hidden) item(key = "page:more") {
                                    PluginLoadMoreKey(more, onLoadMore) { cursor ->
                                        val (next, asked) = paging.tap(cursor, loadingMore)
                                        paging = next
                                        asked
                                    }
                                }
                            },
                        )
                        val actions = pluginDetailActionState(busyActionId, actionError, formErrors, members, settleToken)
                        if (appearance == FlarePluginPageAppearance.Account || loaded.view.presentation?.get("renderer") == "account") {
                            AccountViewContent(loaded.view, actions.busyActionId, actions.error, actions.formErrors,
                                actions.members, actions.settleToken, onAction?.let { emit ->
                                    { id, payload -> emit(id, PluginPageActionPayload.of(page, loaded, payload)) }
                                }, list)
                        } else
                        PluginViewContent(
                            view = loaded.view, icon = null, busy = false, busyActionId = actions.busyActionId, error = actions.error,
                            embedded = true, inset = PluginViewInset.None, resolveUser = resolveUser, members = actions.members,
                            formErrors = actions.formErrors, settleToken = actions.settleToken, displayName = null, viewerId = viewerId,
                            quote = null,
                            onAction = onAction?.let { emit ->
                                { id: String, payload: PluginActionPayload -> emit(id, PluginPageActionPayload.of(page, loaded, payload)) }
                            },
                            onOpenDetail = null,
                            list = list,
                        )
                    }
                }
            }
        }
        if (refreshes) {
            PullToRefreshBox(isRefreshing = refreshing, onRefresh = { onRefresh?.invoke() }, modifier = Modifier.fillMaxSize()) { body() }
        } else {
            body()
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
