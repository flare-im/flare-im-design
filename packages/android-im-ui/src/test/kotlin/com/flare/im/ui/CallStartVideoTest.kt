package com.flare.im.ui

import androidx.compose.runtime.Composable
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame

/**
 * An audio call can be switched to video, checked without a UI against the keys [CallControls] draws: the "switch
 * to video" key (切换到视频 from the strings table, the kit's video glyph) follows the speaker in an audio call when
 * the host passes onStartVideo, never in a video call. A [GroupCallView] tile asks the host for video only while it
 * shows video, and keeps the avatar when the host has none.
 */
class CallStartVideoTest {
    private val zh = FlareStrings()

    private fun keys(
        mode: FlareCallMode,
        canStartVideo: Boolean,
        canAddMember: Boolean = false,
        strings: FlareStrings = zh,
    ) = callControlKeys(strings, muted = false, cameraOn = true, speakerOn = false, mode = mode,
        canAddMember = canAddMember, canStartVideo = canStartVideo)

    @Test fun theKeyFollowsTheSpeakerInAnAudioCall() {
        val voice = keys(FlareCallMode.Audio, canStartVideo = true, canAddMember = true)
        assertEquals(listOf("microphone", "speaker", "startVideo", "addMember", "hangUp"), voice.map { it.id })
        // A button with the video glyph, not a device toggle.
        assertEquals(FlareIconControlSpec("startVideo", "video", "切换到视频"), voice[2])
        assertEquals(zh.callSwitchToVideo, voice[2].label)
        assertEquals("Switch to video", keys(FlareCallMode.Audio, canStartVideo = true, strings = flareStringsEnglish())[2].label)
    }

    @Test fun theKeyIsNotDrawnInAVideoCallNorWithoutTheCallback() {
        assertFalse(keys(FlareCallMode.Video, canStartVideo = true).any { it.id == "startVideo" })
        assertEquals(listOf("microphone", "speaker", "hangUp"), keys(FlareCallMode.Audio, canStartVideo = false).map { it.id })
    }

    @Test fun aTileIsAskedForVideoOnlyWhileItShowsVideo() {
        val asked = mutableListOf<String>()
        val stream: @Composable () -> Unit = {}
        val tile: (CallParticipant) -> (@Composable () -> Unit)? = { p ->
            asked += p.id
            // No stream for c yet: the kit keeps the avatar.
            if (p.id == "a") stream else null
        }
        val on = CallParticipant(id = "a", name = "A")
        assertSame(stream, callTileVideo(on, FlareCallMode.Video, tile))
        assertNull(callTileVideo(CallParticipant(id = "b", name = "B", cameraOff = true), FlareCallMode.Video, tile))
        assertNull(callTileVideo(CallParticipant(id = "c", name = "C"), FlareCallMode.Video, tile))
        assertNull(callTileVideo(on, FlareCallMode.Audio, tile))
        assertNull(callTileVideo(on, FlareCallMode.Video, tileContent = null))
        // Never asked for a camera that is off, nor in an audio call.
        assertEquals(listOf("a", "c"), asked)
    }
}
