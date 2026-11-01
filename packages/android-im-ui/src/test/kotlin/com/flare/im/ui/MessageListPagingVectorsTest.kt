package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The shared paging table (`spec/message-list-paging-vectors.json`): what the two ends of the list draw, when the list
 * asks for a page by itself, and what the floating key at the bottom does. The four kits read the same table.
 */
class MessageListPagingVectorsTest {
    private val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>

    private fun end(raw: Any?): MessageListEnd {
        val map = raw as Map<*, *>
        return MessageListEnd(map["has"] as Boolean, map["loading"] as Boolean, map["error"] as String?, map["handled"] as Boolean)
    }

    @Test fun theListAsksWithinTheDistancesTheTableNames() {
        val auto = table["autoRequest"] as Map<*, *>
        assertEquals(MESSAGE_LIST_OLDER_WITHIN_DP, (auto["olderWithin"] as Number).toInt())
        assertEquals(MESSAGE_LIST_NEWER_WITHIN_DP, (auto["newerWithin"] as Number).toInt())
    }

    @Test fun everyEndDrawsWhatTheTableSays() {
        val cases = table["edges"] as List<*>
        assertTrue(cases.size >= 11, "the shared table lost edge cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val expected = case["expected"] as Map<*, *>
            assertEquals(
                MessageListEdge(expected["spinner"] as Boolean, expected["error"] as Boolean, expected["button"] as Boolean),
                messageListEdge(end(case)), case["id"] as String,
            )
        }
    }

    @Test fun everyScrollAsksWhatTheTableSays() {
        val cases = table["requests"] as List<*>
        assertTrue(cases.size >= 21, "the shared table lost request cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val expected = case["expected"] as Map<*, *>
            assertEquals(
                MessageListRequests(expected["older"] as Boolean, expected["newer"] as Boolean),
                messageListRequests(
                    (case["fromTop"] as Number).toFloat(), (case["fromBottom"] as Number).toFloat(),
                    end(case["older"]), end(case["newer"]),
                ),
                case["id"] as String,
            )
        }
    }

    @Test fun theKeyAtTheBottomDoesWhatTheTableSays() {
        val cases = table["jumpToLatest"] as List<*>
        assertTrue(cases.size >= 8, "the shared table lost back-to-latest cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val expected = case["expected"] as Map<*, *>
            val action = when (expected["action"] as String?) {
                "jumpToLatest" -> MessageListLatestAction.JumpToLatest
                "scrollToBottom" -> MessageListLatestAction.ScrollToBottom
                else -> null
            }
            assertEquals(
                MessageListLatestEntry(expected["shown"] as Boolean, (expected["count"] as Number).toInt(), action),
                messageListLatestEntry(case["hasNewer"] as Boolean, case["handled"] as Boolean, (case["belowCount"] as Number).toInt()),
                case["id"] as String,
            )
        }
    }

