package com.flare.im.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.height
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.material.icons.outlined.*
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.EmojiEmotions
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * The two shapes a composer takes, resolved once so the layout below reads as
 * one composer with values in it rather than two layouts interleaved.
 *
 * [band] is a phone: the field runs the full width of the screen with the
 * rounding taken off, and the tools rest on the app ground below it. Anything
 * wider keeps the bordered card the desktop layout is built around.
 */
private data class ComposerMetrics(
    val band: Boolean,
    val textStart: Dp,
    val textTop: Dp,
    val textBottom: Dp,
    val stripKeyWidth: Dp,
    val stripKeyHeight: Dp,
    val stripInset: Dp,
    val toolInset: Dp,
) {
    companion object {
        fun of(width: Dp, keys: Int): ComposerMetrics =
            if (width >= 600.dp) {
                ComposerMetrics(false, 12.dp, 12.dp, 8.dp, 36.dp, 32.dp, 0.dp, 0.dp)
            } else {
                // 11 above and below a 24dp line is a 46dp band: the text sits in
                // the middle of it without the field growing into a panel of its
                // own. The tool inset is whatever the keys do not need, up to 10 —
                // seven 44dp targets already fill a 320dp screen, and the targets
                // are the part that must not shrink.
                ComposerMetrics(
                    true, 16.dp, 11.dp, 11.dp, 44.dp, 44.dp, 6.dp,
                    ((width - (keys * 44).dp) / 2).coerceIn(0.dp, 10.dp),
                )
            }
    }
}

/** A lightweight reply target shown as a strip above the composer input. */
data class FlareReplyTarget(val senderName: String, val summary: String)

/**
 * The message input — plain or rich text, attach, emoji, send, optional reply
 * strip. Spec: Composer/Composer (`Composer`). Send is optimistic: [onSend]
 * fires immediately; the host does the local echo + core write.
 */
