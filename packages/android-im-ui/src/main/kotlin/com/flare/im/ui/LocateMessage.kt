package com.flare.im.ui

/** How a tapped quote's trip ended. */
enum class FlareLocateOutcome {
    /** The list is showing the message. */
    Shown,

    /**
     * The history was read to its end (or to the budget) without finding it. This is the only answer the
     * host says out loud, and it chooses the words: a page that failed and a message that is genuinely gone
     * read differently, and only the host knows which happened.
     */
    NotInHistory,

    /** The reader left the conversation while the trip was running. Nothing is said. */
    Cancelled,
}

/** Older pages one locate may read before it gives up. */
const val FLARE_LOCATE_MAX_PAGES = 24

/**
 * How many more times the list is asked after the history is spent. The rows of the last page read may not
 * be drawn yet, and a list answers for the pass it last drew.
 */
const val FLARE_LOCATE_SETTLE_ATTEMPTS = 6

/**
 * The trip a tapped quote takes when the message it names is not loaded yet: ask the list, read a page of
 * older history, ask again, and stop with one of three answers.
 *
 * The rule is shared with the Vue, Flutter and SwiftUI kits and tested against
 * `spec/locate-orchestration-vectors.json`. It lives in the kit rather than in each app because all four
 * were writing it, and writing it differently: the page budgets were 24, 20, 5 and 24, only one of them
 * waited for the list to draw the page it had just read, and only one stopped when the reader left.
 *
 * @param showInList asks the list to show the message and answers whether it had it — on this kit that is
 *   [FlareMessageListState.scrollToMessage].
 * @param readOlder reads one older page and answers whether it brought anything in; a page that failed
 *   answers false and ends the search.
 * @param settle lets the list draw one pass.
 * @param isCurrent is false once the reader has left this conversation.
 */
suspend fun flareLocateMessage(
    showInList: suspend () -> Boolean,
    hasOlder: () -> Boolean,
    readOlder: suspend () -> Boolean,
    settle: suspend () -> Unit,
    isCurrent: () -> Boolean,
): FlareLocateOutcome {
    var advanced = true
    var pages = 0
    while (true) {
        if (!isCurrent()) return FlareLocateOutcome.Cancelled
        if (showInList()) return FlareLocateOutcome.Shown
        if (!(hasOlder() && advanced && pages < FLARE_LOCATE_MAX_PAGES)) break
        advanced = readOlder()
        pages += 1
        settle()
    }
    repeat(FLARE_LOCATE_SETTLE_ATTEMPTS) {
        if (!isCurrent()) return FlareLocateOutcome.Cancelled
        settle()
        if (showInList()) return FlareLocateOutcome.Shown
    }
    return FlareLocateOutcome.NotInHistory
}

/** The message a locate opens a window around: its id (server or client), and its seq when the caller has it. */
data class FlareLocateAnchor(val messageId: String, val seq: Long? = null)

/**
 * The same trip when the host can open a window around the message (a timeline view opened with an anchor) instead
 * of paging back to it: ask the list, open once around the anchor, then let the list draw and ask for the anchor key
 * up to [FLARE_LOCATE_SETTLE_ATTEMPTS] times (`spec/locate-orchestration-vectors.json` `around`). The list scrolls to
 * the row and marks it itself.
 *
 * @param showInList asks the list to show the message with this id and answers whether it had it — on this kit that
 *   is [FlareMessageListState.scrollToMessage].
 * @param openAround opens the timeline around the anchor and answers the anchor key — the row key the list will draw
 *   the message with — or null (or a blank key) when the message is not in the history. A failed open answers null.
 * @param settle lets the list draw one pass.
 * @param isCurrent is false once the reader has left this conversation.
 */
suspend fun flareLocateMessageAround(
    anchor: FlareLocateAnchor,
    showInList: suspend (String) -> Boolean,
    openAround: suspend (FlareLocateAnchor) -> String?,
    settle: suspend () -> Unit,
    isCurrent: () -> Boolean,
): FlareLocateOutcome {
    if (!isCurrent()) return FlareLocateOutcome.Cancelled
    if (showInList(anchor.messageId)) return FlareLocateOutcome.Shown
    if (!isCurrent()) return FlareLocateOutcome.Cancelled
    val key = openAround(anchor)?.trim().orEmpty()
    if (!isCurrent()) return FlareLocateOutcome.Cancelled
    if (key.isEmpty()) return FlareLocateOutcome.NotInHistory
    repeat(FLARE_LOCATE_SETTLE_ATTEMPTS) {
        if (!isCurrent()) return FlareLocateOutcome.Cancelled
        settle()
        if (showInList(key)) return FlareLocateOutcome.Shown
    }
    return FlareLocateOutcome.NotInHistory
}
