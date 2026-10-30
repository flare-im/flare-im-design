package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** The whole read list: ready, being read, failed (retry), or not available for this message (no retry). */
enum class FlareReadReceiptState { Ready, Loading, Error, Unavailable }

/** A column of the read list. */
enum class FlareReadReceiptColumn { Read, Unread }

/** What the sheet draws (spec/read-receipt-vectors.json): the tabs and their numbers, the body, the rows, the list's tail. */
data class FlareReadReceiptPresentation(
    /** The two tabs in order with the number each shows (null: no number); null when no tabs are drawn. */
    val tabs: List<Pair<FlareReadReceiptColumn, Int?>>?,
    val body: Body,
    val rows: Int,
    val tail: Tail,
    /** The column whose empty notice shows ([Body.Empty]). */
    val empty: FlareReadReceiptColumn? = null,
) {
    enum class Body { Spinner, Error, Unavailable, List, Empty }
    enum class Tail { None, Busy, LoadMore, Retry }
}

/**
 * The sheet for a state (spec/read-receipt-vectors.json): tab numbers from the summary counts only (never the loaded
 * rows), the body for the whole list's state, and the active column's tail — busy while it loads more, a retry key after
 * a failed page, the load-more key while it has more.
 */
fun flareReadReceiptPresentation(
    state: FlareReadReceiptState,
    readers: Int,
    unread: Int,
    readCount: Int?,
    unreadCount: Int?,
    readHasMore: Boolean,
    unreadHasMore: Boolean,
    loadingMore: FlareReadReceiptColumn?,
    loadMoreFailed: FlareReadReceiptColumn?,
    tab: FlareReadReceiptColumn,
): FlareReadReceiptPresentation {
    val tabs = listOf(
        FlareReadReceiptColumn.Read to readCount?.takeIf { it >= 0 },
        FlareReadReceiptColumn.Unread to unreadCount?.takeIf { it >= 0 },
    )
    when (state) {
        FlareReadReceiptState.Error -> return FlareReadReceiptPresentation(null, Body.Error, 0, Tail.None)
        FlareReadReceiptState.Unavailable -> return FlareReadReceiptPresentation(null, Body.Unavailable, 0, Tail.None)
        FlareReadReceiptState.Loading -> return FlareReadReceiptPresentation(tabs, Body.Spinner, 0, Tail.None)
        FlareReadReceiptState.Ready -> Unit
    }
    val rows = maxOf(0, if (tab == FlareReadReceiptColumn.Read) readers else unread)
    val hasMore = if (tab == FlareReadReceiptColumn.Read) readHasMore else unreadHasMore
    val end = when {
        loadingMore == tab -> Tail.Busy
        loadMoreFailed == tab -> Tail.Retry
        hasMore -> Tail.LoadMore
        else -> Tail.None
    }
    if (rows == 0 && end == Tail.None) return FlareReadReceiptPresentation(tabs, Body.Empty, 0, end, empty = tab)
    return FlareReadReceiptPresentation(tabs, Body.List, rows, end)
}

private typealias Body = FlareReadReceiptPresentation.Body
private typealias Tail = FlareReadReceiptPresentation.Tail

/** The popover width the sheet takes outside a kit sheet (it shrinks with a narrower container). */
private val ReadReceiptPopoverWidth = 320.dp

/**
 * The read list of one of the viewer's group messages: read / unread tabs whose numbers are the summary counts the host
 * passes ([readCount], [unreadCount], from `receipt.readSummary`; without them a tab has no number — never the length of
 * the rows loaded so far), each column paging on its own ([onLoadMore] with the column; [loadingMore] and
 * [loadMoreFailed] name the column whose next page is being read or failed), and a whole-list [state]: loading (a
 * spinner), error (a notice with a retry key that calls [onRetry]) or unavailable (a notice, no retry — for NOT_FOUND or
 * `available:false`).
 *
 * It takes its container's width. Outside a kit overlay it draws its own card, at most 320 wide, its rows scrolling
 * within 320. In a kit [BottomSheet] it draws no card, fills the sheet and declares its own header
 * ([FlareSheetOwnHeader]): open it with the sheet's `fill` so the sheet's title is the accessible name only and the rows
 * take the remaining height. Spec: Message/ReadReceiptSheet, spec/read-receipt-vectors.json.
 */
