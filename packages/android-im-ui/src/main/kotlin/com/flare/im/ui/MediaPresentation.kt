package com.flare.im.ui

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest

/*
 * Received media the kit consumes on its own. When the host passes no media handler, a tap on an image
 * opens the image preview, a tap on a video opens the video player, and a tap on a voice message plays it
 * in its bubble, one voice at a time. These stay inside the app. Leaving the app is the host's (a file, a
 * map) with one exception: a link without a host link handler opens in the platform's browser, and only
 * when it is a safe web address ([safeExternalUrl]).
 */

/** What a tap on a message body does; null when the body is not tappable. */
internal sealed interface FlareContentTap {
    /** The host's media handler takes the tap. */
    data object Host : FlareContentTap
    data class PreviewImage(val src: String) : FlareContentTap
    /** An album: the body previews the image of the tile that was tapped. */
    data object PreviewAlbumImage : FlareContentTap
    data class PlayVideo(val src: String) : FlareContentTap
    data class PlayVoice(val src: String) : FlareContentTap
    /** The host's file handler opens the file. */
    data object OpenFile : FlareContentTap
    /** A link card: the link intent ([flareLinkTarget]). */
    data class OpenLink(val url: String) : FlareContentTap
}

/**
 * The host's media handler, when passed, takes every tap on a media body (full control). Without one,
 * the kit previews an image (the full-size URL, else the thumbnail), plays a video and plays a voice
 * message, and a file goes to the host's file handler when there is one. A link card is a link, whatever
 * the media handler: it follows the link intent ([flareLinkTarget]) and is not tappable when the link can
 * go nowhere. Location and cards stay the host's: without its media handler they are not tappable.
 */
internal fun flareContentTap(
    content: FlareMessageContent,
    hasMediaHandler: Boolean,
    hasFileHandler: Boolean,
    hasLinkHandler: Boolean = false,
): FlareContentTap? {
    if (content is FlareLinkCardContent) return flareLinkTarget(content.url, hasLinkHandler)?.let { FlareContentTap.OpenLink(content.url) }
    if (!acceptsMediaAction(content)) return null
    if (hasMediaHandler) return FlareContentTap.Host
    return when (content) {
        is FlareImageContent -> FlareContentTap.PreviewImage(content.url.ifBlank { content.thumbnailUrl.orEmpty() })
        is FlareImageGroupContent -> FlareContentTap.PreviewAlbumImage
        is FlareVideoContent -> FlareContentTap.PlayVideo(content.url)
        is FlareAudioContent -> FlareContentTap.PlayVoice(content.url)
        is FlareFileContent -> FlareContentTap.OpenFile.takeIf { hasFileHandler }
        else -> null
    }
}

/** The built-in bodies a media handler receives taps from (a link card is a link, see [flareContentTap]). */
private fun acceptsMediaAction(content: FlareMessageContent): Boolean = when (content) {
    is FlareEmojiContent, is FlareStickerContent, is FlareImageContent, is FlareImageGroupContent, is FlareVideoContent, is FlareAudioContent,
    is FlareFileContent, is FlareLocationContent, is FlareCardContent, is FlareCalendarContent,
    is FlareMiniAppContent, is FlareAnnouncementContent -> true
    else -> false
}

/** Where a tapped link goes. */
internal sealed interface FlareLinkTarget {
    /** The host's link handler, with the address as the message wrote it (the host gates it). */
    data class Host(val url: String) : FlareLinkTarget
    /** The platform opener, with the normalised safe web address. */
    data class Platform(val url: String) : FlareLinkTarget
}

/**
 * The link intent: the host's link handler takes every link; without one the kit opens a safe web address
 * (http or https, [safeExternalUrl]) with the platform opener, and anything else (`javascript:`, `intent:`,
 * `file:`, a blank string) goes nowhere (null).
 */
internal fun flareLinkTarget(url: String, hasLinkHandler: Boolean): FlareLinkTarget? = when {
    hasLinkHandler -> FlareLinkTarget.Host(url)
    else -> safeExternalUrl(url)?.let { FlareLinkTarget.Platform(it) }
}

/**
 * The link opener of a message body: [onOpenLink] when the host handles links, else the platform's
 * [LocalUriHandler] for a safe web address ([flareLinkTarget]); an address that goes nowhere, or a platform
 * with no app to open it, does nothing. Stable across recompositions, so text keeps its laid-out links.
 */
