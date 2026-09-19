package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ConversationHeaderGroupingTest {
    private val group = ConversationIdentity("g1", "Product room", ConversationHeaderKind.Group)

    @Test
    fun headerActionsResolveDefaultsCapabilitiesAndHostConfiguration() {
        val resolved = resolveConversationHeaderActions(
            identity = group,
            capabilities = ConversationHeaderCapabilities(setOf("search", "addMember", "share", "task", "pin")),
            configuration = ConversationHeaderConfiguration(
                removeActionIds = setOf("share"),
                actionOverrides = listOf(
                    ConversationHeaderAction(
                        id = "addMember",
                        label = "Invite people",
                        icon = "person-add",
                        placement = ConversationHeaderActionPlacement.Add,
                        order = 30,
                        enabled = false,
                        disabledReason = "Read only",
                    ),
                ),
            ),
            actions = listOf(
                ConversationHeaderAction("pin", "Pin", placement = ConversationHeaderActionPlacement.Primary, order = 5),
                ConversationHeaderAction("task", "Create task", placement = ConversationHeaderActionPlacement.Add, order = 40),
            ),
        )
        assertEquals(listOf("pin", "search", "addMember", "task"), resolved.map { it.id })
        assertFalse(resolved[2].enabled)
        assertEquals("Invite people", resolved[2].label)
    }

    @Test
    fun groupingCoversSenderTimeAndSystemBoundaries() {
        val messages = listOf(
            message("1", "ivy", 1_000), message("2", "ivy", 2_000),
            message("3", "ivy", 400_000), message("4", "system", 401_000, system = true),
            message("5", "ivy", 402_000), message("6", "me", 403_000),
        )
        assertEquals(MessageGroupPosition.First, messageGroupPosition(messages, 0))
        assertEquals(MessageGroupPosition.Last, messageGroupPosition(messages, 1))
        assertEquals(MessageGroupPosition.Single, messageGroupPosition(messages, 2))
        assertEquals(MessageGroupPosition.Single, messageGroupPosition(messages, 3))
        assertEquals(MessageGroupPosition.Single, messageGroupPosition(messages, 4))

        // A recalled message is a notice: it stands alone and ends the sender's run.
        val recalledRun = listOf(
            message("r1", "ivy", 1_000), message("r2", "ivy", 2_000),
            message("r3", "ivy", 3_000).copy(lifecycle = FlareMessageLifecycle(mutation = FlareMessageMutationState.Recalled)),
            message("r4", "ivy", 4_000),
        )
        assertEquals(
            listOf(MessageGroupPosition.First, MessageGroupPosition.Last, MessageGroupPosition.Single, MessageGroupPosition.Single),
            recalledRun.indices.map { messageGroupPosition(recalledRun, it) },
        )

        val incoming = messageRowPresentation(messages.first(), MessageGroupPosition.First, "me", true)
        val outgoing = messageRowPresentation(messages.last(), MessageGroupPosition.Single, "me", true)
        assertTrue(incoming.showAvatar)
        assertTrue(incoming.showSenderName)
        assertTrue(incoming.reserveAvatarSpace)
        assertFalse(outgoing.showAvatar)
        assertFalse(outgoing.showSenderName)
    }

    private fun message(id: String, sender: String, time: Long, system: Boolean = false) = FlareMessageData(
        id = id,
        senderId = sender,
        senderName = sender,
        sentAtMs = time,
        content = if (system) FlareNotificationContent("boundary") else FlareTextContent("hello"),
    )
}

/** The More button performs the only overflow action itself; two or more keep the menu. */
class ConversationHeaderOverflowTest {
    private val direct = ConversationIdentity("u1", "陈默")

    @Test fun oneOverflowActionTakesTheMoreButton() {
        // Compact phones keep one primary button: search stays, and details alone overflows.
        val resolved = resolveConversationHeaderActions(
            direct,
            configuration = ConversationHeaderConfiguration(removeActionIds = setOf("audioCall", "videoCall", "share")),
        )
        val layout = conversationHeaderLayout(resolved, maxPrimary = 1)
        assertEquals(listOf("search"), layout.primary.map { it.id })
        assertEquals("details", layout.soleOverflow?.id)
    }

    @Test fun twoOrMoreOverflowActionsKeepTheMenu() {
        val resolved = resolveConversationHeaderActions(direct, configuration = ConversationHeaderConfiguration(removeActionIds = setOf("share")))
        val compact = conversationHeaderLayout(resolved, maxPrimary = 1)
        assertEquals(listOf("audioCall", "videoCall", "details"), compact.overflow.map { it.id })
        assertEquals(null, compact.soleOverflow)
        // With room for every primary action only details overflows, and it takes the More button again.
        assertEquals("details", conversationHeaderLayout(resolved, maxPrimary = 3).soleOverflow?.id)
        // Nothing overflows: there is no More button at all.
        val withoutDetails = resolveConversationHeaderActions(direct, configuration = ConversationHeaderConfiguration(removeActionIds = setOf("share", "details")))
        assertEquals(emptyList(), conversationHeaderLayout(withoutDetails, maxPrimary = 3).overflow)
    }
}
