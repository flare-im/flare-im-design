package com.flare.im.ui

import androidx.compose.animation.core.animate
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BrokenImage
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import coil.compose.AsyncImagePainter
import kotlinx.coroutines.launch
import kotlin.math.abs

/**
 * The download key of a message's picture, video or file, for where it stands on this device — the same key on the
 * file card, in the image preview and in the video player. Only with the host's download handler ([canDownload]):
 * a download while the file is not saved (a failed download is retried from it), nothing to press while it downloads
 * (the progress ring stands there), and once it is [saved] a folder (`reveal`) that shows the file in its folder
 * through the host ([canReveal]). Never a spent "downloaded" mark: a saved file the host cannot show keeps the
 * download key.
 */
internal fun mediaDownloadKey(
    strings: FlareStrings,
    canDownload: Boolean,
    downloading: Boolean,
    saved: Boolean,
    canReveal: Boolean,
): FlareIconControlSpec? = when {
    !canDownload || downloading -> null
    saved && canReveal -> FlareIconControlSpec("reveal", "folder", strings.showInFolder)
    else -> FlareIconControlSpec("download", "download", strings.download)
}

/**
 * The icon-only controls on an [ImagePreview]: close, and the download key while the host offers it — a download, or
 * the folder once the picture is [saved] and the host can show it ([mediaDownloadKey]); none while a download runs
 * (the progress ring takes its place).
 */
internal fun imagePreviewControls(
    strings: FlareStrings,
    canDownload: Boolean,
    downloading: Boolean,
    saved: Boolean = false,
    canReveal: Boolean = false,
): List<FlareIconControlSpec> =
    buildList {
        add(FlareIconControlSpec("close", "close", strings.imagePreviewClose))
        mediaDownloadKey(strings, canDownload, downloading, saved, canReveal)?.let(::add)
    }

/** How far a swipe down must travel before the preview closes: two touch targets. */
private val DismissDistance = FlareSizes.touchTarget * 2

/**
 * Full-screen image viewer — download with progress. Spec: Media/ImagePreviewModal (`ImagePreview`).
 * Renders nothing when [show] is false.
 *
 * Without [image] the preview loads [imageSrc] itself (web or local media; anything else shows the
 * failed state), with a spinner while loading and a failed state with retry. Pinch zooms 1x–4x, a drag
 * pans while zoomed, a double tap toggles zoom; unzoomed, a tap, a swipe down or system back closes
 * through [onClose]. The download control appears only with [onDownload]: a ring with [progressPct] while
 * [downloading], and once the picture is [saved] on this device a folder that calls [onReveal] (the host shows the
 * file in its folder); a saved picture without [onReveal] keeps the download key.
 *
 * In a gallery ([ImageGalleryPreview]) the preview says where it is ([galleryIndex] of [galleryCount]) and pages with
 * [onPrevious] and [onNext]: their controls at the sides, or a sideways swipe while unzoomed. A control with no
 * callback (the first or the last image) is disabled.
 */
