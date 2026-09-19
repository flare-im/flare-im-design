package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** The header identity block as a target, and toggle actions. */
class ConversationHeaderIdentityTest {
    private val details = ConversationHeaderAction("details", "Group details")
    private val identity = ConversationIdentity("g1", "Product room", ConversationHeaderKind.Group, action = details)
    private val defaults = ConversationHeaderConfiguration()

    @Test fun theIdentityActionNeedsAHandlerAndSurvivesFiltering() {
        assertEquals(details, resolveConversationIdentityAction(identity, null, defaults, hasOnAction = true))
        assertNull(resolveConversationIdentityAction(identity, null, defaults, hasOnAction = false))
        assertNull(resolveConversationIdentityAction(identity.copy(action = null), null, defaults, hasOnAction = true))
        assertNull(resolveConversationIdentityAction(identity.copy(action = details.copy(enabled = false)), null, defaults, hasOnAction = true))
        assertNull(resolveConversationIdentityAction(identity.copy(action = details.copy(visible = false)), null, defaults, hasOnAction = true))
        assertNull(resolveConversationIdentityAction(identity, null, ConversationHeaderConfiguration(removeActionIds = setOf("details")), hasOnAction = true))
        assertNull(resolveConversationIdentityAction(identity, ConversationHeaderCapabilities(setOf("search")), defaults, hasOnAction = true))
        assertEquals(details, resolveConversationIdentityAction(identity, ConversationHeaderCapabilities(setOf("details")), defaults, hasOnAction = true))
        val gated = details.copy(capability = "groupAdmin")
        assertNull(resolveConversationIdentityAction(identity.copy(action = gated), ConversationHeaderCapabilities(setOf("details")), defaults, hasOnAction = true))
    }

    @Test fun theIdentityLabelJoinsTitleAndAction() {
        assertEquals("Product room，Group details", FlareStrings().conversationHeaderIdentityLabel("Product room", "Group details"))
        val en = FlareStrings { conversationHeaderIdentityLabel = { title, action -> "$title, $action" } }
        assertEquals("Product room, Group details", en.conversationHeaderIdentityLabel("Product room", "Group details"))
    }

    @Test fun pressedMakesAnActionAToggleOnlyWhenSet() {
        assertNull(ConversationHeaderAction("mute", "Mute").pressed)
        assertEquals(false, ConversationHeaderAction("mute", "Mute", pressed = false).pressed)
    }
}
