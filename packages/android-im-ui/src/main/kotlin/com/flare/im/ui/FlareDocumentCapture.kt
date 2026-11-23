package com.flare.im.ui

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

/** The side's name, as the document input names it. */
fun flareDocumentSideLabel(strings: FlareStrings, side: FlareDocumentSide): String = when (side) {
    FlareDocumentSide.Front -> strings.pluginFormDocumentFront
    FlareDocumentSide.Back -> strings.pluginFormDocumentBack
    FlareDocumentSide.Holding -> strings.pluginFormDocumentHolding
}

private sealed interface CapturePhase {
    data object Viewfinder : CapturePhase
    data object Processing : CapturePhase
    class Review(val file: FlareCapturedDocument) : CapturePhase
    class Failed(val error: FlareDocumentProcessError) : CapturePhase
}

/**
 * The document capture a host shows for the engine's captureDocument request (design 7.2 and 7.5; spec
 * Message/DocumentCapture). Composing it shows it in a kit [BottomSheet] that fills the height.
 *
 * The camera is the host's (CameraX): it passes its live [preview] and a [capture] that takes a still, so the kit never
 * asks for camera permission. The kit draws the viewfinder frame for the [side], the hint, review with use and retake,
 * and processes the photo: the EXIF orientation is applied to the pixels and the picture re-encoded as a JPEG with no
 * metadata that fits [maxBytes] ([FlareDocumentRules.process]). [onDone] hands over the file the host answers the
 * engine with (`{file}`).
 */
@Composable
fun FlareDocumentCapture(
    side: FlareDocumentSide,
    maxBytes: Int,
    onDone: (FlareCapturedDocument) -> Unit,
    onCancel: () -> Unit,
    accept: List<String> = emptyList(),
    preview: (@Composable () -> Unit)? = null,
    capture: (suspend () -> ByteArray?)? = null,
    pickPhoto: (suspend () -> ByteArray?)? = null,
    cameraUnavailable: Boolean = false,
) {
    val strings = flareStrings()
    val title = flareDocumentSideLabel(strings, side)
    // 6.4: while a photo is processed, back (and Esc, the scrim) does not cancel.
    var processing by remember { mutableStateOf(false) }
    val cancel = { if (!processing) onCancel() }
    // 6.4: a phone captures full screen on the media stage; a wide window in a dialog of component.capturePreviewWidth.
    if (flareCompactOverlays()) androidx.compose.ui.window.Dialog(
        onDismissRequest = cancel,
        properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        // Laid out under the bars (else the window sits below the status bar and the shutter row falls off screen).
        FlareEdgeToEdgeDialogWindow()
        Box(Modifier.fillMaxSize().background(flareColors().mediaStage).statusBarsPadding().navigationBarsPadding()
            .semantics { paneTitle = title }) {
            FlareDocumentCaptureBody(side, maxBytes, onDone, accept, preview, capture, pickPhoto, cameraUnavailable, onCancel,
                onProcessing = { processing = it })
        }
    } else Modal(onClose = cancel, title = title, width = FlareSizes.componentCapturePreviewWidth, fill = true, scrollable = false,
        dismissible = !processing) {
        FlareDocumentCaptureBody(side, maxBytes, onDone, accept, preview, capture, pickPhoto, cameraUnavailable, onCancel, wide = true,
            onProcessing = { processing = it })
    }
}

