package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Received media without a host media handler: what a tap opens, which addresses the kit's players load,
 * and voice playback (one at a time, pause and resume, failure and retry) on a fake audio engine.
 */
class MediaDefaultsTest {
    private val zh = FlareStrings()

    // MARK: taps

    @Test fun withoutAHandlerATapPreviewsImagesPlaysVideosAndVoice() {
        assertEquals(FlareContentTap.PreviewImage("https://cdn/full.jpg"), flareContentTap(FlareImageContent("https://cdn/full.jpg", thumbnailUrl = "https://cdn/thumb.jpg"), false, false))
        // No full-size address: the thumbnail is what can be shown.
        assertEquals(FlareContentTap.PreviewImage("https://cdn/thumb.jpg"), flareContentTap(FlareImageContent("", thumbnailUrl = "https://cdn/thumb.jpg"), false, false))
        assertEquals(FlareContentTap.PlayVideo("https://cdn/v.mp4"), flareContentTap(FlareVideoContent("https://cdn/v.mp4"), false, false))
        assertEquals(FlareContentTap.PlayVoice("https://cdn/a.m4a"), flareContentTap(FlareAudioContent("https://cdn/a.m4a", 3), false, false))
    }

    @Test fun aHostMediaHandlerTakesPrecedenceOverEveryDefault() {
        val media = listOf(
            FlareImageContent("https://cdn/i.jpg"), FlareVideoContent("https://cdn/v.mp4"), FlareAudioContent("https://cdn/a.m4a"),
            FlareFileContent("spec.pdf", "https://cdn/spec.pdf"), FlareLocationContent("西湖"),
        )
        for (content in media) {
            assertEquals(FlareContentTap.Host, flareContentTap(content, hasMediaHandler = true, hasFileHandler = true), content.type)
        }
        // A link card is a link whatever the media handler: it follows the link intent, not the media one.
        assertEquals(
            FlareContentTap.OpenLink("https://flare.im"),
            flareContentTap(FlareLinkCardContent("https://flare.im", "Flare"), hasMediaHandler = true, hasFileHandler = true),
        )
        // Bodies that never took a media tap stay untappable.
        assertNull(flareContentTap(FlareTextContent("hi"), hasMediaHandler = true, hasFileHandler = true))
        assertNull(flareContentTap(FlarePollContent("p", "午饭"), hasMediaHandler = true, hasFileHandler = true))
    }

    @Test fun filesAndLocationsStayHostActions() {
        val file = FlareFileContent("spec.pdf", "https://cdn/spec.pdf")
        assertNull(flareContentTap(file, hasMediaHandler = false, hasFileHandler = false))
        assertEquals(FlareContentTap.OpenFile, flareContentTap(file, hasMediaHandler = false, hasFileHandler = true))
        assertNull(flareContentTap(FlareLocationContent("西湖"), hasMediaHandler = false, hasFileHandler = true))
        assertNull(flareContentTap(FlareCardContent("Ann"), hasMediaHandler = false, hasFileHandler = true))
    }

    // MARK: links (K4)

    @Test fun aLinkCardFollowsTheLinkIntentAndOpensNothingUnsafe() {
        // Without a host handler the kit opens a safe web address itself; another scheme is not tappable at all.
        assertEquals(
            FlareContentTap.OpenLink("https://flare.im"),
            flareContentTap(FlareLinkCardContent("https://flare.im", "Flare"), hasMediaHandler = false, hasFileHandler = true),
        )
        assertNull(flareContentTap(FlareLinkCardContent("javascript:alert(1)", "X"), hasMediaHandler = false, hasFileHandler = true))
        // With a host handler every address reaches the host, which gates it.
        assertEquals(
            FlareContentTap.OpenLink("javascript:alert(1)"),
            flareContentTap(FlareLinkCardContent("javascript:alert(1)", "X"), hasMediaHandler = false, hasFileHandler = true, hasLinkHandler = true),
        )
    }

    @Test fun aTappedLinkReachesTheHostAndOtherSchemesGoNowhere() {
        // A host link handler takes every address as the message wrote it.
        assertEquals(FlareLinkTarget.Host("https://flare.im/a"), flareLinkTarget("https://flare.im/a", hasLinkHandler = true))
        assertEquals(FlareLinkTarget.Host("javascript:alert(1)"), flareLinkTarget("javascript:alert(1)", hasLinkHandler = true))
        // Without one the kit opens only http and https, normalised by the URL gate.
        assertEquals(FlareLinkTarget.Platform("https://flare.im/a"), flareLinkTarget("https://flare.im/a", hasLinkHandler = false))
        assertEquals(FlareLinkTarget.Platform("http://10.0.2.2:9000/a"), flareLinkTarget("http://10.0.2.2:9000/a", hasLinkHandler = false))
        for (unsafe in listOf("javascript:alert(1)", "intent://x#Intent;end", "file:///etc/passwd", "data:text/html,<b>", "")) {
            assertNull(flareLinkTarget(unsafe, hasLinkHandler = false), unsafe)
        }
    }

