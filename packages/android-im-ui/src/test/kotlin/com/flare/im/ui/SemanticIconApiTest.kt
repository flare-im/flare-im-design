package com.flare.im.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Public item models carry a semantic icon **name**, never a platform glyph (FR-079): a settings item, a
 * navigation item and an action item all name a registry icon, the kit's own defaults do too, and a name the
 * registry does not have draws the fallback glyph instead of crashing or printing the word.
 */
class SemanticIconApiTest {
    @Test fun settingsItemsNameARegistryIcon() {
        val item = SettingsItem("theme", "外观", "theme", FlareSettingKind.Navigation, detail = "跟随系统")
        assertEquals("theme", item.icon)
        assertTrue(item.icon in flareIconNames)
        // The kit's own profile entries are names too.
        val entries = profileEntries(FlareStrings())
        assertEquals(listOf("star", "moments", "settings"), entries.map { it.icon })
        for (entry in entries) assertTrue(entry.icon in flareIconNames, "`${entry.icon}` is a registry name")
        // An icon is optional: a row without one draws no glyph.
        assertNull(SettingsItem("version", "版本").icon)
    }

    @Test fun navigationItemsNameARegistryIcon() {
        val item = FlareApplicationNavigationItem("chats", "消息", "chats")
        assertEquals("chats", item.icon)
        for (nav in flareDefaultIMNavigation() + flareDefaultContactNavigation()) {
            assertTrue(nav.icon in flareIconNames, "`${nav.icon}` is a registry name")
        }
    }

    @Test fun actionItemsNameARegistryIcon() {
        // Composer tiles.
        val actions = defaultComposerActions(FlareStrings())
        assertEquals(listOf("image", "file", "mic", "location", "card"), actions.map { it.icon })
        for (action in actions) assertTrue(action.icon in flareIconNames, "`${action.icon}` is a registry name")
        // Message menu entries.
        val menu = messageMenuActions(FlareMessageActionAvailability(canReply = true, canDelete = true), FlareStrings())
        assertEquals(listOf("reply", "mark", "delete"), menu.map { it.icon })
        // Action menu items already took names; they stay names.
        assertEquals("report", FlareActionItem("report", "举报", icon = "report").icon)
    }

    @Test fun anUnknownNameDrawsTheFallbackAndNeverCrashes() {
        // Drawn, not thrown, and never the word itself.
        assertEquals(Icons.AutoMirrored.Outlined.HelpOutline, flareIconVector("not-a-registry-name"))
        assertEquals(Icons.AutoMirrored.Outlined.HelpOutline, flareIconVector(""))
        // A typo an app might make (a Material glyph name, an SF Symbol) resolves to the same fallback.
        for (typo in listOf("MoreVert", "person.crop.circle", "chat_bubble_outline", "person add")) {
            assertEquals(Icons.AutoMirrored.Outlined.HelpOutline, flareIconVector(typo), typo)
            assertNull(flareIconVectorOrNull(typo), typo)
        }
    }
}
