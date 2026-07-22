package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withLink
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/*
 * Standalone, presentational per-type message bodies (clean params, no SDK /
 * media coupling) — drop any single one into your own layout. Interaction is
 * surfaced as callbacks: the host owns the URLs/handlers. The SDK-driven
 * dispatcher MessageContentView stays the batteries-included path.
 * Spec: Message/MessageContentView content types, decomposed into components.
 */

private fun Modifier.bubbleCard(colors: FlareColors): Modifier = this
    .shadow(2.dp, RoundedCornerShape(16.dp), clip = false)
    .clip(RoundedCornerShape(16.dp))
    .background(colors.bgPrimary)
    .border(1.dp, colors.borderSecondary, RoundedCornerShape(16.dp))

/** Attach an optional click handler without changing layout. */
private fun Modifier.onClickIf(action: (() -> Unit)?): Modifier =
    if (action != null) this.clickable { action() } else this

/** A network image (host-provided URL) that falls back to a placeholder. */
@Composable
private fun NetImage(
    url: String?,
    modifier: Modifier,
    contentDescription: String? = null,
    placeholder: @Composable () -> Unit,
) {
    if (!url.isNullOrEmpty()) {
        AsyncImage(model = url, contentDescription = contentDescription, modifier = modifier, contentScale = ContentScale.Crop)
    } else {
        Box(modifier, contentAlignment = Alignment.Center) { placeholder() }
    }
}

/** Linkify bare URLs; taps report the href via [onLinkTap]. */
private fun linkify(text: String, linkColor: Color, onLinkTap: ((String) -> Unit)?): AnnotatedString {
    val regex = Regex("((?:https?://)?[a-z0-9.-]+\\.[a-z]{2,}(?:/\\S*)?)", RegexOption.IGNORE_CASE)
    return buildAnnotatedString {
        var last = 0
        for (m in regex.findAll(text)) {
            if (m.range.first > last) append(text.substring(last, m.range.first))
            val href = m.value
            val url = if (href.startsWith("http")) href else "https://$href"
            val style = SpanStyle(color = linkColor, textDecoration = TextDecoration.Underline)
            if (onLinkTap != null) {
                withLink(LinkAnnotation.Url(url, TextLinkStyles(style)) { onLinkTap(url) }) { append(href) }
            } else {
                withStyle(style) { append(href) }
            }
            last = m.range.last + 1
        }
        if (last < text.length) append(text.substring(last))
    }
}

/** text — linkifies bare URLs and reports [onLinkTap]; [selectable] allows copy. */
@Composable
fun TextMessage(
    text: String,
    self: Boolean = false,
    selectable: Boolean = false,
    onLinkTap: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    val dark = isSystemInDarkTheme()
    val linkColor = if (self) Color.White else colors.primary
    val annotated = remember(text, linkColor, onLinkTap) { linkify(text, linkColor, onLinkTap) }
    // Aurora signature — your own bubble is a light source: a dimensional violet
    // gradient (lit top-left → brand → deeper bottom-right) + a violet-tinted glow.
    val selfBrush = Brush.linearGradient(
        listOf(
            lerp(colors.bubbleSelf, Color.White, 0.24f),
            colors.bubbleSelf,
            lerp(colors.bubbleSelf, Color.Black, 0.16f),
        ),
    )
    val content: @Composable () -> Unit = {
        Text(
            annotated,
            color = if (self) Color.White else colors.textPrimary,
            fontSize = FlareSizes.fontSizeXl.value.sp,
            lineHeight = (FlareSizes.fontSizeXl.value * 1.45f).sp,
            modifier = Modifier
                .then(
                    if (self) {
                        Modifier
                            .shadow(
                                if (dark) 14.dp else 8.dp,
                                RoundedCornerShape(16.dp),
                                clip = false,
                                ambientColor = colors.bubbleSelf,
                                spotColor = colors.bubbleSelf,
                            )
                            .clip(RoundedCornerShape(16.dp))
                            .background(selfBrush)
                    } else {
                        Modifier.bubbleCard(colors)
                    },
                )
                .padding(horizontal = 14.dp, vertical = 9.dp),
        )
    }
    if (selectable) SelectionContainer { content() } else content()
}

