package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.appendInlineContent
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.Spacer
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLayoutResult
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
 * surfaced as callbacks: the host owns the URLs and handlers. The registry-driven
 * dispatcher MessageContentView stays the batteries-included path.
 * Spec: Message/MessageContentView content types, decomposed into components.
 */

/** Attach an optional click handler without changing layout. */
private fun Modifier.onClickIf(action: (() -> Unit)?): Modifier =
    if (action != null) this.clickable { action() } else this

/** Attach an optional click handler that TalkBack announces as [label] ("double tap to [label]"). */
private fun Modifier.onClickIf(action: (() -> Unit)?, label: String): Modifier =
    if (action != null) this.clickable(onClickLabel = label) { action() } else this

/** A network image (host-provided URL) that falls back to a placeholder. */
@Composable
internal fun NetImage(
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

/** Linkify bare URLs outside the [mentions]; taps report the href via [onLinkTap]. */
private fun linkify(
    text: String,
    linkColor: Color,
    onLinkTap: ((String) -> Unit)?,
    mentions: List<FlareTextMentionSpan> = emptyList(),
): AnnotatedString {
    val regex = Regex("((?:https?://)?[a-z0-9.-]+\\.[a-z]{2,}(?:/\\S*)?)", RegexOption.IGNORE_CASE)
    return buildAnnotatedString {
        var last = 0
        for (m in regex.findAll(text)) {
            // A mention keeps its run: an address-like name after "@" is not a link.
            if (mentions.any { m.range.first < it.start + it.length && it.start <= m.range.last }) continue
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

/**
 * [annotated] with each mention run in the mention look: the accent text colour at medium weight in an
 * incoming bubble, the bubble's own colour at semibold in an outgoing one (which already sits on the accent).
 */
private fun withMentionStyles(annotated: AnnotatedString, mentions: List<FlareTextMentionSpan>, self: Boolean, accent: Color): AnnotatedString {
    if (mentions.isEmpty()) return annotated
    val style = if (self) SpanStyle(fontWeight = FontWeight.SemiBold) else SpanStyle(color = accent, fontWeight = FontWeight.Medium)
    return AnnotatedString.Builder(annotated).apply {
        for (mention in mentions) addStyle(style, mention.start, mention.start + mention.length)
    }.toAnnotatedString()
}

/**
 * [annotated] with each `[key]` emoji-pack token ([runs]) drawn as its inline image. The token keeps its own
 * text as the placeholder's alternate text, so the string's length never changes and the mention runs, the
 * link ranges and the mention grounds all stay on the characters they were measured for.
 */
internal fun withInlineEmoji(annotated: AnnotatedString, runs: List<FlareInlineEmojiRun>): AnnotatedString {
    if (runs.isEmpty()) return annotated
    return buildAnnotatedString {
        var last = 0
        for (run in runs) {
            if (run.start > last) append(annotated.subSequence(last, run.start))
            appendInlineContent(flareInlineEmojiId(run.key), annotated.substring(run.start, run.end))
            last = run.end
        }
        if (last < annotated.length) append(annotated.subSequence(last, annotated.length))
    }
}

/**
 * The grounds behind [mentions] in a laid-out text: one rounded box per line a mention covers, reaching
 * [padX] past the glyphs on each side and at most [maxHeight] tall, centred on the line.
 */
private fun mentionGroundRects(layout: TextLayoutResult, mentions: List<FlareTextMentionSpan>, padX: Float, maxHeight: Float): List<Rect> {
    val length = layout.layoutInput.text.length
    return buildList {
        for (mention in mentions) {
            val end = minOf(mention.start + mention.length, length)
            if (mention.start >= end) continue
            for (line in layout.getLineForOffset(mention.start)..layout.getLineForOffset(end - 1)) {
                val from = maxOf(mention.start, layout.getLineStart(line))
                val to = minOf(end, layout.getLineEnd(line))
                if (from >= to) continue
                val box = layout.getPathForRange(from, to).getBounds()
                if (box.width <= 0f || box.height <= 0f) continue
                val height = minOf(box.height, maxHeight)
                val top = box.center.y - height / 2
                add(Rect(box.left - padX, top, box.right + padX, top + height))
            }
        }
    }
}

/**
 * text — linkifies bare URLs and reports [onLinkTap]; [selectable] allows copy. [mentions] (UTF-16
 * runs, see [textMentionSpans]) read as names: in an incoming bubble the accent colour at medium weight,
 * and a mention of the reader or of everyone also sits on the selected ground; in an outgoing bubble
 * semibold in the bubble's colour, with no ground. A span outside the text or overlapping the one
 * before it is ignored, and text without mentions renders exactly as it did.
 *
 * An emoji-pack token (`[smile]`) inside the text draws that emoji inline at the text's size (Vue
 * `PlainTextEmojiRich`); a key the bundled pack does not have stays the bracket text it is. Text with no
 * token never loads the catalog.
 */
@Composable
fun TextMessage(
    text: String,
    self: Boolean = false,
    selectable: Boolean = false,
    onLinkTap: ((String) -> Unit)? = null,
    mentions: List<FlareTextMentionSpan> = emptyList(),
) {
    val colors = flareColors()
    val linkColor = if (self) colors.messageOutgoingForeground else colors.primary
    val spans = remember(text, mentions) { drawableMentionSpans(text, mentions) }
    // Inline emoji: only text that holds a token at all waits for the catalog.
    val mayHoldEmoji = remember(text) { flareMayHoldEmojiTokens(text) }
    val catalogLoaded = if (mayHoldEmoji) rememberCatalogLoaded() else false
    val catalogRevision = if (mayHoldEmoji) FlareEmojiStickerCatalog.revision.collectAsState().value else 0
    if (catalogLoaded) {
        val loneEmoji = flareLoneEmojiPackKey(text)
        if (loneEmoji != null) {
            FlareEmojiPackMessage(loneEmoji, isSelf = self)
            return
        }
    }
    val emojiRuns = remember(text, mayHoldEmoji, catalogLoaded, catalogRevision) {
        if (mayHoldEmoji && catalogLoaded) flareInlineEmojiRuns(text, FlareEmojiStickerCatalog::hasEmojiKey) else emptyList()
    }
    // Plain text builds no image loader at all: only a body that really holds a bundled key asks for one.
    val inlineEmoji = if (emojiRuns.isEmpty()) emptyMap() else {
        rememberFlareInlineEmojiContent(remember(emojiRuns) { emojiRuns.mapTo(LinkedHashSet()) { it.key } })
    }
    val annotated = remember(text, linkColor, onLinkTap, spans, self, colors.primaryText, emojiRuns) {
        withInlineEmoji(withMentionStyles(linkify(text, linkColor, onLinkTap, spans), spans, self, colors.primaryText), emojiRuns)
    }
    val grounded = remember(spans, self) { mentionGrounds(spans, self) }
    var layout by remember { mutableStateOf<TextLayoutResult?>(null) }
    val ground = colors.bgSelected
    // 消息正文取 message 角色 —— 四端同一个出处(15/1.45)。
    val fontSize = FlareTextRoles.Message.fontSize
    val content: @Composable () -> Unit = {
        Row( verticalAlignment = Alignment.Bottom) {
            Text(
                annotated,
                color = if (self) colors.messageOutgoingForeground else colors.messageIncomingForeground,
                fontSize = fontSize.value.sp,
                lineHeight = (FlareTextRoles.Message.fontSize.value * FlareTextRoles.Message.lineHeight).sp,
                inlineContent = inlineEmoji,
                modifier = Modifier.weight(1f, fill = false).then(
                    if (grounded.isEmpty()) Modifier
                    else Modifier.drawWithCache {
                        // 2 dp either side, the small radius, one tight line tall.
                        val rects = layout?.let { mentionGroundRects(it, grounded, 2.dp.toPx(), fontSize.toPx() * FlareSizes.lineHeightTight) }.orEmpty()
                        val radius = CornerRadius(FlareSizes.radiusSm.toPx())
                        onDrawBehind { rects.forEach { drawRoundRect(ground, it.topLeft, it.size, radius) } }
                    },
                ),
                onTextLayout = { if (grounded.isNotEmpty()) layout = it },
            )
        }
    }
    if (selectable) SelectionContainer { content() } else content()
}

/** The mentions that get the selected ground: the reader's and everyone's, and only in an incoming bubble. */
internal fun mentionGrounds(mentions: List<FlareTextMentionSpan>, self: Boolean): List<FlareTextMentionSpan> =
    if (self) emptyList() else mentions.filter { it.self || it.all }

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
    val mod = sizeMod.clip(RoundedCornerShape(FlareSizes.radiusCard)).background(colors.bgTertiary).onClickIf(onTap, flareStrings().imagePreviewOpen)
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
        outer.clip(RoundedCornerShape(FlareSizes.radiusCard)).background(colors.bgTertiary).onClickIf(onPlay, flareStrings().play),
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
        Icon(flareIconVector("play"), null, Modifier.size(34.dp), tint = Color.White)
        Box(Modifier.matchParentSize().padding(FlareSizes.spacing2xs), contentAlignment = Alignment.BottomEnd) {
            Text(
                duration, color = Color.White, fontSize = FlareSizes.fontSize2xs,
                modifier = Modifier.clip(RoundedCornerShape(5.dp)).background(Color.Black.copy(alpha = 0.45f))
                    .padding(horizontal = 5.dp, vertical = 1.dp),
            )
        }
    }
}

/** The play control of a [VoiceMessage], named for what a tap does next: retry after a failure, pause while playing, else play. */
internal fun voiceMessageControl(strings: FlareStrings, playing: Boolean, failed: Boolean): FlareIconControlSpec = when {
    failed -> FlareIconControlSpec("voice", "refresh", strings.retry)
    playing -> FlareIconControlSpec("voice", "pause", strings.pause)
    else -> FlareIconControlSpec("voice", "play", strings.play)
}

/** What a [VoiceMessage] shows beside its waveform, and what TalkBack reads when that differs ([spoken]). */
internal data class VoiceMessageTime(val text: String, val spoken: String? = null)

/**
 * The failure; elapsed / total while playing or paused part-way; the duration (`12"`, read as seconds)
 * otherwise; the word for a voice message while the duration is still unknown.
 */
internal fun voiceMessageTime(strings: FlareStrings, seconds: Int, elapsedSeconds: Int, playing: Boolean, failed: Boolean): VoiceMessageTime = when {
    failed -> VoiceMessageTime(strings.voicePlaybackFailed)
    (playing || elapsedSeconds > 0) && seconds > 0 -> VoiceMessageTime("${voiceClock(elapsedSeconds.coerceIn(0, seconds))} / ${voiceClock(seconds)}")
    seconds > 0 -> VoiceMessageTime("$seconds\"", strings.voiceDuration(seconds))
    else -> VoiceMessageTime(strings.voiceMessage)
}

private fun voiceClock(seconds: Int): String = "%d:%02d".format(seconds / 60, seconds % 60)

private const val VOICE_BARS = 9

/**
 * audio / voice — a play control, a waveform and the time. With [onPlay] the control is a button named
 * for what a tap does next (play; pause while [playing]; retry once [failed]) with a 48 dp target that
 * reaches past its disc, and a tap anywhere on the row does the same. While playing, or paused part-way
 * ([elapsedSeconds] > 0), the waveform fills to the elapsed share and the time reads elapsed / total.
 * Without [onPlay] the row is display-only.
 */
@Composable
fun VoiceMessage(
    seconds: Int = 1,
    playing: Boolean = false,
    onPlay: (() -> Unit)? = null,
    elapsedSeconds: Int = 0,
    failed: Boolean = false,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val control = voiceMessageControl(strings, playing, failed)
    val time = voiceMessageTime(strings, seconds, elapsedSeconds, playing, failed)
    val started = !failed && (playing || elapsedSeconds > 0)
    val lit = if (started && seconds > 0) (elapsedSeconds.coerceIn(0, seconds) * VOICE_BARS + seconds / 2) / seconds else VOICE_BARS
    // The row keeps one tap detector while playback recomposes it; the tap reaches the current handler.
    val play by rememberUpdatedState(onPlay)
    Row(
        if (onPlay != null) Modifier.pointerInput(Unit) { detectTapGestures { play?.invoke() } } else Modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        FlareIconControl(
            label = control.label,
            onClick = onPlay,
            // The disc keeps its place in the row; the 48 dp target reaches past it into the bubble's padding.
            modifier = if (onPlay != null) Modifier.flareTouchTargetBeyond(FlareSizes.controlHeightSm) else Modifier,
            minSize = if (onPlay != null) FlareSizes.touchTarget else 0.dp,
        ) {
            Box(Modifier.size(FlareSizes.controlHeightSm).clip(CircleShape).background(colors.primary.copy(alpha = FlareOpacity.tintWeak)))
            Icon(flareIconVector(control.icon), null, Modifier.size(FlareSizes.iconSizeSm), tint = if (failed) colors.textSecondary else colors.primaryText)
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            for (n in 1..VOICE_BARS) {
                Box(
                    Modifier.size(2.dp, (4 + (n * 5) % 13).dp).clip(RoundedCornerShape(2.dp))
                        .background(if (n <= lit) colors.primary else colors.primary.copy(alpha = FlareOpacity.tintStrong)),
                )
            }
        }
        Text(
            time.text, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1,
            modifier = time.spoken?.let { spoken -> Modifier.semantics { contentDescription = spoken } } ?: Modifier,
        )
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
        Modifier.widthIn(max = 300.dp).onClickIf(onOpen),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2sm),
    ) {
        if (icon != null) icon() else Icon(Icons.Outlined.Description, null, Modifier.size(20.dp), tint = colors.primaryText)
        Column(Modifier.weight(1f, fill = false)) {
            Text(name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(sub, color = colors.textTertiary, fontSize = 11.sp)
        }
        // With a host download handler the glyph is a named button with a 48 dp target; without one
        // it stays a small decorative mark and the card keeps its compact height.
        FlareIconControl(label = flareStrings().download, onClick = onDownload, minSize = if (onDownload != null) FlareSizes.touchTarget else 0.dp) {
            Icon(flareIconVector("download"), null, Modifier.size(17.dp), tint = colors.textTertiary)
        }
    }
}

/** location — a map image (or placeholder) over title / address; emits [onOpen]. */
@Composable
fun LocationMessage(title: String, address: String = "", mapImage: String? = null, onOpen: (() -> Unit)? = null) {
    val colors = flareColors()
    Column(Modifier.width(264.dp).onClickIf(onOpen)) {
        NetImage(mapImage, Modifier.fillMaxWidth().height(84.dp)) {
            Box(
                Modifier.fillMaxWidth().height(84.dp)
                    .background(colors.primary.copy(alpha = 0.08f).compositeOverColor(colors.bgTertiary)),
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Outlined.LocationOn, null, Modifier.size(22.dp), tint = colors.primaryText) }
        }
        Column(Modifier.padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm)) {
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
        Modifier.widthIn(min = 240.dp).onClickIf(onOpen),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        NetImage(avatarUrl, Modifier.size(44.dp).clip(RoundedCornerShape(FlareSizes.radiusLg)).background(tint.first)) {
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
fun LinkCardMessage(title: String, domain: String = "", thumb: String? = null, description: String? = null, onOpen: (() -> Unit)? = null,
    icon: (@Composable () -> Unit)? = null, descriptionMaxLines: Int = 2) {
    val colors = flareColors()
    Row(
        Modifier.widthIn(max = 300.dp).onClickIf(onOpen).padding(horizontal = FlareSizes.spacing2sm, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2sm),
    ) {
        if (icon != null) icon() else NetImage(thumb, Modifier.size(48.dp).clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgTertiary)) {
            Icon(Icons.Outlined.Image, null, Modifier.size(22.dp), tint = colors.textTertiary)
        }
        Column(Modifier.weight(1f, fill = false), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                fontWeight = FontWeight.Medium, maxLines = 2, overflow = TextOverflow.Ellipsis)
            if (!description.isNullOrEmpty()) {
                Text(description, color = colors.textSecondary, fontSize = 12.sp, maxLines = descriptionMaxLines, overflow = TextOverflow.Ellipsis)
            }
            if (domain.isNotEmpty()) Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                Icon(Icons.Outlined.Link, null, Modifier.size(12.dp), tint = colors.textTertiary)
                Text(domain, color = colors.textTertiary, fontSize = 11.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

/** A vote option for [VoteMessage]. */
data class FlareVoteOption(val text: String, val pct: Int? = null)

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
        Modifier.widthIn(min = 220.dp).padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacing2sm),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
            Icon(Icons.Outlined.BarChart, null, Modifier.size(16.dp), tint = colors.textPrimary)
            Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.SemiBold)
        }
        options.forEachIndexed { i, o ->
            Box(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget).clip(RoundedCornerShape(7.dp)).background(colors.textPrimary.copy(alpha = 0.08f))
                    .onClickIf(if (onSelect != null) ({ onSelect(o, i) }) else null),
            ) {
                if (o.pct != null) Box(Modifier.fillMaxWidth((o.pct.coerceIn(0, 100)) / 100f).height(FlareSizes.touchTarget)
                    .background(colors.primary.copy(alpha = 0.16f)))
                Row(Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget).padding(horizontal = FlareSizes.spacing2sm), verticalAlignment = Alignment.CenterVertically) {
                    Text(o.text, color = colors.textPrimary, fontSize = 13.sp, modifier = Modifier.weight(1f))
                    if (o.pct != null) Text("${o.pct}%", color = colors.textSecondary, fontSize = 12.sp)
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
    // With [onToggle] the box is a checkbox named by the task title, holding the done state, in a
    // 48 dp target. The target adds 14 dp around the 20 dp box; a negative gap takes that margin back
    // on the title side so the title keeps its 10 dp distance from the box.
    val toggles = onToggle != null
    Row(
        Modifier.widthIn(min = 220.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(if (toggles) (10 - 14).dp else FlareSizes.spacing2sm),
    ) {
        FlareIconControl(
            label = title,
            onClick = onToggle,
            checked = done,
            role = Role.Checkbox,
            shape = RoundedCornerShape(FlareSizes.radiusSm),
            minSize = if (toggles) FlareSizes.touchTarget else 0.dp,
        ) {
            Box(
                Modifier.size(20.dp).clip(RoundedCornerShape(FlareSizes.radiusSm))
                    .then(if (done) Modifier.background(colors.primary) else Modifier.border(1.5.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusSm))),
                contentAlignment = Alignment.Center,
            ) { if (done) Icon(Icons.Rounded.Check, null, Modifier.size(13.dp), tint = Color.White) }
        }
        Column(Modifier.weight(1f, fill = false)) {
            Text(
                title,
                color = if (done) colors.textTertiary else colors.textPrimary,
                fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.Medium,
                textDecoration = if (done) TextDecoration.LineThrough else null,
                // The checkbox already carries the title as its name.
                modifier = if (toggles) Modifier.clearAndSetSemantics {} else Modifier,
            )
            if (!meta.isNullOrEmpty()) Text(meta, color = colors.textTertiary, fontSize = 11.sp)
        }
    }
}

/** sticker — a bare, larger glyph (no bubble); emits [onTap]. */
@Composable
fun StickerMessage(
    emoji: String = "", onTap: (() -> Unit)? = null,
    url: String? = null, packageId: String? = null, stickerId: String? = null,
    width: Int? = null, height: Int? = null,
) {
    Box(Modifier.onClickIf(onTap)) {
        if (url != null || stickerId != null) {
            FlareStickerPackMessage(stickerId = stickerId.orEmpty(), packageId = packageId,
                url = url, width = width, height = height)
        } else EmojiMessage(emoji)
    }
}

/** emoji — a bare, large emoji (no bubble); emits [onTap]. */
@Composable
fun EmojiMessage(emoji: String = "🎉", onTap: (() -> Unit)? = null) {
    Box(Modifier.onClickIf(onTap)) { FlareEmojiPackMessage(emoji) }
}

/** notification / system — a centered pill. */
@Composable
fun SystemMessage(text: String) {
    val colors = flareColors()
    Text(
        text, color = colors.textTertiary, fontSize = 12.sp,
        modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgTertiary)
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
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
