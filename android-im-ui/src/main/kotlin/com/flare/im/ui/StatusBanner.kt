package com.flare.im.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Semantic tone of a [StatusBanner]. */
enum class FlareStatusTone { Info, Success, Warning, Danger, Neutral }

/**
 * A compact status strip (connection / sync / runtime state) with an optional
 * pulsing dot and an optional inline action. Spec: General/StatusBanner
 * (`StatusBanner`).
 */
@Composable
fun StatusBanner(
    text: String,
    tone: FlareStatusTone = FlareStatusTone.Info,
    dot: Boolean = true,
    pulse: Boolean = false,
    actionText: String? = null,
    onAction: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val toneColor = statusToneColor(colors, tone)
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(toneColor.copy(alpha = 0.10f))
            .border(1.dp, toneColor.copy(alpha = 0.24f), RoundedCornerShape(FlareSizes.radiusLg))
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (dot) {
            val dotAlpha = if (pulse) {
                val transition = rememberInfiniteTransition(label = "status-pulse")
                val a by transition.animateFloat(
                    initialValue = 1f,
                    targetValue = 0.35f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(700),
                        repeatMode = RepeatMode.Reverse,
                    ),
                    label = "status-pulse-alpha",
                )
                a
            } else {
                1f
            }
            Spacer(
                Modifier
                    .size(FlareSizes.spacingSm)
                    .alpha(dotAlpha)
                    .clip(CircleShape)
                    .background(toneColor),
            )
            Spacer(Modifier.width(FlareSizes.spacingSm))
        }
        Text(
            text,
            color = toneColor,
            fontSize = FlareSizes.fontSizeMd.value.sp,
            modifier = Modifier.weight(1f),
        )
        if (actionText != null) {
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Text(
                actionText,
                color = toneColor,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                fontWeight = FontWeight.SemiBold,
                textDecoration = TextDecoration.Underline,
                modifier = Modifier.clickable { onAction?.invoke() },
            )
        }
    }
}

internal fun statusToneColor(colors: FlareColors, tone: FlareStatusTone): Color = when (tone) {
    FlareStatusTone.Info -> colors.info
    FlareStatusTone.Success -> colors.success
    FlareStatusTone.Warning -> colors.warning
    FlareStatusTone.Danger -> colors.error
    FlareStatusTone.Neutral -> colors.textSecondary
}