/** image — a rounded thumbnail; emits [onTap]. */
@Composable
fun ImageMessage(
    src: String? = null,
    width: Int = 132,
    height: Int = 92,
    maxWidth: Int? = null,
    maxHeight: Int? = null,
    alt: String? = null,
    onTap: (() -> Unit)? = null,
) {
    val colors = flareColors()
    // Flexible mode: given maxWidth/maxHeight, size within bounds preserving aspect
    // (Fit); otherwise the fixed width×height thumbnail (Crop).
    val flexible = maxWidth != null || maxHeight != null
    val sizeMod = if (flexible)
        Modifier.sizeIn(maxWidth = (maxWidth ?: 10_000).dp, maxHeight = (maxHeight ?: 10_000).dp)
    else Modifier.size(width.dp, height.dp)
    val mod = sizeMod.clip(RoundedCornerShape(12.dp)).background(colors.bgTertiary).onClickIf(onTap)
    if (!src.isNullOrEmpty()) {
        AsyncImage(
            model = src,
            contentDescription = alt,
            modifier = mod,
            contentScale = if (flexible) ContentScale.Fit else ContentScale.Crop,
        )
    } else {
        Box(mod, contentAlignment = Alignment.Center) {
            Icon(Icons.Outlined.Image, null, Modifier.size(26.dp), tint = colors.textTertiary)
        }
    }
}

/** video — a thumbnail with a play overlay and duration badge; emits [onPlay]. */
@Composable
fun VideoMessage(
    poster: String? = null,
    posterContent: (@Composable () -> Unit)? = null,
    duration: String = "00:00",
    alt: String? = null,
    onPlay: (() -> Unit)? = null,
) {
    val colors = flareColors()
    // With posterContent (e.g. a host-generated frame bitmap of any size) the slot
    // defines the size; otherwise the fixed 148×92 thumbnail from the poster URL.
    val outer = if (posterContent != null) Modifier else Modifier.size(148.dp, 92.dp)
    Box(
        outer.clip(RoundedCornerShape(12.dp)).background(colors.bgTertiary).onClickIf(onPlay),
        contentAlignment = Alignment.Center,
    ) {
        if (posterContent != null) {
            posterContent()
        } else {
            NetImage(poster, Modifier.matchParentSize(), contentDescription = alt) {
                Icon(Icons.Outlined.Videocam, null, Modifier.size(24.dp), tint = colors.textTertiary.copy(alpha = 0.5f))
            }
        }
        Box(Modifier.matchParentSize().background(Color.Black.copy(alpha = 0.28f)))
        Icon(Icons.Filled.PlayArrow, null, Modifier.size(34.dp), tint = Color.White)
        Box(Modifier.matchParentSize().padding(6.dp), contentAlignment = Alignment.BottomEnd) {
            Text(
                duration, color = Color.White, fontSize = 10.sp,
                modifier = Modifier.clip(RoundedCornerShape(5.dp)).background(Color.Black.copy(alpha = 0.45f))
                    .padding(horizontal = 5.dp, vertical = 1.dp),
            )
        }
    }
}

/** audio / voice — waveform + duration; [playing] drives the look, emits [onPlay]. */
@Composable
fun VoiceMessage(seconds: Int = 1, playing: Boolean = false, onPlay: (() -> Unit)? = null) {
    val colors = flareColors()
    Row(
        Modifier.bubbleCard(colors).onClickIf(onPlay).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(
            if (playing) Icons.Outlined.VolumeUp else Icons.Filled.PlayArrow, null,
            Modifier.size(17.dp), tint = if (playing) colors.primary else colors.textSecondary,
        )
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            for (n in 1..9) {
                Box(Modifier.size(2.dp, (4 + (n * 5) % 13).dp).clip(RoundedCornerShape(2.dp)).background(colors.primary))
            }
        }
        Text("$seconds\"", color = colors.textTertiary, fontSize = 12.sp)
    }
}

