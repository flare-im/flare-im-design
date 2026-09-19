package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test

/** The rendered header carries the strings table's words for its default actions, member count and presence. */
class ConversationHeaderLabelInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val s = FlareStrings()
    private val english = listOf("Search messages", "Start audio call", "Start video call", "Add member", "Share conversation", "Conversation details")

    @Test fun theRenderedHeaderAndItsAddMenuCarryNoEnglishDefaultNames() {
        compose.setContent { MaterialTheme {
            ConversationHeader(identity = ConversationIdentity("g1", "设计评审组", ConversationHeaderKind.Group, memberCount = 8), onAction = {})
        } }
        compose.onNodeWithText(s.conversationHeaderMemberCount(8)).assertIsDisplayed()
        compose.onNodeWithContentDescription(s.conversationHeaderSearch).assertExists()
        english.forEach { compose.onAllNodesWithContentDescription(it).assertCountEquals(0) }
        // Add member and share sit in the add menu on every width.
        compose.onNodeWithContentDescription(s.conversationHeaderAddActions).performClick()
        compose.onNodeWithText(s.conversationHeaderAddMember).assertIsDisplayed()
        compose.onNodeWithText(s.conversationHeaderShare).assertIsDisplayed()
        english.forEach { compose.onAllNodesWithText(it).assertCountEquals(0) }
    }

    @Test fun aDirectHeaderNamesThePresenceInWords() {
        compose.setContent { MaterialTheme {
            ConversationHeader(identity = ConversationIdentity("u1", "陈默", presence = FlarePresence.Busy), onAction = {})
        } }
        compose.onNodeWithText(s.presenceBusy).assertIsDisplayed()
        compose.onAllNodesWithText("Busy").assertCountEquals(0)
    }
}
