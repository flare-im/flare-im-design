package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ConversationActionSheetTest {
    private val base = FlareConversationActionSnapshot("c1", "设计评审")
    private val all = FlareConversationActionCapabilities(pin = true, mute = true, markRead = true, archive = true, delete = true, hide = true)
    private fun ids(c: FlareConversationActionSnapshot, caps: FlareConversationActionCapabilities) =
        conversationActions(c, caps).map { it.action }

    @Test fun nothingWithoutCapabilities() {
        assertEquals(emptyList(), ids(base, FlareConversationActionCapabilities()))
    }

    @Test fun eachCapabilityRevealsItsAction() {
        assertEquals(listOf(FlareConversationAction.Pin), ids(base, FlareConversationActionCapabilities(pin = true)))
        assertEquals(listOf(FlareConversationAction.Mute), ids(base, FlareConversationActionCapabilities(mute = true)))
        assertEquals(listOf(FlareConversationAction.Archive), ids(base, FlareConversationActionCapabilities(archive = true)))
        assertEquals(listOf(FlareConversationAction.Hide), ids(base, FlareConversationActionCapabilities(hide = true)))
        assertEquals(listOf(FlareConversationAction.Delete), ids(base, FlareConversationActionCapabilities(delete = true)))
    }

    @Test fun invertsByState() {
        assertEquals(listOf(FlareConversationAction.Unpin), ids(base.copy(pinned = true), FlareConversationActionCapabilities(pin = true)))
        assertEquals(listOf(FlareConversationAction.Unmute), ids(base.copy(muted = true), FlareConversationActionCapabilities(mute = true)))
        assertEquals(listOf(FlareConversationAction.Unarchive), ids(base.copy(archived = true), FlareConversationActionCapabilities(archive = true)))
    }

    @Test fun markReadOnlyWithUnread() {
        assertEquals(emptyList(), ids(base, FlareConversationActionCapabilities(markRead = true)))
        assertEquals(listOf(FlareConversationAction.MarkRead), ids(base.copy(unreadCount = 3), FlareConversationActionCapabilities(markRead = true)))
    }

    @Test fun orderAndDangerGroup() {
        val entries = conversationActions(base.copy(unreadCount = 2), all)
        assertEquals(
            listOf(FlareConversationAction.Pin, FlareConversationAction.Mute, FlareConversationAction.MarkRead,
                FlareConversationAction.Archive, FlareConversationAction.Hide, FlareConversationAction.Delete),
            entries.map { it.action },
        )
        assertEquals(listOf(FlareConversationAction.Delete), entries.filter { it.danger }.map { it.action })
        assertTrue(entries.last().danger)
    }
}
