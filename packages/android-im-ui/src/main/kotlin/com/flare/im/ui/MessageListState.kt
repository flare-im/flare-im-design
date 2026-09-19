package com.flare.im.ui

import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MonotonicFrameClock
import androidx.compose.runtime.Stable
import androidx.compose.runtime.remember
import kotlin.coroutines.coroutineContext

/**
 * The host's handle on one [MessageList] (Vue `defineExpose`, Flutter/SwiftUI `FlareMessageListController`).
 *
 * It carries the thread's [listState], so a host that wants raw scrolling still has it, and it adds the one
 * thing a host cannot do from the outside: ask the list to show a message ([scrollToMessage]). Pass the same
 * handle to `MessageList(state = …)`; without one the list makes its own and nothing else changes.
 *
 * ```kotlin
 * val messages = rememberFlareMessageListState()
 * MessageList(messages = rows, currentUserId = me, state = messages, onLocateMessage = { id ->
 *     scope.launch {
 *         // `id` is the quoted message's core id. Hand it back unchanged, page after page, until the
 *         // list says it has that message — the list knows every row by both of its ids.
 *         var shown = messages.scrollToMessage(id)
 *         while (!shown && hasOlder) { readOnePageOfHistory(); shown = messages.scrollToMessage(id) }
 *         if (!shown) toast("原消息已不在这个会话的历史里")
 *     }
 * })
 * ```
 *
 * One handle belongs to one list at a time. Before that list is composed, and after it leaves,
 * [scrollToMessage] answers false instead of failing.
 */
@Stable
class FlareMessageListState(
    /** The thread's scroll state — the one the list's `LazyColumn` runs on. */
    val listState: LazyListState = LazyListState(),
) {
    /** The composed list this handle is answering for, or null while none is. */
    private var owner: Any? = null

    /** Row index by message id, as the list last laid the thread out. */
    private var rowIndexById: Map<String, Int> = emptyMap()

    /** Whether that list read reduced motion, so a located row arrives the same way a tapped quote does. */
    private var reducedMotion = false

    /**
     * How the composed list is told to mark the row a jump landed on. The mark belongs to the list (it is
     * drawn by the row), so the handle only reports which row it just sent the reader to.
     */
    private var onLocated: ((Int) -> Unit)? = null

    /** The composed [MessageList] hands over the rows it is showing, on every composition. */
    internal fun attach(
        owner: Any,
        rowIndexById: Map<String, Int>,
        reducedMotion: Boolean,
        onLocated: ((Int) -> Unit)? = null,
    ) {
        this.owner = owner
        this.rowIndexById = rowIndexById
        this.reducedMotion = reducedMotion
        this.onLocated = onLocated
    }

    /** That list left composition. A list that replaced it already owns the handle and keeps it. */
    internal fun detach(owner: Any) {
        if (this.owner !== owner) return
        this.owner = null
        this.rowIndexById = emptyMap()
        this.onLocated = null
    }

    /**
     * The row [messageId] is on in the thread showing now — null when no list is composed with this
     * handle, or when that message is not among the ones it loaded. [messageId] may be either id a row
     * answers to (its own id or the core's), by the one rule in [messageRowIndexByAnyId]: the list handed
     * over both, so the host asks with whatever id it has.
     */
    internal fun rowIndexOf(messageId: String): Int? = if (owner == null) null else rowIndexById[messageId]

    /**
     * Shows the message [messageId]: the list scrolls to it exactly the way tapping a quote of a loaded
     * message does — same row, animated unless the reader asked for reduced motion — and the reader stops
     * following the newest message, as any other scroll away from the bottom does.
     *
     * [messageId] is either id that message answers to: the [FlareMessageData.id] the list drew its row
     * with, or the [FlareMessageData.serverId] the core knows it by. A host that took an id from a quote
     * ([FlareReplyTarget.messageId], always the core id) passes it on unchanged — there is nothing to
     * convert, and converting is what this rule exists to remove.
     *
     * Returns whether the list had that message. False means nothing moved: the message is not in the
     * loaded thread (the host can read more history and ask again), or no list is composed with this
     * handle. A host can tell "shown" from "not in this conversation" apart by the answer alone.
     */
    suspend fun scrollToMessage(messageId: String): Boolean {
        // A host that has just read history writes the new messages and asks in the same breath. Let the
        // composition those writes scheduled apply first, so the answer is about the rows the list is about
        // to show and not the ones it showed before (Vue's `scrollToMessage` awaits `nextTick` here). A
        // caller outside a frame-driven scope has no composition pending on it: there is nothing to wait for.
        coroutineContext[MonotonicFrameClock]?.withFrameNanos { }
        val index = rowIndexOf(messageId) ?: return false
        // Marked the same way a tapped quote marks it: the reader has to see which row this landed on,
        // whichever entrance asked for the jump.
        onLocated?.invoke(index)
        listState.scrollToLocatedRow(index, reducedMotion)
        return true
    }
}

/**
 * Remembers a [FlareMessageListState] for `MessageList(state = …)`. The scroll position survives
 * configuration changes, the way `rememberLazyListState` does on its own.
 */
@Composable
fun rememberFlareMessageListState(listState: LazyListState = rememberLazyListState()): FlareMessageListState =
    remember(listState) { FlareMessageListState(listState) }
