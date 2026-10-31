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
