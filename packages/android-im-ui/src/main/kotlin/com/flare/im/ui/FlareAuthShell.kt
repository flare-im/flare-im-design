package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * The shared Flare account entrance. Product copy and form state belong to the host;
 * brand composition, responsive sizing, safe areas and keyboard scrolling belong here.
 * No connection settings, unsupported login methods or marketing claims are invented by the shell.
 */
@Composable
fun FlareAuthShell(
    product: String,
    title: String,
    subtitle: String,
    modifier: Modifier = Modifier,
    tagline: String? = null,
    headline: String? = null,
    description: String? = null,
    backLabel: String? = null,
    onBack: (() -> Unit)? = null,
    eyebrow: String? = null,
    footer: String? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    FlareScreen(surface = FlareScreenSurface.Canvas, scroll = false) {
        BoxWithConstraints(modifier.fillMaxSize().imePadding()) {
            val wide = authShellUsesSplitLayout(maxWidth.value, LocalDensity.current.fontScale)
            val form: @Composable (Modifier, Boolean) -> Unit = { formModifier, showBrand ->
                FormPanel(
                    product, tagline, title, subtitle, backLabel, onBack, eyebrow, footer,
                    showBrand, formModifier, content,
                )
            }
            if (wide) {
                Row(Modifier.fillMaxSize().background(flareColors().bgSecondary)) {
                    BrandPanel(
                        product, tagline, headline, description,
                        Modifier.weight(0.44f).fillMaxHeight(),
                    )
                    form(Modifier.weight(0.56f).fillMaxHeight(), false)
                }
            } else {
                form(Modifier.fillMaxSize(), true)
            }
        }
    }
}

/** Larger text needs a usable form column before the optional brand story earns a column. */
internal fun authShellUsesSplitLayout(width: Float, textScale: Float = 1f): Boolean =
    width >= FlareSizes.appShellCompactMinWidth.value * textScale.coerceIn(1f, 1.5f)

@Composable
private fun BrandPanel(
    product: String,
    tagline: String?,
    headline: String?,
    description: String?,
    modifier: Modifier,
) {
    val colors = flareColors()
    BoxWithConstraints(modifier.background(colors.bgSelected)) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .heightIn(min = maxHeight)
                .padding(horizontal = 48.dp, vertical = 40.dp),
        ) {
            BrandLockup(product, tagline, mobile = false)
            Spacer(Modifier.heightIn(min = 56.dp).weight(1f))
            Column(Modifier.widthIn(max = 360.dp), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
                headline?.takeIf(String::isNotBlank)?.let {
                    Text(
                        it,
                        color = colors.textPrimary,
                        fontSize = FlareSizes.fontSizeAuthHeadline,
                        fontWeight = FontWeight.Bold,
                        lineHeight = 44.sp,
                    )
                }
                description?.takeIf(String::isNotBlank)?.let {
                    Text(
                        it,
                        color = colors.textSecondary,
                        fontSize = FlareSizes.fontSize2xl,
                        lineHeight = 26.sp,
                    )
                }
                AuthConnectionArt(Modifier.widthIn(max = FlareSizes.authArtworkWidth).fillMaxWidth().padding(top = FlareSizes.spacing2xl))
            }
            Spacer(Modifier.heightIn(min = 40.dp).weight(1f))
        }
    }
}