@Composable
internal fun rememberFlareLinkOpener(onOpenLink: ((String) -> Unit)?): (String) -> Unit {
    val uriHandler = LocalUriHandler.current
    val handler by rememberUpdatedState(onOpenLink)
    return remember(uriHandler) {
        { url ->
            when (val target = flareLinkTarget(url, hasLinkHandler = handler != null)) {
                is FlareLinkTarget.Host -> handler?.invoke(target.url)
                is FlareLinkTarget.Platform -> runCatching { uriHandler.openUri(target.url) }
                null -> Unit
            }
        }
    }
}

/** The schemes the kit's own preview and players load: web media and local media. */
internal val flarePlayableMediaSchemes: Set<String> = setOf("http", "https", "file", "content", "android.resource")

/**
 * The address the kit's preview and players may load, or null: web (http, https) or local (file,
 * content, android.resource, an absolute path) media. Anything else — javascript:, data:, intent: or a
 * blank string — loads nothing and shows the failed state. Presenting media never leaves the app, so this
 * is not the navigation gate ([safeExternalUrl] is).
 */
internal fun flarePlayableMediaUrl(raw: String?): String? {
    val value = raw?.trim().orEmpty()
    if (value.isEmpty()) return null
    if (value.startsWith("/")) return value
    val scheme = Regex("^([a-zA-Z][a-zA-Z0-9+.\\-]*):").find(value)?.groupValues?.get(1)?.lowercase() ?: return null
    return value.takeIf { scheme in flarePlayableMediaSchemes }
}

/** A full-screen presentation the kit owns. */
internal sealed interface FlareMediaPresentation {
    /** One picture; [onDownload] is its download key, and there is none without it. */
    data class Image(val src: String, val onDownload: (() -> Unit)? = null) : FlareMediaPresentation
    /** A gallery of [sources], starting at [index]; [onDownload] downloads the picture of a page, and there is no key without it. */
    data class Gallery(val sources: List<String>, val index: Int, val onDownload: ((Int) -> Unit)? = null) : FlareMediaPresentation
    data class Video(val src: String) : FlareMediaPresentation
}

internal enum class FlareVoicePhase { Idle, Preparing, Playing, Paused, Failed }

/** One audio player. [FlareVoicePlayback] drives it; tests drive a fake. */
internal interface FlareVoiceEngine {
    /** Starts loading [url]. [onPrepared] or [onError] follows (possibly at once), and [onCompleted] at the end. */
    fun open(url: String, onPrepared: (durationMs: Int) -> Unit, onCompleted: () -> Unit, onError: () -> Unit)
    fun start()
    fun pause()
    val positionMs: Int
    fun release()
}

/**
 * Voice playback for a list: one voice at a time. [toggle] plays, pauses and resumes the voice at a key
 * and stops any other; a failure leaves that voice failed until it is tapped again (retry). The state is
 * snapshot state, so a bubble recomposes when its own voice changes.
 */
@Stable
internal class FlareVoicePlayback(private val newEngine: () -> FlareVoiceEngine) {
    var activeKey: String? by mutableStateOf(null)
        private set
    var phase: FlareVoicePhase by mutableStateOf(FlareVoicePhase.Idle)
        private set
    var positionMs: Int by mutableIntStateOf(0)
        private set

    /** Durations learnt from the player, by key, for voices whose message carries none. */
    val durations = mutableStateMapOf<String, Int>()

    private var engine: FlareVoiceEngine? = null

    fun phaseOf(key: String): FlareVoicePhase = if (activeKey == key) phase else FlareVoicePhase.Idle

    fun toggle(key: String, src: String) {
        if (key == activeKey) {
            when (phase) {
                FlareVoicePhase.Playing -> { engine?.pause(); phase = FlareVoicePhase.Paused; return }
                FlareVoicePhase.Paused -> { engine?.start(); phase = FlareVoicePhase.Playing; return }
                FlareVoicePhase.Preparing -> { stop(); return }
                FlareVoicePhase.Idle, FlareVoicePhase.Failed -> Unit
            }
        }
        play(key, src)
    }

    private fun play(key: String, src: String) {
        stop()
        activeKey = key
        val url = flarePlayableMediaUrl(src)
        if (url == null) {
            phase = FlareVoicePhase.Failed
            return
        }
        phase = FlareVoicePhase.Preparing
        val current = newEngine()
        engine = current
        current.open(
            url,
            onPrepared = { duration ->
                if (engine === current) {
                    if (duration > 0) durations[key] = duration
                    current.start()
                    phase = FlareVoicePhase.Playing
                }
            },
            onCompleted = { if (engine === current) stop() },
            onError = {
                if (engine === current) {
                    releaseEngine()
                    phase = FlareVoicePhase.Failed
                }
            },
        )
    }