@Composable
internal fun FlareDocumentCaptureBody(
    side: FlareDocumentSide,
    maxBytes: Int,
    onDone: (FlareCapturedDocument) -> Unit,
    accept: List<String> = emptyList(),
    preview: (@Composable () -> Unit)? = null,
    capture: (suspend () -> ByteArray?)? = null,
    pickPhoto: (suspend () -> ByteArray?)? = null,
    cameraUnavailable: Boolean = false,
    onCancel: (() -> Unit)? = null,
    /** A wide window picks a file rather than an album photo. */
    wide: Boolean = false,
    /** Whether a photo is being processed (the surface around it then ignores back). */
    onProcessing: ((Boolean) -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val scope = rememberCoroutineScope()
    var phase by remember(side) { mutableStateOf<CapturePhase>(CapturePhase.Viewfinder) }
    val camera = capture != null && !cameraUnavailable
    val processing = phase == CapturePhase.Processing
    val reportProcessing by rememberUpdatedState(onProcessing)
    LaunchedEffect(processing) { reportProcessing?.invoke(processing) }
    // A camera stage stays dark in both themes (the media stage tokens).
    val stage = colors.mediaStage
    val light = colors.mediaOnStage
    fun take(source: (suspend () -> ByteArray?)?) {
        if (source == null || processing) return
        scope.launch {
            val photo = source() ?: return@launch
            phase = CapturePhase.Processing
            phase = try {
                CapturePhase.Review(FlareDocumentRules.process(photo, side, maxBytes, accept))
            } catch (e: FlareDocumentProcessException) {
                CapturePhase.Failed(e.error)
            } catch (e: Exception) {
                CapturePhase.Failed(FlareDocumentProcessError.Failed)
            }
        }
    }
    val error = (phase as? CapturePhase.Failed)?.let {
        when (it.error) {
            FlareDocumentProcessError.TooLarge -> strings.documentCaptureTooLarge
            FlareDocumentProcessError.NotAccepted -> strings.documentCaptureNotAccepted
            FlareDocumentProcessError.Failed -> strings.documentCaptureFailed
        }
    }
    // 6.4: the capture is a camera stage, dark in both themes.
    Column(Modifier.fillMaxSize().background(stage).padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        // 6.4: a failure says why above the stage and the viewfinder comes back.
        error?.let {
            Box(Modifier.fillMaxWidth().semantics { liveRegion = LiveRegionMode.Polite }.testTag("flare-doc-error")) {
                StatusBanner(text = it, tone = FlareStatusTone.Danger)
            }
        }
        Box(
            Modifier.fillMaxWidth().weight(1f).clip(RoundedCornerShape(FlareSizes.radiusLg)).background(stage),
            contentAlignment = Alignment.Center,
        ) {
            val shown = phase
            if (shown is CapturePhase.Review) {
                val bitmap = remember(shown) { BitmapFactory.decodeByteArray(shown.file.bytes, 0, shown.file.bytes.size) }
                if (bitmap != null) Image(bitmap.asImageBitmap(), contentDescription = flareDocumentSideLabel(strings, side),
                    contentScale = ContentScale.Fit, modifier = Modifier.fillMaxSize().testTag("flare-doc-review"))
            } else {
                preview?.invoke()
                FlareDocumentViewfinder(side, colors.mediaStageShade, light, Modifier.fillMaxSize().testTag("flare-doc-frame"))
                Column(
                    Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(FlareSizes.spacingLg),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                ) {
                    when {
                        cameraUnavailable -> {
                            FlareIcon("camera-off", size = FlareSizes.iconSizeXl, tint = light)
                            Text(strings.documentCaptureCameraUnavailable, color = light, fontSize = FlareSizes.fontSizeXl, textAlign = TextAlign.Center)
                        }
                        processing -> {
                            androidx.compose.material3.CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeXl), color = light, strokeWidth = 2.dp)
                            Text(strings.documentCaptureProcessing, color = light, fontSize = FlareSizes.fontSizeXl, textAlign = TextAlign.Center,
                                modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
                        }
                        else -> {
                            Text(when (side) {
                                FlareDocumentSide.Front -> strings.documentCaptureHintFront
                                FlareDocumentSide.Back -> strings.documentCaptureHintBack
                                FlareDocumentSide.Holding -> strings.documentCaptureHintHolding
                            }, color = light, fontSize = FlareSizes.fontSizeXl, textAlign = TextAlign.Center)
                            Text(strings.documentCaptureHintGlare, color = light.copy(alpha = 0.72f), fontSize = FlareSizes.fontSizeMd, textAlign = TextAlign.Center)
                        }
                    }
                }
            }
        }
        val shown = phase
        if (shown is CapturePhase.Review) {
            // The preview's two keys share the row: retake, then use.
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                Box(Modifier.weight(1f)) {
                    Button(label = strings.documentCaptureRetake, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Lg, block = true,
                        onClick = { phase = CapturePhase.Viewfinder })
                }
                Box(Modifier.weight(1f)) {
                    Button(label = strings.documentCaptureUse, size = FlareControlSize.Lg, block = true,
                        onClick = { phase = CapturePhase.Viewfinder; onDone(shown.file) })
                }
            }
        } else {
            // Album at the start, the shutter in the middle, cancel at the end.
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
                    if (pickPhoto != null) FlareStageKey(if (wide) strings.pluginFileChoose else strings.documentCaptureFromAlbum, "image", light, enabled = !processing) { take(pickPhoto) }
                }
                if (camera) FlareCaptureShutter(strings.documentCaptureShoot, enabled = !processing) { take(capture) }
                Box(Modifier.weight(1f), contentAlignment = Alignment.CenterEnd) {
                    if (onCancel != null) FlareStageKey(strings.cancel, null, light, enabled = !processing, onClick = onCancel)
                }
            }
        }
    }
}

