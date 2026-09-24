package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Hold-to-talk voice button (语音) — a composable composer part. Press and hold
 * to record, release to send; the host owns recording via the callbacks.
 */
@Suppress("NAME_SHADOWING")
@Composable
fun FlareVoiceHoldButton(
    label: String? = null,
    recordingLabel: String? = null,
    cancelLabel: String? = null,
    cancelThreshold: Float = 80f,
    onStart: (() -> Unit)? = null,
    onEnd: (() -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val label = label ?: strings.voiceHoldButtonLabel
    val recordingLabel = recordingLabel ?: strings.voiceHoldButtonRecording
    val cancelLabel = cancelLabel ?: strings.voiceHoldButtonCancel
    val colors = flareColors()
    var pressing by remember { mutableStateOf(false) }
    var willCancel by remember { mutableStateOf(false) }
    val haptics = LocalHapticFeedback.current
    val bg = if (!pressing) colors.bgSecondary else if (willCancel) colors.error else colors.primary
    Box(
        Modifier.fillMaxWidth().height(FlareSizes.componentComposerActionHeight)
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(bg)
            .pointerInput(cancelThreshold) {
                val cancelPx = cancelThreshold * density
                awaitEachGesture {
                    val down = awaitFirstDown()
                    pressing = true
                    willCancel = false
                    onStart?.invoke()
                    var cancelled = false
                    while (true) {
                        val event = awaitPointerEvent()
                        val change = event.changes.firstOrNull { it.id == down.id } ?: break
                        // Sliding up past the threshold from the press origin arms cancel.
                        val c = (change.position.y - down.position.y) < -cancelPx
                        // Sliding past the line changes what letting go means, so it is felt as well as seen.
                        if (flareHapticCrossed(willCancel, c)) haptics.flareHapticTick()
                        if (c != willCancel) willCancel = c
                        cancelled = c
                        if (!change.pressed) break
                    }
                    pressing = false
                    willCancel = false
                    if (cancelled) onCancel?.invoke() else onEnd?.invoke()
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        Text(
            if (!pressing) label else if (willCancel) cancelLabel else recordingLabel,
            color = if (pressing) Color.White else colors.textSecondary,
            fontSize = FlareSizes.fontSizeLg.value.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}

/**
 * The composer's bottom function area (下方功能区) — an inline grid of attachment
 * actions. Composable part; wrap in `AnimatedVisibility` to expand under the
 * input, or use standalone. Shares [FlareComposerAction] with the action sheet.
 */
@Composable
fun FlareComposerActionPanel(
    actions: List<FlareComposerAction>? = null,
    capabilities: FlareComposerCapabilities = FlareComposerCapabilities(),
    columns: Int = 4,
    onAction: ((FlareComposerAction) -> Unit)? = null,
) {
    val colors = flareColors()
    val resolvedActions = resolveComposerActions(defaultComposerActions(), capabilities, actions)
    Column(Modifier.fillMaxWidth().background(colors.bgPrimary).padding(FlareSizes.spacingLg)) {
        resolvedActions.chunked(columns).forEach { row ->
            Row(
                Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingLg),
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
            ) {
                row.forEach { action ->
                    Column(
                        Modifier.weight(1f).alpha(if (action.enabled) 1f else FlareOpacity.disabled)
                            .clickable(enabled = action.enabled) { onAction?.invoke(action) },
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Box(
                            Modifier.size(FlareSizes.componentComposerActionWidth).clip(RoundedCornerShape(FlareSizes.radiusLg))
                                .background(Color.Transparent),
                            contentAlignment = Alignment.Center,
                        ) { FlareIcon(name = action.icon, size = 20.dp, tint = colors.textPrimary, contentDescription = action.accessibilityLabel ?: action.label) }
                        Spacer(Modifier.size(FlareSizes.spacingXs))
                        Text(action.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeXs.value.sp)
                    }
                }
                repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}

/**
 * Send button (发送) — a composable composer part. Theme primary when active,
 * disabled otherwise; fires onSend only when active.
 */
/**
 * Send — a paper plane, and nothing else.
 *
 * It used to be a filled brand disc with a white glyph inside. Sending is the
 * same kind of act as every other key in the tool row — one tap, one outcome —
 * so it is drawn the same way, and only colour says which one sends: the brand
 * at rest against the row, faded while there is nothing to send. That is also
 * what [Composer]'s own send key does, and the two must not drift.
 */
@Composable
fun FlareComposerSendButton(active: Boolean, onSend: (() -> Unit)? = null) {
    val colors = flareColors()
    Box(
        Modifier.size(FlareSizes.componentComposerActionWidth).clickable(enabled = active) { onSend?.invoke() },
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.AutoMirrored.Filled.Send, flareStrings().send, Modifier.size(20.dp),
            tint = colors.primaryText.copy(alpha = if (active) 1f else 0.38f),
        )
    }
}

/**
 * Reply strip (回复条) — a composable composer part shown above the input when
 * replying. Left brand rail + sender / summary + cancel.
 */
@Suppress("NAME_SHADOWING")
@Composable
fun FlareComposerReplyStrip(
    senderName: String,
    summary: String,
    label: String? = null,
    onCancel: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val label = label ?: strings.composerReplyStripLabel
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(colors.messageReplyBackground),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(3.dp).height(36.dp).background(colors.messageReplyBorder))
        Column(
            Modifier.weight(1f).padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
        ) {
            Text(
                "$label $senderName", color = colors.primaryText,
                fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold,
            )
            Text(summary, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1)
        }
        Box(
            Modifier.padding(end = FlareSizes.spacingSm).size(18.dp).clickable { onCancel?.invoke() },
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Rounded.Close, flareStrings().cancelReply, Modifier.size(18.dp), tint = colors.textTertiary) }
    }
}