@Composable
fun ImagePreview(
    show: Boolean,
    imageSrc: String,
    loading: Boolean = false,
    downloading: Boolean = false,
    progressPct: Int = 0,
    onClose: (() -> Unit)? = null,
    onDownload: (() -> Unit)? = null,
    image: (@Composable () -> Unit)? = null,
    galleryIndex: Int? = null,
    galleryCount: Int? = null,
    onPrevious: (() -> Unit)? = null,
    onNext: (() -> Unit)? = null,
    saved: Boolean = false,
    onReveal: (() -> Unit)? = null,
) {
    if (!show) return
    val strings = flareStrings()
    val reducedMotion = flareReducedMotion()
    val scope = rememberCoroutineScope()
    val close by rememberUpdatedState(onClose)
    val previous by rememberUpdatedState(onPrevious)
    val next by rememberUpdatedState(onNext)
    val pages = galleryIndex != null && (galleryCount ?: 0) > 1
    // Built-in zoom (parity with iOS/Flutter): pinch 1x–4x, drag to pan when zoomed, double-tap toggles.
    var scale by remember(imageSrc) { mutableFloatStateOf(1f) }
    var offset by remember(imageSrc) { mutableStateOf(Offset.Zero) }
    // A swipe down while unzoomed drags the image with it and closes past the distance.
    var dragY by remember(imageSrc) { mutableFloatStateOf(0f) }
    var attempt by remember(imageSrc) { mutableIntStateOf(0) }
    var state by remember(imageSrc) { mutableStateOf<AsyncImagePainter.State>(AsyncImagePainter.State.Empty) }
    val source = remember(imageSrc) { flarePlayableMediaUrl(imageSrc) }
    val dismissAfter = with(LocalDensity.current) { DismissDistance.toPx() }
    FlareNativeBackEffect(enabled = onClose != null) { close?.invoke() }
    // The backdrop thins to half as the swipe nears the distance, so the chat behind shows through.
    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 1f - (dragY / dismissAfter).coerceIn(0f, 1f) / 2))) {
        Box(
            Modifier.fillMaxSize()
                .pointerInput(imageSrc) {
                    detectTapGestures(
                        onTap = { if (scale <= 1f) close?.invoke() },
                        onDoubleTap = {
                            if (scale > 1f) { scale = 1f; offset = Offset.Zero } else scale = 2.5f
                        },
                    )
                }
                .pointerInput(imageSrc) {
                    awaitEachGesture {
                        awaitFirstDown(requireUnconsumed = false)
                        var swiping = false
                        var sideways = false
                        var travel = Offset.Zero
                        do {
                            val event = awaitPointerEvent()
                            val zoom = event.calculateZoom()
                            val pan = event.calculatePan()
                            val pointers = event.changes.count { it.pressed }
                            if (!swiping && (pointers > 1 || scale > 1f || zoom != 1f)) {
                                val next = (scale * zoom).coerceIn(1f, 4f)
                                scale = next
                                offset = if (next <= 1f) Offset.Zero else offset + pan
                                event.changes.forEach { if (it.positionChanged()) it.consume() }
                            } else if (pointers == 1 && (close != null || pages)) {
                                travel += pan
                                if (!swiping && !sideways && pages && abs(travel.x) > viewConfiguration.touchSlop && abs(travel.x) > abs(travel.y)) {
                                    sideways = true
                                }
                                if (sideways) event.changes.forEach { if (it.positionChanged()) it.consume() }
                                if (!swiping && !sideways && close != null && travel.y > viewConfiguration.touchSlop && travel.y > abs(travel.x)) swiping = true
                                if (swiping) {
                                    dragY = (dragY + pan.y).coerceAtLeast(0f)
                                    event.changes.forEach { if (it.positionChanged()) it.consume() }
                                }
                            }
                        } while (event.changes.any { it.pressed })
                        // A sideways swipe of half the closing distance pages: to the left shows the next image.
                        if (sideways && abs(travel.x) >= dismissAfter / 2) {
                            if (travel.x < 0) next?.invoke() else previous?.invoke()
                        } else if (swiping && dragY >= dismissAfter) {
                            close?.invoke()
                        } else if (dragY > 0f) {
                            if (reducedMotion) dragY = 0f
                            else scope.launch { animate(dragY, 0f, animationSpec = tween(FlareMotion.fast)) { value, _ -> dragY = value } }
                        }
                    }
                },
            contentAlignment = Alignment.Center,
        ) {
            val transform = Modifier.graphicsLayer {
                scaleX = scale
                scaleY = scale
                translationX = offset.x
                translationY = offset.y + dragY
            }
            when {
                loading -> CircularProgressIndicator(color = Color.White)
                image != null -> Box(transform) { image() }
                source != null && state !is AsyncImagePainter.State.Error -> {
                    key(attempt) {
                        AsyncImage(
                            model = source,
                            contentDescription = null,
                            contentScale = ContentScale.Fit,
                            onState = { state = it },
                            modifier = Modifier.fillMaxSize().then(transform),
                        )
                    }
                    if (state is AsyncImagePainter.State.Loading || state is AsyncImagePainter.State.Empty) {
                        CircularProgressIndicator(color = Color.White)
                    }
                }
                source != null -> ImagePreviewFailed(strings) { state = AsyncImagePainter.State.Empty; attempt++ }
                // An address the preview may not load: nothing to retry.
                imageSrc.isNotBlank() -> ImagePreviewFailed(strings, onRetry = null)
                else -> Icon(Icons.Outlined.BrokenImage, null, Modifier.size(64.dp), tint = Color.White.copy(alpha = 0.5f))
            }
        }
        if (pages) {
            Text(
                "${galleryIndex!! + 1} / $galleryCount",
                color = Color.White,
                fontSize = FlareSizes.fontSizeLg,
                modifier = Modifier.align(Alignment.TopCenter).windowInsetsPadding(WindowInsets.safeDrawing)
                    .padding(top = FlareSizes.spacingMd + FlareSizes.spacingSm)
                    .clearAndSetSemantics { contentDescription = strings.imagePreviewPosition(galleryIndex + 1, galleryCount!!) },
            )
            Box(Modifier.align(Alignment.CenterStart).windowInsetsPadding(WindowInsets.safeDrawing).padding(FlareSizes.spacingSm)) {
                PagingButton(FlareIconControlSpec("previous", "chevron-left", strings.imagePreviewPrevious, enabled = onPrevious != null), onPrevious)
            }
            Box(Modifier.align(Alignment.CenterEnd).windowInsetsPadding(WindowInsets.safeDrawing).padding(FlareSizes.spacingSm)) {
                PagingButton(FlareIconControlSpec("next", "chevron-right", strings.imagePreviewNext, enabled = onNext != null), onNext)
            }
        }
        Row(Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.safeDrawing).padding(FlareSizes.spacingMd)) {
            imagePreviewControls(strings, canDownload = onDownload != null, downloading = downloading, saved = saved, canReveal = onReveal != null).forEach { control ->
                when (control.id) {
                    "close" -> CircleButton(control, onClose)
                    "download" -> CircleButton(control, onDownload)
                    "reveal" -> CircleButton(control, onReveal)
                }
                if (control.id == "close") androidx.compose.foundation.layout.Spacer(Modifier.weight(1f))
            }
            if (onDownload != null && downloading) DownloadProgressRing(progressPct)
        }
    }
}

