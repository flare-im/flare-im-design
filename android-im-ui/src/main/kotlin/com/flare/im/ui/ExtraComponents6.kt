package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Search
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.math.sin

// MARK: - VoicePlayer

/** Rich voice playback bubble. Spec: Message/VoicePlayer. */
@Composable
fun VoicePlayer(
    durationLabel: String,
    elapsedLabel: String? = null,
    progress: Double = 0.0,
    playing: Boolean = false,
    amplitudes: List<Double> = emptyList(),
    speed: Double = 1.0,
    transcript: String? = null,
    transcriptOpen: Boolean = false,
    unplayed: Boolean = false,
    outbound: Boolean = false,
    onToggle: (() -> Unit)? = null,
    onSeek: ((Double) -> Unit)? = null,
    onCycleSpeed: (() -> Unit)? = null,
    onToggleTranscript: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val n = 32
    val samples = if (amplitudes.isNotEmpty()) amplitudes else List(n) { 0.25 + 0.6 * abs(sin(it * 0.6)) }
    val bars = List(n) { samples[it % samples.size] }
    val filled = (progress.coerceIn(0.0, 1.0) * n).roundToInt()
    val shape = if (outbound) RoundedCornerShape(16.dp, 16.dp, 4.dp, 16.dp) else RoundedCornerShape(16.dp, 16.dp, 16.dp, 4.dp)
    val speedText = if (speed % 1.0 == 0.0) "${speed.toInt()}×" else "${(speed * 10).roundToInt() / 10.0}×"

    Column(
        Modifier.clip(shape)
            .background(if (outbound) colors.bgSelected else colors.bgPrimary)
            .border(1.dp, if (outbound) colors.primary.copy(alpha = 0.24f) else colors.borderPrimary, shape)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(
                Modifier.size(36.dp).clip(CircleShape)
                    .background(Brush.linearGradient(listOf(colors.primary, colors.primaryActive)))
                    .clickable { onToggle?.invoke() },
                contentAlignment = Alignment.Center,
            ) {
                Icon(if (playing) Icons.Filled.Pause else Icons.Filled.PlayArrow, contentDescription = "播放",
                    tint = Color.White, modifier = Modifier.size(18.dp))
                if (unplayed && !playing) {
                    Box(Modifier.align(Alignment.TopEnd).size(8.dp).clip(CircleShape).background(colors.error))
                }
            }
            Row(
                Modifier.weight(1f).height(26.dp)
                    .pointerInput(Unit) {
                        detectTapGestures { pos -> onSeek?.invoke((pos.x / size.width).toDouble().coerceIn(0.0, 1.0)) }
                    },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                bars.forEachIndexed { i, a ->
                    Box(
                        Modifier.weight(1f).height((4 + a * 18).dp).clip(RoundedCornerShape(2.dp))
                            .background(if (i < filled) colors.primary else colors.borderHover),
                    )
                }
            }
            Text(if (playing && elapsedLabel != null) elapsedLabel else durationLabel,
                color = colors.textTertiary, fontSize = 12.sp)
            Text(speedText, color = colors.textSecondary, fontWeight = FontWeight.SemiBold, fontSize = 11.sp,
                modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgSecondary)
                    .border(1.dp, colors.borderPrimary, RoundedCornerShape(999.dp))
                    .clickable { onCycleSpeed?.invoke() }.padding(horizontal = 8.dp, vertical = 2.dp))
        }
        if (transcript != null) {
            Row(
                Modifier.clickable { onToggleTranscript?.invoke() },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.Description, contentDescription = null, tint = colors.primary, modifier = Modifier.size(13.dp))
                Spacer(Modifier.width(4.dp))
                Text(if (transcriptOpen) "隐藏文字" else "转文字", color = colors.primary, fontSize = 12.sp)
            }
            if (transcriptOpen) {
                Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
                Text(transcript, color = colors.textSecondary, fontSize = 13.sp, modifier = Modifier.padding(top = 2.dp))
            }
        }
    }
}

// MARK: - EmojiPicker

private val SKIN_TONES = listOf("", "🏻", "🏼", "🏽", "🏾", "🏿")

