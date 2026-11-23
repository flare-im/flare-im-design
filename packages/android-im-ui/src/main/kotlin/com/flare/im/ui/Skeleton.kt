package com.flare.im.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.unit.dp

/**
 * Loading skeleton placeholders. Spec: Feedback/Skeleton. [Card], [List] and [Form] are the plugin page archetypes'
 * (R8 of docs/plugin-experience.md): one `component.skeletonCardHeight` card, list-height rows, labelled field placeholders;
 * [Tile] is a "+" panel tile still loading (4.1).
 */
enum class SkeletonVariant { Conversation, Message, Profile, Text, Card, List, Form, Tile }

@Composable
fun Skeleton(
    variant: SkeletonVariant = SkeletonVariant.Conversation,
    rows: Int = 4,
    still: Boolean = false,
) {
    val colors = flareColors()
    val transition = rememberInfiniteTransition(label = "skeleton")
    val progress by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(durationMillis = 1200), RepeatMode.Restart),
        label = "shimmer",
    )
    val brush: Brush = if (still) {
        SolidColor(colors.bgSecondary)
    } else {
        val x = progress * 600f - 300f
        Brush.linearGradient(
            colors = listOf(colors.bgSecondary, colors.bgHover, colors.bgSecondary),
            start = Offset(x, 0f),
            end = Offset(x + 300f, 0f),
        )
    }
    when (variant) {
        SkeletonVariant.Conversation -> Column(Modifier.fillMaxWidth()) {
            repeat(rows) {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacing2sm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    skBlock(Modifier.size(FlareSizes.avatarSize), brush, CircleShape)
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                        skBlock(Modifier.fillMaxWidth(0.42f).height(11.dp), brush)
                        skBlock(Modifier.fillMaxWidth(0.68f).height(11.dp), brush)
                    }
                    Spacer(Modifier.width(FlareSizes.spacingSm))
                    skBlock(Modifier.width(34.dp).height(11.dp), brush)
                }
            }
        }

        SkeletonVariant.Message -> Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingLg),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
        ) {
            val fractions = listOf(0.6f, 0.45f, 0.7f, 0.5f, 0.65f)
            repeat(rows) { i ->
                val fraction = fractions[i % fractions.size]
                if (i % 2 == 0) {
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
                        skBlock(Modifier.size(32.dp), brush, CircleShape)
                        Spacer(Modifier.width(FlareSizes.spacingSm))
                        skBlock(
                            Modifier.fillMaxWidth(fraction).height(40.dp),
                            brush,
                            RoundedCornerShape(FlareSizes.radiusLg),
                        )
                    }
                } else {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                        skBlock(
                            Modifier.fillMaxWidth(fraction).height(40.dp),
                            brush,
                            RoundedCornerShape(FlareSizes.radiusLg),
                        )
                    }
                }
            }
        }

        SkeletonVariant.Profile -> Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingXl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
        ) {
            skBlock(Modifier.size(72.dp), brush, CircleShape)
            skBlock(Modifier.fillMaxWidth(0.4f).height(15.dp), brush)
            skBlock(Modifier.fillMaxWidth(0.6f).height(11.dp), brush)
        }

        SkeletonVariant.Card -> skBlock(Modifier.fillMaxWidth().height(FlareSizes.componentSkeletonCardHeight), brush, RoundedCornerShape(FlareSizes.radiusCard))

        // A "+" panel tile still loading (4.1): the icon square and its label line.
        SkeletonVariant.Tile -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
            skBlock(Modifier.size(FlareSizes.componentComposerActionWidth), brush, RoundedCornerShape(FlareSizes.radiusLg))
            skBlock(Modifier.width(32.dp).height(9.dp), brush)
        }

        SkeletonVariant.List -> Column(Modifier.fillMaxWidth()) {
            repeat(rows) {
                Row(
                    Modifier.fillMaxWidth().height(52.dp).padding(horizontal = FlareSizes.spacingLg),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                        skBlock(Modifier.fillMaxWidth(0.5f).height(11.dp), brush)
                        skBlock(Modifier.fillMaxWidth(0.3f).height(9.dp), brush)
                    }
                    skBlock(Modifier.width(56.dp).height(11.dp), brush)
                }
            }
        }

        SkeletonVariant.Form -> Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingLg),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
        ) {
            repeat(rows) {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                    skBlock(Modifier.fillMaxWidth(0.3f).height(11.dp), brush)
                    skBlock(Modifier.fillMaxWidth().height(FlareSizes.controlHeightLg), brush, RoundedCornerShape(FlareSizes.radiusLg))
                }
            }
        }

        SkeletonVariant.Text -> Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingLg),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2sm),
        ) {
            val fractions = listOf(0.9f, 0.75f, 0.85f, 0.6f, 0.8f)
            repeat(rows) { i ->
                skBlock(Modifier.fillMaxWidth(fractions[i % fractions.size]).height(11.dp), brush)
            }
        }
    }
}

@Composable
private fun skBlock(modifier: Modifier, brush: Brush, shape: Shape = RoundedCornerShape(FlareSizes.radiusSm)) {
    Box(modifier.clip(shape).background(brush))
}
