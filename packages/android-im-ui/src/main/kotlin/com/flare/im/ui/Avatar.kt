package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.People
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import kotlin.math.roundToInt

/** Presence state shown as a corner dot on [Avatar]. */
enum class FlarePresence { Online, Offline, Busy, Away }

/** Which layer [Avatar] paints inside the circle. */
internal enum class AvatarSource { Slot, Url, Initials }

/**
 * Resolution order shared with the other three platforms: an explicit [image]
 * slot wins, then a non-blank [avatarUrl] (loaded with Coil, initials shown
 * while loading / on error), else deterministic initials.
 */
internal fun avatarSource(hasImageSlot: Boolean, avatarUrl: String?): AvatarSource = when {
    hasImageSlot -> AvatarSource.Slot
    !avatarUrl.isNullOrBlank() -> AvatarSource.Url
    else -> AvatarSource.Initials
}

/**
 * Round user avatar — deterministic initials fallback plus an optional presence
 * dot. Spec: General/Avatar (`Avatar`).
 *
 * [avatarUrl] is loaded with the bundled Coil (same prop name as Vue/Flutter;
 * iOS spells it `avatarURL`). An explicit [image] slot takes precedence over the
 * url; with neither, initials are shown.
 */
@Composable
fun Avatar(
    userId: String,
    displayName: String,
    size: Dp = FlareSizes.avatarSize,
    presence: FlarePresence? = null,
    image: (@Composable () -> Unit)? = null,
    avatarUrl: String? = null,
    /** A group's avatar: a people mark in the corner, in place of the presence dot a group never has (Vue `group`). */
    group: Boolean = false,
) {
    val colors = flareColors()
    // Seed by the stable display name (not the id, which varies by surface — peer
    // id vs conversation id vs sender id) so a person is one colour everywhere:
    // list, chat header, message bubbles.
    val tint = seedTint(displayName.ifEmpty { userId })
    Box(contentAlignment = Alignment.BottomEnd, modifier = Modifier.size(size)) {
        Box(
            modifier = Modifier.size(size).clip(CircleShape).background(tint.first),
            contentAlignment = Alignment.Center,
        ) {
            val initialsText: @Composable () -> Unit = {
                Text(
                    initials(displayName),
                    color = tint.second,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = (size.value * 0.4f).sp,
                )
            }
            when (avatarSource(image != null, avatarUrl)) {
                AvatarSource.Slot -> image?.invoke()
                AvatarSource.Url -> SubcomposeAsyncImage(
                    model = avatarUrl,
                    contentDescription = displayName.ifEmpty { userId },
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize(),
                    loading = { Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { initialsText() } },
                    error = { Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { initialsText() } },
                )
                AvatarSource.Initials -> initialsText()
            }
        }
        if (group) {
            // The avatar's palette inverted, ringed in the surface colour so it stands off any tint or photo; the filled
            // two-person glyph, since an outlined one at this size is a smudge.
            val mark = (size.value * 0.45f).roundToInt().dp
            Box(
                Modifier
                    .offset(3.dp, 3.dp)
                    .size(mark)
                    .clip(CircleShape)
                    .background(colors.bgPrimary)
                    .padding(2.dp)
                    .clip(CircleShape)
                    .background(tint.second),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Filled.People,
                    contentDescription = flareStrings().displayNameGroup,
                    tint = tint.first,
                    modifier = Modifier.size((mark.value * 0.5f).roundToInt().dp),
                )
            }
        } else if (presence != null) {
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

/** The first character of the name, as on the web and iOS (one glyph, so "Lab Bob" is "L", not "LB"). */
internal fun initials(name: String): String {
    val trimmed = name.trim()
    if (trimmed.isEmpty()) return "?"
    return trimmed.substring(0, trimmed.offsetByCodePoints(0, 1)).uppercase()
}

/**
 * Soft pastel identity — matches the reference app (avatarPastelForKey): a
 * tinted surface + dark initials reads more premium than a saturated solid and
 * stays legible in both themes. Returns (background, foreground).
 */
@Composable
internal fun seedTint(seed: String): Pair<Color, Color> = seedTint(seed, flareColors())

/**
 * The palette comes from the token source (`colors.avatarTint.*`): the same six pairs on four
 * platforms, **with a dark set**. This used to be six light hex literals, so in dark mode an avatar
 * sat on the dark surface like a pastel macaron — only the web had a dark variant. The order is part
 * of the contract (the seed's hash picks a slot), and follows the token file's insertion order.
 *
 * Kept free of composition so the choice can be unit-tested: the composable overload above only
 * supplies the current theme's colours.
 */
internal fun seedTint(seed: String, colors: FlareColors): Pair<Color, Color> {
    val pairs = listOf(
        colors.avatarTintBlueBg to colors.avatarTintBlueFg,
        colors.avatarTintPurpleBg to colors.avatarTintPurpleFg,
        colors.avatarTintPinkBg to colors.avatarTintPinkFg,
        colors.avatarTintGreenBg to colors.avatarTintGreenFg,
        colors.avatarTintAmberBg to colors.avatarTintAmberFg,
        colors.avatarTintSlateBg to colors.avatarTintSlateFg,
    )
    return pairs[avatarTintIndex(seed)]
}

/**
 * The palette slot for [seed], the Vue kit's `avatarTint` (`shared/avatar-tint.ts`) to the bit, so one name is one colour
 * on every kit: JS `hash = code + ((hash << 5) - hash)` over the seed's code points (each one's first UTF-16 unit), the
 * shift on `ToInt32(hash)` while the sum stays a double; a blank seed hashes `"user"`; slot `abs(hash) % 6`.
 */
internal fun avatarTintIndex(seed: String): Int {
    val source = if (seed.isBlank()) "user" else seed
    var hash = 0.0
    var i = 0
    while (i < source.length) {
        hash = source[i].code + ((hash.toLong().toInt() shl 5).toDouble() - hash)
        i += Character.charCount(source.codePointAt(i))
    }
    return (kotlin.math.abs(hash) % 6).toInt()
}

internal fun presenceColor(colors: FlareColors, presence: FlarePresence): Color = when (presence) {
    FlarePresence.Online -> colors.success
    FlarePresence.Busy -> colors.error
    FlarePresence.Away -> colors.warning
    FlarePresence.Offline -> colors.textTertiary
}
