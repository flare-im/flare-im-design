package com.flare.im.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.CheckBox
import androidx.compose.material.icons.outlined.CheckBoxOutlineBlank
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlin.math.abs
import kotlin.math.sin

private fun parseHexColor(s: String?): Color? {
    val hex = s?.trim()?.removePrefix("#") ?: return null
    if (hex.length != 6) return null
    return try {
        Color(("FF$hex").toLong(16))
    } catch (e: NumberFormatException) {
        null
    }
}

// MARK: - ImageGrid

/** Adaptive album grid (九宫格) with +N overflow. Spec: Message/ImageGrid. */
@Composable
fun ImageGrid(
    images: List<GridImage>,
    max: Int = 9,
    onOpen: ((Int) -> Unit)? = null,
) {
    val colors = flareColors()
    val visible = images.take(max)
    val overflow = images.size - visible.size
    if (visible.isEmpty()) return

    if (visible.size == 1) {
        Box(
            Modifier.widthIn(max = 220.dp).heightIn(max = 260.dp)
                .clip(RoundedCornerShape(12.dp)).background(colors.bgSecondary)
                .clickable { onOpen?.invoke(0) },
        ) { imageOrPlaceholder(visible[0].url, ContentScale.Fit) }
        return
    }

    val cols = when {
        visible.size == 4 -> 2
        visible.size <= 3 -> visible.size
        else -> 3
    }
    val rows = visible.chunked(cols)
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        rows.forEachIndexed { rowIdx, row ->
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                row.forEachIndexed { colIdx, img ->
                    val index = rowIdx * cols + colIdx
                    Box(
                        Modifier.size(84.dp).clip(RoundedCornerShape(8.dp))
                            .background(colors.bgSecondary).clickable { onOpen?.invoke(index) },
                    ) {
                        imageOrPlaceholder(img.url, ContentScale.Crop)
                        if (overflow > 0 && index == visible.size - 1) {
                            Box(
                                Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.42f)),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text("+$overflow", color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 18.sp)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun imageOrPlaceholder(url: String?, scale: ContentScale) {
    if (url != null) {
        AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = scale)
    }
}

// MARK: - VoiceRecordingBar

/** Active voice-recording overlay. Spec: Composer/VoiceRecordingBar. */
@Composable
fun VoiceRecordingBar(
    durationLabel: String,
    amplitudes: List<Double> = emptyList(),
    cancelling: Boolean = false,
    onCancel: (() -> Unit)? = null,
    onSend: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val n = 28
    val samples = if (amplitudes.isNotEmpty()) amplitudes
    else List(n) { 0.2 + 0.5 * abs(sin(it * 0.7)) }
    val bars = List(n) { samples[it % samples.size] }
    val accent = if (cancelling) colors.error else colors.primary

    val blink = rememberInfiniteTransition(label = "rec")
    val dotAlpha by blink.animateFloat(
        initialValue = 1f, targetValue = 0.25f,
        animationSpec = infiniteRepeatable(tween(1100), RepeatMode.Reverse), label = "dot",
    )

    Row(
        Modifier.clip(RoundedCornerShape(999.dp))
            .background(if (cancelling) colors.error.copy(alpha = 0.1f) else colors.bgPrimary)
            .border(1.dp, if (cancelling) colors.error.copy(alpha = 0.4f) else colors.borderPrimary, RoundedCornerShape(999.dp))
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            Modifier.size(36.dp).clip(CircleShape)
                .background(if (cancelling) colors.error else colors.bgSecondary)
                .clickable { onCancel?.invoke() },
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.DeleteOutline, contentDescription = "Cancel",
                tint = if (cancelling) Color.White else colors.textSecondary, modifier = Modifier.size(18.dp))
        }
        Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(Modifier.size(9.dp).clip(CircleShape).background(colors.error.copy(alpha = dotAlpha)))
            Text(durationLabel, color = colors.textPrimary, fontSize = 13.sp)
            Row(
                Modifier.weight(1f).height(24.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                bars.forEach { a ->
                    Box(
                        Modifier.weight(1f).height((4 + a * 20).dp)
                            .clip(RoundedCornerShape(2.dp)).background(accent.copy(alpha = 0.7f)),
                    )
                }
            }
        }
        if (cancelling) {
            Text("Release to cancel", color = colors.error, fontWeight = FontWeight.Medium, fontSize = 12.sp,
                modifier = Modifier.padding(end = 4.dp))
        } else {
            Box(
                Modifier.size(36.dp).clip(CircleShape).background(colors.primary).clickable { onSend?.invoke() },
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.AutoMirrored.Outlined.Send, contentDescription = "Send", tint = Color.White, modifier = Modifier.size(18.dp))
            }
        }
    }
}