/** file — icon / name / size / ext; emits [onOpen] (card) and [onDownload].
 *  Override the leading [icon] slot to show a per-file-type glyph. */
@Composable
fun FileMessage(
    name: String,
    size: String = "",
    ext: String? = null,
    icon: (@Composable () -> Unit)? = null,
    onOpen: (() -> Unit)? = null,
    onDownload: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val sub = if (!ext.isNullOrEmpty()) "$size · $ext" else size
    Row(
        Modifier.widthIn(max = 300.dp).bubbleCard(colors).onClickIf(onOpen).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        if (icon != null) icon() else Icon(Icons.Outlined.Folder, null, Modifier.size(20.dp), tint = colors.primary)
        Column(Modifier.weight(1f, fill = false)) {
            Text(name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(sub, color = colors.textTertiary, fontSize = 11.sp)
        }
        Icon(
            Icons.Outlined.FileDownload, null,
            Modifier.size(17.dp).onClickIf(onDownload), tint = colors.textTertiary,
        )
    }
}

/** location — a map image (or placeholder) over title / address; emits [onOpen]. */
@Composable
fun LocationMessage(title: String, address: String = "", mapImage: String? = null, onOpen: (() -> Unit)? = null) {
    val colors = flareColors()
    Column(Modifier.width(264.dp).bubbleCard(colors).onClickIf(onOpen)) {
        NetImage(mapImage, Modifier.fillMaxWidth().height(84.dp)) {
            Box(
                Modifier.fillMaxWidth().height(84.dp)
                    .background(colors.primary.copy(alpha = 0.08f).compositeOverColor(colors.bgTertiary)),
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Outlined.LocationOn, null, Modifier.size(22.dp), tint = colors.primary) }
        }
        Column(Modifier.padding(horizontal = 12.dp, vertical = 8.dp)) {
            Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.Medium)
            Text(address, color = colors.textTertiary, fontSize = 11.sp)
        }
    }
}

