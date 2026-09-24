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
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/** Typing indicator — bouncing dots. Spec: Message/TypingIndicator. */
enum class TypingVariant { Bubble, Inline }

@Composable
fun TypingIndicator(
    names: List<String> = emptyList(),
    userId: String? = null,
    avatarUrl: String? = null,
    variant: TypingVariant = TypingVariant.Bubble,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val clean = names.filter { it.isNotEmpty() }
    val label = when {
        clean.isEmpty() -> strings.typing
        clean.size == 1 -> strings.typingOne(clean[0])
        else -> strings.typingMany(clean.size)
    }
    val isBubble = variant == TypingVariant.Bubble
    val dotColor = if (isBubble) colors.primary.copy(alpha = 0.65f) else colors.textTertiary

    val transition = rememberInfiniteTransition(label = "typing")
    val body: @Composable () -> Unit = {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (variant == TypingVariant.Inline || names.isNotEmpty()) {
                Text(label, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp)
                Spacer(Modifier.width(8.dp))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs), verticalAlignment = Alignment.CenterVertically) {
                repeat(3) { i ->
                    val y by transition.animateFloat(
                        initialValue = 0f, targetValue = -4f,
                        animationSpec = infiniteRepeatable(
                            tween(durationMillis = 600, delayMillis = i * 150), RepeatMode.Reverse),
                        label = "dot$i",
                    )
                    Box(Modifier.offset(y = y.dp).size(6.dp).clip(CircleShape).background(dotColor))
                }
            }
        }
    }

    if (!isBubble) {
        body()
    } else {
        Row(verticalAlignment = Alignment.Bottom) {
            Avatar(
                userId = names.firstOrNull() ?: (userId ?: "typing"),
                displayName = names.firstOrNull() ?: (userId ?: "typing"), size = 32.dp,
                image = avatarUrl?.let { url ->
                    { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
                },
            )
            Spacer(Modifier.width(FlareSizes.spacingSm))
            // 一个形状同时给填充和描边。从前这两处各写一遍,而且尾角写反了(描边把
            // 尖角放在左上、填充放在左下),1dp 的线于是画在背景没填到的形状上。
            val bubbleShape = RoundedCornerShape(
                FlareSizes.radiusBubble, FlareSizes.radiusBubble,
                FlareSizes.radiusBubble, FlareSizes.radiusBubbleTail,
            )
            Box(
                Modifier.clip(bubbleShape)
                    .background(colors.bgPrimary)
                    .border(1.dp, colors.borderPrimary, bubbleShape)
                    .padding(horizontal = FlareSizes.spacing2md, vertical = FlareSizes.spacing2sm),
            ) { body() }
        }
    }
}
