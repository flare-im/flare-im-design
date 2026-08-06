package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.math.sin

/** Rich voice playback bubble. Spec: Message/VoicePlayer. */
@Composable
fun VoicePlayer(
    durationLabel: String,
    elapsedLabel: String? = null,
    progress: Double = 0.0,
    playing: Boolean = false,
    amplitudes: List<Double> = emptyList(),
    speed: Double = 1.0,
    transcript: String? = null,
    transcriptOpen: Boolean = false,
    unplayed: Boolean = false,
    outbound: Boolean = false,
    onToggle: (() -> Unit)? = null,
    onSeek: ((Double) -> Unit)? = null,
    onCycleSpeed: (() -> Unit)? = null,
    onToggleTranscript: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val n = 32
    val samples = if (amplitudes.isNotEmpty()) amplitudes else List(n) { 0.25 + 0.6 * abs(sin(it * 0.6)) }
    val bars = List(n) { samples[it % samples.size] }
    val filled = (progress.coerceIn(0.0, 1.0) * n).roundToInt()
    val shape = if (outbound) RoundedCornerShape(16.dp, 16.dp, 4.dp, 16.dp) else RoundedCornerShape(16.dp, 16.dp, 16.dp, 4.dp)
    val speedText = if (speed % 1.0 == 0.0) "${speed.toInt()}×" else "${(speed * 10).roundToInt() / 10.0}×"

    Column(
        Modifier.clip(shape)
            .background(if (outbound) colors.bgSelected else colors.bgPrimary)
            .border(1.dp, if (outbound) colors.primary.copy(alpha = 0.24f) else colors.borderPrimary, shape)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(
                Modifier.size(36.dp).clip(CircleShape)
                    .background(Brush.linearGradient(listOf(colors.primary, colors.primaryActive)))
                    .clickable { onToggle?.invoke() },
                contentAlignment = Alignment.Center,
            ) {
                Icon(if (playing) Icons.Filled.Pause else Icons.Filled.PlayArrow, contentDescription = flareStrings().play,
                    tint = Color.White, modifier = Modifier.size(18.dp))
                if (unplayed && !playing) {
                    Box(Modifier.align(Alignment.TopEnd).size(8.dp).clip(CircleShape).background(colors.error))
                }
            }
            Row(
                Modifier.weight(1f).height(26.dp)
                    .pointerInput(Unit) {
                        detectTapGestures { pos -> onSeek?.invoke((pos.x / size.width).toDouble().coerceIn(0.0, 1.0)) }
                    },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                bars.forEachIndexed { i, a ->
                    Box(
                        Modifier.weight(1f).height((4 + a * 18).dp).clip(RoundedCornerShape(2.dp))
                            .background(if (i < filled) colors.primary else colors.borderHover),
                    )
                }
            }
            Text(if (playing && elapsedLabel != null) elapsedLabel else durationLabel,
                color = colors.textTertiary, fontSize = 12.sp)
            Text(speedText, color = colors.textSecondary, fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgSecondary)
                    .border(1.dp, colors.borderPrimary, RoundedCornerShape(999.dp))
                    .clickable { onCycleSpeed?.invoke() }.padding(horizontal = 8.dp, vertical = 2.dp))
        }
        if (transcript != null) {
            Row(
                Modifier.clickable { onToggleTranscript?.invoke() },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.Description, contentDescription = null, tint = colors.primary, modifier = Modifier.size(13.dp))
                Spacer(Modifier.width(4.dp))
                Text(if (transcriptOpen) flareStrings().hideTranscript else flareStrings().showTranscript, color = colors.primary, fontSize = 12.sp)
            }
            if (transcriptOpen) {
                Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
                Text(transcript, color = colors.textSecondary, fontSize = 13.sp, modifier = Modifier.padding(top = 2.dp))
            }
        }
    }
}