    @Test fun thePlayersLoadWebAndLocalMediaOnly() {
        for (ok in listOf("https://cdn/a.m4a", "http://10.0.2.2:9000/b.mp4", "file:///data/v.mp4", "content://media/1", "/data/user/0/app/cache/a.wav", " https://cdn/pad.jpg ")) {
            assertEquals(ok.trim(), flarePlayableMediaUrl(ok), ok)
        }
        for (bad in listOf(null, "", "  ", "javascript:alert(1)", "data:audio/wav;base64,AAAA", "intent://x#Intent;end", "cdn/relative.mp4")) {
            assertNull(flarePlayableMediaUrl(bad), bad.toString())
        }
        assertEquals(FlareVideoPhase.Failed, videoPlayerStartPhase("javascript:alert(1)"))
        assertEquals(FlareVideoPhase.Failed, videoPlayerStartPhase(""))
        assertEquals(FlareVideoPhase.Loading, videoPlayerStartPhase("https://cdn/v.mp4"))
    }

    // MARK: voice playback

    private class FakeEngine(val url: String) : FlareVoiceEngine {
        var prepared: ((Int) -> Unit)? = null
        var completed: (() -> Unit)? = null
        var failed: (() -> Unit)? = null
        var started = 0
        var paused = 0
        var released = false
        override var positionMs: Int = 0

        override fun open(url: String, onPrepared: (durationMs: Int) -> Unit, onCompleted: () -> Unit, onError: () -> Unit) {
            prepared = onPrepared; completed = onCompleted; failed = onError
        }
        override fun start() { started++ }
        override fun pause() { paused++ }
        override fun release() { released = true }
    }

    private val engines = mutableListOf<FakeEngine>()
    private val playback = FlareVoicePlayback { FakeEngine("").also { engines += it } }

    @Test fun aTapPlaysPausesAndResumesTheVoice() {
        playback.toggle("m1", "https://cdn/a.m4a")
        assertEquals("m1" to FlareVoicePhase.Preparing, playback.activeKey to playback.phase)
        engines.single().prepared!!(12_400)
        assertEquals(FlareVoicePhase.Playing, playback.phase)
        assertEquals(1, engines.single().started)
        assertEquals(12_400, playback.durations["m1"])

        engines.single().positionMs = 3_000
        playback.tick()
        assertEquals(3_000, playback.positionMs)

        playback.toggle("m1", "https://cdn/a.m4a")
        assertEquals(FlareVoicePhase.Paused, playback.phase)
        assertEquals(1, engines.single().paused)
        playback.toggle("m1", "https://cdn/a.m4a")
        assertEquals(FlareVoicePhase.Playing, playback.phase)
        assertEquals(2, engines.single().started)

        // The end of the voice returns the bubble to its idle look and releases the player.
        engines.single().completed!!()
        assertEquals(null to FlareVoicePhase.Idle, playback.activeKey to playback.phase)
        assertTrue(engines.single().released)
    }

    @Test fun startingASecondVoiceStopsTheFirst() {
        playback.toggle("m1", "https://cdn/a.m4a")
        engines[0].prepared!!(5_000)
        playback.toggle("m2", "https://cdn/b.m4a")
        assertTrue(engines[0].released)
        assertEquals(FlareVoicePhase.Idle, playback.phaseOf("m1"))
        assertEquals(FlareVoicePhase.Preparing, playback.phaseOf("m2"))
        // A late callback from the stopped player changes nothing.
        engines[0].prepared!!(5_000)
        engines[0].failed!!()
        assertEquals("m2" to FlareVoicePhase.Preparing, playback.activeKey to playback.phase)
    }

    @Test fun aFailureShowsFailedAndATapRetries() {
        playback.toggle("m1", "https://cdn/missing.m4a")
        engines[0].failed!!()
        assertEquals(FlareVoicePhase.Failed, playback.phaseOf("m1"))
        assertTrue(engines[0].released)
        playback.toggle("m1", "https://cdn/missing.m4a")
        assertEquals(FlareVoicePhase.Preparing, playback.phaseOf("m1"))
        assertEquals(2, engines.size)
        // An address the player may not load fails without opening a player.
        playback.toggle("m2", "javascript:alert(1)")
        assertEquals(FlareVoicePhase.Failed, playback.phaseOf("m2"))
        assertEquals(2, engines.size)
    }

