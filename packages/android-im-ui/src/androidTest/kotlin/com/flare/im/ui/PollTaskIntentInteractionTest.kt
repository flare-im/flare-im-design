package com.flare.im.ui

import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertHasNoClickAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * A poll's options and a task's checkbox are controls in a timeline only when the host takes the intent (R9-B8):
 * `onVote` with the option's index, `onTaskToggle` with the state asked for. Without a handler, and in multi-select
 * mode, they are read-only.
 */
class PollTaskIntentInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val poll = FlareMessageData(id = "m1", senderId = "ann", senderName = "Ann", content = FlarePollContent("vote-1", "周五聚餐", listOf("火锅", "烤肉")))
    private val task = FlareMessageData(id = "m2", senderId = "ann", senderName = "Ann", content = FlareTaskContent("task-1", "提交周报", "今天 18:00", done = false))

    @Test fun theListHandsTheHostTheVoteAndTheToggle() {
        val intents = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(poll, task),
                    currentUserId = "me",
                    onVote = { message, index -> intents += "vote ${message.id}:$index" },
                    onTaskToggle = { message, done -> intents += "task ${message.id}:$done" },
                )
            }
        }
        compose.onNodeWithText("烤肉").performClick()
        // The checkbox is named by the task title (the title text itself carries no semantics then).
        compose.onNodeWithContentDescription("提交周报").performClick()
        assertEquals(listOf("vote m1:1", "task m2:true"), intents)
    }

    @Test fun withoutHandlersNothingIsAControl() {
        compose.setContent {
            FlareThemeProvider { MessageList(messages = listOf(poll), currentUserId = "me") }
        }
        compose.onNodeWithText("火锅").assertHasNoClickAction()
    }

    @Test fun multiSelectTapsSelectTheRowInstead() {
        val intents = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                MessageBubble(
                    message = poll,
                    currentUserId = "me",
                    multiSelectMode = true,
                    onToggleSelect = { intents += "select $it" },
                    onVote = { message, index -> intents += "vote ${message.id}:$index" },
                )
            }
        }
        compose.onNodeWithText("火锅").performClick()
        assertEquals(listOf("select m1"), intents)
    }

    @Test fun aVoteOptionIsAControlWithAHandler() {
        compose.setContent {
            FlareThemeProvider { MessageContentView(content = poll.content, onVote = {}) }
        }
        compose.onNodeWithText("火锅").assertHasClickAction()
    }
}
