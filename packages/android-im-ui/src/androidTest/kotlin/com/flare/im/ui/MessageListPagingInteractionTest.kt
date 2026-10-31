package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * The newer end of a window detached from the latest (`spec/message-list-paging-vectors.json`), on the device: its load
 * button below the timeline, the back-to-latest key, and neither on a list left at its defaults.
 */
class MessageListPagingInteractionTest {
    @get:Rule val compose = createComposeRule()

    private fun message(id: Int) =
        FlareMessageData(id = "m$id", senderId = "ann", senderName = "Ann", content = FlareTextContent("第 $id 条"))

    private val strings = FlareStrings()

    @Test fun aDetachedWindowOffersNewerPagesAndTheLatest() {
        val asked = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            Box(Modifier.fillMaxWidth().height(320.dp)) {
                MessageList(
                    messages = (1..30).map(::message), currentUserId = "me", conversationId = "c1",
                    hasNewer = true, onLoadNewer = { asked += "newer" }, onJumpToLatest = { asked += "latest" },
                )
            }
        } }
        compose.onNodeWithText(strings.messageListLoadNewer).performClick()
        compose.onNodeWithContentDescription(strings.scrollToLatest).performClick()
        compose.runOnIdle { assertEquals(listOf("newer", "latest"), asked) }
    }

    @Test fun aListLeftAtItsDefaultsHasNoNewerEndAndNoBackToLatestKey() {
        compose.setContent { MaterialTheme {
            Box(Modifier.fillMaxWidth().height(320.dp)) {
                MessageList(messages = (1..30).map(::message), currentUserId = "me", conversationId = "c1", onLoadNewer = {}, onJumpToLatest = {})
            }
        } }
        compose.onNodeWithText(strings.messageListLoadNewer).assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.scrollToLatest).assertDoesNotExist()
    }

    @Test fun aNewerPageLoadingShowsNoButtonAndAFailureOffersARetry() {
        compose.setContent { MaterialTheme {
            Box(Modifier.fillMaxWidth().height(320.dp)) {
                MessageList(
                    messages = (1..30).map(::message), currentUserId = "me", conversationId = "c1",
                    hasNewer = true, newerError = "加载失败", onLoadNewer = {},
                )
            }
        } }
        compose.onNodeWithText("加载失败").assertExists()
        compose.onNodeWithText(strings.messageListLoadNewer).assertExists()
    }
}