    @Test fun aTapWhileLoadingCancelsAndStopReleases() {
        playback.toggle("m1", "https://cdn/a.m4a")
        playback.toggle("m1", "https://cdn/a.m4a")
        assertEquals(FlareVoicePhase.Idle, playback.phaseOf("m1"))
        assertTrue(engines[0].released)
        playback.toggle("m2", "https://cdn/b.m4a")
        engines[1].prepared!!(1_000)
        playback.stop()
        assertEquals(null to FlareVoicePhase.Idle, playback.activeKey to playback.phase)
        assertTrue(engines[1].released)
    }

    @Test fun presentingMediaOrReleasingTheListStopsTheVoice() {
        val host = FlareMediaHost(playback)
        playback.toggle("m1", "https://cdn/a.m4a")
        engines[0].prepared!!(1_000)
        host.present(FlareMediaPresentation.Image("https://cdn/i.jpg"))
        assertEquals(FlareMediaPresentation.Image("https://cdn/i.jpg"), host.presentation)
        assertEquals(FlareVoicePhase.Idle, playback.phase)
        host.dismiss()
        assertNull(host.presentation)
        playback.toggle("m2", "https://cdn/b.m4a")
        host.present(FlareMediaPresentation.Video("https://cdn/v.mp4"))
        host.release()
        assertNull(host.presentation)
        assertTrue(engines.all { it.released })
    }

    // MARK: named controls

    @Test fun theVoiceControlSaysWhatATapDoesNext() {
        assertEquals("play" to "播放", voiceMessageControl(zh, playing = false, failed = false).let { it.icon to it.label })
        assertEquals("pause" to "暂停", voiceMessageControl(zh, playing = true, failed = false).let { it.icon to it.label })
        assertEquals("refresh" to "重试", voiceMessageControl(zh, playing = false, failed = true).let { it.icon to it.label })
        assertTrue(voiceMessageControl(zh, playing = true, failed = false).icon in flareIconNames)
        assertTrue(voiceMessageControl(zh, playing = false, failed = true).icon in flareIconNames)
    }

    @Test fun theVoiceTimeShowsDurationProgressOrTheFailure() {
        assertEquals(VoiceMessageTime("12\"", "12 秒"), voiceMessageTime(zh, seconds = 12, elapsedSeconds = 0, playing = false, failed = false))
        assertEquals(VoiceMessageTime("0:03 / 0:12"), voiceMessageTime(zh, seconds = 12, elapsedSeconds = 3, playing = true, failed = false))
        // Paused part-way keeps the progress.
        assertEquals(VoiceMessageTime("0:03 / 0:12"), voiceMessageTime(zh, seconds = 12, elapsedSeconds = 3, playing = false, failed = false))
        assertEquals(VoiceMessageTime("播放失败"), voiceMessageTime(zh, seconds = 12, elapsedSeconds = 3, playing = false, failed = true))
        // A voice whose message carries no duration reads as a voice message until the player knows it.
        assertEquals(VoiceMessageTime("语音"), voiceMessageTime(zh, seconds = 0, elapsedSeconds = 0, playing = false, failed = false))
        val en = FlareStrings { voiceDuration = { "$it seconds" }; voicePlaybackFailed = "Playback failed"; voiceMessage = "Voice message" }
        assertEquals(VoiceMessageTime("12\"", "12 seconds"), voiceMessageTime(en, seconds = 12, elapsedSeconds = 0, playing = false, failed = false))
        assertEquals("Playback failed", voiceMessageTime(en, 12, 0, playing = false, failed = true).text)
    }

    @Test fun theVideoToggleAndMediaStringsAreKitStrings() {
        assertEquals("pause" to "暂停", videoPlayerToggle(zh, FlareVideoPhase.Playing).let { it.icon to it.label })
        assertEquals("play" to "播放", videoPlayerToggle(zh, FlareVideoPhase.Paused).let { it.icon to it.label })
        assertEquals(listOf("视频无法播放", "图片加载失败", "查看图片", "关闭预览", "重试", "关闭"), listOf(zh.videoLoadFailed, zh.imageLoadFailed, zh.imagePreviewOpen, zh.imagePreviewClose, zh.retry, zh.close))
        val en = FlareStrings { videoLoadFailed = "This video can't be played"; imageLoadFailed = "Image failed to load"; imagePreviewOpen = "View image" }
        assertEquals(listOf("This video can't be played", "Image failed to load", "View image"), listOf(en.videoLoadFailed, en.imageLoadFailed, en.imagePreviewOpen))
        assertFalse(en.voiceMessage.isEmpty(), "an unset key keeps its default")
    }
}
