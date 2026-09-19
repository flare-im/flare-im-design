package com.flare.im.ui

import androidx.compose.ui.unit.sp
import kotlin.test.Test
import kotlin.test.assertEquals

class MaterialPresentationTest {
    @Test fun materialColorsFollowEveryBrandAndAppearance() {
        for (brand in FlareBrandTheme.entries) for (dark in listOf(false, true)) {
            val colors = FlareColors.resolve(brand, dark)
            val material = flareMaterialColorScheme(colors, dark)
            assertEquals(colors.primary, material.primary)
            assertEquals(colors.bgPrimary, material.surface)
            assertEquals(colors.textPrimary, material.onSurface)
            assertEquals(colors.bgTertiary, material.surfaceContainerHigh)
            assertEquals(colors.borderPrimary, material.outline)
        }
        val custom = FlareColors.Light.copy(primary = FlareColors.ForestLight.primary)
        assertEquals(custom.primary, flareMaterialColorScheme(custom, false).primary)
    }

    @Test fun materialTypographyUsesTokenSizesAndNoTracking() {
        val type = flareMaterialTypography()
        assertEquals(FlareSizes.fontSize4xl, type.headlineLarge.fontSize)
        assertEquals(FlareSizes.fontSize3xl, type.titleLarge.fontSize)
        assertEquals(FlareSizes.fontSizeXl, type.bodyLarge.fontSize)
        assertEquals(FlareSizes.fontSizeSm, type.bodySmall.fontSize)
        assertEquals(type.bodyLarge.fontSize * FlareSizes.lineHeightNormal, type.bodyLarge.lineHeight)
        for (style in listOf(type.displayLarge, type.displayMedium, type.displaySmall,
            type.headlineLarge, type.headlineMedium, type.headlineSmall,
            type.titleLarge, type.titleMedium, type.titleSmall, type.bodyLarge,
            type.bodyMedium, type.bodySmall, type.labelLarge, type.labelMedium, type.labelSmall)) {
            assertEquals(0.sp, style.letterSpacing)
        }
    }
}
