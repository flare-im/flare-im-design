package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Product authentication shell shared by Flare Compose applications.
 *
 * The kit owns the responsive brand/form composition. Hosts provide localized
 * copy and business controls through [content].
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
    content: @Composable ColumnScope.() -> Unit,
) {
    FlareScreen(surface = FlareScreenSurface.Brand, scroll = false) {
        BoxWithConstraints(modifier.fillMaxSize()) {
            val wide = maxWidth >= FlareSizes.appShellCompactMinWidth
            Box(Modifier.fillMaxSize().background(flareColors().bgPrimary)) {
                if (wide) {
                    Row(
                        Modifier
                            .fillMaxSize()
                            .background(flareColors().bgPrimary),
                    ) {
                        BrandPanel(
                            product = product,
                            tagline = tagline,
                            headline = headline,
                            description = description,
                            modifier = Modifier.weight(5f).fillMaxHeight(),
                        )
                        FormPanel(
                            product = product,
                            tagline = tagline,
                            title = title,
                            subtitle = subtitle,
                            backLabel = backLabel,
                            onBack = onBack,
                            showBrand = false,
                            modifier = Modifier.weight(6f).fillMaxHeight(),
                            content = content,
                        )
                    }
                } else {
                    FormPanel(
                        product = product,
                        tagline = tagline,
                        title = title,
                        subtitle = subtitle,
                        backLabel = backLabel,
                        onBack = onBack,
                        showBrand = true,
                        modifier = Modifier.fillMaxSize().background(flareColors().bgPrimary),
                        content = content,
                    )
                }
            }
        }
    }
}

@Composable
private fun BrandPanel(
    product: String,
    tagline: String?,
    headline: String?,
    description: String?,
    modifier: Modifier = Modifier,
) {
    val colors = flareColors()
    Column(
        modifier.background(
            Brush.linearGradient(
                listOf(lerp(colors.info, colors.bgPrimary, 0.80f), lerp(colors.primary, colors.bgSecondary, 0.90f)),
            ),
        ).padding(56.dp),
        verticalArrangement = Arrangement.Top,
    ) {
        BrandLockup(product, tagline, 72.dp)
        Box(Modifier.weight(1f).fillMaxWidth()) {
            Column(Modifier.align(Alignment.CenterStart).widthIn(max = 420.dp)) {
                headline?.let {
                    Text(
                        it,
                        color = colors.textPrimary,
                        fontSize = FlareSizes.fontSize5xl,
                        fontWeight = FontWeight.Bold,
                        lineHeight = FlareSizes.fontSize5xl * FlareSizes.lineHeightTight,
                    )
                }
                description?.let {
                    Text(
                        it,
                        modifier = Modifier.padding(top = FlareSizes.spacingLg),
                        color = colors.textSecondary,
                        fontSize = FlareSizes.fontSize2xl,
                        lineHeight = FlareSizes.fontSize2xl * FlareSizes.lineHeightRelaxed,
                    )
                }
            }
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
    showBrand: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = flareColors()
    Box(modifier.background(colors.bgPrimary).verticalScroll(rememberScrollState())) {
        Column(
            Modifier
                .align(if (showBrand) Alignment.TopCenter else Alignment.Center)
                .widthIn(max = 500.dp)
                .fillMaxWidth()
                .padding(horizontal = if (showBrand) FlareSizes.spacing2xl else 64.dp, vertical = if (showBrand) FlareSizes.spacing2xl else 48.dp),
        ) {
            if (showBrand) {
                BrandLockup(product, tagline, 52.dp)
                Spacer(Modifier.size(FlareSizes.spacing2xl))
            }
            if (backLabel != null && onBack != null) {
                TextButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = null, modifier = Modifier.size(FlareSizes.iconSizeSm))
                    Spacer(Modifier.size(FlareSizes.spacingSm))
                    Text(backLabel)
                }
            }
            Text(
                title,
                modifier = Modifier.semantics { heading() },
                color = colors.textPrimary,
                fontSize = FlareSizes.fontSize5xl,
                fontWeight = FontWeight.Bold,
            )
            Text(
                subtitle,
                modifier = Modifier.padding(top = FlareSizes.spacingSm),
                color = colors.textSecondary,
                fontSize = FlareSizes.fontSize2xl,
                lineHeight = FlareSizes.fontSize2xl * FlareSizes.lineHeightRelaxed,
            )
            Spacer(Modifier.size(FlareSizes.spacing2xl))
            content()
        }
    }
}

@Composable
private fun BrandLockup(product: String, tagline: String?, logoSize: androidx.compose.ui.unit.Dp) {
    val colors = flareColors()
    Row(verticalAlignment = Alignment.CenterVertically) {
        FlareBrandLogo(size = logoSize)
        Column(Modifier.padding(start = FlareSizes.spacingLg)) {
            Text(product, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl, fontWeight = FontWeight.Bold)
            tagline?.let {
                Text(
                    it,
                    modifier = Modifier.padding(top = FlareSizes.spacingXs),
                    color = colors.primaryText,
                    fontSize = FlareSizes.fontSizeSm,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = FlareSizes.fontSize2xs * 0.05f,
                )
            }
        }
    }
}
