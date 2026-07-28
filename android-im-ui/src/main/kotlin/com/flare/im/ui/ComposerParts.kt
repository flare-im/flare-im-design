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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
@Composable
fun FlareVoiceHoldButton(
    label: String = "按住 说话",
    recordingLabel: String = "松开发送 · 上滑取消",
    cancelLabel: String = "松开取消",
    cancelThreshold: Float = 80f,
    onStart: (() -> Unit)? = null,
    onEnd: (() -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var pressing by remember { mutableStateOf(false) }
    var willCancel by remember { mutableStateOf(false) }
    val bg = if (!pressing) colors.bgSecondary else if (willCancel) colors.error else colors.primary
    Box(
        Modifier.fillMaxWidth().height(40.dp)
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
    actions: List<FlareComposerAction> = defaultComposerActions,
    columns: Int = 4,
    onAction: ((FlareComposerAction) -> Unit)? = null,
) {
    val colors = flareColors()
    Column(Modifier.fillMaxWidth().background(colors.bgPrimary).padding(FlareSizes.spacingLg)) {
        actions.chunked(columns).forEach { row ->
            Row(
                Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingLg),
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
            ) {
                row.forEach { action ->
                    Column(
                        Modifier.weight(1f).clickable { onAction?.invoke(action) },
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Box(
                            Modifier.size(52.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                                .background(colors.bgSecondary),
                            contentAlignment = Alignment.Center,
                        ) { androidx.compose.material3.Icon(action.icon, null, Modifier.size(24.dp), tint = colors.textPrimary) }
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
 * Send button (发送) — a composable composer part. Brand-purple when active,
 * disabled otherwise; fires onSend only when active.
 */
@Composable
fun FlareComposerSendButton(active: Boolean, onSend: (() -> Unit)? = null) {
    val colors = flareColors()
    Box(
        Modifier.size(34.dp).clip(RoundedCornerShape(999.dp))
            .background(if (active) colors.primary else colors.bgDisabled)
            .clickable(enabled = active) { onSend?.invoke() },
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.AutoMirrored.Filled.Send, flareStrings().send, Modifier.size(16.dp),
            tint = if (active) Color.White else colors.textDisabled,
        )
    }
}

/**
 * Reply strip (回复条) — a composable composer part shown above the input when
 * replying. Left brand rail + sender / summary + cancel.
 */
@Composable
fun FlareComposerReplyStrip(
    senderName: String,
    summary: String,
    label: String = "回复",
    onCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(colors.bgSecondary),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(3.dp).height(36.dp).background(colors.primary))
        Column(
            Modifier.weight(1f).padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
        ) {
            Text(
                "$label $senderName", color = colors.primary,
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