    @Test fun aWindowIsReplacedWhenTheTableSaysSo() {
        val cases = (table["windows"] as Map<*, *>)["cases"] as List<*>
        assertTrue(cases.size >= 17, "the shared table lost window cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            assertEquals(
                case["expected"] as Boolean,
                messageListWindowReplaced(
                    (case["previous"] as List<*>).map { it as String },
                    (case["next"] as List<*>).map { it as String },
                    jumpRequested = case["jumpRequested"] as Boolean? ?: false,
                    hasNewer = case["hasNewer"] as Boolean? ?: false,
                    previousWindowId = case["previousWindowId"] as String?,
                    windowId = case["windowId"] as String?,
                ),
                case["id"] as String,
            )
        }
    }

    /**
     * The list's reading position through one run of `locateAfterReplace`, on the tail that [MessageList] keeps: the
     * moves the list makes without the reader (the swap leaving the offset at either end, the new window opening at
     * its newest row, the locate landing) ask for nothing in a replaced window; the reader's drags do; and a page that
     * lands under a locate keeps the located row. Rows are the table's height in its viewport; the device side of the
     * same run is `MessageListReplaceInteractionTest`.
     */
    @Test fun aReplacedWindowAndALocateDoWhatTheTableSays() {
        val spec = table["locateAfterReplace"] as Map<*, *>
        val rowHeight = (spec["rowHeight"] as Number).toFloat()
        val viewport = (spec["viewportHeight"] as Number).toFloat()
        val pageRows = (spec["pageRows"] as Number).toInt()
        val cases = spec["cases"] as List<*>
        assertTrue(cases.size >= 8, "the shared table lost locate cases: ${cases.size}")
        fun rows(from: Int, to: Int) = (from..to).map { FlareMessageData(id = "m$it", senderId = "ann", senderName = "Ann", content = FlareTextContent("$it")) }
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val before = case["before"] as Map<*, *>
            val after = case["after"] as Map<*, *>
            val expected = case["expected"] as Map<*, *>
            val located = "m${(case["locate"] as Number).toInt()}"
            val asked = mutableListOf<String>()
            val tail = MessageListTail()
            var messages = rows((before["from"] as Number).toInt(), (before["to"] as Number).toInt())
            var hasNewer = before["hasNewer"] as Boolean
            tail.rendered = messages
            tail.renderedIds = messages.mapTo(HashSet()) { it.id }
            tail.renderedWindowId = before["windowId"] as String?
            var olderAsked = false
            var newerAsked = false
            fun span() = messages.size * rowHeight - viewport
            // One move of the list to `top` (px from the start); it asks the way [MessageList] does, once per end.
            fun moved(top: Float) {
                if (!tail.mayAsk()) return
                val wanted = messageListRequests(
                    top, span() - top, MessageListEnd(true, olderAsked, null, true), MessageListEnd(hasNewer, newerAsked, null, true),
                )
                if (wanted.older) { olderAsked = true; asked += "older" }
                if (wanted.newer) { newerAsked = true; asked += "newer" }
            }
            if (case["readerAskedOlder"] as Boolean) { tail.readerDragged(); moved(0f) }
            val next = rows((after["from"] as Number).toInt(), (after["to"] as Number).toInt())
            val nextHasNewer = after["hasNewer"] as Boolean
            if (messageListWindowReplaced(
                    messages.map { it.id }, next.map { it.id }, tail.jumpRequested, nextHasNewer,
                    tail.renderedWindowId, after["windowId"] as String?,
                )
            ) {
                tail.openReplaced(next, nextHasNewer)
            }
            tail.renderedWindowId = after["windowId"] as String?
            val changed = next.map { it.id } != messages.map { it.id }
            messages = next
            hasNewer = nextHasNewer
            // The swap leaves the offset at either end, then the new window opens at its newest row: the list's moves.
            if (changed) { moved(0f); moved(span()) }
            // The locate lands with the row in the middle, and marks it.
            val index = messages.indexOfFirst { it.id == located }
            val top = (index * rowHeight - (viewport - rowHeight) / 2).coerceIn(0f, span())
            tail.locatedId = located
            moved(top)
            var inView = true
            if (case["pageLands"] as Boolean) {
                val first = messages.first().id.drop(1).toInt()
                val readerRow = messages[(top / rowHeight).toInt()].id
                messages = rows(first - pageRows, first - 1) + messages
                inView = tail.prependAnchorId(readerRow) { key -> messages.any { it.id == key } } == located
                olderAsked = false
            }
            when (case["readerMovesTo"] as String?) {
                "top" -> { tail.readerDragged(); moved(0f); inView = false }
                "bottom" -> { tail.readerDragged(); moved(span()); inView = false }
            }
            assertEquals((expected["requests"] as List<*>).map { it as String }, asked, id)
            assertEquals(expected["locatedInView"] as Boolean, inView, id)
        }
    }

    // A newer page and a message that arrived look alike to the growth rule; only a detached window tells them apart.
    @Test fun rowsAppendedToADetachedWindowAreANewerPage() {
        fun message(id: String) = FlareMessageData(id = id, senderId = "peer", senderName = "peer", content = FlareTextContent(id))
        val window = (1..5).map { message("m$it") }
        val ids = window.map { it.id }.toSet()
        val appended = messageListGrowth(ids, window + message("m6"))
        assertTrue(messageListNewerPage(appended, hadNewer = true))
        assertFalse(messageListNewerPage(appended, hadNewer = false))
        // Rows above are older history, and a window of its own is a new window: neither is a newer page.
        assertFalse(messageListNewerPage(messageListGrowth(ids, listOf(message("m0")) + window), hadNewer = true))
        assertFalse(messageListNewerPage(messageListGrowth(ids, listOf(message("x1"))), hadNewer = true))
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/message-list-paging-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/message-list-paging-vectors.json not found above ${File(".").absolutePath}")
}
