package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale

/** The core's ForwardMode: how a forward was sent. One item that is not [Merged] draws inline. */
enum class FlareForwardMode { Unspecified, Single, Merged }

/**
 * One message of a merged-forward record: its original sender's name (core `sourceSenderName`), when it was sent
 * (`sourceMessageTimeMs`), its plain text and its content, mapped by the host like any message content.
 */
data class FlareForwardItem(
    val senderName: String = "",
    val sentAtMs: Long = 0,
    val plainText: String = "",
    val content: FlareMessageContent? = null,
)

/**
 * A merged-forward record — the chat history card (core content type `forward`, the `card` surface), drawn as the Vue
 * kit's ForwardView draws it (spec/message-forward-vectors.json, dataTypes ForwardContent). [title] is the record's own
 * title; [mode] the core's ForwardMode (`0` unspecified, `1` single, `2` merged).
 */
data class FlareForwardContent(
    val items: List<FlareForwardItem>,
    val title: String = "",
    val mode: FlareForwardMode = FlareForwardMode.Unspecified,
) : FlareMessageContent {
    override val type get() = "forward"
}

/** What a record shows (spec/message-forward-vectors.json). */
data class FlareForwardRecordView(
    val layout: Layout,
    val title: String,
    /** "共 N 条消息" when the record holds more than one message. */
    val subtitle: String?,
    /** The first three messages as sender and one-line summary. */
    val previews: List<Pair<String, String>>,
    /** "还有 N 条消息…" past the first three. */
    val more: String?,
    val hint: String,
    /** The card's accessible name. */
    val label: String,
    val drawerTitle: String,
) {
    enum class Layout { Empty, Single, Card }
}

/** How many preview lines the card shows. */
const val FLARE_FORWARD_PREVIEW_LIMIT = 3

/** A forwarded message's sender: its name, else "unknown sender" — an account id is internal and never shown. */
fun flareForwardSender(item: FlareForwardItem, strings: FlareStrings): String =
    item.senderName.trim().ifEmpty { strings.forwardRecordUnknownSender }

/**
 * A forwarded message's initial for the drawer avatar: the first character of its sender's name, upper-cased, else "?"
 * — never the first character of "unknown sender".
 */
fun flareForwardSenderInitial(item: FlareForwardItem): String {
    val name = item.senderName.trim()
    if (name.isEmpty()) return "?"
    return name.substring(0, name.offsetByCodePoints(0, 1)).uppercase()
}

/**
 * A forwarded message's one-line summary: its plain text — the core's words for it, read as any text body's summary is
 * (Markdown to plain text, emoji-pack keys in the reader's language) — else its content's summary, else "[转发]".
 */
fun flareForwardPreviewLine(item: FlareForwardItem, strings: FlareStrings, locale: Locale): String {
    val tag = locale.toLanguageTag()
    val words = item.plainText.trim()
    return (if (words.isEmpty()) "" else flareMessagePreviewText(FlareTextContent(words), strings, tag).trim())
        .ifEmpty { flareMessagePreviewText(item.content, strings, tag).trim() }
        .ifEmpty { strings.previewForward }
}

/** The record's layout, title, counts and copy (spec/message-forward-vectors.json). */
fun flareForwardRecordView(content: FlareForwardContent, strings: FlareStrings, locale: Locale): FlareForwardRecordView {
    val count = content.items.size
    val layout = when {
        count == 0 -> FlareForwardRecordView.Layout.Empty
        count == 1 && content.mode != FlareForwardMode.Merged -> FlareForwardRecordView.Layout.Single
        else -> FlareForwardRecordView.Layout.Card
    }
    val title = content.title.trim().ifEmpty { strings.forwardRecordTitle }
    val subtitle = if (count > 1) flarePlural(count.toLong(), strings.forwardRecordTotalOne, strings.forwardRecordTotal, locale) else null
    val beyond = count - FLARE_FORWARD_PREVIEW_LIMIT
    return FlareForwardRecordView(
        layout = layout,
        title = title,
        subtitle = subtitle,
        previews = content.items.take(FLARE_FORWARD_PREVIEW_LIMIT).map { flareForwardSender(it, strings) to flareForwardPreviewLine(it, strings, locale) },
        more = if (beyond > 0) flarePlural(beyond.toLong(), strings.forwardRecordMoreOne, strings.forwardRecordMore, locale) else null,
        hint = strings.forwardRecordViewDetails,
        label = subtitle?.let { strings.forwardRecordCardLabel.replace("{title}", title).replace("{subtitle}", it) } ?: title,
        drawerTitle = title + strings.forwardRecordCountSuffix.replace("{count}", count.toString()),
    )
}

