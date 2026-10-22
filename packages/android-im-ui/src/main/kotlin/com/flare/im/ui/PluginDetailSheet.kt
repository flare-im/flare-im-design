package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
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
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

/**
 * "See all" of a plugin card: the kit [BottomSheet] with the detail view (core SDK `plugin_detail`) as an embedded
 * [PluginView]. Spec: Overlay/PluginDetailSheet (`PluginDetailSheet`).
 *
 * The host composes it while the sheet is open. Its title is the view's, else [title]. While [loading] (or before a view
 * arrives) it shows a spinner named by `loading`; with [error] the host's text and the retry key ([onRetry]); otherwise
 * the view without a card shell or title row, whose blocks, actions and forms behave as on the card. The scrim, back and
 * Escape call [onClose].
 *
 * Actions run from the detail: [busyActionId], [actionError] (the view's error), [formErrors], [members] and
 * [settleToken] go to the embedded [PluginView] unchanged, so such an action spins, fails, collects its form and settles
 * inside the sheet. The host keeps them apart from the card's own busy and error, so a failure in the detail never lands
 * on the card below. [error] stays the loading failure (with retry).
 *
 * Pages: a view with `nextCursor` ends with "load more", which calls [onLoadMore] (cursor); the host fetches the next page
 * and hands back the merged view (the core SDK merges; the kit never does). The key spins while [loadingMore], and from
 * the tap until the merged view moves the cursor on, the host stops loading or reports a failure ([actionError],
 * [settleToken]), so it never sends the same page twice.
 */
@Composable
fun PluginDetailSheet(
    title: String? = null,
    view: PluginViewModel? = null,
    loading: Boolean = false,
    error: String? = null,
    resolveUser: (suspend (String) -> PluginUser?)? = null,
    /** The viewer's user id, for the "me" tag in grouped entries. */
    viewerId: String? = null,
    busyActionId: String? = null,
    actionError: String? = null,
    formErrors: List<PluginFormError> = emptyList(),
    members: List<PluginMember> = emptyList(),
    settleToken: Int = 0,
    /** The host is fetching the next page. */
    loadingMore: Boolean = false,
    onRetry: (() -> Unit)? = null,
    onAction: ((String, PluginActionPayload) -> Unit)? = null,
    /** "Load more" of a paged detail: the view's `nextCursor`. */
    onLoadMore: ((String) -> Unit)? = null,
    onClose: () -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    // The cursor asked for and not answered yet; a failure or the host stopping frees the key for another try.
    var paging by remember { mutableStateOf(PluginDetailPaging()) }
    PluginOnChange(loadingMore) { _, loading -> if (!loading) paging = paging.released() }
    PluginOnChange(settleToken) { _, _ -> paging = paging.released() }
    PluginOnChange(actionError) { _, next -> if (!next.isNullOrEmpty()) paging = paging.released() }
    BottomSheet(onClose = onClose, title = pluginDetailHeading(view, title)) {
        Column(
            Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState())
                .padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = FlareSizes.spacingXl),
        ) {
            when (pluginDetailPhase(loading, error, view)) {
                PluginDetailPhase.Loading -> Box(Modifier.fillMaxWidth().heightIn(min = 120.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(FlareSizes.iconSizeLg).semantics { contentDescription = strings.loading },
                        color = colors.primaryText, strokeWidth = 2.dp,
                    )
                }
                PluginDetailPhase.Error -> Column(
                    Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingXl),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
                ) {
                    Text(error.orEmpty(), color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center,
                        modifier = Modifier.semantics { liveRegion = LiveRegionMode.Assertive })
                    Button(label = strings.retry, variant = FlareButtonVariant.Secondary, disabled = onRetry == null,
                        onClick = { onRetry?.invoke() })
                }
                PluginDetailPhase.Loaded -> view?.let {
                    val actions = pluginDetailActionState(busyActionId, actionError, formErrors, members, settleToken)
                    PluginView(
                        view = it, busyActionId = actions.busyActionId, error = actions.error, embedded = true,
                        resolveUser = resolveUser, members = actions.members, formErrors = actions.formErrors,
                        settleToken = actions.settleToken, viewerId = viewerId, quote = null, onAction = onAction,
                    )
                    PluginLoadMoreKey(paging.key(it.nextCursor, loadingMore), onLoadMore) { cursor ->
                        val (next, asked) = paging.tap(cursor, loadingMore)
                        paging = next
                        asked
                    }
                }
            }
        }
    }
}

/**
 * The full-width "load more" key under a paged view: spinning while the page loads, tappable with a cursor, gone on the
 * last page. [ask] turns a tap into the cursor to request (null while the same page is already asked for).
 */
@Composable
internal fun PluginLoadMoreKey(key: PluginDetailLoadMore, onLoadMore: ((String) -> Unit)?, ask: (String) -> String?) {
    val strings = flareStrings()
    when (key) {
        PluginDetailLoadMore.Hidden -> Unit
        PluginDetailLoadMore.Loading -> Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingMd)) {
            Button(label = strings.myInviteLoadMore, variant = FlareButtonVariant.Text, loading = true, block = true, onClick = {})
        }
        is PluginDetailLoadMore.Ready -> Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingMd)) {
            Button(
                label = strings.myInviteLoadMore, variant = FlareButtonVariant.Text, disabled = onLoadMore == null, block = true,
                onClick = { ask(key.cursor)?.let { onLoadMore?.invoke(it) } },
            )
        }
    }
}

/** The key at the foot of a paged detail. */
internal sealed interface PluginDetailLoadMore {
    data object Hidden : PluginDetailLoadMore
    data object Loading : PluginDetailLoadMore
    data class Ready(val cursor: String) : PluginDetailLoadMore
}

/**
 * No cursor (or a blank one): the last page, no key. Otherwise it spins while the host loads, or while the cursor asked
 * for is still the view's.
 */
internal fun pluginDetailLoadMore(cursor: String?, requested: String?, loadingMore: Boolean): PluginDetailLoadMore = when {
    cursor.isNullOrBlank() -> PluginDetailLoadMore.Hidden
    loadingMore || requested == cursor -> PluginDetailLoadMore.Loading
    else -> PluginDetailLoadMore.Ready(cursor)
}

/** A paged detail's state: the cursor asked for and not answered yet, so the same page is never asked for twice. */
internal data class PluginDetailPaging(val requested: String? = null) {
    fun key(cursor: String?, loadingMore: Boolean): PluginDetailLoadMore = pluginDetailLoadMore(cursor, requested, loadingMore)

    /** A tap on the key: the next state and the cursor to ask for (null while the key is off). */
    fun tap(cursor: String?, loadingMore: Boolean): Pair<PluginDetailPaging, String?> {
        val ready = key(cursor, loadingMore) as? PluginDetailLoadMore.Ready ?: return this to null
        return PluginDetailPaging(ready.cursor) to ready.cursor
    }

    /** The host stopped loading, settled an action or reported a failure: the key may be tried again. */
    fun released(): PluginDetailPaging = PluginDetailPaging()
}

/** What the detail hands its embedded [PluginView] for the actions run from it: the action's error is the view's error. */
internal data class PluginDetailActionState(
    val busyActionId: String?,
    val error: String?,
    val formErrors: List<PluginFormError>,
    val members: List<PluginMember>,
    val settleToken: Int,
)

internal fun pluginDetailActionState(
    busyActionId: String?,
    actionError: String?,
    formErrors: List<PluginFormError>,
    members: List<PluginMember>,
    settleToken: Int,
): PluginDetailActionState = PluginDetailActionState(busyActionId, actionError, formErrors, members, settleToken)
