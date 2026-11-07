package com.flare.im.ui

import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.height
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.material.icons.outlined.*
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconToggleButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.LocalView
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

/**
 * The icon keys of the composer's tool row, in order: registry glyph, the name TalkBack reads, and
 * whether each is enabled. Rich text is a toggle that is checked while rich mode is on; more opens and
 * closes the action panel and draws `close` while the panel is open. The send key follows them.
 * [capabilities] leaves out each key the host does not offer ([FlareComposerCapabilities.availableToolIds];
 * the more key is the `attachments` tool).
 */
internal fun composerToolKeys(
    strings: FlareStrings,
    disabled: Boolean,
    canEmoji: Boolean,
    canVoice: Boolean,
    canImage: Boolean,
    canMore: Boolean,
    richMode: Boolean,
    panelOpen: Boolean?,
    /** Null where the host owns the panel: the key is then a plain button with no state to report. */
    emojiOpen: Boolean? = null,
    capabilities: FlareComposerCapabilities = FlareComposerCapabilities(),
    mentionOpen: Boolean? = null,
): List<FlareIconControlSpec> = buildList {
    val allows = capabilities::allowsTool
    if (allows("emoji")) add(FlareIconControlSpec("emoji", "emoji", strings.composerEmoji, !disabled && canEmoji, checked = emojiOpen))
    if (allows("mention")) add(FlareIconControlSpec("mention", "mention", strings.composerMention, !disabled, checked = mentionOpen))
    if (canVoice && allows("voice")) add(FlareIconControlSpec("voice", "mic", strings.composerVoice, !disabled))
    if (allows("image")) add(FlareIconControlSpec("image", "image", strings.composerImage, !disabled && canImage))
    if (allows("richText")) add(FlareIconControlSpec("richText", "rich-text", strings.composerRichText, !disabled, checked = richMode))
    // "+" with nothing to open or attach is hidden, not drawn disabled.
    if (allows("attachments") && canMore) add(FlareIconControlSpec("more", if (panelOpen == true) "close" else "add", strings.composerMore, !disabled, checked = panelOpen))
}

/**
 * Whether a "+" tile opens the composer's own recorder: the voice tile does whenever the voice key could, so both reach
 * the same recorder (as on Flutter) and a host never has to recreate the composer's voice mode. The host still gets the
 * recording through `onVoiceSend`; without a recorder the tile goes to the host's `onAction`.
 */
internal fun composerPanelTileOpensRecorder(action: FlareComposerAction, offersVoice: Boolean): Boolean =
    action.id == "voice" && offersVoice

/** The key beside the text field that grows the input and shrinks it back, named for what it does next. */
internal fun composerExpandKey(strings: FlareStrings, disabled: Boolean, expanded: Boolean): FlareIconControlSpec =
    if (expanded) FlareIconControlSpec("expand", "collapse", strings.composerCollapseInput, !disabled)
    else FlareIconControlSpec("expand", "expand", strings.composerExpandInput, !disabled)

/**
 * A quoted message: the reply strip above the composer input, and the quote at the top
 * of a replying message's bubble. [messageId] is the quoted message's **core id** — the id the core knows
 * it by, which a host has for every quote it maps, loaded original or not. Set it to make the bubble quote
 * locate the original: the list matches it against both ids of each row ([FlareMessageData.id] and
 * [FlareMessageData.serverId]), so a host never converts it to a row id.
 */
data class FlareReplyTarget(
    val senderName: String,
    val summary: String,
    val messageId: String? = null,
    /** The quoted message's sender id: with no name, the quote reads 「用户 9876」 by its tail ([flareQuoteSenderText]). */
    val senderId: String? = null,
    /** The core's projected name for the quoted message's sender; written before [senderName] when given. */
    val sender: FlareDisplayName? = null,
)

