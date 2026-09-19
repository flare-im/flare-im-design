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
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * The host asking the list to show a message ([FlareMessageListState.scrollToMessage]) — the return trip
 * after [MessageList]'s `onLocateMessage` sent the host off to read history. On the device, because the
 * answer is about rows that were really laid out and the proof is the row arriving in view.
 */
class MessageListStateInteractionTest {
    @get:Rule val compose = createComposeRule()

    private fun message(id: String, serverId: String? = null) =
        FlareMessageData(id = id, senderId = "ann", senderName = "Ann", content = FlareTextContent("第 $id 条"), serverId = serverId)

    /** A thread taller than the screen, opened at its newest message, plus the handle the host holds. */
    private fun openThread(messages: List<FlareMessageData> = (1..60).map { message("$it") }): Pair<FlareMessageListState, CoroutineScope> {
        lateinit var state: FlareMessageListState
        lateinit var scope: CoroutineScope
        compose.setContent {
            MaterialTheme {
                state = rememberFlareMessageListState()
                scope = rememberCoroutineScope()
                Box(Modifier.fillMaxWidth().height(320.dp)) {
                    MessageList(messages = messages, currentUserId = "me", conversationId = "c1", state = state)
                }
            }
        }
        compose.onNodeWithText("第 60 条").assertExists()
        return state to scope
    }

    /** Runs [ask] on the list's own scope and waits for its answer. */
    private fun answer(scope: CoroutineScope, ask: suspend () -> Boolean): Boolean {
        val answers = mutableListOf<Boolean>()
        compose.runOnUiThread { scope.launch { answers += ask() } }
        compose.waitUntil { answers.isNotEmpty() }
        compose.waitForIdle()
        return answers.single()
    }

    @Test fun aLoadedMessageIsShownAndTheAnswerIsTrue() {
        val (state, scope) = openThread()
        compose.onNodeWithText("第 1 条").assertDoesNotExist()
        assertTrue(answer(scope) { state.scrollToMessage("1") })
        compose.onNodeWithText("第 1 条").assertIsDisplayed()
    }

    /**
     * Either id of one row is a true answer and the same scroll. The host asks with the id a quote gave it —
     * the quoted message's core id — without knowing that the list drew that row with the client id instead,
     * which is the whole reason the host no longer converts anything.
     */
    @Test fun eitherIdOfTheSameRowIsShownAndAnsweredTrue() {
        val (state, scope) = openThread(listOf(message("cli-1", serverId = "srv-1")) + (2..60).map { message("$it") })
        compose.onNodeWithText("第 cli-1 条").assertDoesNotExist()
        assertTrue(answer(scope) { state.scrollToMessage("srv-1") })
        compose.onNodeWithText("第 cli-1 条").assertIsDisplayed()
        assertTrue(answer(scope) { state.scrollToMessage("cli-1") })
        compose.onNodeWithText("第 cli-1 条").assertIsDisplayed()
    }

    @Test fun aMessageTheListDoesNotHaveIsAnsweredFalseAndNothingMoves() {
        val (state, scope) = openThread()
        val before = state.listState.firstVisibleItemIndex to state.listState.firstVisibleItemScrollOffset
        assertFalse(answer(scope) { state.scrollToMessage("很早以前的消息") })
        assertEquals(before, state.listState.firstVisibleItemIndex to state.listState.firstVisibleItemScrollOffset)
        compose.onNodeWithText("第 60 条").assertExists()
    }

    /**
     * The host may ask before it rebuilds the list (the contract's lifecycle rule): false, no crash.
     * The same handle then works once a list is composed with it.
     */
    @Test fun aHandleWithNoComposedListAnswersFalse() {
        lateinit var scope: CoroutineScope
        val state = FlareMessageListState()
        compose.setContent { MaterialTheme { scope = rememberCoroutineScope() } }
        assertFalse(answer(scope) { state.scrollToMessage("1") })
    }

    /**
     * A message read into the thread after the host went to fetch it: the host writes the longer thread and
     * asks in the same breath, and the list answers about the rows it is about to show — one tap, not two.
     */
    @Test fun aMessageJustReadIntoTheThreadIsShownWithoutWaitingForAnotherTap() {
        lateinit var state: FlareMessageListState
        lateinit var scope: CoroutineScope
        var messages by mutableStateOf((40..60).map { message("$it") })
        compose.setContent {
            MaterialTheme {
                state = rememberFlareMessageListState()
                scope = rememberCoroutineScope()
                Box(Modifier.fillMaxWidth().height(320.dp)) {
                    MessageList(messages = messages, currentUserId = "me", conversationId = "c1", state = state)
                }
            }
        }
        compose.onNodeWithText("第 60 条").assertExists()
        val answers = mutableListOf<Boolean>()
        compose.runOnUiThread {
            messages = (1..60).map { message("$it") } // the older page the host just read
            scope.launch { answers += state.scrollToMessage("1") }
        }
        compose.waitUntil { answers.isNotEmpty() }
        compose.waitForIdle()
        assertEquals(listOf(true), answers)
        compose.onNodeWithText("第 1 条").assertIsDisplayed()
    }
}
