package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

/** What a [FlareDocumentSlot] shows (DocumentSlot `state`). */
enum class FlareDocumentSlotState { Empty, Captured, Uploading, Failed }

/**
 * What TalkBack reads for a slot: its name and its state; the tap says what it does through the click label
 * ([flareDocumentSlotClickLabel]), so a captured slot reads "证件正面，已拍摄" and offers "double-tap to retake".
 */
internal fun flareDocumentSlotDescription(label: String, state: FlareDocumentSlotState, progress: Int?, strings: FlareStrings): String =
    when (state) {
        FlareDocumentSlotState.Empty -> "$label, ${strings.documentSlotTapToCapture}"
        FlareDocumentSlotState.Captured -> "$label, ${strings.documentSlotCaptured}"
        FlareDocumentSlotState.Uploading -> "$label, " + (progress?.let { strings.documentSlotUploading.replace("{percent}", it.coerceIn(0, 100).toString()) }
            ?: strings.pluginFileUploading)
        FlareDocumentSlotState.Failed -> "$label, ${strings.documentSlotUploadFailed}"
    }

/** What a slot's tap does, read after "double-tap to": take the photo, retake or retry; nothing while it uploads. */
internal fun flareDocumentSlotClickLabel(state: FlareDocumentSlotState, strings: FlareStrings): String? = when (state) {
    FlareDocumentSlotState.Empty -> strings.documentCaptureShoot
    FlareDocumentSlotState.Captured -> strings.documentCaptureRetake
    FlareDocumentSlotState.Failed -> strings.retry
    FlareDocumentSlotState.Uploading -> null
}

/** 6.3: the slots a row holds — two on a phone, three on a wide window. */
internal fun pluginDocumentColumns(phone: Boolean): Int = if (phone) 2 else 3

/**
 * Document slot — one capture tile for an ID photo (6.3 of docs/plugin-experience.md). Spec: Plugin/DocumentSlot
 * (`FlareDocumentSlot`). 16:10, at least `component.documentSlotHeight` high, on `color.bg.secondary` with a 1.5 dashed
 * `color.border.primary` edge and `radius.card` corners.
 *
 * Empty: the side's outline (front: a portrait box at the end; back: an emblem at the start; holding: a person and a
 * card), camera 24, [label] 14/600 and "tap to take a photo" 12 — a tap emits [onCapture]. Captured: [imageUrl] cover
 * (the host's file address; without one the outline stays) with a success badge and a retake strip — a tap captures
 * again. Uploading: a progress ring with the percent ([progress] 0–100). Failed: an error edge and "upload failed, tap
 * to retry" — a tap emits [onRetry]. [disabled] takes no taps (the form is submitting). One TalkBack node per slot.
 */
