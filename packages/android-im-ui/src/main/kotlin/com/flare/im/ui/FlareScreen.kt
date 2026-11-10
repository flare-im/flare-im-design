package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.heightIn
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
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics

enum class FlareScreenSurface { Canvas, Surface, Brand }

internal fun flareContentMaxWidth(value: Dp?): Dp? = value?.takeIf { it.value.isFinite() && it.value > 0f }

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
    windowInsets: WindowInsets = WindowInsets.safeDrawing,
    contentMaxWidth: Dp? = null,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    val width = flareContentMaxWidth(contentMaxWidth)
    val columnWidth = if (width == null) Modifier else Modifier.widthIn(max = width)
    val base = if (surface == FlareScreenSurface.Surface) colors.bgPrimary else colors.bgSecondary
    val hasHeader = title != null || onBack != null || actions != null
    FlareNativeBackEffect(enabled = onBack != null && LocalFlareSheetHeader.current?.handlesBack != true) { onBack?.invoke() }
    // A page with a way back is not its destination's root: a shell hides its phone navigation under it.
    FlareDestinationDepth(active = onBack != null)
    if (onBack != null) FlareSheetOwnHeader(back = onBack)

    val bg = if (surface == FlareScreenSurface.Brand) {
        Modifier.background(Brush.verticalGradient(listOf(lerp(colors.primary, base, 0.84f), base, base)))
    } else {
        Modifier.background(base)
    }

    Column(Modifier.fillMaxSize().then(bg).windowInsetsPadding(windowInsets)) {
        if (hasHeader) {
            Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
            Row(
                Modifier.then(columnWidth).fillMaxWidth().padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm).heightIn(min = FlareSizes.touchTarget),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                if (onBack != null) {
                    IconButton(onClick = onBack, modifier = Modifier.size(FlareSizes.touchTarget)) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, flareStrings().back, tint = colors.textPrimary, modifier = Modifier.size(FlareSizes.iconSizeMd))
                    }
                }
                if (title != null) {
                    Text(
                        title, color = colors.textPrimary, fontSize = FlareSizes.fontSize5xl, fontWeight = FontWeight.Bold,
                        maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f).semantics { heading() },
                    )
                } else {
                    Spacer(Modifier.weight(1f))
                }
                actions?.invoke()
            }
            }
        }
        Box(Modifier.fillMaxWidth().weight(1f), contentAlignment = Alignment.TopCenter) {
        Column(
            Modifier.then(columnWidth).fillMaxSize()
                .then(if (scroll) Modifier.verticalScroll(rememberScrollState()) else Modifier)
                .then(if (padded) Modifier.padding(FlareSizes.spacingLg) else Modifier),
        ) {
            content()
        }
        }
    }
}

/**
 * The height a page header occupies: [FlareScreen]'s header row is a touch-target-tall row with
 * [FlareSizes.spacingSm] above and below.
 *
 * Exposed because anything that floats *over* a page — a connection banner, a toast — has to clear
 * the header without reserving layout space, and guessing that height in the host is how it ends up
 * sitting on top of the title.
 */
val FlareSizes.screenHeaderHeight: Dp get() = touchTarget + spacingSm * 2
