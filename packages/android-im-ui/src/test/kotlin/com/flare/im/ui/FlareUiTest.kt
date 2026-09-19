package com.flare.im.ui

import androidx.compose.ui.graphics.Color
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class FlareUiTest {
    @Test fun initialsFallback() {
        assertEquals("HF", initials("Henry Ford"))
        assertEquals("I", initials("Ivy"))
        assertEquals("?", initials("   "))
    }

    @Test fun seedTintDeterministic() {
        assertEquals(seedTint("u1"), seedTint("u1"))
    }

    @Test fun byteAndDurationFormat() {
        assertEquals("2.0 KB", bytes(2048))
        assertEquals("01:15", duration(75))
    }

    @Test fun conversationRowFlags() {
        assertTrue(ConversationRowData("c1", "A", unreadCount = 3).hasUnread)
        assertTrue(ConversationRowData("c1", "A", draftPreview = "wip").hasDraft)
        assertFalse(ConversationRowData("c1", "A").hasUnread)
    }

    @Test fun contentTypeKeysAndBareMedia() {
        assertEquals("text", FlareTextContent("x").type)
        assertEquals("vote", FlareGenericContent("vote", "l").type)
        assertTrue(isBareMedia(FlareImageContent("u")))
        assertFalse(isBareMedia(FlareTextContent("x")))
        assertTrue(FlareMessageData("m", "s", "s", FlareNotificationContent("j")).isSystem)
    }

    @Test fun registryRegisterUnregister() {
        FlareContentRegistry.register("vote") { _, _ -> }
        assertNotNull(FlareContentRegistry.lookup("vote"))
        FlareContentRegistry.unregister("vote")
        assertNull(FlareContentRegistry.lookup("vote"))
    }

    @Test fun tokensThemeDiffers() {
        assertTrue(FlareColors.Light.bgPrimary != FlareColors.Dark.bgPrimary)
        assertEquals(44f, FlareSizes.avatarSize.value)
    }

    @Test fun allBrandsHaveDistinctMessageSemanticsAndSupportOverrides() {
        val outgoing = FlareBrandTheme.entries.map { FlareColors.resolve(it, false).messageOutgoingBackground }.toSet()
        val read = FlareBrandTheme.entries.map { FlareColors.resolve(it, false).messageStatusRead }.toSet()
        assertEquals(FlareBrandTheme.entries.size, outgoing.size)
        assertEquals(FlareBrandTheme.entries.size, read.size)

        val custom = FlareColors.OceanLight.copy(primary = Color(0xFF0057B8))
        assertEquals(Color(0xFF0057B8), custom.primary)
        assertEquals(FlareColors.OceanLight.messageOutgoingBackground, custom.messageOutgoingBackground)
    }

    @Test fun voteOptionHoldsValues() {
        val o = FlareVoteOption("Thu 15:00", 62)
        assertEquals("Thu 15:00", o.text)
        assertEquals(62, o.pct)
        assertEquals(FlareVoteOption("a", 1), FlareVoteOption("a", 1))
    }
}
