package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The contact surfaces a contact card leads to: a friend request's source line, the add key's host wording and a
 * stranger's primary action on the contact page.
 */
class ContactSurfaceTest {
    private val s = FlareStrings()

    @Test fun theSourceIsALineOfItsOwnUnderTheMessage() {
        val request = FriendRequest(id = "r1", name = "Ivy", message = "一起做设计", source = "通过名片添加，由 Kai 推荐")
        assertEquals(listOf("一起做设计", "通过名片添加，由 Kai 推荐"), newFriendRequestLines(request), "two lines, message first")
        assertEquals(listOf("来自群聊"), newFriendRequestLines(FriendRequest(id = "r2", name = "Lu", source = "来自群聊")))
        assertEquals(listOf("hi"), newFriendRequestLines(FriendRequest(id = "r3", name = "Kai", message = "hi")))
        assertEquals(emptyList(), newFriendRequestLines(FriendRequest(id = "r4", name = "Kai", message = "", source = "")))
        assertNull(FriendRequest(id = "r5", name = "Lu").source)
    }

    @Test fun theAddKeyTakesTheHostsWordingElseTheKits() {
        val worded = relationActionBarCopy(s, addText = "添加到通讯录")
        assertEquals("添加到通讯录", worded.labelFor(FlareRelationAction.Add))
        assertEquals("添加到通讯录", relationActionBarCopy(flareStringsEnglish(), addText = "添加到通讯录").add, "the host's words in every language")
        val plain = relationActionBarCopy(s)
        assertEquals(s.relationActionBarAdd, plain.labelFor(FlareRelationAction.Add))
        assertEquals(flareStringsEnglish().relationActionBarAdd, relationActionBarCopy(flareStringsEnglish()).add)
        assertEquals(plain.labelFor(FlareRelationAction.Block), worded.labelFor(FlareRelationAction.Block), "only the add key changes")
        assertEquals(s.sendMessage, plain.labelFor(FlareRelationAction.Message))
    }

    @Test fun thePrimaryActionLeadsTheRowAndMessageFollowsAsSecondary() {
        val intents = contactDetailActions(handlesMessage = true, handlesCall = false, handlesVideo = false)
        assertEquals(
            listOf(ContactDetailRowKey(null, primary = true), ContactDetailRowKey(ContactDetailAction.Message, primary = false)),
            contactDetailRow(hasPrimary = true, intents = intents),
            "the host's action leads, Message follows as a secondary key",
        )
        val friend = contactDetailRow(hasPrimary = false, intents = contactDetailActions(true, true, false))
        assertEquals(
            listOf(ContactDetailRowKey(ContactDetailAction.Message, primary = true), ContactDetailRowKey(ContactDetailAction.Call, primary = false)),
            friend, "a friend's page leads with Message",
        )
        assertEquals(listOf(ContactDetailRowKey(null, primary = true)), contactDetailRow(true, emptyList()), "the row shows for it alone")
        assertTrue(contactDetailRow(false, emptyList()).isEmpty())
        assertTrue(contactDetailHasPrimaryAction("添加到通讯录", handled = true))
        assertFalse(contactDetailHasPrimaryAction("添加到通讯录", handled = false), "needs its handler")
        assertFalse(contactDetailHasPrimaryAction(" ", handled = true), "needs its label")
        assertFalse(contactDetailHasPrimaryAction(null, handled = true))
        assertTrue(flareIconVectorOrNull("person-add") != null, "the key's icon is a registry name")
    }
}
