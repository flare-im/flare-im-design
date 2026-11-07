package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.tan

/** Shared italic IM mark, with either a violet plate or a white plate. */
enum class FlareBrandLogoVariant { Gradient, Plate }

/** Canonical 100×100 geometry matches the Vue, Flutter and SwiftUI brand mark. */
@Composable
fun FlareBrandLogo(
    size: Dp = 64.dp,
    variant: FlareBrandLogoVariant = FlareBrandLogoVariant.Gradient,
) {
    val colors = flareColors()
    val plate = variant == FlareBrandLogoVariant.Plate
    Canvas(Modifier.size(size).semantics { contentDescription = "IM" }) {
        scale(this.size.minDimension / 100f, pivot = Offset.Zero) {
            val gradient = Brush.linearGradient(
                listOf(colors.primaryActive, colors.primary, colors.info),
                start = Offset.Zero, end = Offset(100f, 100f),
            )
            val silhouette = Path().apply {
                moveTo(50f, 3f)
                cubicTo(12f, 3f, 3f, 12f, 3f, 50f)
                cubicTo(3f, 88f, 12f, 97f, 50f, 97f)
                cubicTo(88f, 97f, 97f, 88f, 97f, 50f)
                cubicTo(97f, 12f, 88f, 3f, 50f, 3f)
                close()
            }
            if (plate) drawPath(silhouette, Color.White) else drawPath(silhouette, gradient)
            val letters = Path().apply {
                moveTo(22f, 27f); lineTo(32f, 27f); lineTo(32f, 75f); lineTo(22f, 75f); close()
                moveTo(40f, 75f); lineTo(40f, 27f); lineTo(50f, 27f); lineTo(60f, 48f)
                lineTo(70f, 27f); lineTo(80f, 27f); lineTo(80f, 75f); lineTo(70f, 75f)
                lineTo(70f, 48f); lineTo(60f, 65f); lineTo(50f, 48f); lineTo(50f, 75f); close()
            }
            val skew = tan(-9.0 * PI / 180.0).toFloat()
            letters.asAndroidPath().transform(android.graphics.Matrix().apply {
                setValues(floatArrayOf(1f, skew, -skew * 51f, 0f, 1f, 0f, 0f, 0f, 1f))
            })
            if (plate) drawPath(letters, gradient) else drawPath(letters, Color.White)
        }
    }
}
