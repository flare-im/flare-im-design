package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

enum class FlareScreenSurface { Canvas, Surface, Aurora }

/**
 * FlareScreen — the base page scaffold for Flare business pages.
 *
 * Themed page surface (auto light/dark via [flareColors], which reads
 * `isSystemInDarkTheme()` unless the app forces a theme), optional header
 * (back / large title / actions), and a scrollable body. Mirrors the Vue
 * contract — business code writes `FlareScreen(title = "设置", onBack = pop) { … }`
 * and gets a consistent, fully themeable page with no hard-coded page colours.
 */
@Composable
fun FlareScreen(
    title: String? = null,
    onBack: (() -> Unit)? = null,
    surface: FlareScreenSurface = FlareScreenSurface.Canvas,
    padded: Boolean = false,
    scroll: Boolean = true,
    actions: (@Composable () -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    val base = if (surface == FlareScreenSurface.Surface) colors.bgPrimary else colors.bgSecondary
    val hasHeader = title != null || onBack != null || actions != null

    val bg = if (surface == FlareScreenSurface.Aurora) {
        // Aurora — a soft violet light wash at the top of the canvas.
        Modifier.background(Brush.verticalGradient(listOf(lerp(colors.primary, base, 0.84f), base, base)))
    } else {
        Modifier.background(base)
    }

    Column(Modifier.fillMaxSize().then(bg)) {
        if (hasHeader) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (onBack != null) {
                    IconButton(onClick = onBack, modifier = Modifier.size(40.dp)) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, flareStrings().back, tint = colors.textPrimary)
                    }
                }
                if (title != null) {
                    Text(
                        title, color = colors.textPrimary, fontSize = 24.sp, fontWeight = FontWeight.Bold,
                        maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f),
                    )
                } else {
                    Spacer(Modifier.weight(1f))
                }
                actions?.invoke()
            }
        }
        Column(
            Modifier.fillMaxWidth().weight(1f)
                .then(if (scroll) Modifier.verticalScroll(rememberScrollState()) else Modifier)
                .then(if (padded) Modifier.padding(FlareSizes.spacingLg) else Modifier),
        ) {
            content()
        }
    }
}