/** contact / business card — avatar (image or pastel initials) + name / subtitle; emits [onOpen]. */
@Composable
fun ContactMessage(name: String, subtitle: String? = null, avatarUrl: String? = null, onOpen: (() -> Unit)? = null) {
    val colors = flareColors()
    val tint = seedTint(name)
    Row(
        Modifier.widthIn(min = 240.dp).bubbleCard(colors).onClickIf(onOpen).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        NetImage(avatarUrl, Modifier.size(44.dp).clip(RoundedCornerShape(10.dp)).background(tint.first)) {
            Text(initials(name), color = tint.second, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
        }
        Column(Modifier.weight(1f, fill = false)) {
            Text(name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl.value.sp, fontWeight = FontWeight.SemiBold)
            if (!subtitle.isNullOrEmpty()) {
                Text(subtitle, color = colors.textTertiary, fontSize = 11.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        Icon(Icons.Outlined.ChevronRight, null, Modifier.size(16.dp), tint = colors.textTertiary)
    }
}

/** link card — thumbnail + title + optional description + domain; emits [onOpen]. */
@Composable
fun LinkCardMessage(title: String, domain: String = "", thumb: String? = null, description: String? = null, onOpen: (() -> Unit)? = null) {
    val colors = flareColors()
    Row(
        Modifier.widthIn(max = 300.dp).bubbleCard(colors).onClickIf(onOpen).padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        NetImage(thumb, Modifier.size(48.dp).clip(RoundedCornerShape(8.dp)).background(colors.bgTertiary)) {
            Icon(Icons.Outlined.Image, null, Modifier.size(22.dp), tint = colors.textTertiary)
        }
        Column(Modifier.weight(1f, fill = false), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (!description.isNullOrEmpty()) {
                Text(description, color = colors.textSecondary, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                Icon(Icons.Outlined.Link, null, Modifier.size(12.dp), tint = colors.textTertiary)
                Text(domain, color = colors.textTertiary, fontSize = 11.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

/** A vote option for [VoteMessage]. */
data class FlareVoteOption(val text: String, val pct: Int)

/** vote — a title over option rows with proportional bars; emits [onSelect]. */
@Composable
fun VoteMessage(
    title: String,
    options: List<FlareVoteOption> = emptyList(),
    total: String? = null,
    onSelect: ((FlareVoteOption, Int) -> Unit)? = null,
) {
    val colors = flareColors()
    Column(
        Modifier.widthIn(min = 220.dp).bubbleCard(colors).padding(horizontal = 12.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(Icons.Outlined.BarChart, null, Modifier.size(16.dp), tint = colors.textPrimary)
            Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.SemiBold)
        }
        options.forEachIndexed { i, o ->
            Box(
                Modifier.fillMaxWidth().height(30.dp).clip(RoundedCornerShape(7.dp)).background(colors.bgSecondary)
                    .onClickIf(if (onSelect != null) ({ onSelect(o, i) }) else null),
            ) {
                Box(Modifier.fillMaxWidth((o.pct.coerceIn(0, 100)) / 100f).height(30.dp)
                    .background(colors.primary.copy(alpha = 0.16f)))
                Row(Modifier.fillMaxWidth().height(30.dp).padding(horizontal = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(o.text, color = colors.textPrimary, fontSize = 13.sp, modifier = Modifier.weight(1f))
                    Text("${o.pct}%", color = colors.textSecondary, fontSize = 12.sp)
                }
            }
        }
        if (!total.isNullOrEmpty()) Text(total, color = colors.textTertiary, fontSize = 11.sp)
    }
}

/** task — checkbox + title (struck through when done) + meta; emits [onToggle]. */
@Composable
fun TaskMessage(title: String, meta: String? = null, done: Boolean = false, onToggle: (() -> Unit)? = null) {
    val colors = flareColors()
    Row(
        Modifier.widthIn(min = 220.dp).bubbleCard(colors).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            Modifier.size(20.dp).clip(RoundedCornerShape(6.dp)).onClickIf(onToggle)
                .then(if (done) Modifier.background(colors.primary) else Modifier.border(1.5.dp, colors.borderPrimary, RoundedCornerShape(6.dp))),
            contentAlignment = Alignment.Center,
        ) { if (done) Icon(Icons.Rounded.Check, null, Modifier.size(13.dp), tint = Color.White) }
        Column(Modifier.weight(1f, fill = false)) {
            Text(
                title,
                color = if (done) colors.textTertiary else colors.textPrimary,
                fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.Medium,
                textDecoration = if (done) TextDecoration.LineThrough else null,
            )
            if (!meta.isNullOrEmpty()) Text(meta, color = colors.textTertiary, fontSize = 11.sp)
        }
    }
}

/** sticker — a bare, larger glyph (no bubble); emits [onTap]. */
@Composable
fun StickerMessage(emoji: String = "🐱", onTap: (() -> Unit)? = null) {
    Text(emoji, fontSize = 72.sp, modifier = Modifier.onClickIf(onTap))
}

/** emoji — a bare, large emoji (no bubble); emits [onTap]. */
@Composable
fun EmojiMessage(emoji: String = "🎉", onTap: (() -> Unit)? = null) {
    Text(emoji, fontSize = 40.sp, modifier = Modifier.onClickIf(onTap))
}

/** notification / system — a centered pill. */
@Composable
fun SystemMessage(text: String) {
    val colors = flareColors()
    Text(
        text, color = colors.textTertiary, fontSize = 12.sp,
        modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgTertiary)
            .padding(horizontal = 12.dp, vertical = 4.dp),
    )
}

// blend a translucent color over an opaque base (for the location map tint)
private fun Color.compositeOverColor(base: Color): Color {
    val a = alpha
    return Color(
        red = red * a + base.red * (1 - a),
        green = green * a + base.green * (1 - a),
        blue = blue * a + base.blue * (1 - a),
        alpha = 1f,
    )
}
