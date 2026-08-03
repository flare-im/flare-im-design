// GENERATED. Do not edit by hand. Source: @flare-im/tokens/tokens.json
package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Flare IM design colours, theme-aware. Prefer [flareColors]. */
data class FlareColors(
    val bgDisabled: Color,
    val bgElevated: Color,
    val bgHover: Color,
    val bgPrimary: Color,
    val bgSecondary: Color,
    val bgSelected: Color,
    val bgTertiary: Color,
    val borderHover: Color,
    val borderPrimary: Color,
    val borderSecondary: Color,
    val borderSelected: Color,
    val bubbleOther: Color,
    val bubbleRobot: Color,
    val bubbleSelf: Color,
    val bubbleSystem: Color,
    val error: Color,
    val focusRing: Color,
    val important: Color,
    val info: Color,
    val pinned: Color,
    val primary: Color,
    val primaryActive: Color,
    val primaryHover: Color,
    val robot: Color,
    val success: Color,
    val textDisabled: Color,
    val textLink: Color,
    val textLinkHover: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val warning: Color,
) {
    companion object {
        val Light = FlareColors(
            bgDisabled = Color(0xFFF3F1F9),
            bgElevated = Color(0xFFFFFFFF),
            bgHover = Color(0xFFF1EEF8),
            bgPrimary = Color(0xFFFFFFFF),
            bgSecondary = Color(0xFFF6F5FB),
            bgSelected = Color(0xFFF1EAFF),
            bgTertiary = Color(0xFFF3F1F9),
            borderHover = Color(0xFFDAD5E7),
            borderPrimary = Color(0xFFE9E6F1),
            borderSecondary = Color(0xFFF0EDF7),
            borderSelected = Color(0xFF7C3AED),
            bubbleOther = Color(0xFFECE5FF),
            bubbleRobot = Color(0xFFF4F0FF),
            bubbleSelf = Color(0xFF7C3AED),
            bubbleSystem = Color(0xFFF3F1F9),
            error = Color(0xFFEF4444),
            focusRing = Color(0x597C3AED),
            important = Color(0xFFF59E0B),
            info = Color(0xFF6D5DF6),
            pinned = Color(0xFF7C3AED),
            primary = Color(0xFF7C3AED),
            primaryActive = Color(0xFF5B21B6),
            primaryHover = Color(0xFF6D28D9),
            robot = Color(0xFF64748B),
            success = Color(0xFF22C55E),
            textDisabled = Color(0xFFCCC8D8),
            textLink = Color(0xFF7C3AED),
            textLinkHover = Color(0xFF6D28D9),
            textPrimary = Color(0xFF15131C),
            textSecondary = Color(0xFF6B6780),
            textTertiary = Color(0xFFA7A2B4),
            warning = Color(0xFFF59E0B),
        )
        val Dark = FlareColors(
            bgDisabled = Color(0xFF272334),
            bgElevated = Color(0xFF221E30),
            bgHover = Color(0x0FFFFFFF),
            bgPrimary = Color(0xFF1B1922),
            bgSecondary = Color(0xFF131019),
            bgSelected = Color(0x337C3AED),
            bgTertiary = Color(0xFF232030),
            borderHover = Color(0x29FFFFFF),
            borderPrimary = Color(0x1AFFFFFF),
            borderSecondary = Color(0x14FFFFFF),
            borderSelected = Color(0xFFA78BFA),
            bubbleOther = Color(0xFF241D33),
            bubbleRobot = Color(0xFF2B2340),
            bubbleSelf = Color(0xFF8B5CF6),
            bubbleSystem = Color(0xFF232030),
            error = Color(0xFFEF4444),
            focusRing = Color(0x66A78BFA),
            important = Color(0xFFF59E0B),
            info = Color(0xFF6D5DF6),
            pinned = Color(0xFF7C3AED),
            primary = Color(0xFF7C3AED),
            primaryActive = Color(0xFF5B21B6),
            primaryHover = Color(0xFF6D28D9),
            robot = Color(0xFF64748B),
            success = Color(0xFF22C55E),
            textDisabled = Color(0x47FFFFFF),
            textLink = Color(0xFFC4B5FD),
            textLinkHover = Color(0xFF6D28D9),
            textPrimary = Color(0xF0FFFFFF),
            textSecondary = Color(0x9EFFFFFF),
            textTertiary = Color(0x66FFFFFF),
            warning = Color(0xFFF59E0B),
        )
    }
}

@Composable
fun flareColors(): FlareColors =
    if (isSystemInDarkTheme()) FlareColors.Dark else FlareColors.Light

/** Flare IM spacing / radius / font-size / line-height / layout tokens. */
object FlareSizes {
    val fontSize2xl: Dp = 16.dp
    val fontSize3xl: Dp = 18.dp
    val fontSize4xl: Dp = 20.dp
    val fontSizeLg: Dp = 14.dp
    val fontSizeMd: Dp = 13.dp
    val fontSizeSm: Dp = 12.dp
    val fontSizeXl: Dp = 15.dp
    val fontSizeXs: Dp = 11.dp
    val avatarSize: Dp = 42.dp
    val headerHeight: Dp = 60.dp
    val leftPanel: Dp = 260.dp
    val rightPanel: Dp = 300.dp
    val sessionItemHeight: Dp = 68.dp
    val lineHeightNormal: Dp = 1.5.dp
    val lineHeightRelaxed: Dp = 1.6.dp
    val lineHeightTight: Dp = 1.2.dp
    val radius2xl: Dp = 18.dp
    val radiusFull: Dp = 999.dp
    val radiusLg: Dp = 10.dp
    val radiusMd: Dp = 8.dp
    val radiusSm: Dp = 6.dp
    val radiusXl: Dp = 14.dp
    val radiusXs: Dp = 3.dp
    val spacing2xl: Dp = 24.dp
    val spacingLg: Dp = 16.dp
    val spacingMd: Dp = 12.dp
    val spacingSm: Dp = 8.dp
    val spacingXl: Dp = 20.dp
    val spacingXs: Dp = 4.dp
}