    /** Reads the playing position; called on a short interval while playing. */
    fun tick() {
        if (phase == FlareVoicePhase.Playing) engine?.let { positionMs = it.positionMs }
    }

    /** Stops and forgets the voice playing, if any. */
    fun stop() {
        releaseEngine()
        activeKey = null
        phase = FlareVoicePhase.Idle
        positionMs = 0
    }

    private fun releaseEngine() {
        val current = engine ?: return
        engine = null
        current.release()
    }
}

/** [FlareVoiceEngine] on the platform [MediaPlayer]. Created and called on the main thread, which receives its callbacks. */
private class MediaPlayerVoiceEngine(private val context: Context) : FlareVoiceEngine {
    private val player = MediaPlayer()

    override fun open(url: String, onPrepared: (durationMs: Int) -> Unit, onCompleted: () -> Unit, onError: () -> Unit) {
        player.setAudioAttributes(
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build(),
        )
        player.setOnPreparedListener { onPrepared(runCatching { it.duration }.getOrDefault(0)) }
        player.setOnCompletionListener { onCompleted() }
        player.setOnErrorListener { _, _, _ -> onError(); true }
        try {
            player.setDataSource(context, Uri.parse(url))
            player.prepareAsync()
        } catch (e: Exception) {
            onError()
        }
    }

    override fun start() { runCatching { player.start() } }

    override fun pause() { runCatching { player.pause() } }

    override val positionMs: Int get() = runCatching { player.currentPosition }.getOrDefault(0)

    override fun release() {
        runCatching { player.reset() }
        player.release()
    }
}

/** The media a list presents: the full-screen preview or player, and its voice playback. */
@Stable
internal class FlareMediaHost(val voice: FlareVoicePlayback) {
    var presentation: FlareMediaPresentation? by mutableStateOf(null)
        private set

    /** Opens the preview or player; a voice playing stops first. */
    fun present(next: FlareMediaPresentation) {
        voice.stop()
        presentation = next
    }

    fun dismiss() {
        presentation = null
    }

    fun release() {
        voice.stop()
        presentation = null
    }
}

/** The media host of the enclosing [MessageList]; null outside one. */
internal val LocalFlareMediaHost = staticCompositionLocalOf<FlareMediaHost?> { null }

/** The id of the message whose body is composing, so its voice keeps its own playback state. */
internal val LocalFlareMessageKey = staticCompositionLocalOf<String?> { null }

private const val VOICE_TICK_MS = 250L

/**
 * A media host scoped to the caller: playback stops when the caller leaves composition (the list is
 * disposed) or the screen stops (the app goes to the background or another screen covers it).
 */
@Composable
internal fun rememberFlareMediaHost(): FlareMediaHost {
    val context = LocalContext.current.applicationContext
    val host = remember { FlareMediaHost(FlareVoicePlayback { MediaPlayerVoiceEngine(context) }) }
    DisposableEffect(host) { onDispose { host.release() } }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle, host) {
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_STOP) host.voice.stop() }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }
    LaunchedEffect(host) {
        snapshotFlow { host.voice.phase }.collectLatest { phase ->
            while (phase == FlareVoicePhase.Playing) {
                host.voice.tick()
                delay(VOICE_TICK_MS)
            }
        }
    }
    return host
}

/**
 * The host's full-screen presentation, in its own dialog window over everything: system back and the
 * close control dismiss it, and the preview also closes on a swipe down.
 */
@Composable
internal fun FlareMediaOverlay(host: FlareMediaHost) {
    val presentation = host.presentation ?: return
    Dialog(
        onDismissRequest = host::dismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        FlareEdgeToEdgeDialogWindow()
        when (presentation) {
            is FlareMediaPresentation.Image ->
                ImagePreview(show = true, imageSrc = presentation.src, onClose = host::dismiss, onDownload = presentation.onDownload)
            is FlareMediaPresentation.Gallery ->
                ImageGalleryPreview(presentation.sources, presentation.index, onClose = host::dismiss, onDownload = presentation.onDownload)
            is FlareMediaPresentation.Video -> VideoPlayer(show = true, videoSrc = presentation.src, onClose = host::dismiss)
        }
    }
}
