package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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

/** What a plugin page shows: the first load, its failure with nothing to show, or the view. */
internal enum class PluginPagePhase { Loading, Error, Loaded }

/** The view wins once there is one; before it the error (with retry) wins over the spinner. */
internal fun pluginPagePhase(loading: Boolean, error: String?, view: PluginViewModel?): PluginPagePhase = when {
    view != null -> PluginPagePhase.Loaded
    !error.isNullOrEmpty() -> PluginPagePhase.Error
    // Nothing yet: still loading, whether or not the host said so.
    else -> PluginPagePhase.Loading
}

/** The page title: the view's, else the host's. */
internal fun pluginPageTitle(view: PluginViewModel?, title: String?): String = pluginDetailHeading(view, title)

/** Pull to refresh is a touch gesture; a fine pointer gets a refresh key in the header instead. */
internal fun pluginPageRefreshKey(pointer: FlarePointerKind, canRefresh: Boolean): Boolean =
    canRefresh && pointer == FlarePointerKind.Fine

/**
 * Plugin page host — a full-screen page for a plugin's `page` contribution (red packet v5's wallet, any plugin list).
 * Spec: Layout/PluginPage (`PluginPage`), docs/design/red-packet-v5-roles-and-wallet.md §3.2.
 *
 * The kit [FlareScreen] with the title (the view's, else [title]) and, with [onBack], the back key (the platform back does
 * the same). The view is drawn by an embedded [PluginView] — the same document renderer as [PluginDetailSheet], so blocks,
 * menu actions (as keys), forms and settling behave the same, and [busyActionId], [actionError], [formErrors], [members]
 * and [settleToken] go to it unchanged. Before the first view: a spinner while [loading], the host's [error] with a retry
 * key ([onRetry]). Refresh: pull down on touch, or the header's refresh key on a fine pointer; the indicator stays while
 * [refreshing]. Pages: a non-blank `view.nextCursor` draws a full-width "load more" key that asks [onLoadMore] once per
 * cursor and spins while [loadingMore]. The host fetches everything — refresh, retry and load more are requests; the
 * kit calls nothing — and draws nothing the view does not declare (no placeholder keys).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FlarePluginPage(
    title: String? = null,
    view: PluginViewModel? = null,
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
    onAction: ((String, PluginActionPayload) -> Unit)? = null,
    onOpenDetail: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val heading = pluginPageTitle(view, title)
    // The cursor asked for and not answered yet: the same page is never asked for twice.
    var paging by remember { mutableStateOf(PluginDetailPaging()) }
    PluginOnChange(loadingMore) { _, more -> if (!more) paging = paging.released() }
    PluginOnChange(settleToken) { _, _ -> paging = paging.released() }
    PluginOnChange(actionError) { _, next -> if (!next.isNullOrEmpty()) paging = paging.released() }
    val refreshKey = pluginPageRefreshKey(flarePlatform().capabilities.pointer, onRefresh != null)
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
            Column(
                Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                    .semantics { paneTitle = heading }
                    .padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = FlareSizes.spacingXl),
            ) {
                when (pluginPagePhase(loading, error, view)) {
                    PluginPagePhase.Loading -> Box(Modifier.fillMaxWidth().heightIn(min = 160.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(FlareSizes.iconSizeLg).semantics { contentDescription = strings.loading },
                            color = colors.primaryText, strokeWidth = 2.dp,
                        )
                    }
                    PluginPagePhase.Error -> Column(
                        Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingXl),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
                    ) {
                        Text(error.orEmpty(), color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center,
                            modifier = Modifier.semantics { liveRegion = LiveRegionMode.Assertive })
                        Button(label = strings.retry, variant = FlareButtonVariant.Secondary, disabled = onRetry == null,
                            onClick = { onRetry?.invoke() })
                    }
                    PluginPagePhase.Loaded -> view?.let { loaded ->
                        val actions = pluginDetailActionState(busyActionId, actionError, formErrors, members, settleToken)
                        PluginView(
                            view = loaded, busyActionId = actions.busyActionId, error = actions.error, embedded = true,
                            resolveUser = resolveUser, members = actions.members, formErrors = actions.formErrors,
                            settleToken = actions.settleToken, viewerId = viewerId, quote = null,
                            onAction = onAction, onOpenDetail = onOpenDetail,
                        )
                        PluginLoadMoreKey(paging.key(loaded.nextCursor, loadingMore), onLoadMore) { cursor ->
                            val (next, asked) = paging.tap(cursor, loadingMore)
                            paging = next
                            asked
                        }
                    }
                }
            }
        }
        if (onRefresh != null) {
            PullToRefreshBox(isRefreshing = refreshing, onRefresh = onRefresh, modifier = Modifier.fillMaxSize()) { body() }
        } else {
            body()
        }
    }
}