/**
 * The message input — plain or rich text, attach, emoji, send, optional reply
 * strip. Spec: Composer/Composer (`Composer`). Send is optimistic: [onSend]
 * fires immediately; the host owns local echo and persistence.
 *
 * A non-null [value] makes the text controlled — a draft the host keeps, e.g. per
 * conversation: the field shows [value] and every edit, including the clear after a
 * send, arrives through [onValueChange]. With a null [value] the composer keeps its
 * own text per [conversationKey] and [onValueChange] only observes it.
 *
 * Kit-owned panels are mutually exclusive. They open below the editor and tools at any Android
 * width. Opening a panel from its tool dismisses the keyboard.
 * A typed mention leaves focus in the editor.
 */
@Suppress("NAME_SHADOWING")
@Composable
fun Composer(
    modifier: Modifier = Modifier,
    value: String? = null,
    onValueChange: ((String) -> Unit)? = null,
    /**
     * Every edit the person makes to the text — not the clear after a send, and not a text the host sets.
     * Hosts drive the typing signal ([FlareTypingSignal]) from this, never from [onValueChange], which also
     * reports the composer's own clear.
     */
    onUserInput: ((String) -> Unit)? = null,
    rich: Boolean = false,
    placeholder: String? = null,
    disabled: Boolean = false,
    replyTo: FlareReplyTarget? = null,
    /** Prefix on the reply strip above the input, e.g. "Reply Ivy". */
    replyLabel: String? = null,
    maxLength: Int? = null,
    /** Optional brand accent for the active send button (e.g. a gradient). Defaults to `primary`. */
    sendAccent: androidx.compose.ui.graphics.Brush? = null,
    onSend: ((String) -> Unit)? = null,
    onAttach: (() -> Unit)? = null,
    onImage: (() -> Unit)? = null,
    onSendRich: ((String) -> Unit)? = null,
    onEmoji: (() -> Unit)? = null,
    /** A sticker the person picked in the composer's own panel (FR-097): the host sends it. */
    onSendSticker: ((packageId: String, stickerId: String) -> Unit)? = null,
    onCancelReply: (() -> Unit)? = null,
    actions: List<FlareComposerAction>? = null,
    capabilities: FlareComposerCapabilities = FlareComposerCapabilities(),
    onAction: ((FlareComposerAction) -> Unit)? = null,
    enableVoice: Boolean = false,
    conversationKey: String = "",
    onVoiceSend: (suspend (String, Int) -> Boolean)? = null,
    /** Hold-to-talk labels — forwarded to [FlareVoiceHoldButton] so hosts can localize them. */
    voiceLabel: String? = null,
    voiceRecordingLabel: String? = null,
    voiceCancelLabel: String? = null,
    onVoiceStart: (() -> Unit)? = null,
    onVoiceEnd: (() -> Unit)? = null,
    onVoiceCancel: (() -> Unit)? = null,
    /**
     * Members to mention. Typing "@" at the start of a word or tapping the mention key opens an inline
     * [MentionPicker]. Typing after "@" filters the candidates. A pick replaces that token or writes
     * "@name " at the end of the draft when the mention key opened the picker.
     */
    mentionCandidates: List<MentionCandidate> = emptyList(),
    /** The picker offers everyone first (a group where the viewer may mention all members). */
    mentionEveryone: Boolean = false,
) {
    val strings = flareStrings()
    val placeholder = placeholder ?: strings.composerPlaceholder
    val replyLabel = replyLabel ?: strings.composerReply
    val voiceLabel = voiceLabel ?: strings.voiceHoldButtonLabel
    val voiceRecordingLabel = voiceRecordingLabel ?: strings.voiceHoldButtonRecording
    val voiceCancelLabel = voiceCancelLabel ?: strings.voiceHoldButtonCancel
    val colors = flareColors()
    val resolvedActions = resolveComposerActions(defaultComposerActions(), capabilities, actions)
    val hasActionPanel = onAction != null && resolvedActions.isNotEmpty()
    var localText by remember(conversationKey) { mutableStateOf("") }
    var mentionEdit by remember(conversationKey) { mutableStateOf<ComposerMentionEdit?>(null) }
    val text = value ?: localText
    fun updateText(next: String, byUser: Boolean = true, mentionCursor: Int? = null) {
        mentionEdit = mentionCursor?.let { ComposerMentionEdit(next, it) }
        if (value == null) localText = next
        onValueChange?.invoke(next)
        if (byUser) onUserInput?.invoke(next)
    }
    val view = LocalView.current
    val keyboard = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current
    fun dismissKeyboard() {
        keyboard?.hide()
        (view.findFocus() as? android.widget.EditText)?.clearFocus()
        focusManager.clearFocus()
    }
    var voiceMode by remember(conversationKey) { mutableStateOf(false) }
    var activePanel by remember(conversationKey) { mutableStateOf<ComposerPanel?>(null) }
    var expanded by remember(conversationKey) { mutableStateOf(false) }
    var richMode by remember(conversationKey) { mutableStateOf(rich) }
    var formats by remember(conversationKey) { mutableStateOf(setOf<String>()) }
    // Each toolbar key the host offers. A key taken away closes what it opened at once — the effective flags below
    // hide it in the same frame, the effect clears the state — and the draft stays.
    val allows = capabilities::allowsTool
    val offersVoice = enableVoice && onVoiceSend != null && allows("voice")
    val richOn = richMode && allows("richText")
    val hasMentions = mentionCandidates.isNotEmpty() || mentionEveryone
    val shownPanel = activePanel?.takeIf { panel ->
        !disabled && when (panel) {
            ComposerPanel.Emoji -> allows("emoji") && onEmoji == null
            ComposerPanel.More -> allows("attachments") && hasActionPanel
            is ComposerPanel.Mention -> allows("mention") && hasMentions &&
                (panel.trigger == null || panel.trigger.query(text) != null)
        }
    }
    LaunchedEffect(activePanel, shownPanel) { if (shownPanel == null) activePanel = null }
    LaunchedEffect(offersVoice, capabilities) {
        if (!offersVoice) voiceMode = false
        if (!allows("richText")) { richMode = false; formats = emptySet() }
    }
    FlareNativeBackEffect(enabled = shownPanel != null) { activePanel = null }
    fun togglePanel(panel: ComposerPanel) {
        dismissKeyboard()
        activePanel = if (shownPanel == panel) null else panel
    }
    // A pick writes the candidate's label, as Vue does: the core resolves "@label" against the conversation roster when the text is sent.
    val selectCurrentMention by rememberUpdatedState(pick@{ panel: ComposerPanel.Mention, picked: MentionCandidate ->
        if (shownPanel !== panel) return@pick
        val name = if (picked.isEveryone) strings.everyone.takeIf { mentionEveryone }
        else mentionCandidates.firstOrNull { it.id == picked.id }?.name
        if (name == null) return@pick
        val trigger = panel.trigger
        val query = trigger?.query(text)
        if (trigger != null && query == null) return@pick
        val start = trigger?.start
        val next = composerTextWithinLimit(composerTextWithMention(text, name, start, query?.length ?: 0), maxLength)
        val cursor = if (start == null) next.length else (start + name.length + 2).coerceAtMost(next.length)
        activePanel = null
        updateText(next, mentionCursor = cursor)
    })
    val canSend = text.isNotBlank() && !disabled && (onSend != null || onSendRich != null)
    fun send() {
        if (!canSend) return
        var orderedIndex = 0
        if (richOn && onSendRich != null) onSendRich(text.trim().lines().mapIndexed { _, line ->
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
        // The composer's own clear, not an edit: a host driving a typing signal must not read it as one.
        if (activePanel is ComposerPanel.Mention) activePanel = null
        updateText("", byUser = false)
    }
    @Composable fun tool(key: FlareIconControlSpec, active: Boolean = false, action: () -> Unit) {
        val glyph: @Composable () -> Unit = {
            Icon(flareIconVector(key.icon), key.label, Modifier.size(20.dp), tint = if (!key.enabled) colors.textDisabled else if (active) colors.primaryText else colors.textSecondary)
        }
        // A toggle key reports whether it is on; its container stays transparent, as on the plain keys.
        val checked = key.checked
        if (checked == null) IconButton(onClick = action, enabled = key.enabled, modifier = Modifier.size(FlareSizes.touchTargetMin), content = glyph)
        else IconToggleButton(checked = checked, onCheckedChange = { action() }, enabled = key.enabled, modifier = Modifier.size(FlareSizes.touchTargetMin), content = glyph)
    }
    // One row, two homes: inside the card on a tablet, on the app ground below
    // the band on a phone. Writing it twice is how the two drift apart.
    @Composable fun tools(m: ComposerMetrics) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = m.toolInset),
            horizontalArrangement = if (m.band) Arrangement.SpaceBetween else Arrangement.End,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            composerToolKeys(
                strings,
                disabled = disabled,
                // The composer opens its own panel when no host handles the key, so the key is always there.
                canEmoji = true,
                canVoice = enableVoice && onVoiceSend != null,
                canImage = onImage != null || onAttach != null,
                canMore = hasActionPanel || onAttach != null,
                richMode = richOn,
                panelOpen = if (hasActionPanel) shownPanel == ComposerPanel.More else null,
                emojiOpen = if (onEmoji == null) shownPanel == ComposerPanel.Emoji else null,
                capabilities = capabilities,
                mentionOpen = if (hasMentions) shownPanel is ComposerPanel.Mention else null,
            ).forEach { key ->
                when (key.id) {
                    // A host that handles the key keeps its own panel; otherwise the composer opens its own.
                    "emoji" -> tool(key, active = shownPanel == ComposerPanel.Emoji) {
                        if (onEmoji == null) togglePanel(ComposerPanel.Emoji) else {
                            dismissKeyboard()
                            activePanel = null
                            onEmoji.invoke()
                        }
                    }
                    "mention" -> tool(key, active = shownPanel is ComposerPanel.Mention) {
                        if (hasMentions) {
                            dismissKeyboard()
                            activePanel = if (shownPanel is ComposerPanel.Mention) null else ComposerPanel.Mention(trigger = null)
                        } else {
                            activePanel = null
                            updateText(composerTextWithinLimit(text + "@", maxLength))
                        }
                    }
                    "voice" -> tool(key) { dismissKeyboard(); voiceMode = true; activePanel = null }
                    "image" -> tool(key) { dismissKeyboard(); activePanel = null; (onImage ?: onAttach)?.invoke() }
                    "richText" -> tool(key, active = richOn) { richMode = !richMode; if (!richMode) formats = emptySet(); activePanel = null }
                    "more" -> tool(key, active = shownPanel == ComposerPanel.More) {
                        if (hasActionPanel) togglePanel(ComposerPanel.More) else {
                            dismissKeyboard()
                            activePanel = null
                            onAttach?.invoke()
                        }
                    }
                }
            }
            FlareComposerSendButton(active = canSend) { send() }
        }
    }
    @Composable fun panel(m: ComposerMetrics) {
        when (shownPanel) {
            ComposerPanel.Emoji -> FlareEmojiStickerPicker(
                onInsertEmoji = { key -> updateText(composerTextWithinLimit("$text[$key]", maxLength)) },
                onSendSticker = { packageId, stickerId ->
                    activePanel = null
                    onSendSticker?.invoke(packageId, stickerId)
                },
                modifier = Modifier.fillMaxWidth().heightIn(max = 240.dp),
            )
            ComposerPanel.More -> FlareComposerActionPanel(
                resolvedActions,
                formFactor = if (m.band) FlareComposerPanelFormFactor.Mobile else FlareComposerPanelFormFactor.Desktop,
                onAction = { action ->
                    if (disabled || !allows("attachments") || !action.enabled) return@FlareComposerActionPanel
                    activePanel = null
                    if (composerPanelTileOpensRecorder(action, offersVoice)) {
                        voiceMode = true
                        expanded = false
                    } else {
                        onAction?.invoke(action)
                    }
                },
            )
            is ComposerPanel.Mention -> MentionPicker(
                candidates = mentionCandidates,
                allowEveryone = mentionEveryone,
                framed = false,
                onSelect = { candidate -> selectCurrentMention(shownPanel, candidate) },
                onClose = { activePanel = null },
                modifier = Modifier.background(colors.bgPrimary),
                resultsMaxHeight = if (m.band) 160.dp else 264.dp,
                editorQuery = shownPanel.trigger?.query(text),
            )
            null -> Unit
        }
    }
    BoxWithConstraints(modifier.fillMaxWidth()) {
        // The keys in the row, the send key included: the band's tool inset is what they leave of the width.
        val keys = 1 + listOf("emoji", "mention", "image", "richText", "attachments").count(allows) + if (offersVoice) 1 else 0
        val m = ComposerMetrics.of(maxWidth, keys = keys)
        Column(
            Modifier.fillMaxWidth().background(if (m.band) colors.bgSecondary else colors.bgPrimary)
                .then(if (m.band) Modifier.padding(bottom = FlareSizes.spacingXs) else Modifier.padding(horizontal = FlareSizes.spacingXs, vertical = FlareSizes.spacingSm))
        ) {
            replyTo?.let { ReplyStrip(it, replyLabel, strings.cancelReply, colors, onCancelReply, m.band) }
            if (voiceMode && offersVoice) {
                // The band runs edge to edge; the recorder is a framed row, so it keeps the band's side inset.
                Box(if (m.band) Modifier.padding(start = FlareSizes.spacingSm, end = FlareSizes.spacingSm, top = FlareSizes.spacingXs) else Modifier) {
                    InlineVoiceComposer(conversationKey, disabled, onKeyboard = { voiceMode = false }, onSend = onVoiceSend)
                }
            } else {
                Column(
                    Modifier.fillMaxWidth().background(colors.bgPrimary)
                        .then(if (m.band) Modifier else Modifier.border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusCard)))
                ) {
                    if (richOn) Row(Modifier.fillMaxWidth().height(m.stripKeyHeight).horizontalScroll(rememberScrollState()).padding(horizontal = m.stripInset)) {
                        val styles = listOf("bold" to Icons.Outlined.FormatBold, "italic" to Icons.Outlined.FormatItalic, "strike" to Icons.Outlined.FormatStrikethrough, "code" to Icons.Outlined.Code, "link" to Icons.Outlined.Link, "heading" to Icons.Outlined.Title, "quote" to Icons.Outlined.FormatQuote, "bullet" to Icons.AutoMirrored.Outlined.FormatListBulleted, "ordered" to Icons.Outlined.FormatListNumbered)
                        styles.forEach { (id, icon) -> val name = composerFormatName(id, strings); IconButton(onClick = { val blocks = setOf("heading", "quote", "bullet", "ordered"); formats = if (id in formats) formats - id else (if (id in blocks) formats - blocks else formats) + id }, enabled = !disabled, modifier = Modifier.size(m.stripKeyWidth, m.stripKeyHeight)) { Icon(icon, name, Modifier.size(FlareSizes.spacing2md), tint = if (id in formats) colors.primaryText else colors.textSecondary) } }
                    }
                    // The row is the top of the same band; a hairline is all
                    // that separates it from the text it formats.
                    if (richOn) HorizontalDivider(color = colors.borderPrimary)
                    Row(verticalAlignment = Alignment.Top) {
                        // 11 above and below a 24dp line is a 46dp band: the
                        // text sits in the middle of it without the field
                        // growing into a panel of its own.
                        Box(Modifier.weight(1f).padding(start = m.textStart, top = m.textTop, bottom = m.textBottom)) {
                            FlareComposerEmojiEditText(value = text, onValueChange = {
                                val next = composerTextWithinLimit(it, maxLength)
                                val typedAt = if (!hasMentions || richOn || !allows("mention")) null else composerTypedMentionAt(text, next)
                                updateText(next)
                                if (typedAt != null) {
                                    activePanel = ComposerPanel.Mention(
                                        ComposerMentionTrigger(next.take(typedAt + 1), next.drop(typedAt + 1)),
                                    )
                                }
                            }, enabled = !disabled,
                                placeholder = placeholder,
                                onFocus = { activePanel = null },
                                expanded = expanded,
                                textColor = if ("link" in formats) colors.primaryText else colors.textPrimary,
                                hintColor = colors.textTertiary,
                                fontWeight = if ("bold" in formats) FontWeight.Bold else FontWeight.Normal,
                                fontStyle = if ("italic" in formats) FontStyle.Italic else FontStyle.Normal,
                                textDecoration = if ("strike" in formats) TextDecoration.LineThrough else if ("link" in formats) TextDecoration.Underline else TextDecoration.None,
                                cursorAfterReplacement = mentionEdit?.takeIf { it.text == text }?.cursor,
                                modifier = Modifier.fillMaxWidth())
                        }
                        tool(composerExpandKey(strings, disabled, expanded)) { expanded = !expanded }
                    }
                    if (!m.band) tools(m)
                }
                // The tools leave the band and rest on the ground, taking back
                // the inset the band gave up.
                if (m.band) tools(m)
                panel(m)
            }
        }
    }
}

