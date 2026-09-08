package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.tan

/**
 * Flare 品牌 Logo 呈现方式。
 * - [Gradient]: 品牌渐变 squircle + 白色 F(中性/浅底、app 图标)。
 * - [Plate]: 白色 squircle + 品牌渐变 F(品牌色背景上,如登录头)。
 */
enum class FlareBrandLogoVariant { Gradient, Plate }

/**
 * Flare 品牌 Logo(通用件,归属 kit)。前倾几何 F(skewX -9°),取自品牌色阶,四端共用同一几何。
 * Spec: Brand/BrandLogo。
 */
@Composable
fun FlareBrandLogo(
    size: Dp = 64.dp,
    variant: FlareBrandLogoVariant = FlareBrandLogoVariant.Gradient,
) {
    val kc = flareColors()
    val grad = Brush.linearGradient(listOf(kc.primaryActive, kc.primary, kc.info))
    val plate = variant == FlareBrandLogoVariant.Plate
    Box(
        Modifier.size(size)
            .shadow(size * 0.25f, RoundedCornerShape(size * 0.28f))
            .clip(RoundedCornerShape(size * 0.28f))
            .then(if (plate) Modifier.background(Color.White) else Modifier.background(grad)),
        Alignment.Center,
    ) {
        Canvas(Modifier.fillMaxSize()) {
            val s = this.size.minDimension / 100f
            val p = Path().apply {
                addRoundRect(RoundRect(Rect(28f * s, 22f * s, 43f * s, 80f * s), CornerRadius(7f * s)))
                addRoundRect(RoundRect(Rect(28f * s, 22f * s, 72f * s, 37f * s), CornerRadius(7f * s)))
                addRoundRect(RoundRect(Rect(28f * s, 45f * s, 62f * s, 58f * s), CornerRadius(6f * s)))
            }
            val k = tan(-9.0 * PI / 180.0).toFloat()
            val ap = p.asAndroidPath()
            val m = android.graphics.Matrix()
            m.setValues(floatArrayOf(1f, k, -k * (this.size.height / 2f), 0f, 1f, 0f, 0f, 0f, 1f))
            ap.transform(m)
            if (plate) drawPath(p, grad) else drawPath(p, Color.White)
        }
    }
}
