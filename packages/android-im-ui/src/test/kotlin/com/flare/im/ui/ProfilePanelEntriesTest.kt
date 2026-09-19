package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/** The profile panel's default entries take their labels from [FlareStrings]; entries or sections the host passes win. */
class ProfilePanelEntriesTest {
    @Test fun theDefaultEntriesUseTheChineseStrings() {
        val entries = profileEntries(FlareStrings())
        assertEquals(listOf("favorites", "moments", "settings"), entries.map { it.key })
        assertEquals(listOf("收藏", "圈子", "设置"), entries.map { it.label })
    }

    @Test fun anOverrideWins() {
        val strings = FlareStrings { favorites = "Favorites"; moments = "Moments"; settings = "Settings" }
        assertEquals(listOf("Favorites", "Moments", "Settings"), profileEntries(strings).map { it.label })
        // Only the overridden key changes.
        assertEquals(listOf("收藏", "Moments", "设置"), profileEntries(FlareStrings { moments = "Moments" }).map { it.label })
    }

    @Test fun hostEntriesWin() {
        val strings = FlareStrings()
        val host = listOf(SettingsItem("wallet", "钱包"))
        assertEquals(listOf(SettingsSection(items = host)), profilePanelGroups(sections = null, entries = host, strings = strings))
        // An empty list is the host's choice too: no default rows.
        assertEquals(listOf(SettingsSection(items = emptyList())), profilePanelGroups(sections = null, entries = emptyList(), strings = strings))
        // No entries from the host: the defaults, labelled from the strings.
        assertEquals(listOf(SettingsSection(items = profileEntries(strings))), profilePanelGroups(sections = null, entries = null, strings = strings))
        // Sections win over entries.
        val sections = listOf(SettingsSection(title = "账号", items = host))
        assertEquals(sections, profilePanelGroups(sections = sections, entries = listOf(SettingsItem("x", "y")), strings = strings))
    }
}
