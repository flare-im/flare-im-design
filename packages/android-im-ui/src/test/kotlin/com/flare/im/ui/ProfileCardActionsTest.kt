package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The profile card offers a tile only for an intent the host handles; the voice and video tiles are named from [FlareStrings]. */
class ProfileCardActionsTest {
    private val strings = FlareStrings()

    @Test fun noTilesWithoutCallbacks() {
        assertTrue(profileCardTiles(strings, handlesMessage = false, handlesCall = false, handlesVideo = false).isEmpty())
    }

    @Test fun aHandledCallIsOneTileNamedForVoiceCalls() {
        val tiles = profileCardTiles(strings, handlesMessage = false, handlesCall = true, handlesVideo = false)
        assertEquals(listOf(ProfileCardTile(ContactDetailAction.Call, "语音通话")), tiles)
        assertEquals(strings.contactDetailVoice, tiles.single().label)
    }

    @Test fun everyHandledIntentInOrderWithItsName() {
        val tiles = profileCardTiles(strings, handlesMessage = true, handlesCall = true, handlesVideo = true)
        assertEquals(listOf(ContactDetailAction.Message, ContactDetailAction.Call, ContactDetailAction.Video), tiles.map { it.action })
        assertEquals(listOf(strings.sendMessage, "语音通话", "视频通话"), tiles.map { it.label })
        // A host's wording names the tile.
        val english = FlareStrings { contactDetailVideo = "Video call" }
        assertEquals("Video call", profileCardTiles(english, handlesMessage = false, handlesCall = false, handlesVideo = true).single().label)
    }
}