private sealed interface ComposerPanel {
    data object Emoji : ComposerPanel
    data object More : ComposerPanel
    /** A null trigger means the mention key opened the picker. */
    data class Mention(val trigger: ComposerMentionTrigger?) : ComposerPanel
}

/** The untouched parts of the draft anchor the query and prevent replacing unrelated text. */
internal data class ComposerMentionTrigger(val prefix: String, val suffix: String) {
    val start: Int get() = prefix.length - 1

    fun query(text: String): String? {
        val end = text.length - suffix.length
        if (end < prefix.length || !text.startsWith(prefix) || !text.endsWith(suffix)) return null
        return text.substring(prefix.length, end).takeIf { it.length <= 40 && '\n' !in it && '\r' !in it }
    }
}

/** A picked mention leaves the caret after the inserted label when the draft is rendered. */
private data class ComposerMentionEdit(val text: String, val cursor: Int)

/**
 * Where the user just typed "@" at the start of a word, as a pure one-character insertion from [previous] to
 * [next] (a keystroke or a commit); null otherwise. An "@" inside a word, such as an email address, is plain text.
 */
internal fun composerTypedMentionAt(previous: String, next: String): Int? {
    if (next.length != previous.length + 1) return null
    var at = 0
    while (at < previous.length && next[at] == previous[at]) at++
    if (next[at] != '@' || next.regionMatches(at + 1, previous, at, previous.length - at).not()) return null
    return at.takeIf { it == 0 || next[it - 1].isWhitespace() }
}