/**
 * The viewfinder over the camera (6.4): the area outside the frame shaded with `colors.media.stageShade` and four 3-wide,
 * 24-long corner marks; front and back an ID-1 frame (`component.documentFrameRatio`) as wide as the stage less
 * `spacing.2xl` each side; holding a face oval (half the width) above and a card frame (60%) lower right.
 */
@Composable
internal fun FlareDocumentViewfinder(side: FlareDocumentSide, shade: androidx.compose.ui.graphics.Color, mark: androidx.compose.ui.graphics.Color, modifier: Modifier = Modifier) {
    androidx.compose.foundation.Canvas(modifier) {
        val gutter = FlareSizes.spacing2xl.toPx()
        val ratio = FlareSizes.componentDocumentFrameRatio
        val card: androidx.compose.ui.geometry.Rect
        val face: androidx.compose.ui.geometry.Rect?
        if (side == FlareDocumentSide.Holding) {
            val faceWidth = size.width * 0.5f
            face = androidx.compose.ui.geometry.Rect(androidx.compose.ui.geometry.Offset((size.width - faceWidth) / 2, size.height * 0.08f),
                androidx.compose.ui.geometry.Size(faceWidth, faceWidth * 1.25f))
            val cardWidth = size.width * 0.6f
            val cardHeight = cardWidth / ratio
            card = androidx.compose.ui.geometry.Rect(androidx.compose.ui.geometry.Offset(size.width - cardWidth - gutter, face.bottom + gutter / 2),
                androidx.compose.ui.geometry.Size(cardWidth, cardHeight))
        } else {
            face = null
            val width = (size.width - gutter * 2).coerceAtLeast(0f)
            val height = width / ratio
            card = androidx.compose.ui.geometry.Rect(androidx.compose.ui.geometry.Offset(gutter, (size.height - height) / 2 - gutter),
                androidx.compose.ui.geometry.Size(width, height))
        }
        val hole = androidx.compose.ui.graphics.Path().apply {
            addRoundRect(androidx.compose.ui.geometry.RoundRect(card, androidx.compose.ui.geometry.CornerRadius(FlareSizes.radiusMd.toPx())))
            face?.let { addOval(it) }
        }
        clipPath(hole, androidx.compose.ui.graphics.ClipOp.Difference) { drawRect(shade) }
        val stroke = FlareSizes.componentCaptureFrameStroke.toPx()
        val arm = 24.dp.toPx()
        fun corner(x: Float, y: Float, dx: Float, dy: Float) {
            drawLine(mark, androidx.compose.ui.geometry.Offset(x, y), androidx.compose.ui.geometry.Offset(x + dx * arm, y), stroke)
            drawLine(mark, androidx.compose.ui.geometry.Offset(x, y), androidx.compose.ui.geometry.Offset(x, y + dy * arm), stroke)
        }
        corner(card.left, card.top, 1f, 1f); corner(card.right, card.top, -1f, 1f)
        corner(card.left, card.bottom, 1f, -1f); corner(card.right, card.bottom, -1f, -1f)
        face?.let { drawOval(mark, it.topLeft, it.size, style = androidx.compose.ui.graphics.drawscope.Stroke(width = 2.dp.toPx())) }
    }
}

/** The shutter (6.4): a white `component.captureShutterSize` disc in a 4-wide ring, named for TalkBack. */
@Composable
internal fun FlareCaptureShutter(label: String, enabled: Boolean, onClick: () -> Unit) {
    val colors = flareColors()
    Box(
        Modifier.size(FlareSizes.componentCaptureShutterSize).clip(androidx.compose.foundation.shape.CircleShape)
            .border(4.dp, colors.mediaOnStage, androidx.compose.foundation.shape.CircleShape)
            .padding(FlareSizes.spacing2xs).clip(androidx.compose.foundation.shape.CircleShape).background(colors.mediaOnStage)
            .flareDimmed(if (enabled) 1f else FlareOpacity.disabled)
            .clickable(enabled = enabled, role = androidx.compose.ui.semantics.Role.Button, onClickLabel = label, onClick = onClick)
            .semantics { contentDescription = label },
    )
}

/** A text key on the camera stage (album, cancel): light ink, a 48 target. */
@Composable
private fun FlareStageKey(label: String, icon: String?, ink: androidx.compose.ui.graphics.Color, enabled: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.heightIn(min = FlareSizes.touchTarget).flareDimmed(if (enabled) 1f else FlareOpacity.disabled)
            .clickable(enabled = enabled, role = androidx.compose.ui.semantics.Role.Button, onClick = onClick)
            .padding(horizontal = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        icon?.let { FlareIcon(it, size = FlareSizes.iconSizeMd, tint = ink) }
        Text(label, color = ink, fontSize = FlareSizes.fontSizeLg)
    }
}
