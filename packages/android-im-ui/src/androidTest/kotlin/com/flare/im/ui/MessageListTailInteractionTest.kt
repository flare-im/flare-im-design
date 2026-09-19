package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * The reading position on the device: a conversation longer than the screen opens at its newest message,
 * an appended message keeps a reader at the bottom in view, and a link in a text bubble reaches the host.
 */
class MessageListTailInteractionTest {
    @get:Rule val compose = createComposeRule()

    private fun message(id: String, sender: String = "ann", text: String = "第 $id 条") =
        FlareMessageData(id = id, senderId = sender, senderName = if (sender == "me") "我" else "Ann", content = FlareTextContent(text))

    @Test fun aConversationLongerThanTheScreenOpensAtItsNewestMessage() {
        val messages = (1..60).map { message("$it") }
        compose.setContent { MaterialTheme {
            Box(Modifier.fillMaxWidth().height(320.dp)) {
                MessageList(messages = messages, currentUserId = "me", conversationId = "c1")
            }
        } }
        compose.onNodeWithText("第 60 条").assertExists()
        compose.onNodeWithText("第 1 条").assertDoesNotExist()
    }

    @Test fun anAppendedMessageStaysInViewForAReaderAtTheBottom() {
        var messages by mutableStateOf((1..60).map { message("$it") })
        compose.setContent { MaterialTheme {
            Box(Modifier.fillMaxWidth().height(320.dp)) {
                MessageList(messages = messages, currentUserId = "me", conversationId = "c1")
            }
        } }
        compose.onNodeWithText("第 60 条").assertExists()
        messages = messages + message("61")
        compose.waitForIdle()
        compose.onNodeWithText("第 61 条").assertExists()
    }

    @Test fun aLinkInATextBubbleReachesTheHost() {
        val opened = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            MessageList(
                messages = listOf(message("1", text = "见 https://flare.im/docs")),
                currentUserId = "me",
                onOpenLink = { opened += it },
            )
        } }
        compose.onNodeWithText("https://flare.im/docs", substring = true).performClick()
        compose.runOnIdle { assertEquals(listOf("https://flare.im/docs"), opened) }
    }
}
