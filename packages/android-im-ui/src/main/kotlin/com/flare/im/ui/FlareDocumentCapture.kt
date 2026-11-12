package com.flare.im.ui

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.LiveRegionMode
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
    BottomSheet(onClose = onCancel, title = flareDocumentSideLabel(strings, side), fill = true) {
        FlareDocumentCaptureBody(side, maxBytes, onDone, accept, preview, capture, pickPhoto, cameraUnavailable)
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
) {
    val colors = flareColors()
    val strings = flareStrings()
    val scope = rememberCoroutineScope()
    var phase by remember(side) { mutableStateOf<CapturePhase>(CapturePhase.Viewfinder) }
    val camera = capture != null && !cameraUnavailable
    val processing = phase == CapturePhase.Processing
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
    Column(Modifier.fillMaxSize().padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
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
                Box(
                    Modifier.padding(FlareSizes.spacingLg).aspectRatio(side.frameAspect)
                        .border(2.dp, light, RoundedCornerShape(FlareSizes.radiusMd)).testTag("flare-doc-frame"),
                )
                if (cameraUnavailable) Text(strings.documentCaptureCameraUnavailable, color = light, fontSize = FlareSizes.fontSizeMd,
                    textAlign = TextAlign.Center, modifier = Modifier.align(Alignment.BottomCenter).padding(FlareSizes.spacingLg))
            }
        }
        val message = when (val p = phase) {
            CapturePhase.Processing -> strings.documentCaptureProcessing to false
            is CapturePhase.Failed -> when (p.error) {
                FlareDocumentProcessError.TooLarge -> strings.documentCaptureTooLarge
                FlareDocumentProcessError.NotAccepted -> strings.documentCaptureNotAccepted
                FlareDocumentProcessError.Failed -> strings.documentCaptureFailed
            } to true
            CapturePhase.Viewfinder -> when (side) {
                FlareDocumentSide.Front -> strings.documentCaptureHintFront
                FlareDocumentSide.Back -> strings.documentCaptureHintBack
                FlareDocumentSide.Holding -> strings.documentCaptureHintHolding
            } to false
            is CapturePhase.Review -> null
        }
        if (message != null) Text(message.first, color = if (message.second) colors.errorText else colors.textSecondary,
            fontSize = FlareSizes.fontSizeMd, textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().semantics { liveRegion = LiveRegionMode.Polite }
                .then(if (message.second) Modifier.testTag("flare-doc-error") else Modifier))
        Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            val shown = phase
            if (shown is CapturePhase.Review) {
                Button(label = strings.documentCaptureUse, size = FlareControlSize.Lg, block = true,
                    onClick = { phase = CapturePhase.Viewfinder; onDone(shown.file) })
                Button(label = strings.documentCaptureRetake, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Lg, block = true,
                    onClick = { phase = CapturePhase.Viewfinder })
            } else {
                if (camera) Button(label = strings.documentCaptureShoot, size = FlareControlSize.Lg, loading = processing, block = true,
                    onClick = { take(capture) })
                if (pickPhoto != null) Button(label = strings.documentCaptureFromAlbum,
                    variant = if (camera) FlareButtonVariant.Secondary else FlareButtonVariant.Primary, size = FlareControlSize.Lg,
                    disabled = processing, block = true, onClick = { take(pickPhoto) })
            }
        }
    }
}
