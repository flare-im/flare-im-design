package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/** Categorized sticker panel. Spec: Composer/StickerPanel. */
@Composable
fun StickerPanel(
    packs: List<StickerPack>,
    recents: List<StickerItem> = emptyList(),
    onSelect: ((StickerItem) -> Unit)? = null,
) {
    val colors = flareColors()
    val recentKey = "__recent"
    val recentLabel = flareStrings().recent
    val railPacks = buildList {
        if (recents.isNotEmpty()) add(StickerPack(recentKey, recentLabel, coverEmoji = "🕘", stickers = recents))
        addAll(packs)
    }
    var activeKey by remember { mutableStateOf(railPacks.firstOrNull()?.key ?: "") }
    val activePack = railPacks.firstOrNull { it.key == activeKey } ?: railPacks.firstOrNull()

    Column(
        Modifier.width(320.dp).clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)),
    ) {
        Text(activePack?.label ?: "", color = colors.textTertiary, fontWeight = FontWeight.SemiBold,
            fontSize = 12.sp, modifier = Modifier.padding(start = 14.dp, end = 14.dp, top = 10.dp, bottom = 4.dp))
        Column(
            Modifier.height(208.dp).verticalScroll(rememberScrollState()).padding(horizontal = 12.dp, vertical = 6.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            (activePack?.stickers ?: emptyList()).chunked(4).forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    row.forEach { s ->
                        Box(
                            Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(FlareSizes.radiusLg))
                                .background(colors.bgSecondary).clickable { onSelect?.invoke(s) },
                            contentAlignment = Alignment.Center,
                        ) {
                            if (s.url != null) {
                                AsyncImage(model = s.url, contentDescription = s.id,
                                    modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Fit)
                            } else {
                                Text(s.placeholder ?: "🎨", fontSize = 32.sp)
                            }
                        }
                    }
                    repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
            if (activePack?.stickers.isNullOrEmpty()) {
                Text(flareStrings().emptyStickerPack, color = colors.textTertiary, fontSize = 13.sp,
                    modifier = Modifier.fillMaxWidth().padding(44.dp), textAlign = TextAlign.Center)
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        Row(
            Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            railPacks.forEach { p ->
                Box(
                    Modifier.size(38.dp).clip(RoundedCornerShape(10.dp))
                        .background(if (p.key == activeKey) colors.bgSelected else Color.Transparent)
                        .clickable { activeKey = p.key },
                    contentAlignment = Alignment.Center,
                ) {
                    when {
                        p.key == recentKey -> Icon(Icons.Outlined.Schedule, contentDescription = p.label, tint = colors.textSecondary, modifier = Modifier.size(18.dp))
                        p.coverUrl != null -> AsyncImage(model = p.coverUrl, contentDescription = p.label,
                            modifier = Modifier.size(26.dp).clip(RoundedCornerShape(6.dp)), contentScale = ContentScale.Fit)
                        else -> Text(p.coverEmoji ?: p.stickers.firstOrNull()?.placeholder ?: "🖼️", fontSize = 20.sp)
                    }
                }
            }
        }
    }
}
