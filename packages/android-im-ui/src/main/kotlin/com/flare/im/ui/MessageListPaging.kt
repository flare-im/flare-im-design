package com.flare.im.ui

import androidx.compose.foundation.lazy.LazyListLayoutInfo

/*
 * The two ends of the message list and its back-to-latest key (`spec/message-list-paging-vectors.json`, read by the
 * Vue, Flutter and SwiftUI kits too). A window is the run of messages the host hands the list; its older end (above
 * the timeline) and its newer end (below it) follow one rule.
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