/** Full emoji picker — search + categories + recents + skin tones. Spec: Composer/EmojiPicker. */
@Composable
fun EmojiPicker(
    categories: List<EmojiCategory>,
    recents: List<String> = emptyList(),
    skinTones: Boolean = false,
    onSelect: ((String) -> Unit)? = null,
    onToneChange: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    var query by remember { mutableStateOf("") }
    var tone by remember { mutableStateOf("") }
    val recentKey = "__recent"
    val tabs = buildList {
        if (recents.isNotEmpty()) add(EmojiCategory(recentKey, "最近", "🕘", recents))
        addAll(categories)
    }
    var activeKey by remember { mutableStateOf(tabs.firstOrNull()?.key ?: "") }
    val activeCat = tabs.firstOrNull { it.key == activeKey } ?: tabs.firstOrNull()
    val searching = query.trim().isNotEmpty()
    val shown = if (searching) {
        categories.flatMap { it.emojis }.distinct().filter { it.contains(query.trim()) }
    } else {
        activeCat?.emojis ?: emptyList()
    }

    Column(
        Modifier.width(320.dp).clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.Search, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(15.dp))
            Spacer(Modifier.width(8.dp))
            BasicTextField(
                value = query, onValueChange = { query = it }, singleLine = true,
                textStyle = TextStyle(color = colors.textPrimary, fontSize = 14.sp),
                cursorBrush = SolidColor(colors.primary), modifier = Modifier.weight(1f),
                decorationBox = { inner ->
                    if (query.isEmpty()) Text("搜索表情", color = colors.textTertiary, fontSize = 14.sp)
                    inner()
                },
            )
            if (skinTones) {
                Row {
                    SKIN_TONES.forEach { tn ->
                        Text(if (tn.isEmpty()) "✋" else "✋$tn", fontSize = 14.sp,
                            modifier = Modifier.size(22.dp).clip(RoundedCornerShape(6.dp))
                                .background(if (tone == tn) colors.bgSelected else Color.Transparent)
                                .clickable { tone = tn; onToneChange?.invoke(tn) },
                            textAlign = TextAlign.Center)
                    }
                }
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        Column(Modifier.height(200.dp).verticalScroll(rememberScrollState()).padding(8.dp)) {
            shown.chunked(8).forEach { row ->
                Row(Modifier.fillMaxWidth()) {
                    row.forEach { e ->
                        Text(e, fontSize = 22.sp, textAlign = TextAlign.Center,
                            modifier = Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(8.dp))
                                .clickable { onSelect?.invoke(if (tone.isEmpty()) e else e + tone) }.padding(4.dp))
                    }
                    repeat(8 - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
            if (shown.isEmpty()) {
                Text("没有匹配的表情", color = colors.textTertiary, fontSize = 13.sp,
                    modifier = Modifier.fillMaxWidth().padding(40.dp), textAlign = TextAlign.Center)
            }
        }
        if (!searching) {
            Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
            Row(
                Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                tabs.forEach { c ->
                    Box(
                        Modifier.size(32.dp).clip(RoundedCornerShape(8.dp))
                            .background(if (c.key == activeKey) colors.bgSelected else Color.Transparent)
                            .clickable { activeKey = c.key },
                        contentAlignment = Alignment.Center,
                    ) {
                        if (c.key == recentKey) {
                            Icon(Icons.Outlined.Schedule, contentDescription = c.label, tint = colors.textSecondary, modifier = Modifier.size(16.dp))
                        } else {
                            Text(c.symbol ?: c.emojis.firstOrNull() ?: "🙂", fontSize = 18.sp)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - StickerPanel

/** Categorized sticker panel. Spec: Composer/StickerPanel. */
@Composable
fun StickerPanel(
    packs: List<StickerPack>,
    recents: List<StickerItem> = emptyList(),
    onSelect: ((StickerItem) -> Unit)? = null,
) {
    val colors = flareColors()
    val recentKey = "__recent"
    val railPacks = buildList {
        if (recents.isNotEmpty()) add(StickerPack(recentKey, "最近", coverEmoji = "🕘", stickers = recents))
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
                Text("该表情包暂无贴纸", color = colors.textTertiary, fontSize = 13.sp,
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
