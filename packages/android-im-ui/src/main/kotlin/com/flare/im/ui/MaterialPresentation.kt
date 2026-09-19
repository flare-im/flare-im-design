package com.flare.im.ui

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

internal fun flareMaterialColorScheme(colors: FlareColors, dark: Boolean): ColorScheme {
    val base = if (dark) darkColorScheme() else lightColorScheme()
    return base.copy(
        primary = colors.primary, onPrimary = Color.White,
        primaryContainer = colors.bgSelected, onPrimaryContainer = colors.textPrimary,
        secondary = colors.info, onSecondary = Color.White,
        secondaryContainer = colors.bgSelected, onSecondaryContainer = colors.textPrimary,
        tertiary = colors.success, onTertiary = Color.White,
        tertiaryContainer = colors.bgSecondary, onTertiaryContainer = colors.textPrimary,
        background = colors.bgSecondary, onBackground = colors.textPrimary,
        surface = colors.bgPrimary, onSurface = colors.textPrimary,
        surfaceVariant = colors.bgTertiary, onSurfaceVariant = colors.textSecondary,
        surfaceTint = colors.primary,
        error = colors.error, onError = Color.White,
        errorContainer = colors.messageFailedBackground, onErrorContainer = colors.messageFailedForeground,
        outline = colors.borderPrimary, outlineVariant = colors.borderSecondary,
        surfaceDim = colors.bgSecondary, surfaceBright = colors.bgPrimary,
        surfaceContainerLowest = colors.bgPrimary, surfaceContainerLow = colors.bgSecondary,
        surfaceContainer = colors.bgSecondary, surfaceContainerHigh = colors.bgTertiary,
        surfaceContainerHighest = colors.bgElevated,
    )
}

internal fun flareMaterialTypography(): Typography {
    fun style(size: TextUnit, weight: FontWeight = FontWeight.Normal) = TextStyle(
        fontSize = size, fontWeight = weight,
        lineHeight = size * FlareSizes.lineHeightNormal, letterSpacing = 0.sp,
    )
    return Typography(
        displayLarge = style(FlareSizes.fontSize4xl, FontWeight.SemiBold),
        displayMedium = style(FlareSizes.fontSize4xl, FontWeight.SemiBold),
        displaySmall = style(FlareSizes.fontSize3xl, FontWeight.SemiBold),
        headlineLarge = style(FlareSizes.fontSize4xl, FontWeight.SemiBold),
        headlineMedium = style(FlareSizes.fontSize3xl, FontWeight.SemiBold),
        headlineSmall = style(FlareSizes.fontSize2xl, FontWeight.SemiBold),
        titleLarge = style(FlareSizes.fontSize3xl, FontWeight.Bold),
        titleMedium = style(FlareSizes.fontSize2xl, FontWeight.SemiBold),
        titleSmall = style(FlareSizes.fontSizeLg, FontWeight.Medium),
        bodyLarge = style(FlareSizes.fontSizeXl),
        bodyMedium = style(FlareSizes.fontSizeLg, FontWeight.Medium),
        bodySmall = style(FlareSizes.fontSizeSm),
        labelLarge = style(FlareSizes.fontSizeLg, FontWeight.SemiBold),
        labelMedium = style(FlareSizes.fontSizeSm, FontWeight.SemiBold),
        labelSmall = style(FlareSizes.fontSizeXs, FontWeight.SemiBold),
    )
}
