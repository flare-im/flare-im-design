package com.flare.im.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.abs
import kotlin.math.sin

/** The icon-only controls of a [VoiceRecordingBar]: cancel, and send unless the gesture is already cancelling. */
internal fun voiceRecordingBarControls(strings: FlareStrings, cancelling: Boolean): List<FlareIconControlSpec> = buildList {
    add(FlareIconControlSpec("cancel", "delete", strings.voiceRecordingCancel))
    if (!cancelling) add(FlareIconControlSpec("send", "send", strings.voiceRecordingSend))
}

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
    val strings = flareStrings()
    val controls = voiceRecordingBarControls(strings, cancelling).associateBy { it.id }
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

    // The two discs are drawn at 36 dp inside 48 dp touch targets. The bar's padding and spacing give
    // back the 6 dp a side the targets add, so the bar keeps its 52 dp height and its visual insets.
    Row(
        Modifier.clip(RoundedCornerShape(999.dp))
            .background(if (cancelling) colors.error.copy(alpha = 0.1f) else colors.bgPrimary)
            .border(1.dp, if (cancelling) colors.error.copy(alpha = 0.4f) else colors.borderPrimary, RoundedCornerShape(999.dp))
            .padding(horizontal = FlareSizes.spacingXs, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        val cancel = controls.getValue("cancel")
        FlareIconControl(label = cancel.label, onClick = onCancel) {
            Box(Modifier.size(36.dp).clip(CircleShape).background(if (cancelling) colors.error else colors.bgSecondary))
            Icon(flareIconVector(cancel.icon), contentDescription = null,
                tint = if (cancelling) Color.White else colors.textSecondary, modifier = Modifier.size(18.dp))
        }
        Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
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
        val send = controls["send"]
        if (send == null) {
            Text(strings.releaseToCancel, color = colors.errorText, fontWeight = FontWeight.Medium, fontSize = 12.sp,
                modifier = Modifier.padding(start = FlareSizes.spacing2xs, end = FlareSizes.spacing2sm))
        } else {
            FlareIconControl(label = send.label, onClick = onSend) {
                Box(Modifier.size(36.dp).clip(CircleShape).background(Brush.linearGradient(listOf(colors.primary, colors.primaryActive))))
                Icon(flareIconVector(send.icon), contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
            }
        }
    }
}
