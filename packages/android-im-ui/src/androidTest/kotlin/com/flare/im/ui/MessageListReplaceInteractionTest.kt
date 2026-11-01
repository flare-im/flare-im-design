package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * A window the host replaces as a whole and a locate that lands in it (`spec/message-list-paging-vectors.json`
 * `locateAfterReplace`), on the device: the list asks for no page by itself before the reader drags, and the located
 * row ends in view even when a page of older rows lands while the list is still scrolling to it. The JVM side of the
 * same table is `MessageListPagingVectorsTest.aReplacedWindowAndALocateDoWhatTheTableSays`.
 */
class MessageListReplaceInteractionTest {
    @get:Rule val compose = createComposeRule()

    private fun rows(from: Int, to: Int) =
        (from..to).map { FlareMessageData(id = "m$it", senderId = if (it % 2 == 0) "lee" else "ann", senderName = "Ann", content = FlareTextContent("第 $it 条")) }

    private var messages by mutableStateOf(rows(961, 1000))
    private var hasNewer by mutableStateOf(false)
    private var windowId by mutableStateOf<String?>("timeline:1")
    private val asked = mutableListOf<String>()
    private val state = FlareMessageListState()
    private lateinit var scope: CoroutineScope

    /** The latest window, the reader at its bottom; both ends of every window have more to read. */
    private fun open() {
        compose.setContent { MaterialTheme {
            scope = rememberCoroutineScope()
            Box(Modifier.fillMaxWidth().height(400.dp)) {
                MessageList(
                    messages = messages, currentUserId = "me", conversationId = "c1", state = state,
                    hasOlder = true, hasNewer = hasNewer, windowId = windowId,
                    onLoadOlder = { asked += "older" }, onLoadNewer = { asked += "newer" }, onJumpToLatest = {},
                )
            }
        } }
        compose.onNodeWithText("第 1000 条").assertExists()
    }

    /** The host hands the list another window and asks it to show [id], the way the locate trip does. */
    private fun locateAround(window: IntRange, id: Int, name: String? = windowId) {
        compose.runOnIdle { messages = rows(window.first, window.last); hasNewer = true; windowId = name }
        compose.waitForIdle()
        val answers = mutableListOf<Boolean>()
        compose.runOnUiThread { scope.launch { answers += state.scrollToMessage("m$id") } }
        compose.waitUntil { answers.isNotEmpty() }
        assertTrue(answers.single())
    }

    @Test fun aWindowOpenedAroundAMessageInAnotherOneAsksForNothingAndShowsIt() {
        open()
        locateAround(921..960, 941)
        compose.waitForIdle()
        compose.onNodeWithText("第 941 条").assertIsDisplayed()
        assertEquals(emptyList<String>(), asked)
    }

    @Test fun aWindowTheHostNamesAnewAsksForNothingEvenWhereItSharesRows() {
        open()
        locateAround(941..980, 945, name = "timeline:2")
        compose.waitForIdle()
        compose.onNodeWithText("第 945 条").assertIsDisplayed()
        assertEquals(emptyList<String>(), asked)
    }

    @Test fun aPageThatLandsWhileTheListScrollsToTheLocatedRowKeepsItInView() {
        open()
        compose.mainClock.autoAdvance = false
        compose.runOnIdle { messages = rows(921, 960); hasNewer = true }
        compose.mainClock.advanceTimeBy(100)
        compose.runOnUiThread { scope.launch { state.scrollToMessage("m941") } }
        // Two frames into the scroll a page of older rows lands.
        compose.mainClock.advanceTimeBy(32)
        compose.runOnIdle { messages = rows(881, 920) + messages }
        compose.mainClock.advanceTimeBy(1_000)
        compose.mainClock.autoAdvance = true
        compose.waitForIdle()
        compose.onNodeWithText("第 941 条").assertIsDisplayed()
        assertEquals(emptyList<String>(), asked)
    }
}