@Composable
private fun FormPanel(
    product: String,
    tagline: String?,
    title: String,
    subtitle: String,
    backLabel: String?,
    onBack: (() -> Unit)?,
    eyebrow: String?,
    footer: String?,
    showBrand: Boolean,
    modifier: Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = flareColors()
    val wash = Brush.verticalGradient(
        listOf(colors.primary.copy(alpha = 0.10f).compositeOver(colors.bgSecondary), colors.bgSecondary),
    )
    BoxWithConstraints(modifier.background(wash)) {
        Box(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .heightIn(min = maxHeight)
                .padding(horizontal = if (showBrand) FlareSizes.spacingLg else 48.dp, vertical = 32.dp),
            contentAlignment = if (showBrand) Alignment.TopCenter else Alignment.Center,
        ) {
            Column(Modifier.widthIn(max = FlareSizes.authFormMaxWidth).fillMaxWidth()) {
                if (showBrand) {
                    BrandLockup(product, tagline, mobile = true)
                    Spacer(Modifier.size(FlareSizes.spacing2xl))
                }
                val cardShape = RoundedCornerShape(FlareSizes.radius2xl)
                Column(
                    Modifier.fillMaxWidth()
                        .shadow(2.dp, cardShape)
                        .background(colors.bgPrimary, cardShape)
                        .border(1.dp, colors.borderPrimary, cardShape)
                        .padding(if (showBrand) FlareSizes.spacingXl else FlareSizes.spacing2xl),
                ) {
                    if (backLabel != null && onBack != null) {
                        TextButton(onClick = onBack, modifier = Modifier.heightIn(min = FlareSizes.touchTargetMin)) {
                            Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = null, modifier = Modifier.size(FlareSizes.iconSizeSm))
                            Spacer(Modifier.size(FlareSizes.spacingSm))
                            Text(backLabel)
                        }
                        Spacer(Modifier.size(FlareSizes.spacingSm))
                    }
                    eyebrow?.takeIf(String::isNotBlank)?.let {
                        Text(it, color = colors.primaryText, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold, letterSpacing = 1.sp)
                        Spacer(Modifier.size(FlareSizes.spacingMd))
                    }
                    Text(
                        title,
                        modifier = Modifier.semantics { heading() },
                        color = colors.textPrimary,
                        fontSize = FlareSizes.fontSizeAuthTitle,
                        lineHeight = 36.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        subtitle,
                        modifier = Modifier.padding(top = FlareSizes.spacingSm),
                        color = colors.textSecondary,
                        fontSize = FlareSizes.fontSizeLg,
                        lineHeight = 22.sp,
                    )
                    Spacer(Modifier.size(FlareSizes.spacing2xl))
                    content()
                    footer?.takeIf(String::isNotBlank)?.let {
                        Text(
                            it,
                            modifier = Modifier.padding(top = FlareSizes.spacing2xl),
                            color = colors.textTertiary,
                            fontSize = FlareSizes.fontSizeSm,
                            lineHeight = 18.sp,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun BrandLockup(product: String, tagline: String?, mobile: Boolean) {
    val colors = flareColors()
    Row(verticalAlignment = Alignment.CenterVertically) {
        FlareBrandLogo(size = if (mobile) FlareSizes.authMobileLogoSize else FlareSizes.authBrandLogoSize)
        Column(Modifier.padding(start = FlareSizes.spacingMd)) {
            Text(product, color = colors.textPrimary, fontSize = if (mobile) 20.sp else 24.sp, fontWeight = FontWeight.Bold)
            tagline?.takeIf(String::isNotBlank)?.let {
                Text(
                    it,
                    modifier = Modifier.padding(top = FlareSizes.spacingXs),
                    color = colors.textSecondary,
                    fontSize = FlareSizes.fontSizeSm,
                    lineHeight = 18.sp,
                )
            }
        }
    }
}

/** The same two connected speech outlines as Vue, Flutter and SwiftUI. Decorative only. */
@Composable
private fun AuthConnectionArt(modifier: Modifier) {
    val colors = flareColors()
    Canvas(modifier.aspectRatio(320f / 200f).clearAndSetSemantics {}) {
        scale(size.width / 320f, size.height / 200f, pivot = Offset.Zero) {
            val rear = Path().apply {
                moveTo(48f, 24f); lineTo(200f, 24f); quadraticTo(220f, 24f, 220f, 44f)
                lineTo(220f, 120f); quadraticTo(220f, 140f, 200f, 140f)
                lineTo(80f, 140f); lineTo(58f, 158f); lineTo(58f, 140f); lineTo(48f, 140f)
                quadraticTo(28f, 140f, 28f, 120f); lineTo(28f, 44f); quadraticTo(28f, 24f, 48f, 24f); close()
            }
            drawPath(rear, colors.primary.copy(alpha = 0.06f))
            drawPath(rear, colors.primaryText.copy(alpha = 0.24f), style = Stroke(width = 1.5f))
            val front = Path().apply {
                moveTo(138f, 82f); lineTo(274f, 82f); quadraticTo(292f, 82f, 292f, 100f)
                lineTo(292f, 160f); quadraticTo(292f, 178f, 274f, 178f)
                lineTo(258f, 178f); lineTo(258f, 194f); lineTo(238f, 178f); lineTo(138f, 178f)
                quadraticTo(120f, 178f, 120f, 160f); lineTo(120f, 100f); quadraticTo(120f, 82f, 138f, 82f); close()
            }
            drawPath(front, colors.bgPrimary)
            drawPath(front, colors.primaryText.copy(alpha = 0.55f), style = Stroke(width = 1.5f))
            listOf(166f, 198f, 230f).forEach { x -> drawCircle(colors.primaryText.copy(alpha = 0.7f), radius = 4f, center = Offset(x, 130f)) }
        }
    }
}