// MARK: - PollComposer

/** Create-a-poll form. Spec: Composer/PollComposer. */
@Composable
fun PollComposer(
    maxOptions: Int = 10,
    onSubmit: ((question: String, options: List<String>, multiple: Boolean) -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var question by remember { mutableStateOf("") }
    val options = remember { mutableStateListOf("", "") }
    var multiple by remember { mutableStateOf(false) }
    val filled = options.map { it.trim() }.filter { it.isNotEmpty() }
    val canSubmit = question.trim().isNotEmpty() && filled.size >= 2

    Column(
        Modifier.width(320.dp).clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("New poll", color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeLg.value.sp)
            Spacer(Modifier.weight(1f))
            Icon(Icons.Outlined.Close, contentDescription = "Cancel", tint = colors.textTertiary,
                modifier = Modifier.size(18.dp).clickable { onCancel?.invoke() })
        }
        Box(Modifier.fillMaxWidth().padding(bottom = 4.dp)) {
            BasicTextField(
                value = question, onValueChange = { question = it }, singleLine = true,
                textStyle = TextStyle(color = colors.textPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium),
                cursorBrush = SolidColor(colors.primary), modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                decorationBox = { inner ->
                    if (question.isEmpty()) Text("Ask a question", color = colors.textTertiary, fontSize = 15.sp)
                    inner()
                },
            )
            Box(Modifier.fillMaxWidth().height(1.5.dp).background(colors.borderPrimary).align(Alignment.BottomCenter))
        }
        options.forEachIndexed { i, value ->
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary)
                    .padding(start = 12.dp, end = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                BasicTextField(
                    value = value, onValueChange = { options[i] = it }, singleLine = true,
                    textStyle = TextStyle(color = colors.textPrimary, fontSize = 14.sp),
                    cursorBrush = SolidColor(colors.primary), modifier = Modifier.weight(1f).padding(vertical = 9.dp),
                    decorationBox = { inner ->
                        if (value.isEmpty()) Text("Option ${i + 1}", color = colors.textTertiary, fontSize = 14.sp)
                        inner()
                    },
                )
                if (options.size > 2) {
                    Icon(Icons.Outlined.Close, contentDescription = "Remove option", tint = colors.textTertiary,
                        modifier = Modifier.size(16.dp).padding(4.dp).clickable { options.removeAt(i) })
                }
            }
        }
        if (options.size < maxOptions) {
            Row(
                Modifier.clickable { options.add("") },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.Add, contentDescription = null, tint = colors.primary, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(4.dp))
                Text("Add option", color = colors.primary, fontSize = 13.sp)
            }
        }
        Row(
            Modifier.clickable { multiple = !multiple },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(if (multiple) Icons.Outlined.CheckBox else Icons.Outlined.CheckBoxOutlineBlank,
                contentDescription = null, tint = if (multiple) colors.primary else colors.textTertiary, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(6.dp))
            Text("Allow multiple answers", color = colors.textSecondary, fontSize = 13.sp)
        }
        Box(
            Modifier.fillMaxWidth().height(40.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(if (canSubmit) colors.primary else colors.bgSecondary)
                .then(if (canSubmit) Modifier.clickable { onSubmit?.invoke(question.trim(), filled, multiple) } else Modifier),
            contentAlignment = Alignment.Center,
        ) {
            Text("Create poll", color = if (canSubmit) Color.White else colors.textTertiary,
                fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeMd.value.sp)
        }
    }
}

// MARK: - ChatWallpaperPicker

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
        Text("Chat wallpaper", color = colors.textSecondary, fontWeight = FontWeight.SemiBold,
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