/** A forwarded message's content: its own, else its plain text as a text body. */
private fun forwardItemContent(item: FlareForwardItem): FlareMessageContent = item.content ?: FlareTextContent(item.plainText.trim())

/**
 * The chat history card of a merged forward: the title, "共 N 条消息", the first three messages as "sender: summary",
 * "还有 N 条消息…" and "点击查看详情"; a tap opens the kit [Drawer] listing every message (sender, time, summary, and a
 * non-text content drawn under it). One message that is not a merged record draws inline; none says there is nothing.
 * On the card surface ([card]) the shell carries the row's [quote]. In [selectionMode] the card does not respond.
 */
@Composable
internal fun ForwardRecordMessage(
    content: FlareForwardContent,
    card: Boolean,
    quote: (@Composable () -> Unit)?,
    selectionMode: Boolean,
) {
    val strings = flareStrings()
    val colors = flareColors()
    val locale = flareLocale()
    val view = flareForwardRecordView(content, strings, locale)
    var open by remember(content) { mutableStateOf(false) }
    when (view.layout) {
        FlareForwardRecordView.Layout.Empty -> Text(strings.forwardRecordEmpty, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
        FlareForwardRecordView.Layout.Single -> FlareMessageCardShell(card, quote) { fill ->
            Box(fill) { ForwardedBody(forwardItemContent(content.items.first()), selectionMode) }
        }
        FlareForwardRecordView.Layout.Card -> FlareMessageCardShell(card, quote) { fill ->
            Column(
                fill.then(if (selectionMode) Modifier else Modifier.clickable(role = Role.Button) { open = true })
                    .clearAndSetSemantics {
                        contentDescription = view.label
                        if (!selectionMode) role = Role.Button
                    },
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                Text(view.title, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeMd.value.sp,
                    maxLines = 2, overflow = TextOverflow.Ellipsis)
                view.subtitle?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs.value.sp) }
                for ((sender, text) in view.previews) {
                    Text("$sender: $text", color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                view.more?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp) }
                Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingXs).height(1.dp).background(colors.borderSecondary))
                Text(view.hint, color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs.value.sp)
            }
        }
    }
    if (open && !selectionMode) {
        Drawer(onClose = { open = false }, title = view.drawerTitle) {
            ForwardRecordList(content, strings, locale)
        }
    }
}

/** The drawer's list: every forwarded message with its sender, time and summary, and a non-text content under it. */
@Composable
private fun ForwardRecordList(content: FlareForwardContent, strings: FlareStrings, locale: Locale) {
    val colors = flareColors()
    LazyColumn(Modifier.fillMaxWidth()) {
        itemsIndexed(content.items) { _, item ->
            Column(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val sender = flareForwardSender(item, strings)
                    Avatar(userId = sender, displayName = flareForwardSenderInitial(item), size = 28.dp)
                    Spacer(Modifier.width(FlareSizes.spacingSm))
                    Text(sender, color = colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeSm.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                    if (item.sentAtMs > 0) {
                        Spacer(Modifier.width(FlareSizes.spacingSm))
                        Text(forwardItemTime(item.sentAtMs, strings, locale), color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs.value.sp)
                    }
                }
                Text(flareForwardPreviewLine(item, strings, locale), color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.padding(start = 36.dp, top = FlareSizes.spacingXs))
                val embedded = item.content
                if (embedded != null && embedded !is FlareTextContent) {
                    Box(Modifier.padding(start = 36.dp, top = FlareSizes.spacingXs).clip(RoundedCornerShape(FlareSizes.radiusMd))) {
                        ForwardedBody(embedded, selectionMode = false)
                    }
                }
            }
        }
    }
}

/**
 * A forwarded message's own body: drawn as standalone content (no row surface, no card quote — the record's card is the
 * surface), as someone else's message whoever forwarded it.
 */
@Composable
private fun ForwardedBody(content: FlareMessageContent, selectionMode: Boolean) {
    CompositionLocalProvider(LocalFlareMessageSurface provides null, LocalFlareCardQuote provides null) {
        MessageContentView(content, isSelf = false, selectionMode = selectionMode)
    }
}

/** HH:mm on the same local day, else the day (yesterday, or month and day) and HH:mm, in the kit locale. */
private fun forwardItemTime(epochMs: Long, strings: FlareStrings, locale: Locale): String {
    val clock = FlareTimeFormat.messageTime(epochMs, locale)
    return when (FlareTimeFormat.timelineDayKind(epochMs, System.currentTimeMillis())) {
        FlareTimelineDayKind.Today -> clock
        else -> "${FlareTimeFormat.timelineDateLabel(epochMs, strings.today, strings.yesterday, locale)} $clock"
    }
}
