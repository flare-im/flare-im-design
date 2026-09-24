package com.flare.im.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.unit.dp
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.IntOffset
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.lazy.LazyListLayoutInfo
import androidx.compose.runtime.snapshots.Snapshot
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalView
import kotlinx.coroutines.launch
import java.time.ZoneId

/**
 * Long-press opens the message menu only outside multi-select mode (in
 * multi-select the whole row is tap-to-toggle instead) — same as Flutter.
 */
internal fun messageListLongPressEnabled(multiSelectMode: Boolean, hasLongPress: Boolean): Boolean =
    hasLongPress && !multiSelectMode

/** Where a quote tap in [MessageList] goes. */
internal sealed interface MessageLocateTarget {
    /** The quoted message is loaded: scroll to its row. */
    data class Row(val index: Int) : MessageLocateTarget

    /** Not loaded: the host finds it (it may load older messages). */
    data object Host : MessageLocateTarget
}

/**
 * A loaded quoted row is scrolled to without asking the host; an unloaded one is the host's
 * when it locates messages; otherwise the quote locates nothing (null). [quotedId] is the quoted
 * message's core id, and [rowIndexById] is [messageRowIndexByAnyId], which is what makes a row this
 * device sent — keyed by its client id — answer to the core id the quote carries.
 */
internal fun messageLocateTarget(quotedId: String, rowIndexById: Map<String, Int>, hostLocates: Boolean): MessageLocateTarget? =
    rowIndexById[quotedId]?.let { MessageLocateTarget.Row(it) } ?: MessageLocateTarget.Host.takeIf { hostLocates }

/**
 * Every id a row answers to, mapped to the row it is: the row's own [FlareMessageData.id], plus the id the
 * core knows that message by ([FlareMessageData.serverId]) whenever the two differ.
 *
 * A quote carries one id — the quoted message's core id — while a message this device sent is drawn on a row
 * keyed by its client id. Matching only the row id is what makes a quote of your own message read as "that
 * message is gone" while it is on screen. A row's own id always wins: a core id never displaces one.
 *
 * This is the whole matching rule, written once. The tap inside the list ([messageLocateTarget]) and the host
 * outside it ([FlareMessageListState.scrollToMessage]) both read this one map, so they cannot disagree.
 */
internal fun messageRowIndexByAnyId(rows: List<MessageTimelineRow>, messages: List<FlareMessageData>): Map<String, Int> =
    buildMap {
        rows.forEachIndexed { index, row ->
            if (row is MessageTimelineRow.Message) put(row.key, index)
        }
        rows.forEachIndexed { index, row ->
            if (row !is MessageTimelineRow.Message) return@forEachIndexed
            val coreId = messages.getOrNull(row.index)?.serverId
            if (!coreId.isNullOrEmpty() && !containsKey(coreId)) put(coreId, index)
        }
    }

/**
 * Where a located row sits: in the middle of the viewport, which is where the other three kits put it
 * (`scrollIntoView({ block: "center" })`, `ensureVisible(alignment: 0.5)`, `scrollTo(anchor: .center)`).
 * A lazy list is told the offset from the viewport's start, so centring is a negative one: the row's top
 * sits that far below the top edge. A row at least as tall as the viewport starts at the top — there is
 * nothing to centre, and pushing it down would only hide its beginning.
 */
internal fun centeredRowOffset(viewportSize: Int, rowSize: Int): Int =
    if (rowSize <= 0 || viewportSize <= rowSize) 0 else -((viewportSize - rowSize) / 2)

/**
 * How tall the row at a locate target is: its own height when the list is already drawing it, otherwise
 * the average of the rows it is drawing, otherwise nothing. The estimate only aims the first scroll; the
 * row's real height is known once it is laid out, and [scrollToLocatedRow] corrects from there.
 */
internal fun estimatedRowSize(visibleSizes: List<Int>, exact: Int?): Int = when {
    exact != null && exact > 0 -> exact
    visibleSizes.isEmpty() -> 0
    else -> visibleSizes.sum() / visibleSizes.size
}

/**
 * The one scroll a located message gets, whoever asked for it — a tapped quote inside the list or the host
 * through [FlareMessageListState.scrollToMessage]. Animated, and at once when the reader asked for reduced
 * motion; scrolling away from the bottom is what stops the list following the newest message.
 */
