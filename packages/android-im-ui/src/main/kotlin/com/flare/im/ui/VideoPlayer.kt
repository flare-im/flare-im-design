package com.flare.im.ui

import android.net.Uri
import android.widget.VideoView
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import kotlinx.coroutines.delay

/** Where the kit's own video playback stands. */
internal enum class FlareVideoPhase { Loading, Playing, Paused, Failed }

/** The play / pause key of a [VideoPlayer], named for what a tap does next. */
internal fun videoPlayerToggle(strings: FlareStrings, phase: FlareVideoPhase): FlareIconControlSpec =
    if (phase == FlareVideoPhase.Playing) FlareIconControlSpec("toggle", "pause", strings.pause)
    else FlareIconControlSpec("toggle", "play", strings.play)

/** The phase a video starts in: an address the player may not load fails at once, so the screen is never blank. */
internal fun videoPlayerStartPhase(src: String): FlareVideoPhase =
    if (flarePlayableMediaUrl(src) == null) FlareVideoPhase.Failed else FlareVideoPhase.Loading

/**
 * Full-screen video player — title, close, playback. Spec: Media/VideoPlayerModal (`VideoPlayer`).
 * Renders nothing when [show] is false.
 *
 * Without [player] the kit plays [videoSrc] itself on the platform media player: it starts at once,
 * shows a spinner while loading, a named play / pause key with the time, and a failed state with retry
 * and close (never a blank screen). [onPlay] reports each start. A host [player] replaces the playback
 * and keeps the chrome. System back and the close key call [onClose]; playback pauses when the screen
 * stops and ends when the player leaves composition.
 */
@Composable
fun VideoPlayer(
    show: Boolean,
    videoSrc: String,
    title: String? = null,
    player: (@Composable () -> Unit)? = null,
    onPlay: (() -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    if (!show) return
    val strings = flareStrings()
    val close by rememberUpdatedState(onClose)
    FlareNativeBackEffect(enabled = onClose != null) { close?.invoke() }
    Box(Modifier.fillMaxSize().background(Color.Black)) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            if (player != null) player() else KitVideoPlayback(videoSrc, onPlay, onClose)
        }
        Row(
            Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.safeDrawing).padding(FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(
                icon = "close",
                contentDescription = strings.close,
                customSize = FlareSizes.touchTarget,
                tint = Color.White,
                background = Color.White.copy(alpha = 0.25f),
                onClick = onClose,
            )
            if (!title.isNullOrEmpty()) {
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Text(title, color = Color.White, fontSize = FlareSizes.fontSize2xl.value.sp, fontWeight = FontWeight.SemiBold,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

/** The kit's playback of [src] on the platform [VideoView]. */
@Composable
private fun KitVideoPlayback(src: String, onPlay: (() -> Unit)?, onClose: (() -> Unit)?) {
    val strings = flareStrings()
    val started by rememberUpdatedState(onPlay)
    var phase by remember(src) { mutableStateOf(videoPlayerStartPhase(src)) }
    var attempt by remember(src) { mutableIntStateOf(0) }
    var positionMs by remember(src) { mutableIntStateOf(0) }
    var durationMs by remember(src) { mutableIntStateOf(0) }
    var aspect by remember(src) { mutableFloatStateOf(0f) }
    var view by remember(src) { mutableStateOf<VideoView?>(null) }
    val url = remember(src) { flarePlayableMediaUrl(src) }

    fun play() {
        val video = view ?: return
        video.start()
        phase = FlareVideoPhase.Playing
        started?.invoke()
    }
    fun pause() {
        view?.pause()
        // Paused while still loading, the video stays paused once it is ready.
        if (phase == FlareVideoPhase.Playing || phase == FlareVideoPhase.Loading) phase = FlareVideoPhase.Paused
    }

    // The screen stops (background, another screen): pause, and let the user resume.
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle, src) {
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_STOP) pause() }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }
    LaunchedEffect(phase, view) {
        while (phase == FlareVideoPhase.Playing) {
            view?.let { positionMs = it.currentPosition }
            delay(250)
        }
    }

    if (url != null && phase != FlareVideoPhase.Failed) {
        key(attempt) {
            AndroidView(
                factory = { context ->
                    VideoView(context).apply {
                        setOnPreparedListener { player ->
                            durationMs = player.duration.coerceAtLeast(0)
                            if (player.videoWidth > 0 && player.videoHeight > 0) aspect = player.videoWidth.toFloat() / player.videoHeight
                            if (phase == FlareVideoPhase.Loading) {
                                phase = FlareVideoPhase.Playing
                                started?.invoke()
                            }
                        }
                        setOnCompletionListener {
                            phase = FlareVideoPhase.Paused
                            positionMs = durationMs
                        }
                        // Handled: the platform's own error dialog never shows.
                        setOnErrorListener { _, _, _ ->
                            phase = FlareVideoPhase.Failed
                            true
                        }
                        setVideoURI(Uri.parse(url))
                        start()
                        view = this
                    }
                },
                onRelease = { it.stopPlayback() },
                // The picture fits the screen at the video's aspect, centred; the whole screen until the size is known.
                modifier = if (aspect > 0f) Modifier.aspectRatio(aspect) else Modifier.fillMaxSize(),
            )
        }
        // A tap on the picture plays or pauses.
        Box(Modifier.fillMaxSize().pointerInput(Unit) {
            detectTapGestures { if (phase == FlareVideoPhase.Playing) pause() else if (phase == FlareVideoPhase.Paused) play() }
        })
    }

    when (phase) {
        FlareVideoPhase.Loading -> CircularProgressIndicator(color = Color.White)
        FlareVideoPhase.Failed -> Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
            modifier = Modifier.padding(FlareSizes.spacingLg),
        ) {
            Icon(flareIconVector("error"), null, Modifier.size(FlareSizes.iconSizeXl), tint = Color.White.copy(alpha = FlareOpacity.muted))
            Text(strings.videoLoadFailed, color = Color.White, fontSize = FlareSizes.fontSizeLg.value.sp, textAlign = TextAlign.Center)
            Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                if (url != null) {
                    // Large buttons: the 48 dp touch target.
                    Button(label = strings.retry, size = FlareControlSize.Lg, onClick = {
                        positionMs = 0
                        phase = FlareVideoPhase.Loading
                        attempt++
                    })
                }
                if (onClose != null) Button(label = strings.close, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Lg, onClick = onClose)
            }
        }
        FlareVideoPhase.Playing, FlareVideoPhase.Paused -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomCenter) {
            val toggle = videoPlayerToggle(strings, phase)
            Row(
                Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.safeDrawing).padding(FlareSizes.spacingMd),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                FlareIconControl(label = toggle.label, onClick = { if (phase == FlareVideoPhase.Playing) pause() else play() }) {
                    Box(Modifier.size(FlareSizes.touchTarget).clip(CircleShape).background(Color.White.copy(alpha = 0.25f)))
                    Icon(flareIconVector(toggle.icon), null, tint = Color.White)
                }
                Text(
                    "${videoClock(positionMs)} / ${videoClock(durationMs)}",
                    color = Color.White, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1,
                )
            }
        }
    }
}

private fun videoClock(ms: Int): String {
    val seconds = (ms.coerceAtLeast(0) + 500) / 1000
    return "%d:%02d".format(seconds / 60, seconds % 60)
}
