package com.flare.im.ui

import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The peer's state on the 1:1 call screen, checked without a UI against the marks [CallView] draws: a muted peer
 * gets the mic-off badge named 对方已静音 from the strings table, a speaking peer gets the ring unless muted or
 * covered by video, and the host's own camera is a picture-in-picture in video mode only.
 */
class CallViewPeerStateTest {
    private val zh = FlareStrings()

    private fun marks(
        mode: FlareCallMode = FlareCallMode.Audio,
        hasVideo: Boolean = false,
        hasLocalVideo: Boolean = false,
        peerMuted: Boolean = false,
        peerSpeaking: Boolean = false,
        strings: FlareStrings = zh,
    ) = callViewPeerMarks(strings, mode, hasVideo = hasVideo, hasLocalVideo = hasLocalVideo,
        peerMuted = peerMuted, peerSpeaking = peerSpeaking)

    @Test fun theMutedBadgeIsNamedOnlyWhileThePeerIsMuted() {
        assertEquals("对方已静音", zh.callPeerMuted)
        assertEquals(zh.callPeerMuted, marks(peerMuted = true).mutedLabel)
        assertNull(marks(peerMuted = false).mutedLabel)
        assertEquals("Peer muted", marks(peerMuted = true, strings = FlareStrings { callPeerMuted = "Peer muted" }).mutedLabel)
        // The badge sits by the name, which the peer's video does not hide.
        assertEquals(zh.callPeerMuted, marks(mode = FlareCallMode.Video, hasVideo = true, peerMuted = true).mutedLabel)
    }

    @Test fun theSpeakingRingNeedsAnUnmutedPeerAndTheAvatar() {
        assertTrue(marks(peerSpeaking = true).speakingRing)
        assertFalse(marks(peerSpeaking = true, peerMuted = true).speakingRing)
        assertFalse(marks(peerSpeaking = false).speakingRing)
        // Video mode without the peer's video still shows the avatar, and so the ring.
        assertTrue(marks(mode = FlareCallMode.Video, peerSpeaking = true).speakingRing)
        val covered = marks(mode = FlareCallMode.Video, hasVideo = true, peerSpeaking = true)
        assertFalse(covered.avatar)
        assertFalse(covered.speakingRing)
        // An audio call ignores the video slot: the avatar and the ring stay.
        assertTrue(marks(hasVideo = true, peerSpeaking = true).speakingRing)
    }

    @Test fun theLocalPreviewIsDrawnInVideoModeOnly() {
        assertTrue(marks(mode = FlareCallMode.Video, hasLocalVideo = true).localPreview)
        assertTrue(marks(mode = FlareCallMode.Video, hasVideo = true, hasLocalVideo = true).localPreview)
        assertFalse(marks(mode = FlareCallMode.Video, hasLocalVideo = false).localPreview)
        assertFalse(marks(mode = FlareCallMode.Audio, hasLocalVideo = true).localPreview)
    }

    @Test fun thePeerBlockStartsBelowThePreview() {
        // Both measure from under the status bar: the preview's bottom is its inset plus its 3:4 height, the
        // avatar's top is the peer block's inset.
        val previewBottom = FlareSizes.spacingLg + FlareSizes.componentCallPreviewWidth * 4 / 3
        val avatarTop = marks(mode = FlareCallMode.Video, hasLocalVideo = true).peerTop
        assertTrue(avatarTop > previewBottom, "$avatarTop is below $previewBottom")
        assertEquals(FlareSizes.spacingLg * 2 + FlareSizes.componentCallPreviewWidth * 4 / 3, avatarTop)
        assertEquals(72.dp, marks(mode = FlareCallMode.Video).peerTop)
        assertEquals(72.dp, marks(mode = FlareCallMode.Audio, hasLocalVideo = true).peerTop)
    }
}
