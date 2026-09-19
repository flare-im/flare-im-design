package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.InlineTextContent
import androidx.compose.foundation.text.appendInlineContent
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withLink
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * rich text — the RichDoc v2 document the core stores for a rich-text message ([docJson]), drawn as
 * headings, paragraphs, quotes, code, lists and rules with their marks, links, mentions and emoji
 * (`spec/rich-doc-vectors.json`), under the message's [title] when it has one. A document that is not drawable
 * shows [plainText], the core's own flat text; a message with neither shows the rich-text term.
 *
 * A link reaches [onLinkTap] only when [safeExternalUrl] accepts it; a refused link keeps its words. A spoiler
 * stays covered, and is named for TalkBack, until the reader taps it. Colours follow [TextMessage].
 */
@Composable
fun RichTextMessage(
    docJson: String,
    plainText: String = "",
    title: String = "",
    self: Boolean = false,
    selectable: Boolean = false,
    onLinkTap: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val blocks = remember(docJson) { flareParseRichDoc(docJson) }
    var revealed by remember(docJson) { mutableStateOf(false) }
    val emojiKeys = remember(blocks) { flareRichEmojiKeys(blocks.orEmpty()) }
    val catalogLoaded = if (emojiKeys.isNotEmpty()) rememberCatalogLoaded() else false
    val drawable = remember(emojiKeys, catalogLoaded) {
        if (catalogLoaded) emojiKeys.filterTo(LinkedHashSet()) { FlareEmojiStickerCatalog.hasEmojiKey(it) } else emptySet()
    }
    val inlineEmoji = if (drawable.isEmpty()) emptyMap() else rememberFlareInlineEmojiContent(drawable)
    val foreground = if (self) colors.messageOutgoingForeground else colors.messageIncomingForeground
    val paint = FlareRichPaint(
        foreground = foreground,
        link = if (self) foreground else colors.primary,
        mention = colors.primaryText,
        self = self,
        revealed = revealed,
        spoilerLabel = strings.messageSpoilerReveal,
        drawableEmoji = drawable,
    )
    val body: @Composable () -> Unit = {
        Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
            val heading = title.trim()
            if (heading.isNotEmpty()) {
                Text(heading, color = foreground, fontSize = FlareSizes.fontSizeXl * 1.12f, fontWeight = FontWeight.Bold)
            }
            if (blocks.isNullOrEmpty()) {
                Text(plainText.trim().ifEmpty { strings.previewRichText }, color = foreground, fontSize = FlareSizes.fontSizeXl)
            } else {
                for (block in blocks) RichBlock(block, paint, inlineEmoji, onLinkTap) { revealed = true }
            }
        }
    }
    if (selectable) SelectionContainer { body() } else body()
}

/** Everything a block needs to draw itself. */
internal data class FlareRichPaint(
    val foreground: Color,
    val link: Color,
    val mention: Color,
    val self: Boolean,
    val revealed: Boolean,
    val spoilerLabel: String,
    val drawableEmoji: Set<String> = emptySet(),
)

@Composable
private fun RichBlock(
    block: FlareRichBlock,
    paint: FlareRichPaint,
    inlineEmoji: Map<String, InlineTextContent>,
    onLinkTap: ((String) -> Unit)?,
    onReveal: () -> Unit,
) {
    when (block) {
        is FlareRichBlock.Paragraph -> RichRuns(block.runs, paint, FlareSizes.fontSizeXl, FontWeight.Normal, inlineEmoji, onLinkTap, onReveal)
        is FlareRichBlock.Heading -> {
            val scale = when (block.level) { 1 -> 1.18f; 2 -> 1.12f; else -> 1.04f }
            RichRuns(block.runs, paint, FlareSizes.fontSizeXl * scale, FontWeight.Bold, inlineEmoji, onLinkTap, onReveal)
        }
        is FlareRichBlock.Quote -> Row(Modifier.height(IntrinsicSize.Min)) {
            Box(Modifier.width(3.dp).fillMaxHeight().background(paint.foreground.copy(alpha = 0.42f)))
            Column(
                Modifier.background(paint.foreground.copy(alpha = 0.08f))
                    .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs),
            ) {
                val quoted = paint.copy(foreground = paint.foreground.copy(alpha = 0.82f))
                for (child in block.blocks) RichBlock(child, quoted, inlineEmoji, onLinkTap, onReveal)
            }
        }
        is FlareRichBlock.Code -> Box(
            Modifier.clip(RoundedCornerShape(FlareSizes.radiusSm))
                .background(paint.foreground.copy(alpha = 0.08f))
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
        ) {
            Text(block.text, color = paint.foreground, fontFamily = FontFamily.Monospace,
                fontSize = FlareSizes.fontSizeXl * 0.92f, softWrap = false)
        }
        is FlareRichBlock.ListBlock -> Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
            block.items.forEachIndexed { index, item ->
                Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                    Text(if (block.ordered) "${index + 1}." else "•", color = paint.foreground, fontSize = FlareSizes.fontSizeXl)
                    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
                        for (child in item) RichBlock(child, paint, inlineEmoji, onLinkTap, onReveal)
                    }
                }
            }
        }
        FlareRichBlock.Divider -> Box(Modifier.fillMaxWidth().height(1.dp).background(paint.foreground.copy(alpha = 0.18f)))
    }
}

