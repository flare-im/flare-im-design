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
import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeDown
import androidx.compose.ui.test.swipeUp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * Whether the reader is at the bottom (`spec/message-list-paging-vectors.json` `atBottom`), as the list tells the host
 * through `onAtBottomChange`, on the device: once after the first layout, false when the reader leaves the bottom and
 * true when they come back, nothing while messages arrive under a reader there, and not at the bottom of a window
 * replaced without the reader asking, or of a locate, until the reader drags the list. The JVM side of the same table is
 * `MessageListPagingVectorsTest.theReaderIsAtTheBottomWhereTheTableSays`.
 */
class MessageListAtBottomInteractionTest {
    @get:Rule val compose = createComposeRule()

    private fun rows(from: Int, to: Int) =
        (from..to).map { FlareMessageData(id = "m$it", senderId = if (it % 2 == 0) "lee" else "ann", senderName = "Ann", content = FlareTextContent("第 $it 条")) }

    private var messages by mutableStateOf(rows(961, 1000))
    private var windowId by mutableStateOf<String?>("timeline:1")
    private val told = mutableListOf<Boolean>()
    private val state = FlareMessageListState()
    private lateinit var scope: CoroutineScope

    private fun open() {
        compose.setContent { MaterialTheme {
            scope = rememberCoroutineScope()
            Box(Modifier.fillMaxWidth().height(400.dp)) {
                MessageList(
                    messages = messages, currentUserId = "me", conversationId = "c1", state = state, windowId = windowId,
                    onAtBottomChange = { told += it },
                )
            }
        } }
        compose.onNodeWithText("第 1000 条").assertExists()
        compose.waitForIdle()
    }

    private fun scrollTo(index: Int) {
        compose.runOnUiThread { scope.launch { state.listState.scrollToItem(index) } }
        compose.waitForIdle()
    }

    private fun told(vararg expected: Boolean) = compose.runOnIdle { assertEquals(expected.toList(), told.toList()) }

    @Test fun theFirstLayoutTellsTheBottomOnce() {
        open()
        told(true)
    }

    @Test fun leavingTheBottomTellsFalseAndComingBackTellsTrue() {
        open()
        // The reader drags towards older messages, well past the distance.
        compose.onNode(hasScrollAction()).performTouchInput { swipeDown() }
        compose.waitForIdle()
        told(true, false)
        scrollTo(39)
        compose.onNodeWithText("第 1000 条").assertIsDisplayed()
        told(true, false, true)
    }

    @Test fun messagesArrivingUnderAReaderAtTheBottomKeepThemThere() {
        open()
        compose.runOnIdle { messages = messages + rows(1001, 1001) }
        compose.waitForIdle()
        compose.runOnIdle { messages = messages + rows(1002, 1004) }
        compose.waitForIdle()
        compose.onNodeWithText("第 1004 条").assertExists()
        told(true)
    }

    @Test fun aWindowReplacedWithoutTheReaderAskingIsNotTheirBottomUntilTheyDragIt() {
        open()
        compose.runOnIdle { messages = rows(921, 960); windowId = "timeline:2" }
        compose.waitForIdle()
        compose.onNodeWithText("第 960 条").assertExists()
        // The list opened the new window at its newest row; that is not the reader arriving there.
        told(true, false)
        compose.onNode(hasScrollAction()).performTouchInput { swipeUp() }
        compose.waitForIdle()
        told(true, false, true)
    }

    @Test fun aLocateHoldsTheAnswerEvenAtTheLastRow() {
        open()
        val answers = mutableListOf<Boolean>()
        compose.runOnUiThread { scope.launch { answers += state.scrollToMessage("m1000") } }
        compose.waitUntil { answers.isNotEmpty() }
        assertTrue(answers.single())
        compose.waitForIdle()
        told(true, false)
        compose.onNode(hasScrollAction()).performTouchInput { swipeUp() }
        compose.waitForIdle()
        told(true, false, true)
    }
}