@Composable
fun Composer(
    modifier: Modifier = Modifier,
    rich: Boolean = false,
    placeholder: String = "消息",
    disabled: Boolean = false,
    replyTo: FlareReplyTarget? = null,
    /** Prefix on the reply strip above the input, e.g. "Reply Ivy". */
    replyLabel: String = "回复",
    maxLength: Int? = null,
    /** Optional brand accent for the active send button (e.g. a gradient). Defaults to `primary`. */
    sendAccent: androidx.compose.ui.graphics.Brush? = null,
    onSend: ((String) -> Unit)? = null,
    onAttach: (() -> Unit)? = null,
    onImage: (() -> Unit)? = null,
    onSendRich: ((String) -> Unit)? = null,
    onEmoji: (() -> Unit)? = null,
    onCancelReply: (() -> Unit)? = null,
    actions: List<FlareComposerAction>? = null,
    onAction: ((FlareComposerAction) -> Unit)? = null,
    enableVoice: Boolean = false,
    conversationKey: String = "",
    onVoiceSend: (suspend (String, Int) -> Boolean)? = null,
    /** Hold-to-talk labels — forwarded to [FlareVoiceHoldButton] so hosts can localize them. */
    voiceLabel: String = "按住 说话",
    voiceRecordingLabel: String = "松开发送 · 上滑取消",
    voiceCancelLabel: String = "松开取消",
    onVoiceStart: (() -> Unit)? = null,
    onVoiceEnd: (() -> Unit)? = null,
    onVoiceCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var text by remember(conversationKey) { mutableStateOf("") }
    var voiceMode by remember(conversationKey) { mutableStateOf(false) }
    var panelOpen by remember(conversationKey) { mutableStateOf(false) }
    var expanded by remember(conversationKey) { mutableStateOf(false) }
    var richMode by remember(conversationKey) { mutableStateOf(rich) }
    var formats by remember(conversationKey) { mutableStateOf(setOf<String>()) }
    val canSend = text.isNotBlank() && !disabled && (onSend != null || onSendRich != null)
    fun send() {
        if (!canSend) return
        var orderedIndex = 0
        if (richMode && onSendRich != null) onSendRich(text.trim().lines().mapIndexed { _, line ->
            if (line.isBlank()) return@mapIndexed ""
            orderedIndex++
            var value = line
            if ("link" in formats) value = "[$value](${if (value.startsWith("http://") || value.startsWith("https://")) value else "https://"})"
            if ("code" in formats) value = "`$value`"
            if ("bold" in formats) value = "**$value**"
            if ("italic" in formats) value = "*$value*"
            if ("strike" in formats) value = "~~$value~~"
            when { "heading" in formats -> "## $value"; "quote" in formats -> "> $value"; "bullet" in formats -> "- $value"; "ordered" in formats -> "${orderedIndex}. $value"; else -> value }
        }.joinToString("\n")) else onSend?.invoke(text.trim())
        text = ""
    }
    @Composable fun tool(icon: ImageVector, label: String, enabled: Boolean = !disabled, active: Boolean = false, action: () -> Unit) {
        IconButton(onClick = action, enabled = enabled, modifier = Modifier.size(44.dp)) {
            Icon(icon, label, Modifier.size(20.dp), tint = if (!enabled) colors.textDisabled else if (active) colors.primary else colors.textSecondary)
        }
    }
    // One row, two homes: inside the card on a tablet, on the app ground below
    // the band on a phone. Writing it twice is how the two drift apart.
    @Composable fun tools(m: ComposerMetrics) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = m.toolInset),
            horizontalArrangement = if (m.band) Arrangement.SpaceBetween else Arrangement.End,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            tool(Icons.Outlined.EmojiEmotions, "Emoji", enabled = !disabled && onEmoji != null) { onEmoji?.invoke(); panelOpen = false }
            tool(Icons.Outlined.AlternateEmail, "Mention") { text += "@"; panelOpen = false }
            if (enableVoice && onVoiceSend != null) tool(Icons.Outlined.MicNone, "Voice") { voiceMode = true; panelOpen = false }
            tool(Icons.Outlined.Image, "Image", enabled = !disabled && (onImage != null || onAttach != null)) { (onImage ?: onAttach)?.invoke() }
            tool(Icons.Outlined.Title, "Rich text", active = richMode) { richMode = !richMode; if (!richMode) formats = emptySet(); panelOpen = false }
            tool(if (panelOpen) Icons.Outlined.Close else Icons.Outlined.Add, "More", active = panelOpen) { if (actions != null) panelOpen = !panelOpen else onAttach?.invoke() }
            FlareComposerSendButton(active = canSend) { send() }
        }
    }
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val m = ComposerMetrics.of(maxWidth, keys = 6 + if (enableVoice && onVoiceSend != null) 1 else 0)
        Column(
            Modifier.fillMaxWidth().background(if (m.band) colors.bgSecondary else colors.bgPrimary)
                .then(if (m.band) Modifier.padding(bottom = 4.dp) else Modifier.padding(horizontal = 4.dp, vertical = 8.dp))
        ) {
            replyTo?.let { ReplyStrip(it, replyLabel, colors, onCancelReply, m.band) }
            if (voiceMode && onVoiceSend != null) {
                InlineVoiceComposer(conversationKey, disabled, onKeyboard = { voiceMode = false }, onSend = onVoiceSend)
            } else {
                Column(
                    Modifier.fillMaxWidth().background(colors.bgPrimary)
                        .then(if (m.band) Modifier else Modifier.border(1.dp, colors.borderPrimary, RoundedCornerShape(12.dp)))
                ) {
                    if (!panelOpen) {
                        if (richMode) Row(Modifier.fillMaxWidth().height(m.stripKeyHeight).horizontalScroll(rememberScrollState()).padding(horizontal = m.stripInset)) {
                            val styles = listOf("bold" to Icons.Outlined.FormatBold, "italic" to Icons.Outlined.FormatItalic, "strike" to Icons.Outlined.FormatStrikethrough, "code" to Icons.Outlined.Code, "link" to Icons.Outlined.Link, "heading" to Icons.Outlined.Title, "quote" to Icons.Outlined.FormatQuote, "bullet" to Icons.AutoMirrored.Outlined.FormatListBulleted, "ordered" to Icons.Outlined.FormatListNumbered)
                            styles.forEach { (id, icon) -> IconButton(onClick = { val blocks = setOf("heading", "quote", "bullet", "ordered"); formats = if (id in formats) formats - id else (if (id in blocks) formats - blocks else formats) + id }, enabled = !disabled, modifier = Modifier.size(m.stripKeyWidth, m.stripKeyHeight)) { Icon(icon, id, Modifier.size(14.dp), tint = if (id in formats) colors.primary else colors.textSecondary) } }
                        }
                        // The row is the top of the same band; a hairline is all
                        // that separates it from the text it formats.
                        if (richMode) HorizontalDivider(color = colors.borderPrimary)
                        Row(verticalAlignment = Alignment.Top) {
                            // 11 above and below a 24dp line is a 46dp band: the
                            // text sits in the middle of it without the field
                            // growing into a panel of its own.
                            Box(Modifier.weight(1f).padding(start = m.textStart, top = m.textTop, bottom = m.textBottom)) {
                                BasicTextField(value = text, onValueChange = { if (maxLength == null || it.length <= maxLength) text = it }, enabled = !disabled,
                                    minLines = if (expanded) 9 else 1, maxLines = if (expanded) 14 else 5,
                                    textStyle = TextStyle(color = if ("link" in formats) colors.primary else colors.textPrimary, fontSize = 15.sp, fontWeight = if ("bold" in formats) FontWeight.Bold else FontWeight.Normal, fontStyle = if ("italic" in formats) FontStyle.Italic else FontStyle.Normal, textDecoration = if ("strike" in formats) TextDecoration.LineThrough else if ("link" in formats) TextDecoration.Underline else TextDecoration.None), cursorBrush = SolidColor(colors.primary),
                                    modifier = Modifier.fillMaxWidth(), decorationBox = { inner -> Box { if (text.isEmpty()) Text(placeholder, color = colors.textTertiary, fontSize = 15.sp); inner() } })
                            }
                            tool(if (expanded) Icons.Outlined.CloseFullscreen else Icons.Outlined.OpenInFull, if (expanded) "Collapse input" else "Expand input") { expanded = !expanded }
                        }
                    }
                    if (!m.band) tools(m)
                }
                // The tools leave the band and rest on the ground, taking back
                // the inset the band gave up.
                if (m.band) tools(m)
                if (panelOpen && actions != null) Column(Modifier.fillMaxWidth().background(colors.bgPrimary).heightIn(max = 240.dp).verticalScroll(rememberScrollState())) { FlareComposerActionPanel(actions, onAction = { onAction?.invoke(it); panelOpen = false }) }
            }
        }
    }
}

@Composable
private fun ReplyStrip(
    reply: FlareReplyTarget,
    label: String,
    colors: FlareColors,
    onCancel: (() -> Unit)?,
    band: Boolean = false,
) {
    // In the band the strip is part of it: same white, same full width, closed
    // by the same hairline. As a rounded card on the ground it reads as a
    // separate object from the message it is attached to.
    Row(
        Modifier.fillMaxWidth()
            .then(
                if (band) {
                    Modifier.background(colors.bgPrimary)
                } else {
                    Modifier.padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs)
                        .clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)
                }
            )
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(3.dp).size(width = 3.dp, height = 28.dp).background(colors.primary))
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Column(Modifier.weight(1f)) {
            Text("$label ${reply.senderName}", color = colors.primary, fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold)
            Text(reply.summary, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        IconButton(onClick = { onCancel?.invoke() }) { Icon(Icons.Rounded.Close, null, Modifier.size(18.dp), tint = colors.textTertiary) }
    }
}