@Composable
private fun RichRuns(
    runs: List<FlareRichRun>,
    paint: FlareRichPaint,
    fontSize: TextUnit,
    weight: FontWeight,
    inlineEmoji: Map<String, InlineTextContent>,
    onLinkTap: ((String) -> Unit)?,
    onReveal: () -> Unit,
) {
    val annotated = flareRichRunsText(runs, paint, fontSize, onLinkTap, onReveal)
    val covered = !paint.revealed && runs.any { it.has(FlareRichMark.Spoiler) }
    Text(
        annotated,
        color = paint.foreground,
        fontSize = fontSize,
        fontWeight = weight,
        lineHeight = (fontSize.value * 1.45f).sp,
        inlineContent = inlineEmoji,
        modifier = if (covered) Modifier.semantics { contentDescription = flareRichSpokenText(runs, paint) } else Modifier,
    )
}

/** The pack keys a document's emoji runs name, in the order they appear. */
internal fun flareRichEmojiKeys(blocks: List<FlareRichBlock>): Set<String> = buildSet {
    fun visit(list: List<FlareRichBlock>) {
        for (block in list) when (block) {
            is FlareRichBlock.Paragraph -> block.runs.mapNotNullTo(this) { it.emoji?.takeIf(String::isNotEmpty) }
            is FlareRichBlock.Heading -> block.runs.mapNotNullTo(this) { it.emoji?.takeIf(String::isNotEmpty) }
            is FlareRichBlock.Quote -> visit(block.blocks)
            is FlareRichBlock.ListBlock -> block.items.forEach(::visit)
            else -> Unit
        }
    }
    visit(blocks)
}

/** What TalkBack reads for runs with a covered spoiler: the spoiler's name in its place. */
internal fun flareRichSpokenText(runs: List<FlareRichRun>, paint: FlareRichPaint): String =
    runs.joinToString("") { if (it.has(FlareRichMark.Spoiler) && !paint.revealed) paint.spoilerLabel else it.text }

/** The tag a covered spoiler's clickable carries. */
internal const val FLARE_RICH_SPOILER_TAG = "flare-spoiler"

/**
 * One paragraph's runs as styled text: marks, inline code, mentions, links that [safeExternalUrl] accepts (clickable
 * only when there is an [onLinkTap]), the drawable emoji as inline content, and covered spoilers — the words on a
 * ground of their own colour, clickable to reveal.
 */
internal fun flareRichRunsText(
    runs: List<FlareRichRun>,
    paint: FlareRichPaint,
    fontSize: TextUnit,
    onLinkTap: ((String) -> Unit)?,
    onReveal: () -> Unit,
): AnnotatedString = buildAnnotatedString {
    for (run in runs) {
        if (run.has(FlareRichMark.Spoiler) && !paint.revealed) {
            // The words are not drawn at all while covered: blank space as wide as them, on a ground in the text colour.
            withLink(LinkAnnotation.Clickable(FLARE_RICH_SPOILER_TAG) { onReveal() }) {
                withStyle(SpanStyle(background = paint.foreground)) { append(flareRichSpoilerCover(run.text)) }
            }
            continue
        }
        val key = run.emoji
        if (key != null && key in paint.drawableEmoji) {
            appendInlineContent(flareInlineEmojiId(key), run.text)
            continue
        }
        val decorations = buildList {
            if (run.has(FlareRichMark.Underline)) add(TextDecoration.Underline)
            if (run.has(FlareRichMark.Strike)) add(TextDecoration.LineThrough)
        }
        var style = SpanStyle(
            fontWeight = when {
                run.mention != null -> if (paint.self) FontWeight.SemiBold else FontWeight.Medium
                run.has(FlareRichMark.Bold) -> FontWeight.Bold
                else -> null
            },
            fontStyle = if (run.has(FlareRichMark.Italic)) FontStyle.Italic else null,
            textDecoration = if (decorations.isEmpty()) null else TextDecoration.combine(decorations),
        )
        if (run.code) {
            style = style.merge(SpanStyle(fontFamily = FontFamily.Monospace, fontSize = fontSize * 0.92f,
                background = paint.foreground.copy(alpha = 0.10f)))
        }
        if (run.mention != null && !paint.self) style = style.merge(SpanStyle(color = paint.mention))
        val url = run.link?.let(::safeExternalUrl)
        if (url == null) {
            withStyle(style) { append(run.text) }
            continue
        }
        val linkStyle = style.merge(SpanStyle(color = paint.link, textDecoration = TextDecoration.Underline))
        if (onLinkTap != null) {
            withLink(LinkAnnotation.Url(url, TextLinkStyles(linkStyle)) { onLinkTap(url) }) { append(run.text) }
        } else {
            withStyle(linkStyle) { append(run.text) }
        }
    }
}
