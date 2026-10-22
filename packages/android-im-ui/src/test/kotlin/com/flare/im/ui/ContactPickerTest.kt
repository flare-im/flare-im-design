package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** The contact picker's rules without a UI: tab names, the user's own row, search, and the order a multiple pick keeps. */
class ContactPickerTest {
    private val s = FlareStrings()
    private val ada = FlareContactPickerEntry("u-ada", "Ada", subtitle = "Design")
    private val me = FlareContactPickerEntry("u-me", "Hugo", isSelf = true)
    private val bob = FlareContactPickerEntry("u-bob", "Bob", subtitle = "Ops")
    private val groups = listOf(
        FlareContactPickerGroup(FlareContactPickerGroup.FRIENDS, entries = listOf(ada, bob)),
        FlareContactPickerGroup(FlareContactPickerGroup.GROUP_MEMBERS, entries = listOf(me, ada)),
    )

    @Test fun tabsTakeTheKitsNamesForTheKnownGroups() {
        assertEquals(listOf(s.contactPickerFriends, s.contactPickerGroupMembers), groups.map { it.resolvedLabel(s) })
        assertEquals(listOf("Friends", "Group members"), groups.map { it.resolvedLabel(flareStringsEnglish()) })
        assertEquals("Team", FlareContactPickerGroup("team", "Team", emptyList()).resolvedLabel(s))
        assertEquals("team", FlareContactPickerGroup("team", entries = emptyList()).resolvedLabel(s))
    }

    @Test fun theUsersOwnRowIsMarked() {
        assertEquals("Hugo（我）", contactPickerDisplayName(me, s))
        assertEquals("Hugo (me)", contactPickerDisplayName(me, flareStringsEnglish()))
        assertEquals("Ada", contactPickerDisplayName(ada, s))
    }

    @Test fun searchMatchesNamesAndSubtitlesIgnoringCase() {
        val all = listOf(ada, me, bob)
        assertEquals(listOf("u-ada", "u-me", "u-bob"), filterContactPickerEntries(all, "  ").map { it.userId })
        assertEquals(listOf("u-ada"), filterContactPickerEntries(all, "ADA").map { it.userId })
        assertEquals(listOf("u-bob"), filterContactPickerEntries(all, "ops").map { it.userId })
        assertTrue(filterContactPickerEntries(all, "zz").isEmpty())
    }

    @Test fun aMultiplePickKeepsItsOrderAndEachPersonOnce() {
        var ids = emptyList<String>()
        for (id in listOf("u-bob", "u-ada", "u-me", "u-bob")) ids = contactPickerToggled(ids, id)
        assertEquals(listOf("u-ada", "u-me"), ids)
        assertEquals(listOf(ada, me), contactPickerPicked(ids, groups), "an entry in two groups is handed over once")
    }

    @Test fun onlyTheTappedRowSpinsAndOnlyWhileTheHostSends() {
        assertTrue(contactPickerRowPending("u-bob", pending = "u-bob", sending = true, multiple = false))
        assertFalse(contactPickerRowPending("u-ada", pending = "u-bob", sending = true, multiple = false))
        assertFalse(contactPickerRowPending("u-bob", pending = "u-bob", sending = false, multiple = false), "cleared: the row is forgotten")
        assertFalse(contactPickerRowPending("u-bob", pending = "u-bob", sending = true, multiple = true), "multiple mode spins the confirm key instead")
        assertFalse(contactPickerRowPending("u-bob", pending = null, sending = true, multiple = false))
    }

    @Test fun theCopyExistsInBothLanguages() {
        val en = flareStringsEnglish()
        assertEquals("选择联系人", s.contactPickerTitle)
        assertEquals("Choose a contact", en.contactPickerTitle)
        assertEquals("没有联系人", s.contactPickerEmpty)
        assertEquals("No contacts", en.contactPickerEmpty)
        assertEquals("搜索", s.contactPickerSearch)
    }
}
