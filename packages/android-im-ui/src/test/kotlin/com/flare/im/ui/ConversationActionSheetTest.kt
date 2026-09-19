package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ConversationActionSheetTest {
    private val base = FlareConversationActionSnapshot("c1", "设计评审")
    private val all = FlareConversationActionCapabilities(pin = true, mute = true, markRead = true, archive = true, delete = true, hide = true)
    private val every = all.copy(markUnread = true, clearHistory = true)
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
        assertEquals(listOf(FlareConversationAction.ClearHistory), ids(base, FlareConversationActionCapabilities(clearHistory = true)))
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

    @Test fun markUnreadOnlyWhenNothingIsUnread() {
        val both = FlareConversationActionCapabilities(markRead = true, markUnread = true)
        assertEquals(listOf(FlareConversationAction.MarkUnread), ids(base, both))
        assertEquals(listOf(FlareConversationAction.MarkRead), ids(base.copy(unreadCount = 3), both))
        assertEquals(emptyList(), ids(base.copy(unreadCount = 3), FlareConversationActionCapabilities(markUnread = true)))
    }

    @Test fun orderAndDangerGroup() {
        val entries = conversationActions(base.copy(unreadCount = 2), all.copy(clearHistory = true))
        assertEquals(
            listOf(FlareConversationAction.Pin, FlareConversationAction.Mute, FlareConversationAction.MarkRead,
                FlareConversationAction.Archive, FlareConversationAction.Hide, FlareConversationAction.ClearHistory,
                FlareConversationAction.Delete),
            entries.map { it.action },
        )
        assertEquals(listOf(FlareConversationAction.ClearHistory, FlareConversationAction.Delete), entries.filter { it.danger }.map { it.action })
        assertTrue(entries.last().danger)
    }

    @Test fun fullOrderWithEveryCapability() {
        assertEquals(
            listOf(FlareConversationAction.Pin, FlareConversationAction.Mute, FlareConversationAction.MarkUnread,
                FlareConversationAction.Archive, FlareConversationAction.Hide, FlareConversationAction.ClearHistory,
                FlareConversationAction.Delete),
            ids(base, every),
        )
    }

    @Test fun markUnreadAndClearHistoryCopyComesFromTheStringsTable() {
        val defaults = FlareStrings()
        assertEquals("标为未读", defaults.conversationActionSheetMarkUnread)
        assertEquals("清空本地记录", defaults.conversationActionSheetClearHistory)
        val english = FlareStrings {
            conversationActionSheetMarkUnread = "Mark as unread"
            conversationActionSheetClearHistory = "Clear local history"
        }
        assertEquals("Mark as unread", english.conversationActionSheetMarkUnread)
        assertEquals("Clear local history", english.conversationActionSheetClearHistory)
    }

    @Test fun eachActionDrawsItsOwnRegistryGlyph() {
        assertEquals(
            listOf("pin", "unpin", "mute", "notification", "read", "mark-unread", "archive", "unarchive", "eye-off", "clear-history", "delete"),
            FlareConversationAction.entries.map(::conversationActionIconName),
        )
        for (action in FlareConversationAction.entries) {
            assertTrue(conversationActionIconName(action) in flareIconNames, "$action draws a registry glyph")
        }
        // Clearing local history must not look like deleting the conversation.
        assertTrue(flareIconVector(conversationActionIconName(FlareConversationAction.ClearHistory)) != flareIconVector("delete"))
    }
}