@Composable
fun ReadReceiptSheet(
    readers: List<Contact>,
    unread: List<Contact>,
    dismissible: Boolean = false,
    onSelect: ((String) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
    readCount: Int? = null,
    unreadCount: Int? = null,
    state: FlareReadReceiptState = FlareReadReceiptState.Ready,
    readHasMore: Boolean = false,
    unreadHasMore: Boolean = false,
    loadingMore: FlareReadReceiptColumn? = null,
    loadMoreFailed: FlareReadReceiptColumn? = null,
    initialTab: FlareReadReceiptColumn = FlareReadReceiptColumn.Read,
    onLoadMore: ((FlareReadReceiptColumn) -> Unit)? = null,
    onRetry: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val inSheet = LocalFlareSheetHeader.current != null
    val fills = flareSheetFills()
    FlareSheetOwnHeader()
    var tab by rememberSaveable { mutableStateOf(initialTab) }
    val view = flareReadReceiptPresentation(
        state, readers.size, unread.size, readCount, unreadCount, readHasMore, unreadHasMore, loadingMore, loadMoreFailed, tab,
    )
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    val shell = if (inSheet) modifier.fillMaxWidth()
    else modifier.widthIn(max = ReadReceiptPopoverWidth).fillMaxWidth()
        .shadow(16.dp, shape, clip = false)
        .clip(shape)
        .background(colors.bgPrimary)
        .border(1.dp, colors.borderPrimary, shape)
    Column(shell) {
        Row(
            Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
                .padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingXs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.DoneAll, contentDescription = null, tint = colors.primaryText, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Text(
                strings.readReceipt,
                color = colors.textPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeXl.value.sp,
                modifier = Modifier.weight(1f).semantics { heading() },
            )
            if (dismissible) {
                Box(
                    Modifier.size(FlareSizes.touchTarget)
                        .then(if (onClose != null) Modifier.clickable(role = Role.Button, onClickLabel = strings.close) { onClose() } else Modifier)
                        .semantics { contentDescription = strings.close },
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Outlined.Close, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(18.dp))
                }
            }
        }
        view.tabs?.let { tabs ->
            Row(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg)) {
                for ((column, count) in tabs) {
                    val label = when (column) {
                        FlareReadReceiptColumn.Read -> count?.let(strings.readTab) ?: strings.readReceiptRead
                        FlareReadReceiptColumn.Unread -> count?.let(strings.unreadTab) ?: strings.readReceiptUnread
                    }
                    receiptTab(colors, label, tab == column) { tab = column }
                }
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        }
        val body = if (inSheet && fills) Modifier.fillMaxWidth().weight(1f) else Modifier.fillMaxWidth().heightIn(max = ReadReceiptPopoverWidth)
        ReadReceiptBody(view, if (tab == FlareReadReceiptColumn.Read) readers else unread, tab, onSelect, onLoadMore, onRetry, body)
    }
}

