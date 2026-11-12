package com.flare.im.ui

import androidx.compose.foundation.lazy.LazyListLayoutInfo

/*
 * The two ends of the message list and its back-to-latest key (`spec/message-list-paging-vectors.json`, read by the
 * Vue, Flutter and SwiftUI kits too). A window is the run of messages the host hands the list; its older end (above
 * the timeline) and its newer end (below it) follow one rule. Whether the reader is at the bottom of the window, as the
 * list tells the host, is `atBottom`.
 */

/** How close to an edge the reader must scroll before the list asks for the next page there, in dp. */
internal const val MESSAGE_LIST_OLDER_WITHIN_DP = 160
internal const val MESSAGE_LIST_NEWER_WITHIN_DP = 160

/** One end of the window, as the host describes it: more past it, a page loading, the last page's error, and whether the host takes the intent. */
internal data class MessageListEnd(val has: Boolean, val loading: Boolean, val error: String?, val handled: Boolean) {
    /** Null, empty or blank is no error. */
    val failed: Boolean get() = !error.isNullOrBlank()
}

/** What one end draws. */
internal data class MessageListEdge(val spinner: Boolean, val error: Boolean, val button: Boolean) {
    val visible: Boolean get() = spinner || error || button
}

/**
 * While loading, a spinner and nothing else (the last error is not repeated while it is being retried); otherwise the
 * error when there is one, and the load or retry button while there is more and the host takes the intent.
 */
internal fun messageListEdge(end: MessageListEnd): MessageListEdge =
    if (end.loading) MessageListEdge(spinner = true, error = false, button = false)
    else MessageListEdge(spinner = false, error = end.failed, button = end.has && end.handled)

/** The pages the list asks for by itself. */
internal data class MessageListRequests(val older: Boolean, val newer: Boolean)

/**
 * The pages the list asks for as the reader scrolls: an end asks within its distance of its edge (inclusive), while
 * there is more, nothing is loading, the last page did not fail (after a failure only the retry button asks) and the
 * host takes the intent. [fromTopDp] is how far the first row's top is above the viewport's top, [fromBottomDp] how far
 * the end of the timeline is below the viewport's bottom.
 */
internal fun messageListRequests(fromTopDp: Float, fromBottomDp: Float, older: MessageListEnd, newer: MessageListEnd): MessageListRequests {
    fun asks(end: MessageListEnd, distance: Float, within: Int) =
        end.handled && end.has && !end.loading && !end.failed && distance <= within
    return MessageListRequests(
        older = asks(older, fromTopDp, MESSAGE_LIST_OLDER_WITHIN_DP),
        newer = asks(newer, fromBottomDp, MESSAGE_LIST_NEWER_WITHIN_DP),
    )
}

/**
 * Whether a window overflows the viewport by no more than the paging distance (`fill`): `fromTop + fromBottom` is that
 * overflow wherever the reader is. Such a window cannot be scrolled far enough to move either end into or out of reach
 * (one that fits does not scroll at all), so the list asks for its pages by itself until it overflows, or there is
 * nothing more. A missing report (null) decides nothing.
 */
internal fun messageListFillsViewport(fromTopDp: Float?, fromBottomDp: Float?): Boolean {
    if (fromTopDp == null || fromBottomDp == null) return false
    return fromTopDp + fromBottomDp <= minOf(MESSAGE_LIST_OLDER_WITHIN_DP, MESSAGE_LIST_NEWER_WITHIN_DP)
}

/**
 * What lets each end of the list ask again, as last applied: an end that asked asks nothing more until its page
 * settles, its first or last row changes, or its error does. Each call answers whether its inputs changed since the
 * last one.
 */
internal class MessageListRequestSettle {
    private var older: Triple<Boolean, String?, String?>? = null
    private var newer: Triple<Boolean, String?, String?>? = null

    fun older(loading: Boolean, firstId: String?, error: String?): Boolean {
        val now = Triple(loading, firstId, error)
        return (now != older).also { older = now }
    }

    fun newer(loading: Boolean, lastId: String?, error: String?): Boolean {
        val now = Triple(loading, lastId, error)
        return (now != newer).also { newer = now }
    }
}

/** What the floating key at the bottom does. */
internal enum class MessageListLatestAction { JumpToLatest, ScrollToBottom }

/** The floating key at the bottom: whether it shows, the count it carries, and what a tap does. */
internal data class MessageListLatestEntry(val shown: Boolean, val count: Int, val action: MessageListLatestAction?)

/**
 * A window detached from the latest ([hasNewer]) offers the way back to the latest messages, without a count — rows
 * below a detached reader are history read in, not news — when the host takes the jump. Otherwise it is the
 * new-messages key: shown while messages arrived below a reader who scrolled up, counting them, and it scrolls to the
 * bottom.
 */
internal fun messageListLatestEntry(hasNewer: Boolean, handled: Boolean, belowCount: Int): MessageListLatestEntry = when {
    hasNewer && handled -> MessageListLatestEntry(true, 0, MessageListLatestAction.JumpToLatest)
    hasNewer -> MessageListLatestEntry(false, 0, null)
    belowCount > 0 -> MessageListLatestEntry(true, belowCount, MessageListLatestAction.ScrollToBottom)
    else -> MessageListLatestEntry(false, 0, null)
}

