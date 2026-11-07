package com.flare.im.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.IntOffset
import kotlin.math.roundToInt

/** The sliding fill's share of the track. */
private const val FLARE_PROGRESS_SLIDE_SHARE = 0.4f

/** One pass of the sliding fill, the kit's looping pace. */
private const val FLARE_PROGRESS_SLIDE_MS = 1400

/**
 * A linear progress bar: a value from 0 to 1, or a sliding fill while the length of the work is not known.
 * Spec: Feedback/ProgressBar (`ProgressBar`).
 *
 * A value that is missing or not finite reads as indeterminate (`spec/update-prompt-vectors.json`, the same in every
 * kit). TalkBack reads [label] and the number. Under reduced motion the indeterminate fill stands still and muted.
 */
@Composable
fun ProgressBar(
    /** How far along, 0 to 1. */
    value: Double? = null,
    modifier: Modifier = Modifier,
    /** The length of the work is not known: the fill slides instead. */
    indeterminate: Boolean = false,
    /** What the colour says. */
    tone: FlareProgressBarTone = FlareProgressBarTone.Primary,
    /** What is progressing, for a screen reader. */
    label: String? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val reducedMotion = flareReducedMotion()
    val shown = flareProgressBarValue(value, indeterminate)
    val fraction = shown.value
    val name = label ?: strings.progressBarLabel
    val valueText = shown.percent?.let { "$it%" } ?: strings.progressBarLoading
    val fill: Color = when (tone) {
        FlareProgressBarTone.Primary -> colors.primaryText
        FlareProgressBarTone.Success -> colors.successText
        FlareProgressBarTone.Warning -> colors.warningText
        FlareProgressBarTone.Danger -> colors.errorText
        FlareProgressBarTone.Neutral -> colors.textSecondary
    }
    val shape = RoundedCornerShape(FlareSizes.radiusFull)
    BoxWithConstraints(
        modifier.fillMaxWidth()
            .height(FlareSizes.spacingXs)
            .clip(shape)
            .background(colors.bgTertiary)
            .semantics(mergeDescendants = true) {
                contentDescription = name
                stateDescription = valueText
                progressBarRangeInfo = if (fraction == null) {
                    ProgressBarRangeInfo.Indeterminate
                } else {
                    ProgressBarRangeInfo(fraction.toFloat(), 0f..1f)
                }
            },
    ) {
        when {
            fraction != null -> Box(Modifier.fillMaxHeight().fillMaxWidth(fraction.toFloat()).clip(shape).background(fill))
            reducedMotion -> Box(Modifier.fillMaxSize().flareDimmed(FlareOpacity.muted).background(fill))
            else -> {
                val transition = rememberInfiniteTransition(label = "flareProgressBar")
                val position by transition.animateFloat(
                    initialValue = -FLARE_PROGRESS_SLIDE_SHARE,
                    targetValue = 1f,
                    animationSpec = infiniteRepeatable(tween(FLARE_PROGRESS_SLIDE_MS, easing = LinearEasing)),
                    label = "flareProgressBarSlide",
                )
                val track = maxWidth
                Box(
                    Modifier.fillMaxHeight()
                        .width(track * FLARE_PROGRESS_SLIDE_SHARE)
                        // The lambda form follows the layout direction.
                        .offset { IntOffset((track.toPx() * position).roundToInt(), 0) }
                        .clip(shape)
                        .background(fill),
                )
            }
        }
    }
}
