package com.flare.im.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.abs
import kotlin.math.sin

/** Active voice-recording overlay. Spec: Composer/VoiceRecordingBar. */
@Composable
fun VoiceRecordingBar(
    durationLabel: String,
    amplitudes: List<Double> = emptyList(),
    cancelling: Boolean = false,
    onCancel: (() -> Unit)? = null,
    onSend: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val n = 28
    val samples = if (amplitudes.isNotEmpty()) amplitudes
    else List(n) { 0.2 + 0.5 * abs(sin(it * 0.7)) }
    val bars = List(n) { samples[it % samples.size] }
    val accent = if (cancelling) colors.error else colors.primary

    val blink = rememberInfiniteTransition(label = "rec")
    val dotAlpha by blink.animateFloat(
        initialValue = 1f, targetValue = 0.25f,
        animationSpec = infiniteRepeatable(tween(1100), RepeatMode.Reverse), label = "dot",
    )

    Row(
        Modifier.clip(RoundedCornerShape(999.dp))
            .background(if (cancelling) colors.error.copy(alpha = 0.1f) else colors.bgPrimary)
            .border(1.dp, if (cancelling) colors.error.copy(alpha = 0.4f) else colors.borderPrimary, RoundedCornerShape(999.dp))
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            Modifier.size(36.dp).clip(CircleShape)
                .background(if (cancelling) colors.error else colors.bgSecondary)
                .clickable { onCancel?.invoke() },
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.DeleteOutline, contentDescription = flareStrings().cancel,
                tint = if (cancelling) Color.White else colors.textSecondary, modifier = Modifier.size(18.dp))
        }
        Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(Modifier.size(9.dp).clip(CircleShape).background(colors.error.copy(alpha = dotAlpha)))
            Text(durationLabel, color = colors.textPrimary, fontSize = 13.sp)
            Row(
                Modifier.weight(1f).height(24.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                bars.forEach { a ->
                    Box(
                        Modifier.weight(1f).height((4 + a * 20).dp)
                            .clip(RoundedCornerShape(2.dp)).background(accent.copy(alpha = 0.7f)),
                    )
                }
            }
        }
        if (cancelling) {
            Text(flareStrings().releaseToCancel, color = colors.error, fontWeight = FontWeight.Medium, fontSize = 12.sp,
                modifier = Modifier.padding(end = 4.dp))
        } else {
            Box(
                Modifier.size(36.dp).clip(CircleShape).background(colors.primary).clickable { onSend?.invoke() },
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.AutoMirrored.Outlined.Send, contentDescription = flareStrings().send, tint = Color.White, modifier = Modifier.size(18.dp))
            }
        }
    }
}
