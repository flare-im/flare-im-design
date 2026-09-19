package com.flare.im.ui

import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** The quiet moments cover without an image, and the words the moment controls are named with. */
class MomentsPresentationTest {
    @Test fun aCoverWithoutAnImageIsAShortNeutralBand() {
        for (missing in listOf(null, "", "  ")) {
            val quiet = momentsCoverLook(missing)
            assertEquals(140.dp, quiet.height)
            assertFalse(quiet.photo)
            assertFalse(quiet.brandPlaceholder, "no brand gradient")
            assertFalse(quiet.scrim, "no dark scrim")
            assertFalse(quiet.textShadows, "name and signature in the text colours, without shadows")
        }
        val photo = momentsCoverLook("https://example.com/cover.jpg")
        assertEquals(240.dp, photo.height)
        assertTrue(photo.brandPlaceholder && photo.scrim && photo.textShadows)
    }

    @Test fun commentControlsAndReplyWordsComeFromTheStringsTable() {
        val zh = FlareStrings()
        assertEquals("回复 何川：带上我", zh.momentReplyToComment("何川", "带上我"))
        assertEquals("回复", zh.momentReplyTo)
        val en = FlareStrings {
            momentReplyToComment = { name, text -> "Reply to $name: $text" }
            momentReplyTo = "replying to"
        }
        assertEquals("Reply to He: Count me in", en.momentReplyToComment("He", "Count me in"))
        assertEquals("replying to", en.momentReplyTo)
    }

    @Test fun theProfileIdentityRowAndQrButtonAreNamedFromTheStringsTable() {
        val zh = FlareStrings()
        assertEquals("林夏，编辑资料", zh.profilePanelEditProfile("林夏"))
        assertEquals("我的二维码", zh.myQrCode)
        val en = FlareStrings { profilePanelEditProfile = { "$it, edit profile" }; myQrCode = "My QR code" }
        assertEquals("Lin, edit profile" to "My QR code", en.profilePanelEditProfile("Lin") to en.myQrCode)
    }
}
