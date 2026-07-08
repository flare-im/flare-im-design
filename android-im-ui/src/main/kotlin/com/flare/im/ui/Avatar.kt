package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Presence state shown as a corner dot on [Avatar]. */
enum class FlarePresence { Online, Offline, Busy, Away }

/**
 * Round user avatar — deterministic initials fallback plus an optional presence
 * dot. Spec: General/Avatar (`Avatar`).
 *
 * The package bundles no image-loading library; pass [image] to render a loaded
 * avatar (e.g. a Coil `AsyncImage`) — otherwise initials are shown.
 */
@Composable
fun Avatar(
    userId: String,
    displayName: String,
    size: Dp = FlareSizes.avatarSize,
    presence: FlarePresence? = null,
    image: (@Composable () -> Unit)? = null,
) {
    val colors = flareColors()
    val tint = seedTint(userId)
    Box(contentAlignment = Alignment.BottomEnd, modifier = Modifier.size(size)) {
        Box(
            modifier = Modifier.size(size).clip(CircleShape).background(tint.first),
            contentAlignment = Alignment.Center,
        ) {
            if (image != null) {
                image()
            } else {
                Text(
                    initials(displayName),
                    color = tint.second,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = (size.value * 0.4f).sp,
                )
            }
        }
        if (presence != null) {
            Box(
                Modifier
                    .size(size * 0.28f)
                    .clip(CircleShape)
                    .background(presenceColor(colors, presence))
                    .border(2.dp, colors.bgPrimary, CircleShape),
            )
        }
    }
}

internal fun initials(name: String): String {
    val parts = name.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
    if (parts.isEmpty()) return "?"
    if (parts.size == 1) return parts[0].take(1).uppercase()
    return (parts.first().take(1) + parts.last().take(1)).uppercase()
}

/**
 * Soft pastel identity — matches the reference app (avatarPastelForKey): a
 * tinted surface + dark initials reads more premium than a saturated solid and
 * stays legible in both themes. Returns (background, foreground).
 */
internal fun seedTint(seed: String): Pair<Color, Color> {
    val pairs = listOf(
        Color(0xFFDBEAFE) to Color(0xFF1D4ED8), // blue
        Color(0xFFE9D5FF) to Color(0xFF6D28D9), // purple
        Color(0xFFFBCFE8) to Color(0xFFBE185D), // pink
        Color(0xFFD1FAE5) to Color(0xFF047857), // green
        Color(0xFFFEF3C7) to Color(0xFFB45309), // amber
        Color(0xFFE5E7EB) to Color(0xFF374151), // slate
    )
    var hash = 0
    for (c in seed) hash = (hash * 31 + c.code) and 0x7fffffff
    return pairs[hash % pairs.size]
}

internal fun presenceColor(colors: FlareColors, presence: FlarePresence): Color = when (presence) {
    FlarePresence.Online -> colors.success
    FlarePresence.Busy -> colors.error
    FlarePresence.Away -> colors.warning
    FlarePresence.Offline -> colors.textTertiary
}
