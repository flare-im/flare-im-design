package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/** Chat wallpaper swatch grid. Spec: Conversation/ChatWallpaperPicker. */
@Composable
fun ChatWallpaperPicker(
    options: List<WallpaperOption>,
    selectedId: String? = null,
    onSelect: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    Column(
        Modifier.width(300.dp).clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)).padding(14.dp),
    ) {
        Text(flareStrings().chatBackground, color = colors.textSecondary, fontWeight = FontWeight.SemiBold,
            fontSize = 13.sp, modifier = Modifier.padding(bottom = 12.dp))
        options.chunked(4).forEach { row ->
            Row(
                Modifier.fillMaxWidth().padding(bottom = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                row.forEach { opt -> swatch(colors, opt, opt.id == selectedId, onSelect) }
                repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}

@Composable
private fun RowScope.swatch(
    colors: FlareColors,
    opt: WallpaperOption,
    selected: Boolean,
    onSelect: ((String) -> Unit)?,
) {
    val fill = parseHexColor(opt.color) ?: colors.bgSecondary
    Box(
        Modifier.weight(1f).aspectRatio(0.75f).clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(fill)
            .border(2.dp, if (selected) colors.primary else Color.Transparent, RoundedCornerShape(FlareSizes.radiusLg))
            .clickable { onSelect?.invoke(opt.id) },
    ) {
        if (opt.imageUrl != null) {
            AsyncImage(model = opt.imageUrl, contentDescription = opt.label,
                modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(FlareSizes.radiusLg)), contentScale = ContentScale.Crop)
        }
        if (selected) {
            Box(
                Modifier.align(Alignment.BottomEnd).padding(4.dp).size(22.dp).clip(CircleShape).background(colors.primary),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Outlined.Check, contentDescription = null,
                    tint = Color.White, modifier = Modifier.size(14.dp))
            }
        }
    }
}

private fun parseHexColor(s: String?): Color? {
    val hex = s?.trim()?.removePrefix("#") ?: return null
    if (hex.length != 6) return null
    return try {
        Color(("FF$hex").toLong(16))
    } catch (e: NumberFormatException) {
        null
    }
}