internal suspend fun LazyListState.scrollToLocatedRow(index: Int, reducedMotion: Boolean) {
    val visible = layoutInfo.visibleItemsInfo
    val aimed = centeredRowOffset(
        viewportSizeOf(layoutInfo),
        estimatedRowSize(visible.map { it.size }, visible.firstOrNull { it.index == index }?.size),
    )
    if (reducedMotion) scrollToItem(index, aimed) else animateScrollToItem(index, aimed)
    // Now that the row is laid out its height is known: correct silently rather than animate twice.
    val laidOut = layoutInfo.visibleItemsInfo.firstOrNull { it.index == index } ?: return
    val exact = centeredRowOffset(viewportSizeOf(layoutInfo), laidOut.size)
    if (exact != aimed) scrollToItem(index, exact)
}

/** The viewport's own length, without the content padding a lazy list reports around it. */
internal fun viewportSizeOf(info: androidx.compose.foundation.lazy.LazyListLayoutInfo): Int =
    info.viewportEndOffset - info.viewportStartOffset

/** One row of the timeline: a day's date pill, the unread divider, or a message. [contentType] lets the lazy list reuse rows of a kind. */
internal sealed interface MessageTimelineRow {
    val key: String
    val contentType: String

    data class Day(override val key: String, val label: String) : MessageTimelineRow {
        override val contentType get() = "day"
    }

    data class Unread(override val key: String, val count: Int) : MessageTimelineRow {
        override val contentType get() = "unread"
    }

    data class Message(override val key: String, val index: Int, val groupPosition: MessageGroupPosition) : MessageTimelineRow {
        override val contentType get() = "message"
    }
}

/**
 * The rows of a timeline (Vue `timelineRows`). A date pill goes before the first dated message and
 * before each message on another local calendar day than the dated message before it ([dayLabel] names
 * the day); time gaps within a day get none, since every bubble shows its time. The unread divider goes
 * before [unreadFromId], after that message's date pill, and counts the messages from others from there on.
 * A sender run ends at a date pill and at the unread divider. Days are compared as numbers; only the
 * pills are labelled.
 */
internal fun messageTimelineRows(
    messages: List<FlareMessageData>,
    currentUserId: String,
    unreadFromId: String?,
    zone: ZoneId,
    dayLabel: (epochMs: Long) -> String,
): List<MessageTimelineRow> {
    val unreadIndex = unreadFromId?.let { id -> messages.indexOfFirst { it.id == id } } ?: -1
    // Where a date pill goes: before the first dated message and wherever the local day changes.
    val startsDay = BooleanArray(messages.size)
    var previousDay: Long? = null
    messages.forEachIndexed { index, message ->
        if (message.sentAtMs > 0) {
            val day = flareLocalEpochDay(message.sentAtMs, zone)
            startsDay[index] = day != previousDay
            previousDay = day
        }
    }
    fun dividerBefore(index: Int) = index == unreadIndex || (index in 1 until messages.size && startsDay[index])
    val rows = ArrayList<MessageTimelineRow>(messages.size + 2)
    messages.forEachIndexed { index, message ->
        if (startsDay[index]) rows += MessageTimelineRow.Day("day:${message.id}", dayLabel(message.sentAtMs))
        if (index == unreadIndex) {
            val fromOthers = (index until messages.size).count { messages[it].senderId != currentUserId }
            rows += MessageTimelineRow.Unread("unread:${message.id}", fromOthers)
        }
        val position = messageRunAtDividers(messageGroupPosition(messages, index), dividerBefore(index), dividerBefore(index + 1))
        rows += MessageTimelineRow.Message(message.id, index, position)
    }
    return rows
}

/**
 * A divider (date pill or unread divider) ends a sender run (Vue `breakRunAtDividers`): one right
 * before a message opens a new run there; one right after it closes the run.
 */
internal fun messageRunAtDividers(position: MessageGroupPosition, dividerBefore: Boolean, dividerAfter: Boolean): MessageGroupPosition {
    var next = position
    if (dividerBefore) next = when (next) {
        MessageGroupPosition.Middle -> MessageGroupPosition.First
        MessageGroupPosition.Last -> MessageGroupPosition.Single
        else -> next
    }
    if (dividerAfter) next = when (next) {
        MessageGroupPosition.Middle -> MessageGroupPosition.Last
        MessageGroupPosition.First -> MessageGroupPosition.Single
        else -> next
    }
    return next
}