/**
 * [text] with "@[name] " written for a pick: in place of the token typed at [typedAt] when it is still there,
 * otherwise at the end (after a space when the text does not end in one).
 */
internal fun composerTextWithMention(text: String, name: String, typedAt: Int?, queryLength: Int = 0): String {
    val mention = "@$name "
    if (typedAt != null && text.getOrNull(typedAt) == '@') {
        val end = typedAt + 1 + queryLength
        if (end in (typedAt + 1)..text.length) return text.replaceRange(typedAt, end, mention)
    }
    val separator = if (text.isEmpty() || text.last().isWhitespace()) "" else " "
    return text + separator + mention
}

/** Screen-reader name of a rich-text format key ("bold", "italic", …) — never the raw id. */
internal fun composerFormatName(id: String, strings: FlareStrings): String = when (id) {
    "bold" -> strings.composerFormatBold
    "italic" -> strings.composerFormatItalic
    "strike" -> strings.composerFormatStrike
    "code" -> strings.composerFormatCode
    "link" -> strings.composerFormatLink
    "heading" -> strings.composerFormatHeading
    "quote" -> strings.composerFormatQuote
    "bullet" -> strings.composerFormatBullet
    "ordered" -> strings.composerFormatOrdered
    else -> id
}

@Composable
private fun ReplyStrip(
    reply: FlareReplyTarget,
    label: String,
    cancelLabel: String,
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
            Text("$label ${flareQuoteSenderText(reply, flareStrings())}", color = colors.primaryText, fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold)
            Text(reply.summary, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        IconButton(onClick = { onCancel?.invoke() }) { Icon(Icons.Rounded.Close, cancelLabel, Modifier.size(18.dp), tint = colors.textTertiary) }
    }
}