/**
 * How far the first row's top is above the viewport's top, and how far the end of the list is below the viewport's
 * bottom, in pixels. A row that is not laid out is estimated at the average height of the rows that are; the estimate
 * only decides whether an edge is near.
 */
internal fun messageListEdgeDistances(info: LazyListLayoutInfo): Pair<Float, Float> {
    val visible = info.visibleItemsInfo
    if (visible.isEmpty()) return Float.POSITIVE_INFINITY to Float.POSITIVE_INFINITY
    val average = visible.sumOf { it.size }.toFloat() / visible.size
    val first = visible.first()
    val last = visible.last()
    val fromTop = first.index * average + maxOf(0, info.viewportStartOffset - first.offset)
    val end = info.viewportEndOffset - info.afterContentPadding
    val fromBottom = (info.totalItemsCount - 1 - last.index) * average + maxOf(0, last.offset + last.size - end)
    return fromTop to fromBottom
}

/**
 * Rows appended to a window that was detached are a newer page read in, not messages that arrived: the core appends
 * nothing to a detached window, and a message sent from one comes back as a new latest window.
 */
internal fun messageListNewerPage(growth: MessageListGrowth?, hadNewer: Boolean): Boolean =
    hadNewer && growth != null && growth.prepended == 0 && growth.appended.isNotEmpty()

/**
 * Whether the host replaced the window as a whole rather than grew or edited the one the reader is in
 * (`spec/message-list-paging-vectors.json` `windows`). [previous] and [next] are row keys in timeline order. Both must
 * have rows, and then any of: the host's name for the window ([previousWindowId] to [windowId], the core timeline
 * view's `viewId`; null or empty is none) changed from one name to another; the latest window the reader asked for
 * arrived ([jumpRequested], attached: not [hasNewer]); no row of the new window was in the old one.
 */
internal fun messageListWindowReplaced(
    previous: List<String>,
    next: List<String>,
    jumpRequested: Boolean = false,
    hasNewer: Boolean = false,
    previousWindowId: String? = null,
    windowId: String? = null,
): Boolean {
    if (previous.isEmpty() || next.isEmpty()) return false
    val before = previousWindowId.orEmpty()
    val after = windowId.orEmpty()
    if (before.isNotEmpty() && after.isNotEmpty() && before != after) return true
    if (jumpRequested && !hasNewer) return true
    val kept = previous.toHashSet()
    return next.none(kept::contains)
}

/** How far the end of the timeline may be below the viewport's bottom with the reader still at the bottom, in dp. */
internal const val MESSAGE_LIST_BOTTOM_WITHIN_DP = 80

/** The reader is at the bottom: the end of the timeline is at most [MESSAGE_LIST_BOTTOM_WITHIN_DP] below the viewport. */
internal fun messageListAtBottom(fromBottomDp: Float): Boolean = fromBottomDp <= MESSAGE_LIST_BOTTOM_WITHIN_DP

/**
 * What the list tells the host about the reader being at the bottom of the window (`atBottom` in
 * `spec/message-list-paging-vectors.json`). Each method is one step and answers what to tell the host after it: true,
 * false, or null for nothing. The list tells the host only when the answer changes, and once after its first layout. A
 * window replaced without the reader asking for it and a locate hold the answer at not at the bottom until the reader
 * moves the list, the list goes to its newest row for the reader, the latest window the reader asked for arrives or the
 * window empties; ending a hold answers from the last layout. One report per conversation: another one starts over.
 */
internal class MessageListBottomReport {
    /** The answer last told to the host; null before the first one. */
    var reported: Boolean? = null
        private set
    private var held = false
    private var last: Float? = null

    /** A layout or a scroll the list measured: [fromBottomDp] is how far the end of the timeline is below the viewport. */
    fun layout(fromBottomDp: Float): Boolean? {
        last = fromBottomDp
        return tell(!held && messageListAtBottom(fromBottomDp))
    }

    /** The host handed a window that replaces the one shown, without the reader asking for it. */
    fun replaced(): Boolean? = hold()

    /** The latest window the reader asked for (the back-to-latest key) arrived. */
    fun jumpedToLatest(): Boolean? = release()

    /** A locate took the reading position. */
    fun located(): Boolean? = hold()

    /** The reader moved the list themselves. */
    fun readerMoved(): Boolean? = release()

    /** The list went to its newest row for the reader: the new-messages key, or a message of the reader's own. */
    fun wentToLatest(): Boolean? = release()

    /** The window lost all its rows: an empty list is at its bottom. */
    fun emptied(): Boolean? {
        held = false
        return layout(0f)
    }

    private fun hold(): Boolean? {
        held = true
        return if (reported == true) tell(false) else null
    }

    private fun release(): Boolean? {
        held = false
        return last?.let(::layout)
    }

    private fun tell(atBottom: Boolean): Boolean? {
        if (reported == atBottom) return null
        reported = atBottom
        return atBottom
    }
}