@Composable
fun FlareDocumentSlot(
    label: String,
    side: FlareDocumentSide,
    modifier: Modifier = Modifier,
    state: FlareDocumentSlotState = FlareDocumentSlotState.Empty,
    imageUrl: String? = null,
    progress: Int? = null,
    disabled: Boolean = false,
    onCapture: (() -> Unit)? = null,
    onRetry: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val shape = RoundedCornerShape(FlareSizes.radiusCard)
    val failed = state == FlareDocumentSlotState.Failed
    val tap = if (failed) onRetry else onCapture
    val edge = if (failed) colors.error else colors.borderPrimary
    Box(
        modifier.fillMaxWidth().aspectRatio(16f / 10f).heightIn(min = FlareSizes.componentDocumentSlotHeight)
            .clip(shape).background(colors.bgSecondary)
            .then(
                if (failed) Modifier.border(1.5.dp, edge, shape)
                else Modifier.drawBehind {
                    val radius = FlareSizes.radiusCard.toPx()
                    drawRoundRect(edge, cornerRadius = CornerRadius(radius),
                        style = Stroke(width = 1.5.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(FlareSizes.spacing2xs.toPx(), FlareSizes.spacingXs.toPx()))))
                },
            )
            .flareDimmed(if (disabled) FlareOpacity.disabled else 1f)
            .clickable(enabled = !disabled && tap != null && state != FlareDocumentSlotState.Uploading, role = Role.Button,
                onClickLabel = flareDocumentSlotClickLabel(state, strings)) { tap?.invoke() }
            .clearAndSetSemantics {
                contentDescription = flareDocumentSlotDescription(label, state, progress, strings)
                role = Role.Button
            },
        contentAlignment = Alignment.Center,
    ) {
        val photo = imageUrl?.takeIf { state != FlareDocumentSlotState.Empty }
        if (photo != null) {
            coil.compose.AsyncImage(model = photo, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        } else {
            FlareDocumentOutline(side, colors.borderPrimary, Modifier.fillMaxSize().padding(FlareSizes.spacingMd))
        }
        when (state) {
            FlareDocumentSlotState.Empty -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                FlareIcon("camera", size = FlareSizes.iconSizeLg, tint = colors.textSecondary)
                Text(label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
                Text(strings.documentSlotTapToCapture, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
            }
            FlareDocumentSlotState.Captured -> {
                Box(Modifier.align(Alignment.TopEnd).padding(FlareSizes.spacingSm)) {
                    FlareIcon("success", size = FlareSizes.iconSizeMd, tint = colors.successText)
                }
                Row(
                    Modifier.align(Alignment.BottomCenter).fillMaxWidth()
                        .background(Brush.verticalGradient(listOf(Color.Transparent, colors.mediaStageShade)))
                        .padding(vertical = FlareSizes.spacingXs),
                    horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
                ) {
                    FlareIcon("refresh", size = FlareSizes.iconSizeSm, tint = colors.mediaOnStage)
                    Text(strings.documentCaptureRetake, color = colors.mediaOnStage, fontSize = FlareSizes.fontSizeSm,
                        modifier = Modifier.padding(start = FlareSizes.spacing3xs))
                }
            }
            FlareDocumentSlotState.Uploading -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                val fraction = progress?.coerceIn(0, 100)?.div(100f)
                if (fraction != null) CircularProgressIndicator(progress = { fraction }, modifier = Modifier.size(FlareSizes.iconSizeXl), color = colors.primaryText, strokeWidth = 3.dp)
                else CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeXl), color = colors.primaryText, strokeWidth = 3.dp)
                progress?.let { Text("${it.coerceIn(0, 100)}%", color = colors.textPrimary, fontSize = FlareSizes.fontSizeSm, style = FlareTabularFigures) }
            }
            FlareDocumentSlotState.Failed -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                FlareIcon("error", size = FlareSizes.iconSizeLg, tint = colors.errorText)
                Text(strings.documentSlotUploadFailed, color = colors.errorText, fontSize = FlareSizes.fontSizeSm, textAlign = TextAlign.Center)
            }
        }
    }
}

/** The faint outline of the side to capture: front a portrait box at the end, back an emblem at the start, holding a person and a card. */
@Composable
private fun FlareDocumentOutline(side: FlareDocumentSide, ink: Color, modifier: Modifier) {
    Canvas(modifier) {
        val line = Stroke(width = 1.dp.toPx())
        val faint = ink.copy(alpha = 0.6f)
        when (side) {
            FlareDocumentSide.Front -> drawRoundRect(faint, Offset(size.width * 0.68f, size.height * 0.18f), Size(size.width * 0.22f, size.height * 0.5f), CornerRadius(FlareSizes.radiusBubbleTail.toPx()), style = line)
            FlareDocumentSide.Back -> drawCircle(faint, radius = size.height * 0.16f, center = Offset(size.width * 0.2f, size.height * 0.3f), style = line)
            FlareDocumentSide.Holding -> {
                drawCircle(faint, radius = size.height * 0.14f, center = Offset(size.width * 0.3f, size.height * 0.3f), style = line)
                drawRoundRect(faint, Offset(size.width * 0.55f, size.height * 0.5f), Size(size.width * 0.32f, size.width * 0.32f / FlareSizes.componentDocumentFrameRatio), CornerRadius(FlareSizes.radiusBubbleTail.toPx()), style = line)
            }
        }
    }
}

/** A document input's state as a slot shows it: uploaded is captured; selected and uploading wait; failed asks a retry. */
internal fun pluginDocumentSlotState(phase: PluginFilePhase?): FlareDocumentSlotState = when (phase) {
    PluginFilePhase.Uploaded -> FlareDocumentSlotState.Captured
    PluginFilePhase.Selected, PluginFilePhase.Uploading -> FlareDocumentSlotState.Uploading
    PluginFilePhase.Failed -> FlareDocumentSlotState.Failed
    PluginFilePhase.Empty, null -> FlareDocumentSlotState.Empty
}

/** 6.3: the photos a document form still needs — its required document inputs not uploaded yet. */
internal fun pluginDocumentsMissing(inputs: List<PluginInput>, phases: Map<String, PluginFilePhase?>): Int =
    inputs.count { it.kind == PluginInputKind.Document && it.required && phases[it.id] != PluginFilePhase.Uploaded }