/*
 * The reading position (Vue `MessageList.vue` tail following). The list opens at the newest message, at the
 * bottom, and follows new messages while the reader is at the bottom or when a new message is their own. A
 * reader who scrolled up keeps their place and sees how many messages arrived below. Older messages loading
 * keep the visible message where it is. The list growing or shrinking keeps a reader at the bottom there.
 * Every scroll is instant: nothing animates, so reduced motion needs no exception.
 */

/** How far above the end still counts as "at the bottom" (Vue `BOTTOM_STICKY_PX`). */
internal val MessageListBottomSlack = 80.dp

/**
 * How the loaded messages changed since the last render (Vue `countPrependedItems` / `countAppendedItems`):
 * [prepended] messages came before the first one still loaded, [appended] after the last one still loaded.
 */
internal data class MessageListGrowth(val prepended: Int, val appended: List<FlareMessageData>)

/**
 * The change from the messages rendered before ([previousIds]) to [messages], or null when none is left in
 * common: the first render, another conversation, or a window replaced as a whole. Those open at the newest.
 */
internal fun messageListGrowth(previousIds: Set<String>, messages: List<FlareMessageData>): MessageListGrowth? {
    if (previousIds.isEmpty()) return null
    val first = messages.indexOfFirst { it.id in previousIds }
    if (first < 0) return null
    val last = messages.indexOfLast { it.id in previousIds }
    return MessageListGrowth(prepended = first, appended = messages.subList(last + 1, messages.size).toList())
}

/**
 * Whether messages added at the end take the reader to the newest one (Vue `shouldFollowAppendedBatch`): the
 * reader follows the tail or sits at the bottom, or one of the new messages is the reader's own.
 */
internal fun messageListFollowsAppend(followTail: Boolean, atBottom: Boolean, appended: List<FlareMessageData>, currentUserId: String): Boolean =
    appended.isNotEmpty() && (followTail || atBottom || appended.any { it.senderId == currentUserId })

/** How many loaded messages are newer than [anchorId], the newest message when the reader left the bottom. */
internal fun messageListBelowCount(messages: List<FlareMessageData>, anchorId: String?): Int {
    if (anchorId == null) return 0
    val index = messages.indexOfLast { it.id == anchorId }
    return if (index < 0) 0 else messages.size - 1 - index
}

/** What the reading position reads from one layout of the list. */
internal data class MessageListViewport(
    val firstKey: Any?,
    val firstOffset: Int,
    val lastIndex: Int,
    val lastKey: Any?,
    val lastEnd: Int,
    val lastSize: Int,
    val totalRows: Int,
    val viewportEnd: Int,
    val viewportSize: Int,
    val scrolling: Boolean,
) {
    /** The last row is laid out and ends inside the viewport. */
    val atEnd: Boolean get() = totalRows == 0 || (lastIndex == totalRows - 1 && lastEnd <= viewportEnd)

    /** The last row is laid out and ends within [slackPx] of the viewport's end. */
    fun atBottom(slackPx: Int): Boolean = totalRows == 0 || (lastIndex == totalRows - 1 && lastEnd <= viewportEnd + slackPx)
}

internal fun messageListViewport(info: LazyListLayoutInfo, scrolling: Boolean): MessageListViewport {
    val first = info.visibleItemsInfo.firstOrNull()
    val last = info.visibleItemsInfo.lastOrNull()
    return MessageListViewport(
        firstKey = first?.key,
        firstOffset = first?.offset ?: 0,
        lastIndex = last?.index ?: -1,
        lastKey = last?.key,
        lastEnd = last?.let { it.offset + it.size } ?: 0,
        lastSize = last?.size ?: 0,
        totalRows = info.totalItemsCount,
        viewportEnd = info.viewportEndOffset - info.afterContentPadding,
        viewportSize = info.viewportSize.height,
        scrolling = scrolling,
    )
}

/** What one new layout of the list asks of the reading position. */
internal enum class MessageListTailAction {
    None,
    /** The reader scrolled to the bottom: follow new messages again. */
    Follow,
    /** The reader scrolled away from the bottom: keep the place and count what arrives below. */
    Browse,
    /** The list grew or shrank (a taller last message, the keyboard, a resize) under a reader at the bottom: back to the end. */
    SettleAtEnd,
}

/**
 * The action for the layout [current] after [previous]. A scroll the reader makes (the first row moved while a
 * scroll is in progress) decides between following and browsing; the kit's own jumps move without a scroll in
 * progress and decide nothing. A change of the list's size, its rows or its last row keeps a following reader at
 * the end; the reader letting go of a scroll does not.
 */
