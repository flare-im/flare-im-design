package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.longClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** Lifecycle mutation and reactions as the thread renders them; fixtures only. */
class MessageProjectionTest {
    @get:Rule val compose = createComposeRule()

    private val recalled = FlareMessageLifecycle(mutation = FlareMessageMutationState.Recalled)

    private fun message(id: String, sender: String, text: String, lifecycle: FlareMessageLifecycle? = null, reactions: List<ReactionGroup> = emptyList()) =
        FlareMessageData(id = id, senderId = sender, senderName = if (sender == "me") "我" else "Ann", content = FlareTextContent(text), lifecycle = lifecycle, reactions = reactions)

    @Test fun recalledMessagesShowANoticeInsteadOfTheirContent() {
        val pressed = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            MessageList(
                messages = listOf(
                    message("1", "ann", "私密内容 A", recalled),
                    message("2", "me", "私密内容 B", recalled),
                    message("3", "ann", "还在的消息"),
                ),
                currentUserId = "me",
                conversationKind = FlareConversationKind.Group,
                onMessageLongPress = { pressed += it.id },
            )
        } }
        compose.onAllNodesWithText("私密内容", substring = true).assertCountEquals(0)
        compose.onNodeWithText("Ann 撤回了一条消息").assertExists()
        compose.onNodeWithText("你撤回了一条消息").performTouchInput { longClick() }
        compose.onNodeWithText("还在的消息").performTouchInput { longClick() }
        compose.runOnIdle { assertEquals(listOf("3"), pressed) }
    }

    private val reactions = listOf(ReactionGroup("👍", 2, reactedBySelf = true), ReactionGroup("🎉", 1))

    @Test fun reactionPillsToggleTheCurrentUsersReaction() {
        val toggled = mutableListOf<Pair<String, String>>()
        compose.setContent { MaterialTheme {
            MessageList(
                messages = listOf(message("1", "ann", "上线了", reactions = reactions), message("2", "me", "收到", reactions = listOf(ReactionGroup("❤️", 1)))),
                currentUserId = "me",
                onReact = { msg, emoji -> toggled += msg.id to emoji },
            )
        } }
        compose.onNodeWithText("🎉").performClick()
        compose.onNodeWithText("❤️").performClick()
        compose.runOnIdle { assertEquals(listOf("1" to "🎉", "2" to "❤️"), toggled) }
    }

    @Test fun reactionPillsAreDisplayOnlyWithoutAHandler() {
        compose.setContent { MaterialTheme {
            MessageList(messages = listOf(message("1", "ann", "上线了", reactions = reactions)), currentUserId = "me")
        } }
        compose.onNodeWithText("👍").assertExists()
        compose.onAllNodes(hasClickAction()).assertCountEquals(0)
    }
}