@Composable
private fun ColumnScope.ReadReceiptBody(
    view: FlareReadReceiptPresentation,
    list: List<Contact>,
    tab: FlareReadReceiptColumn,
    onSelect: ((String) -> Unit)?,
    onLoadMore: ((FlareReadReceiptColumn) -> Unit)?,
    onRetry: (() -> Unit)?,
    modifier: Modifier,
) {
    val colors = flareColors()
    val strings = flareStrings()
    when (view.body) {
        FlareReadReceiptPresentation.Body.Spinner -> Box(modifier.padding(vertical = 28.dp), contentAlignment = Alignment.Center) {
            EmptyState(title = strings.loading, loading = true)
        }
        FlareReadReceiptPresentation.Body.Error -> Box(modifier, contentAlignment = Alignment.Center) {
            EmptyState(
                title = strings.readReceiptLoadFailed,
                icon = "error",
                actionText = strings.retry,
                onAction = onRetry,
                tone = FlareEmptyStateTone.Error,
            )
        }
        FlareReadReceiptPresentation.Body.Unavailable -> Box(modifier, contentAlignment = Alignment.Center) {
            EmptyState(title = strings.readReceiptUnavailable, icon = "info")
        }
        FlareReadReceiptPresentation.Body.Empty -> Text(
            if (view.empty == FlareReadReceiptColumn.Unread) strings.everyoneHasRead else strings.noReadersYet,
            color = colors.textTertiary,
            fontSize = FlareSizes.fontSizeSm.value.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(vertical = 28.dp),
        )
        FlareReadReceiptPresentation.Body.List -> LazyColumn(modifier) {
            items(list, key = { it.id }) { c ->
                Row(
                    Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
                        .then(if (onSelect != null) Modifier.clickable(role = Role.Button) { onSelect(c.id) } else Modifier)
                        .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Avatar(userId = c.id, displayName = c.name, size = 36.dp, presence = c.presence)
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Text(
                        c.name,
                        color = colors.textPrimary,
                        fontSize = FlareSizes.fontSizeLg.value.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            if (view.tail != FlareReadReceiptPresentation.Tail.None) item(key = "tail") {
                ReadReceiptTail(view.tail, onLoadMore?.let { load -> { load(tab) } }, colors, strings)
            }
        }
    }
}

/** The last row of a column: a spinner while the next page loads, else the load-more or the load-more-failed key. */
@Composable
private fun ReadReceiptTail(tail: FlareReadReceiptPresentation.Tail, onPress: (() -> Unit)?, colors: FlareColors, strings: FlareStrings) {
    val row = Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
    if (tail == FlareReadReceiptPresentation.Tail.Busy) {
        Row(
            row.semantics { liveRegion = LiveRegionMode.Polite; contentDescription = strings.loading },
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp, color = colors.primaryText)
        }
        return
    }
    val failed = tail == FlareReadReceiptPresentation.Tail.Retry
    val label = if (failed) strings.readReceiptLoadMoreFailed else strings.readReceiptLoadMore
    Box(
        row.then(if (onPress != null) Modifier.clickable(role = Role.Button) { onPress() } else Modifier),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = if (failed) colors.errorText else colors.primaryText, fontSize = FlareSizes.fontSizeSm.value.sp)
    }
}

@Composable
private fun RowScope.receiptTab(colors: FlareColors, label: String, active: Boolean, onClick: () -> Unit) {
    Column(
        Modifier.weight(1f).heightIn(min = FlareSizes.touchTarget)
            .clickable(role = Role.Tab) { onClick() }
            .semantics { selected = active }
            .padding(top = FlareSizes.spacingSm),
        verticalArrangement = Arrangement.SpaceBetween,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            label,
            color = if (active) colors.primaryText else colors.textSecondary,
            fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
            fontSize = FlareSizes.fontSizeMd.value.sp,
        )
        Box(Modifier.fillMaxWidth().height(2.dp).background(if (active) colors.primary else Color.Transparent))
    }
}

/**
 * [ReadReceiptSheet] for a list [rememberFlareReadReceiptListState] keeps: its columns, state and paging come from
 * [list]; [readCount] / [unreadCount] are the message's summary counts. The host shows it while a message is open; until
 * the holder has started reading that message's list (the frame the key arrives in) it reads as loading.
 */
@Composable
fun ReadReceiptSheet(
    list: FlareReadReceiptListState,
    readCount: Int? = null,
    unreadCount: Int? = null,
    dismissible: Boolean = false,
    initialTab: FlareReadReceiptColumn = FlareReadReceiptColumn.Read,
    onSelect: ((String) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val pages = list.pages ?: FlareReadReceiptPages(FlareReadReceiptState.Loading)
    ReadReceiptSheet(
        readers = pages.read.people,
        unread = pages.unread.people,
        dismissible = dismissible,
        onSelect = onSelect,
        onClose = onClose,
        readCount = readCount,
        unreadCount = unreadCount,
        state = pages.state,
        readHasMore = pages.read.hasMore,
        unreadHasMore = pages.unread.hasMore,
        loadingMore = pages.loadingMore,
        loadMoreFailed = pages.loadMoreFailed,
        initialTab = initialTab,
        onLoadMore = list::loadMore,
        onRetry = list::retry,
        modifier = modifier,
    )
}
