package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

/*
 * The group read list's paging, without UI (spec/read-receipt-list-vectors.json): what a host keeps for
 * [ReadReceiptSheet]. The host gives one loader that reads a page of one column; the kit owns the rest — both first
 * pages on opening, a column's next page on `loadMore`, the whole-list state, the per-column busy and failed marks.
 * The kit calls no SDK: the loader maps the SDK's answer (names the user ids, turns "not offered" into null).
 */

/** A column as far as it is read: its people in order, and the next page's cursor while there is one. */
data class FlareReadReceiptMembers(val people: List<Contact> = emptyList(), val nextCursor: String? = null) {
    val hasMore: Boolean get() = nextCursor != null
}

/** The list: its state, both columns, and the column reading (or last failing to read) its next page. */
data class FlareReadReceiptPages(
    val state: FlareReadReceiptState,
    val read: FlareReadReceiptMembers = FlareReadReceiptMembers(),
    val unread: FlareReadReceiptMembers = FlareReadReceiptMembers(),
    val loadingMore: FlareReadReceiptColumn? = null,
    val loadMoreFailed: FlareReadReceiptColumn? = null,
) {
    fun members(column: FlareReadReceiptColumn): FlareReadReceiptMembers =
        if (column == FlareReadReceiptColumn.Read) read else unread

    /** [column]'s next page arrived ([page]; null: the column ends): its people after the column's, kept once. */
    internal fun appended(column: FlareReadReceiptColumn, page: FlareReadReceiptMembers?): FlareReadReceiptPages {
        val shown = members(column)
        val next = if (page == null) {
            FlareReadReceiptMembers(shown.people)
        } else {
            val listed = shown.people.mapTo(HashSet()) { it.id }
            FlareReadReceiptMembers(shown.people + page.people.filter { listed.add(it.id) }, page.nextCursor)
        }
        val settled = copy(loadingMore = loadingMore.takeIf { it != column })
        return if (column == FlareReadReceiptColumn.Read) settled.copy(read = next) else settled.copy(unread = next)
    }

    /** [column]'s next page failed: the sheet offers to read it again. */
    internal fun failed(column: FlareReadReceiptColumn): FlareReadReceiptPages =
        copy(loadingMore = loadingMore.takeIf { it != column }, loadMoreFailed = column)
}

/**
 * One page of `column` after `cursor` (the first page when null), its user ids named as the host names people. Returns
 * null when the message's list is not offered (the SDK's NOT_FOUND, `available: false`); throws on any other failure.
 */
typealias FlareReadReceiptPageLoader = suspend (column: FlareReadReceiptColumn, cursor: String?) -> FlareReadReceiptMembers?

/**
 * The read list of the message a key names, as [rememberFlareReadReceiptListState] keeps it: [pages] is null while no
 * message is open. [loadMore] and [retry] are the sheet's `onLoadMore` and `onRetry`.
 */
@Stable
class FlareReadReceiptListState(private val scope: CoroutineScope, private val page: FlareReadReceiptPageLoader) {
    /** The open list; null while the key is empty. */
    var pages: FlareReadReceiptPages? by mutableStateOf(null)
        private set

    private var key: String? = null
    private var generation = 0
    private val jobs = mutableListOf<Job>()

    /** Columns whose next page is being read: the sheet shows one busy column, but neither asks twice. */
    private val reading = HashSet<FlareReadReceiptColumn>()

    /**
     * Open the list of the message [key] names (empty or null: close it). A new key reads both first pages again and
     * drops whatever the previous one still had in flight; the same key again does nothing.
     */
    fun open(key: String?) {
        val opened = key?.takeIf { it.isNotEmpty() }
        if (opened == this.key) return
        this.key = opened
        if (opened == null) {
            drop()
            pages = null
        } else {
            read()
        }
    }

    /** Read the list again from both first pages (the sheet's retry); nothing while no message is open. */
    fun retry() {
        if (key != null) read()
    }

    /**
     * The next page of [column] (the sheet's loadMore). Nothing happens unless the list is ready, the column has a next
     * page and is not reading it already; the other column pages on its own meanwhile.
     */
    fun loadMore(column: FlareReadReceiptColumn) {
        val current = pages ?: return
        val cursor = current.members(column).nextCursor.takeIf { current.state == FlareReadReceiptState.Ready } ?: return
        if (column in reading) return
        val mine = generation
        reading += column
        jobs.removeAll { it.isCompleted }
        pages = current.copy(loadingMore = column, loadMoreFailed = current.loadMoreFailed.takeIf { it != column })
        jobs += scope.launch {
            val settle: (FlareReadReceiptPages) -> FlareReadReceiptPages = try {
                val next = page(column, cursor)
                ({ latest -> latest.appended(column, next) })
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                ({ latest -> latest.failed(column) })
            }
            if (mine != generation) return@launch
            reading -= column
            pages?.let { pages = settle(it) }
        }
    }

    private fun read() {
        drop()
        val mine = generation
        pages = FlareReadReceiptPages(FlareReadReceiptState.Loading)
        jobs += scope.launch {
            val next = try {
                coroutineScope {
                    // Both at once; either failing fails the pair, either not offered makes the list unavailable.
                    val readPage = async { page(FlareReadReceiptColumn.Read, null) }
                    val unreadPage = async { page(FlareReadReceiptColumn.Unread, null) }
                    val read = readPage.await()
                    val unread = unreadPage.await()
                    if (read != null && unread != null) {
                        FlareReadReceiptPages(FlareReadReceiptState.Ready, read, unread)
                    } else {
                        FlareReadReceiptPages(FlareReadReceiptState.Unavailable)
                    }
                }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                FlareReadReceiptPages(FlareReadReceiptState.Error)
            }
            if (mine == generation) pages = next
        }
    }

    /** Forget what is in flight: its answers land nowhere. */
    private fun drop() {
        generation += 1
        reading.clear()
        jobs.forEach { it.cancel() }
        jobs.clear()
    }
}

/**
 * The read list of the message [key] names (null or empty: no sheet), read with [page]. Hand its [FlareReadReceiptListState.pages]
 * to [ReadReceiptSheet] (the overload taking the state does), with the message's current `receipt.readSummary` as the
 * tab numbers — they follow the read receipts as they arrive, the pages do not carry them.
 */
@Composable
fun rememberFlareReadReceiptListState(key: String?, page: FlareReadReceiptPageLoader): FlareReadReceiptListState {
    val scope = rememberCoroutineScope()
    val latest by rememberUpdatedState(page)
    val state = remember(scope) { FlareReadReceiptListState(scope) { column, cursor -> latest(column, cursor) } }
    LaunchedEffect(state, key) { state.open(key) }
    return state
}