internal fun messageListTailAction(previous: MessageListViewport?, current: MessageListViewport, followTail: Boolean, slackPx: Int): MessageListTailAction {
    val moved = previous != null && (previous.firstKey != current.firstKey || previous.firstOffset != current.firstOffset)
    if (moved && current.scrolling) return if (current.atBottom(slackPx)) MessageListTailAction.Follow else MessageListTailAction.Browse
    val resized = previous == null || previous.totalRows != current.totalRows || previous.viewportSize != current.viewportSize ||
        previous.lastKey != current.lastKey || previous.lastSize != current.lastSize
    return if (resized && followTail && !current.atEnd && !current.scrolling) MessageListTailAction.SettleAtEnd else MessageListTailAction.None
}

/**
 * The row to keep in place while older messages load: of the rows laid out before ([visible], key and offset
 * from the viewport's top, in order), the first message row that is still loaded, as its new row index and
 * that offset. Null when none of them is.
 */
internal fun messageListReadingAnchor(visible: List<Pair<Any, Int>>, rowIndexById: Map<String, Int>): Pair<Int, Int>? {
    for ((key, offset) in visible) {
        val index = (key as? String)?.let(rowIndexById::get) ?: continue
        return index to offset
    }
    return null
}

/** The reading position of one open conversation. */
@Stable
internal class MessageListTail {
    /** Follow new messages: the reader is at the bottom, or the conversation just opened. */
    var followTail by mutableStateOf(true)

    /** The newest message when the reader left the bottom; the messages after it are counted below. */
    var anchorId by mutableStateOf<String?>(null)

    /** The messages of the last render and their ids. */
    var rendered: List<FlareMessageData>? = null
    var renderedIds: Set<String> = emptySet()

    /** The reader asked for older messages (the kit's load-older control); the next prepend keeps their place. */
    var olderRequested = false

    /** Pixels to scroll back once the list has [shiftRows] rows: an anchor that sat below the viewport's top. */
    var shift = 0
    var shiftRows = -1

    fun follow() { followTail = true; anchorId = null }

    fun browse(newestId: String?) { followTail = false; if (anchorId == null) anchorId = newestId }
}

/** Scrolls to the very end of [rows] rows: the last row's bottom at the viewport's bottom, even when it is taller than the viewport. */
internal suspend fun LazyListState.scrollToMessageListEnd(rows: Int) {
    if (rows <= 0) return
    scrollToItem(rows - 1)
    val info = layoutInfo
    val last = info.visibleItemsInfo.lastOrNull() ?: return
    val overflow = last.offset + last.size - (info.viewportEndOffset - info.afterContentPadding)
    if (last.index == rows - 1 && overflow > 0) scrollBy(overflow.toFloat())
}

/**
 * The message thread — grouping, media state. Spec: Message/MessageList
 * (`MessageList`). `LazyColumn` is virtualised (O(visible)); order is
 * oldest→newest. The host feeds [messages] from the timeline view.
 *
 * Reading position: the list opens at the newest message, at the bottom (a short conversation sits at the
 * bottom too), also when [conversationId] changes. New messages keep a reader at the bottom there, and take the
 * reader to the newest when one of them is their own; a reader who scrolled up keeps their place and sees
 * [ScrollToLatest] with the number of messages below (tap: the newest). Loading older messages keeps the visible
 * message in place, and a keyboard, a resize or a growing last message keeps a reader at the bottom there. No
 * scroll animates.
 *
 * Multi-select (names shared with Flutter/iOS): [multiSelectMode] + [selectedIds]
 * are host state; [onToggleSelect] receives the message id. While in
 * multi-select mode [onMessageLongPress] is not wired.
 *
 * Quotes: a quote names its original by that message's core id ([FlareReplyTarget.messageId]). Tapping it
 * scrolls a loaded original into view (animated, at once under reduced motion) and calls [onLocateMessage]
 * with that id only when the original is not in [messages]. A row counts as loaded when the quoted id is
 * its [FlareMessageData.id] **or** its [FlareMessageData.serverId], so a message this device sent — drawn
 * on a row keyed by its client id — is recognised without the host translating anything. A quote locates
 * nothing — and is plain text — when neither applies. A host that reads the missing history then asks this
 * list to show it, through the same scroll and the same two-id rule, with
 * [FlareMessageListState.scrollToMessage] on the [state] it passed here.
 *
 * Days: a [DatePill] (today, yesterday, then the locale date) opens the first dated message and
 * each new local calendar day. [unreadFromId] draws the [UnreadDivider] above that message, after
 * its date pill; keep it fixed while the conversation stays open.
 *
 * Media: [onMediaAction] takes every media tap. Without it the list previews images and plays videos
 * full screen and plays voice messages in their bubbles, one at a time; playback stops when the list
 * leaves composition or the screen stops. A file tap goes to [onOpenFile]. [onMediaDownload] is the download key of the
 * image preview; without it the preview has none. A tapped picture opens the conversation's gallery — every picture of
 * [messages] in timeline order — and the key downloads the picture on screen with the message it belongs to.
 *
 * Links: a link in a text message and a link card go to [onOpenLink]; without it the kit opens only a safe
 * web address ([safeExternalUrl]) with the platform opener, and never another scheme.
 */