/**
 * A download running, where the download key was: the ring stands at the key's size, is named for what it reports
 * (downloading) and is not a key. The ring carries [progressPct], with the number inside it at the viewers' size
 * ([showPercent]); a download whose progress is not known yet (0) spins instead. The image preview, the video player
 * and the file card show the same ring, in [tint] at [ringSize].
 */
@Composable
internal fun DownloadProgressRing(
    progressPct: Int,
    tint: Color = Color.White,
    ringSize: androidx.compose.ui.unit.Dp = 40.dp,
    showPercent: Boolean = true,
) {
    val strings = flareStrings()
    val pct = progressPct.coerceIn(0, 100)
    Box(
        Modifier.size(FlareSizes.touchTarget).semantics(mergeDescendants = true) { contentDescription = strings.downloading },
        contentAlignment = Alignment.Center,
    ) {
        if (pct > 0) {
            CircularProgressIndicator(progress = { pct / 100f }, modifier = Modifier.size(ringSize), color = tint, strokeWidth = 2.dp)
            if (showPercent) {
                Text(
                    "$pct", color = tint,
                    fontSize = androidx.compose.ui.unit.TextUnit(10f, androidx.compose.ui.unit.TextUnitType.Sp),
                    modifier = Modifier.clearAndSetSemantics {},
                )
            }
        } else {
            CircularProgressIndicator(modifier = Modifier.size(ringSize), color = tint, strokeWidth = 2.dp)
        }
    }
}

/** An image that did not load: the broken-image mark, the reason, and retry when [onRetry] can help. */
@Composable
private fun ImagePreviewFailed(strings: FlareStrings, onRetry: (() -> Unit)?) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        Icon(Icons.Outlined.BrokenImage, null, Modifier.size(FlareSizes.iconSizeXl), tint = Color.White.copy(alpha = FlareOpacity.muted))
        Text(strings.imageLoadFailed, color = Color.White, fontSize = FlareSizes.fontSizeLg.value.sp, textAlign = TextAlign.Center)
        if (onRetry != null) Button(label = strings.retry, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Lg, onClick = onRetry)
    }
}

/** A white glyph on a translucent disc the size of the touch target — the same chrome as [VideoPlayer]'s close. */
@Composable
private fun CircleButton(control: FlareIconControlSpec, onClick: (() -> Unit)?) {
    FlareIconControl(label = control.label, onClick = onClick, enabled = control.enabled) {
        Box(Modifier.matchParentSize().clip(CircleShape).background(Color.White.copy(alpha = 0.25f)))
        Icon(flareIconVector(control.icon), null, tint = Color.White)
    }
}

/**
 * A paging key. At the first or the last image there is nowhere to go, and the key says so rather than disappearing
 * from TalkBack while still drawn: it stays named, is disabled and dims, as the other three kits' keys do.
 */
@Composable
private fun PagingButton(control: FlareIconControlSpec, onClick: (() -> Unit)?) {
    FlareIconControl(
        label = control.label,
        onClick = onClick ?: {},
        enabled = onClick != null,
        modifier = Modifier.alpha(if (onClick != null) 1f else FlareOpacity.disabled),
    ) {
        Box(Modifier.matchParentSize().clip(CircleShape).background(Color.White.copy(alpha = 0.25f)))
        Icon(flareIconVector(control.icon), null, tint = Color.White)
    }
}

/**
 * A conversation's image gallery: [ImagePreview] of one of [sources] at a time, starting at [initialIndex], paging to
 * its neighbours with the side controls or a sideways swipe, and saying where it is. Each image opens fresh at normal
 * size. With [onDownload] the download key downloads the image on screen (its index in [sources]); the key follows
 * [stateOf] that page — progress while it downloads, and once saved the folder that hands the page to [onReveal].
 */
@Composable
internal fun ImageGalleryPreview(
    sources: List<String>,
    initialIndex: Int,
    onClose: () -> Unit,
    onDownload: ((Int) -> Unit)? = null,
    onReveal: ((Int) -> Unit)? = null,
    stateOf: (Int) -> FlareMediaDownloadState? = { null },
) {
    if (sources.isEmpty()) return
    var index by remember(sources) { mutableIntStateOf(initialIndex.coerceIn(0, sources.lastIndex)) }
    val state = stateOf(index)
    key(index) {
        ImagePreview(
            show = true,
            imageSrc = sources[index],
            downloading = state?.isDownloading == true,
            progressPct = state?.progressPct ?: 0,
            onClose = onClose,
            onDownload = onDownload?.let { download -> { download(index) } },
            galleryIndex = index,
            galleryCount = sources.size,
            onPrevious = if (index > 0) ({ index -= 1 }) else null,
            onNext = if (index < sources.lastIndex) ({ index += 1 }) else null,
            saved = state?.isSaved == true,
            onReveal = onReveal?.let { reveal -> { reveal(index) } },
        )
    }
}
