// GENERATED. Do not edit by hand. Source: @flare-im/tokens/tokens.json
package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Flare IM design colours, theme-aware. Prefer [flareColors]. */
data class FlareColors(
    val auroraDeep: Color,
    val auroraBase: Color,
    val auroraSoft: Color,
    val auroraMist: Color,
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
            auroraDeep = Color(0xFF391F7A),
            auroraBase = Color(0xFF7047D6),
            auroraSoft = Color(0xFF9C7EE7),
            auroraMist = Color(0xFFCCBBF7),
            bgDisabled = Color(0xFFF1F2F5),
            bgElevated = Color(0xFFFFFFFF),
            bgHover = Color(0xFFF1F2F5),
            bgPrimary = Color(0xFFFFFFFF),
            bgSecondary = Color(0xFFF7F8FA),
            bgSelected = Color(0xFFF0ECFC),
            bgTertiary = Color(0xFFF1F2F5),
            borderHover = Color(0xFFC9CDD7),
            borderPrimary = Color(0xFFE3E5EB),
            borderSecondary = Color(0xFFECEEF2),
            borderSelected = Color(0xFF7C3AED),
            bubbleOther = Color(0xFFFFFFFF),
            bubbleRobot = Color(0xFFF1F2F5),
            bubbleSelf = Color(0xFF7047D6),
            bubbleSystem = Color(0xFFF1F2F5),
            error = Color(0xFFEF4444),
            focusRing = Color(0x597047D6),
            important = Color(0xFFF59E0B),
            info = Color(0xFF6D5DF6),
            pinned = Color(0xFF7047D6),
            primary = Color(0xFF7047D6),
            primaryActive = Color(0xFF512CAC),
            primaryHover = Color(0xFF6138C4),
            robot = Color(0xFF64748B),
            success = Color(0xFF22C55E),
            textDisabled = Color(0xFFB7BDC8),
            textLink = Color(0xFF7047D6),
            textLinkHover = Color(0xFF6138C4),
            textPrimary = Color(0xFF20232D),
            textSecondary = Color(0xFF626978),
            textTertiary = Color(0xFF687182),
            warning = Color(0xFFF59E0B),
        )
        val Dark = FlareColors(
            auroraDeep = Color(0xFF391F7A),
            auroraBase = Color(0xFF7047D6),
            auroraSoft = Color(0xFF9C7EE7),
            auroraMist = Color(0xFFCCBBF7),
            bgDisabled = Color(0xFF292D37),
            bgElevated = Color(0xFF292D37),
            bgHover = Color(0x0FFFFFFF),
            bgPrimary = Color(0xFF20232B),
            bgSecondary = Color(0xFF17191F),
            bgSelected = Color(0x337C3AED),
            bgTertiary = Color(0xFF292D37),
            borderHover = Color(0x29FFFFFF),
            borderPrimary = Color(0x1AFFFFFF),
            borderSecondary = Color(0x14FFFFFF),
            borderSelected = Color(0xFFA78BFA),
            bubbleOther = Color(0xFF20232B),
            bubbleRobot = Color(0xFF292D37),
            bubbleSelf = Color(0xFF7047D6),
            bubbleSystem = Color(0xFF292D37),
            error = Color(0xFFEF4444),
            focusRing = Color(0x66A78BFA),
            important = Color(0xFFF59E0B),
            info = Color(0xFF6D5DF6),
            pinned = Color(0xFF7047D6),
            primary = Color(0xFF7047D6),
            primaryActive = Color(0xFF512CAC),
            primaryHover = Color(0xFF6138C4),
            robot = Color(0xFF64748B),
            success = Color(0xFF22C55E),
            textDisabled = Color(0x47FFFFFF),
            textLink = Color(0xFFC4B5FD),
            textLinkHover = Color(0xFF6138C4),
            textPrimary = Color(0xF0FFFFFF),
            textSecondary = Color(0x9EFFFFFF),
            textTertiary = Color(0xFF9AA3B3),
            warning = Color(0xFFF59E0B),
        )
    }
}

@Composable
fun flareColors(): FlareColors =
    LocalFlareColors.current ?: if (isSystemInDarkTheme()) FlareColors.Dark else FlareColors.Light

private val LocalFlareColors = staticCompositionLocalOf<FlareColors?> { null }

/** Wrap the app with the same resolved dark flag as its MaterialTheme. */
@Composable
fun FlareThemeProvider(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalFlareColors provides if (dark) FlareColors.Dark else FlareColors.Light, content = content)
}

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
    val avatarSize: Dp = 44.dp
    val headerHeight: Dp = 60.dp
    val leftPanel: Dp = 320.dp
    val rightPanel: Dp = 300.dp
    val sessionItemHeight: Dp = 72.dp
    val dualPaneMinWidth: Dp = 720.dp
    val triplePaneMinWidth: Dp = 1100.dp
    val chatMinWidth: Dp = 360.dp
    val touchTarget: Dp = 48.dp
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

/** Shared logical-dp layout policy. Use the available container, excluding rail and insets. */
object FlareLayoutPolicy {
    fun paneCount(width: Float, hasDetail: Boolean = false, textScale: Float = 1f,
                  listWidth: Float = FlareSizes.leftPanel.value, detailWidth: Float = FlareSizes.rightPanel.value): Int {
        val chat = FlareSizes.chatMinWidth.value * textScale.coerceIn(1f, 2f)
        val list = listWidth.coerceAtLeast(0f)
        val detail = detailWidth.coerceAtLeast(0f)
        if (hasDetail && width >= FlareSizes.triplePaneMinWidth.value && width >= list + detail + chat + 2) return 3
        if (width >= FlareSizes.dualPaneMinWidth.value && width >= list + chat + 1) return 2
        return 1
    }
}