@Suppress("NAME_SHADOWING")
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MessageList(
    messages: List<FlareMessageData>,
    currentUserId: String,
    conversationKind: FlareConversationKind = FlareConversationKind.Single,
    loading: Boolean = false,
    loadingOlder: Boolean = false,
    mediaDownloadStates: Map<String, FlareMediaDownloadState> = emptyMap(),
    emptyText: String? = null,
    /**
     * Replaces the whole empty state, for a timeline that is empty for a reason only the host knows.
     * [emptyText] stays the shorthand for changing only the line.
     */
    empty: (@Composable () -> Unit)? = null,
    onMessageLongPress: ((FlareMessageData) -> Unit)? = null,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
    onResend: ((FlareMessageData) -> Unit)? = null,
    hasOlder: Boolean = false,
    olderError: String? = null,
    loadOlderText: String? = null,
    onLoadOlder: (() -> Unit)? = null,
    conversationId: String? = null,
    state: FlareMessageListState = rememberFlareMessageListState(),
    multiSelectMode: Boolean = false,
    selectedIds: Set<String> = emptySet(),
    onToggleSelect: ((String) -> Unit)? = null,
    onSwipeReply: ((FlareMessageData) -> Unit)? = null,
    showIncomingAvatar: Boolean = true,
    showSelfAvatar: Boolean = false,
    showGroupSenderName: Boolean = true,
    /** Reaction pill tap (toggle the current user's reaction). */
    onReact: ((FlareMessageData, String) -> Unit)? = null,
    onLocateMessage: ((String) -> Unit)? = null,
    onOpenFile: ((FlareMessageData, FlareFileContent) -> Unit)? = null,
    unreadFromId: String? = null,
    onOpenLink: ((String) -> Unit)? = null,
    /** A tapped poll option (message, option index); without it polls are read-only. */
    onVote: ((FlareMessageData, Int) -> Unit)? = null,
    /** A tapped task checkbox (message, the done state asked for); without it tasks are read-only. */
    onTaskToggle: ((FlareMessageData, Boolean) -> Unit)? = null,
    /** The image preview's download key (the message a picture belongs to, and the picture); without it the preview has none. */
    onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
    /**
     * Host content under the newest message, scrolling with the timeline — the contract's `footer` slot,
     * as on Vue. The typing indicator lives here: it belongs to the conversation, not to the composer, and
     * a reader scrolled up must not be told someone is typing at a row they are not looking at.
     */
    footer: (@Composable () -> Unit)? = null,
) {
    val listState = state.listState
    // The `footer` slot is an item of its own, so every count that means "how many items does the list
    // have" must include it. `LazyListLayoutInfo.totalItemsCount` already does; the two places that count
    // rows by hand did not, and a scroll-to-newest that stops one item short is invisible until a footer
    // exists to stop short of.
    val footerRows = if (footer == null) 0 else 1
    val strings = flareStrings()
    val emptyText = emptyText ?: strings.messageListEmpty
    val loadOlderText = loadOlderText ?: strings.messageListLoadOlder
    val colors = flareColors()
    val reducedMotion = flareReducedMotion()
    val haptics = LocalHapticFeedback.current
    val view = LocalView.current
    val scope = rememberCoroutineScope()
    val locale = LocalConfiguration.current.locales[0]
    val rows = remember(messages, currentUserId, unreadFromId, strings.today, strings.yesterday, locale) {
        val zone = ZoneId.systemDefault()
        val now = System.currentTimeMillis()
        messageTimelineRows(messages, currentUserId, unreadFromId, zone) { epochMs ->
            FlareTimeFormat.timelineDateLabel(epochMs, strings.today, strings.yesterday, locale, now, zone)
        }
    }
    // Both ids of every row, so a quote that names the core id and one that names the row id find the same row.
    val rowIndexById = remember(rows, messages) { messageRowIndexByAnyId(rows, messages) }
    // The host's handle answers `scrollToMessage` from the rows of the composition that just ran, and answers
    // false once this list is gone. Attaching in a side effect keeps it in step with what was actually laid out.
    val handleOwner = remember(state) { Any() }
    // The mark a located row wears (`spec/locate-highlight-vectors.json`): the list owns the clock, and the
    // row it names draws the ring. One row at a time — a second jump restarts the clock on the new row, and
    // the first row's window ends with it rather than clearing the second.
    var locatedRowId by remember(state) { mutableStateOf<String?>(null) }
    val locateClock = remember(state) { Animatable(LOCATE_HIGHLIGHT_DURATION_MS.toFloat()) }
    val markLocated: (String) -> Unit = { rowId ->
        // What a screen reader is told when a jump lands. The ring tells everyone else; a reader who
        // cannot see it gets the same fact in words — which row, and what it says — from the one summary
        // a reply strip would show.
        messages.firstOrNull { it.id == rowId || it.serverId == rowId }?.let { message ->
            view.announceForAccessibility(flareLocatedAnnouncement(message, strings))
        }
        locatedRowId = rowId
        scope.launch {
            locateClock.snapTo(0f)
            locateClock.animateTo(
                LOCATE_HIGHLIGHT_DURATION_MS.toFloat(),
                tween(LOCATE_HIGHLIGHT_DURATION_MS, easing = LinearEasing),
            )
            locatedRowId = null
        }
    }
    val markLocatedRow: (Int) -> Unit = { index ->
        (rows.getOrNull(index) as? MessageTimelineRow.Message)?.let { markLocated(it.key) }
    }
    SideEffect { state.attach(handleOwner, rowIndexById, reducedMotion, markLocatedRow) }
    DisposableEffect(state, handleOwner) { onDispose { state.detach(handleOwner) } }
    val media = rememberFlareMediaHost()
    var requested by remember(conversationId) { mutableStateOf(false) }
    LaunchedEffect(loadingOlder, messages.firstOrNull()?.id, olderError) { if (!loadingOlder) requested = false }

    // Reading position: decide what this change of the messages does before the new rows are measured.
    val tail = remember(conversationId) { MessageListTail() }
    val density = LocalDensity.current
    val slackPx = with(density) { MessageListBottomSlack.roundToPx() }
    SideEffect {
        if (tail.rendered === messages) return@SideEffect
        val previousIds = tail.renderedIds
        val previousNewest = tail.rendered?.lastOrNull()?.id
        tail.rendered = messages
        tail.renderedIds = messages.mapTo(HashSet(messages.size)) { it.id }
        if (messages.isEmpty()) { tail.follow(); tail.olderRequested = false; return@SideEffect }
        val before = Snapshot.withoutReadObservation { listState.layoutInfo }
        val growth = messageListGrowth(previousIds, messages)
        val keepPlace = growth != null && growth.prepended > 0 && (tail.olderRequested || !tail.followTail)
        when {
            growth == null -> { tail.follow(); listState.requestScrollToItem(rows.lastIndex) }
            growth.prepended > 0 && !keepPlace -> listState.requestScrollToItem(rows.lastIndex)
            keepPlace -> {
                tail.browse(previousNewest)
                messageListReadingAnchor(before.visibleItemsInfo.map { it.key to it.offset }, rowIndexById)?.let { (index, offset) ->
                    listState.requestScrollToItem(index, maxOf(0, -offset))
                    if (offset > 0) { tail.shift = offset; tail.shiftRows = rows.size + footerRows }
                }
            }
            messageListFollowsAppend(tail.followTail, messageListViewport(before, scrolling = false).atBottom(slackPx), growth.appended, currentUserId) -> {
                tail.follow()
                listState.requestScrollToItem(rows.lastIndex)
            }
        }
        if (growth != null && growth.prepended > 0) tail.olderRequested = false
    }
    val currentMessages by rememberUpdatedState(messages)
    LaunchedEffect(listState, tail) {
        var previous: MessageListViewport? = null
        snapshotFlow { messageListViewport(listState.layoutInfo, listState.isScrollInProgress) }.collect { viewport ->
            val last = previous
            previous = viewport
            if (tail.shift > 0 && viewport.totalRows == tail.shiftRows) {
                val shift = tail.shift
                tail.shift = 0
                listState.scrollBy(-shift.toFloat())
                return@collect
            }
            when (messageListTailAction(last, viewport, tail.followTail, slackPx)) {
                MessageListTailAction.Follow -> tail.follow()
                MessageListTailAction.Browse -> tail.browse(currentMessages.lastOrNull()?.id)
                MessageListTailAction.SettleAtEnd -> listState.scrollToMessageListEnd(viewport.totalRows)
                MessageListTailAction.None -> Unit
            }
        }
    }
    val atBottom by remember(listState, slackPx) {
        derivedStateOf { messageListViewport(listState.layoutInfo, scrolling = false).atBottom(slackPx) }
    }
    val below = if (atBottom) 0 else messageListBelowCount(messages, tail.anchorId)

    val locateHost = remember(locatedRowId, reducedMotion, locateClock) {
        LocateHighlightHost(locatedRowId, locateClock.asState(), reducedMotion)
    }
    val pictures = remember(messages) { flareImageGalleryItems(messages) }
    // A page's download names the message its picture belongs to, looked up when the key is pressed: the thread may
    // have changed while the preview was open, and a picture whose message is gone downloads nothing.
    val currentDownload by rememberUpdatedState(onMediaDownload)
    val gallery = remember(pictures, onMediaDownload != null) {
        FlareTimelineGallery(
            pictures,
            if (onMediaDownload == null) null else ({ item ->
                val owner = currentMessages.firstOrNull { it.id == item.messageId }
                if (owner != null) currentDownload?.invoke(owner, item.image)
            }),
        )
    }
    CompositionLocalProvider(LocalFlareMediaHost provides media, LocalLocateHighlight provides locateHost, LocalFlareImageGallery provides gallery) {
        Column(Modifier.fillMaxSize().background(colors.bgSecondary)) {
            if (hasOlder || loadingOlder || olderError != null) {
                if (olderError != null) Text(olderError, color = colors.textPrimary, modifier = Modifier.padding(horizontal = FlareSizes.spacingMd))
                if (loadingOlder) Box(Modifier.fillMaxWidth().defaultMinSize(minHeight = 48.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
                else if (hasOlder && onLoadOlder != null) TextButton(
                    onClick = { if (!requested && !loadingOlder) { requested = true; tail.olderRequested = true; onLoadOlder() } }, enabled = !requested,
                    modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp)
                ) { Text(loadOlderText) }
            }
            if (messages.isEmpty()) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    if (loading) CircularProgressIndicator()
                    else if (empty != null) empty()
                    else EmptyState(title = emptyText)
                }
            } else Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
                // Bottom arrangement: a conversation shorter than the screen sits at the bottom, by the composer.
                LazyColumn(
                    Modifier.fillMaxHeight().widthIn(max = FlareSizes.messageTimelineContentMaxWidth),
                    state = listState,
                    verticalArrangement = Arrangement.Bottom,
                ) {
                    val longPress = messageListLongPressEnabled(multiSelectMode, onMessageLongPress != null)
                    items(rows, key = { row -> row.key }, contentType = { row -> row.contentType }) { row ->
                        when (row) {
                            is MessageTimelineRow.Day -> DatePill(row.label)
                            is MessageTimelineRow.Unread -> UnreadDivider(row.count)
                            is MessageTimelineRow.Message -> {
                                val msg = messages[row.index]
                                val groupPosition = row.groupPosition
                                val presentation = messageRowPresentation(
                                    message = msg,
                                    position = groupPosition,
                                    currentUserId = currentUserId,
                                    groupConversation = conversationKind == FlareConversationKind.Group,
                                    showIncomingAvatar = showIncomingAvatar,
                                    showSelfAvatar = showSelfAvatar,
                                    showGroupSenderName = showGroupSenderName,
                                )
                                val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
                                // Notices (system lines, recalled messages) carry no message actions.
                                val actionable = !msg.isSystem && !msg.isRecalled
                                val swipeable = onSwipeReply != null && !multiSelectMode && actionable
                                var dragging by remember(msg.id) { mutableStateOf(false) }
                                var gesture by remember(msg.id) { mutableStateOf(SwipeReplyGesture.None) }
                                val swipe = if (swipeable) {
                                    Modifier.pointerInput(msg.id, rtl) {
                                        var dragX = 0f
                                        var dragY = 0f
                                        fun rest() { dragX = 0f; dragY = 0f; dragging = false; gesture = SwipeReplyGesture.None }
                                        detectHorizontalDragGestures(
                                            onDragStart = { rest() },
                                            onHorizontalDrag = { change, amount ->
                                                change.consume()
                                                dragX += amount
                                                dragY += change.positionChange().y
                                                dragging = true
                                                // The rule works in dp; a pointer reports pixels.
                                                val next = swipeReplyGesture(dragX.toDp().value, dragY.toDp().value, rtl)
                                                // Crossing the arming distance changes what letting go
                                                // means, so it is felt as well as seen.
                                                if (flareHapticCrossed(gesture.armed, next.armed)) haptics.flareHapticTick()
                                                gesture = next
                                            },
                                            onDragCancel = { rest() },
                                            onDragEnd = {
                                                val armed = gesture.armed
                                                rest()
                                                if (armed) onSwipeReply!!(msg)
                                            },
                                        )
                                    }
                                } else Modifier
                                // Following a finger is direct manipulation, not an animation; only the
                                // spring back to rest is animated, and not under Reduce Motion.
                                val travel by animateFloatAsState(
                                    targetValue = gesture.travel,
                                    animationSpec = if (dragging || reducedMotion) snap() else tween(FlareMotion.fast, easing = FlareMotion.fastEasing),
                                    label = "swipe-reply-travel",
                                )
                                val locate = msg.replyTo?.messageId
                                    ?.let { quotedId -> messageLocateTarget(quotedId, rowIndexById, hostLocates = onLocateMessage != null) }
                                    ?.let { target ->
                                        { quotedId: String ->
                                            when (target) {
                                                is MessageLocateTarget.Row -> {
                                                    markLocatedRow(target.index)
                                                    scope.launch { listState.scrollToLocatedRow(target.index, reducedMotion) }
                                                }
                                                MessageLocateTarget.Host -> onLocateMessage?.invoke(quotedId)
                                            }
                                            Unit
                                        }
                                    }
                                Box(swipe.then(if (longPress && actionable) Modifier.combinedClickable(onClick = {}, onLongClick = { onMessageLongPress?.invoke(msg) }) else Modifier)) {
                                    if (swipeable) Box(
                                        Modifier.align(Alignment.CenterStart)
                                            .padding(horizontal = FlareSizes.spacingMd)
                                            // Full strength exactly at the arming distance: the reader sees
                                            // that one more millimetre replies before letting go.
                                            .alpha((travel / SWIPE_REPLY_ARM_DISTANCE).coerceIn(0f, 1f)),
                                    ) { FlareIcon("reply", tint = colors.textTertiary) }
                                    Box(Modifier.offset { IntOffset(with(density) { (if (rtl) -travel else travel).dp.roundToPx() }, 0) }) {
                                        MessageBubble(message = msg, currentUserId = currentUserId, conversationKind = conversationKind,
                                            groupPosition = groupPosition, rowPresentation = presentation,
                                            mediaState = mediaDownloadStates[msg.id], onMediaAction = onMediaAction, onResend = onResend,
                                            multiSelectMode = multiSelectMode, selected = msg.id in selectedIds, onToggleSelect = onToggleSelect,
                                            onReact = onReact, onLocateMessage = locate, onOpenFile = onOpenFile, onOpenLink = onOpenLink,
                                            onVote = onVote, onTaskToggle = onTaskToggle, onMediaDownload = onMediaDownload)
                                    }
                                }
                            }
                        }
                    }
                    // The `footer` slot: its own item so it stays under the newest row and scrolls with it.
                    if (footer != null) item(key = "flare-timeline-footer", contentType = "footer") { footer() }
                }
                if (below > 0) {
                    Box(Modifier.align(Alignment.BottomEnd).padding(FlareSizes.spacingMd)) {
                        ScrollToLatest(count = below, onTap = { tail.follow(); scope.launch { listState.scrollToMessageListEnd(rows.size + footerRows) } })
                    }
                }
            }
        }
    }
    FlareMediaOverlay(media)
}
