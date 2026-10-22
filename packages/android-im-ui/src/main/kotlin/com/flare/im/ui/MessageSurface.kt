package com.flare.im.ui

import java.util.Locale

// The message row's surface, the place its time and receipt take, and the receipt it draws
// (docs/design/message-surface-and-meta.md C1–C3). Every rule here is a pure function the four kits run against the
// same tables: spec/message-surface-vectors.json, spec/message-meta-placement-vectors.json and
// spec/message-receipt-vectors.json.

/**
 * The surface a timeline row draws its content on. Spec: dataTypes `MessageSurface`.
 *
 * - [Bubble]: the coloured bubble (incoming / outgoing surfaces, the tail on the last of a run).
 * - [BareMedia]: the media is the surface — no bubble background, padding or tail.
 * - [Card]: the content component's own shell is the surface (PluginView, RedPacketCard, a location or contact card…);
 *   [MessageBubble] draws no background, border, padding, tail or shadow around it.
 * - [Centered]: one centred notice line (system lines, recalls, deletions).
 */
enum class FlareMessageSurface(val wire: String) {
    Bubble("bubble"), BareMedia("bareMedia"), Card("card"), Centered("centered");

    companion object {
        fun fromWire(value: String?): FlareMessageSurface? = entries.firstOrNull { it.wire == value }
    }
}

/** Where a message's time, labels and receipt sit. Spec: dataTypes `MessageMetaPlacement`. */
enum class FlareMessageMetaPlacement(val wire: String) {
    /** After the text's last line inside the bubble; on its own trailing row when it does not fit beside it. */
    Inline("inline"),

    /** Its own trailing row inside the bubble, under the content. */
    BubbleFooter("bubbleFooter"),

    /** Under the surface (spacing xs), at the trailing edge, in the default palette. */
    Below("below"),

    /** No time and no status (centred notices). */
    None("none");

    companion object {
        fun fromWire(value: String?): FlareMessageMetaPlacement? = entries.firstOrNull { it.wire == value }
    }
}

/**
 * The core SDK's group read summary of the viewer's own message (`MessageReceiptView.readSummary`). Spec: dataTypes
 * `MessageReadSummary`. Absent in single chats, in groups above the large-group threshold and before the SDK has data.
 */
data class FlareMessageReadSummary(val readCount: Int, val unreadCount: Int, val total: Int)

/**
 * The facts [flareMessageSurface] reads. [contentType] is the spec vocabulary (`text`, `richText`, `image`,
 * `imageGroup`, `video`, `audio`, `file`, `location`, `card`, `linkCard`, `vote`, `task`, `schedule`, `announcement`,
 * `miniProgram`, `forward`, `thread`, `quote`, `custom`, `placeholder`, `system`, `notification`); [registered] is the
 * surface a host registered for the content's key ([FlareContentScope] `surfaces`).
 */
data class FlareMessageSurfaceInput(
    val contentType: String,
    val subtype: String? = null,
    val registered: FlareMessageSurface? = null,
    /** A text that is one emoji pack token or one emoji, with no mentions. */
    val loneEmoji: Boolean = false,
    /** The message replies to another one. */
    val hasQuote: Boolean = false,
    /** A video that carries a caption that is not blank. */
    val hasCaption: Boolean = false,
    val recalled: Boolean = false,
    val deleted: Boolean = false,
)

private val surfaceDefaults: Map<String, FlareMessageSurface> = buildMap {
    for (type in listOf("text", "richText", "audio", "file", "imageGroup", "quote", "placeholder")) put(type, FlareMessageSurface.Bubble)
    for (type in listOf("image", "sticker", "emoji")) put(type, FlareMessageSurface.BareMedia)
    for (type in listOf("location", "card", "linkCard", "vote", "task", "schedule", "announcement", "miniProgram", "forward", "thread", "custom")) {
        put(type, FlareMessageSurface.Card)
    }
    for (type in listOf("system", "notification")) put(type, FlareMessageSurface.Centered)
}

/**
 * The surface of one row (spec/message-surface-vectors.json `rules.order`), first match wins: a recall or a deletion is a
 * centred notice; so are system and notification lines; then the host's registration (bare media that quotes is a
 * bubble); a quote keeps a card a card and makes every other content a bubble; a video is bare without a caption; a text
 * is bare when it is a lone emoji; then the defaults table. A content type the kit does not know is a bubble.
 */
fun flareMessageSurface(input: FlareMessageSurfaceInput): FlareMessageSurface {
    if (input.recalled || input.deleted) return FlareMessageSurface.Centered
    if (input.contentType == "system" || input.contentType == "notification") return FlareMessageSurface.Centered
    input.registered?.let { registered ->
        return if (registered == FlareMessageSurface.BareMedia && input.hasQuote) FlareMessageSurface.Bubble else registered
    }
    val default = surfaceDefaults[input.contentType]
    if (input.hasQuote) return if (default == FlareMessageSurface.Card) FlareMessageSurface.Card else FlareMessageSurface.Bubble
    if (input.contentType == "video") return if (input.hasCaption) FlareMessageSurface.Bubble else FlareMessageSurface.BareMedia
    if (input.contentType == "text") return if (input.loneEmoji) FlareMessageSurface.BareMedia else FlareMessageSurface.Bubble
    return default ?: FlareMessageSurface.Bubble
}

/**
 * A kit content's type in the spec vocabulary, with its subtype: the kit's own classes by kind, and a
 * [FlareGenericContent] by its wire name (`rich_text`, `image_group`, `link_card`, `mini_program`, `merged_forward`…).
 * A wire type `custom.<subtype>` or `custom:<subtype>` is custom content of that subtype.
 */
fun flareMessageContentType(content: FlareMessageContent): Pair<String, String?> = when (content) {
    is FlareTextContent -> "text" to null
    is FlareRichTextContent -> "richText" to null
    is FlareImageContent -> "image" to null
    is FlareImageGroupContent -> "imageGroup" to null
    is FlareVideoContent -> "video" to null
    is FlareAudioContent -> "audio" to null
    is FlareFileContent -> "file" to null
    is FlareLocationContent -> "location" to null
    is FlareStickerContent -> "sticker" to null
    is FlareEmojiContent -> "emoji" to null
    is FlareCardContent -> "card" to null
    is FlareNotificationContent -> "notification" to null
    is FlarePlaceholderContent -> "placeholder" to null
    is FlarePollContent -> "vote" to null
    is FlareTaskContent -> "task" to null
    is FlareCalendarContent -> "schedule" to null
    is FlareMiniAppContent -> "miniProgram" to null
    is FlareAnnouncementContent -> "announcement" to null
    is FlareLinkCardContent -> "linkCard" to null
    is FlareGenericContent -> flareWireContentType(content.contentType, content.subtype)
    else -> flareWireContentType(content.type, null)
}

/** A wire content type (snake_case or camelCase, optionally `custom.<subtype>`) in the spec vocabulary. */
internal fun flareWireContentType(wire: String, subtype: String?): Pair<String, String?> {
    for (separator in listOf(".", ":")) {
        val prefix = "custom$separator"
        if (wire.startsWith(prefix) && wire.length > prefix.length) return "custom" to (subtype ?: wire.removePrefix(prefix))
    }
    val type = when (wire) {
        "rich_text" -> "richText"
        "image_group" -> "imageGroup"
        "link_card" -> "linkCard"
        "mini_program" -> "miniProgram"
        "merged_forward", "merge_forward", "mergedForward" -> "forward"
        "contact", "business_card" -> "card"
        "poll" -> "vote"
        "calendar" -> "schedule"
        else -> wire
    }
    return type to subtype
}

/**
 * The registration that applies to a content: `contentType:subtype` first, then the content's own key (what its
 * builder is registered under), then the spec content type.
 */
internal fun flareRegisteredSurface(
    surfaces: Map<String, FlareMessageSurface>,
    contentKey: String,
    contentType: String,
    subtype: String?,
): FlareMessageSurface? {
    if (surfaces.isEmpty()) return null
    if (subtype != null) surfaces["$contentType:$subtype"]?.let { return it }
    return surfaces[contentKey] ?: surfaces[contentType]
}

/**
 * The surface of [message]: its content's type, the host's [surfaces] registration, the quote, the recall and deletion
 * state, and whether a text is a lone emoji ([isKnownPackKey] answers for `[key]` pack tokens).
 */
fun flareMessageSurface(
    message: FlareMessageData,
    surfaces: Map<String, FlareMessageSurface> = emptyMap(),
    isKnownPackKey: (String) -> Boolean = { false },
): FlareMessageSurface {
    if (message.isSystem) return FlareMessageSurface.Centered
    val (type, subtype) = flareMessageContentType(message.content)
    val text = message.content as? FlareTextContent
    return flareMessageSurface(
        FlareMessageSurfaceInput(
            contentType = type,
            subtype = subtype,
            registered = flareRegisteredSurface(surfaces, message.content.type, type, subtype),
            loneEmoji = text != null && flareIsLoneEmojiText(text.text, text.mentions, isKnownPackKey),
            hasQuote = message.replyTo != null,
            recalled = message.isRecalled,
            deleted = message.isDeleted,
        ),
    )
}

// ── lone emoji ──────────────────────────────────────────────────────────────

private val loneBracketKey = Regex("^\\[([a-z][a-z0-9_]*)]$")

/**
 * A text that stands as one emoji: a single emoji pack token ([isKnownPackKey]) or a single emoji, without mentions.
 * Such a text is drawn large without a bubble (bareMedia).
 */
internal fun flareIsLoneEmojiText(text: String, mentions: List<FlareTextMentionSpan>, isKnownPackKey: (String) -> Boolean): Boolean {
    if (mentions.isNotEmpty()) return false
    val trimmed = text.trim()
    if (trimmed.isEmpty()) return false
    loneBracketKey.matchEntire(trimmed)?.let { return isKnownPackKey(it.groupValues[1]) }
    return flareIsSingleEmoji(trimmed)
}

/** Whether [cp] starts an emoji (Extended_Pictographic, as far as a table without ICU can tell). */
private fun isEmojiBase(cp: Int): Boolean =
    cp in 0x1F000..0x1FAFF || cp in 0x2600..0x27BF || cp in 0x2300..0x23FF || cp in 0x2B00..0x2BFF ||
        cp in 0x2190..0x21FF || cp in 0x25A0..0x25FF || cp in 0x2934..0x2935 ||
        cp == 0x00A9 || cp == 0x00AE || cp == 0x203C || cp == 0x2049 || cp == 0x2122 || cp == 0x2139 ||
        cp == 0x24C2 || cp == 0x3030 || cp == 0x303D || cp == 0x3297 || cp == 0x3299

/**
 * One emoji cluster: a pictograph with its variation selector, skin tone and tags, joined pictographs (ZWJ
 * sequences), a flag (two regional indicators) or a keycap.
 */
internal fun flareIsSingleEmoji(text: String): Boolean {
    var clusters = 0
    var joining = false
    var regional = 0
    var keycapBase = false
    var i = 0
    while (i < text.length) {
        val cp = text.codePointAt(i)
        i += Character.charCount(cp)
        when {
            cp == 0x200D -> { if (clusters == 0) return false; joining = true; continue }
            cp == 0xFE0F || cp == 0xFE0E || cp in 0x1F3FB..0x1F3FF || cp in 0xE0020..0xE007F -> { if (clusters == 0) return false; continue }
            cp == 0x20E3 -> { if (!keycapBase) return false; keycapBase = false; continue }
            cp in 0x1F1E6..0x1F1FF -> {
                regional++
                if (regional % 2 == 0) continue
                if (!joining) clusters++
            }
            cp in '0'.code..'9'.code || cp == '#'.code || cp == '*'.code -> {
                if (clusters > 0 || joining) return false
                clusters++
                keycapBase = true
            }
            isEmojiBase(cp) -> if (!joining) clusters++
            else -> return false
        }
        joining = false
        if (clusters > 1) return false
    }
    return clusters == 1 && !keycapBase
}

// ── meta placement ──────────────────────────────────────────────────────────

/** The colour family of the meta: the outgoing bubble's foreground, or the default palette. */
enum class FlareMessageMetaTone { Default, OnOutgoing }

/** What the retry is when an outgoing message failed: the failed glyph, or the "Failed to send. Retry" text key. */
enum class FlareMessageRetryControl { Glyph, Text }

/**
 * Where the meta of a row sits (spec/message-meta-placement-vectors.json `rules.placement`): a text bubble inline after
 * its last line, any other bubble in its own footer row, bare media and cards below the surface, centred rows nowhere.
 */
fun flareMessageMetaPlacement(surface: FlareMessageSurface, contentType: String): FlareMessageMetaPlacement = when (surface) {
    FlareMessageSurface.Bubble -> if (contentType == "text") FlareMessageMetaPlacement.Inline else FlareMessageMetaPlacement.BubbleFooter
    FlareMessageSurface.BareMedia, FlareMessageSurface.Card -> FlareMessageMetaPlacement.Below
    FlareMessageSurface.Centered -> FlareMessageMetaPlacement.None
}

/** The outgoing palette only inside an outgoing bubble that has not failed; everything else is the default palette. */
fun flareMessageMetaTone(placement: FlareMessageMetaPlacement, self: Boolean, status: FlareMessageDeliveryStatus): FlareMessageMetaTone =
    if (self && status != FlareMessageDeliveryStatus.Failed &&
        (placement == FlareMessageMetaPlacement.Inline || placement == FlareMessageMetaPlacement.BubbleFooter)
    ) FlareMessageMetaTone.OnOutgoing else FlareMessageMetaTone.Default

/** The retry of a failed outgoing message: the glyph inside a bubble, the text key below a surface; none otherwise. */
fun flareMessageRetryControl(placement: FlareMessageMetaPlacement, self: Boolean, status: FlareMessageDeliveryStatus): FlareMessageRetryControl? {
    if (!self || status != FlareMessageDeliveryStatus.Failed) return null
    return when (placement) {
        FlareMessageMetaPlacement.Inline, FlareMessageMetaPlacement.BubbleFooter -> FlareMessageRetryControl.Glyph
        FlareMessageMetaPlacement.Below -> FlareMessageRetryControl.Text
        FlareMessageMetaPlacement.None -> null
    }
}

// ── receipt ─────────────────────────────────────────────────────────────────

/** The receipt glyphs; delivered has none (a single check is the server, a double check is read). */
enum class FlareMessageReceiptGlyph(val wire: String) {
    Clock("clock"), Spinner("spinner"), Check("check"), DoubleCheck("doubleCheck"), Alert("alert");
}

/** The read summary that replaces the check glyph: "{count} unread", or "read by all" when [unreadCount] is 0. */
data class FlareMessageReadSummaryText(val unreadCount: Int) {
    val allRead: Boolean get() = unreadCount == 0

    fun text(strings: FlareStrings): String =
        if (allRead) strings.messageReadSummaryAllRead else strings.messageReadSummaryUnread.replace("{count}", unreadCount.toString())
}

/** What the receipt of one row draws: a glyph, a read summary, or nothing (incoming messages). */
data class FlareMessageReceiptPresentation(val glyph: FlareMessageReceiptGlyph?, val summary: FlareMessageReadSummaryText?)

fun flareMessageReceiptGlyph(status: FlareMessageDeliveryStatus): FlareMessageReceiptGlyph = when (status) {
    FlareMessageDeliveryStatus.Pending -> FlareMessageReceiptGlyph.Clock
    FlareMessageDeliveryStatus.Sending -> FlareMessageReceiptGlyph.Spinner
    FlareMessageDeliveryStatus.Sent -> FlareMessageReceiptGlyph.Check
    FlareMessageDeliveryStatus.Read -> FlareMessageReceiptGlyph.DoubleCheck
    FlareMessageDeliveryStatus.Failed -> FlareMessageReceiptGlyph.Alert
}

/**
 * The receipt of one row (spec/message-receipt-vectors.json): incoming messages draw none; the viewer's own messages in a
 * group with an SDK read summary, sent or read, draw the summary in place of the glyph; every other own message draws
 * its status glyph. A single chat never shows a summary, whatever the SDK passed.
 */
fun flareMessageReceiptPresentation(
    conversationKind: FlareConversationKind,
    self: Boolean,
    status: FlareMessageDeliveryStatus,
    readSummary: FlareMessageReadSummary?,
): FlareMessageReceiptPresentation {
    if (!self) return FlareMessageReceiptPresentation(null, null)
    val summarised = readSummary != null && conversationKind == FlareConversationKind.Group &&
        (status == FlareMessageDeliveryStatus.Sent || status == FlareMessageDeliveryStatus.Read)
    if (summarised) return FlareMessageReceiptPresentation(null, FlareMessageReadSummaryText(readSummary!!.unreadCount.coerceAtLeast(0)))
    return FlareMessageReceiptPresentation(flareMessageReceiptGlyph(status), null)
}

/** The spoken name of a receipt glyph. */
fun flareMessageStatusLabel(status: FlareMessageDeliveryStatus, strings: FlareStrings): String = when (status) {
    FlareMessageDeliveryStatus.Pending -> strings.messagePending
    FlareMessageDeliveryStatus.Sending -> strings.messageSending
    FlareMessageDeliveryStatus.Sent -> strings.messageSent
    FlareMessageDeliveryStatus.Read -> strings.messageRead
    FlareMessageDeliveryStatus.Failed -> strings.messageFailed
}

/**
 * One reading unit per row (spec/message-receipt-vectors.json `rules.accessibilityLabel`): the sender, the content
 * summary, the time and — for the viewer's own messages — the status ("Failed to send. Retry" when it failed) or the read
 * summary that replaces the glyph. Empty parts are skipped; parts are joined with the locale's list separator.
 */
fun flareMessageAccessibilityLabel(
    sender: String,
    preview: String,
    time: String,
    self: Boolean,
    status: FlareMessageDeliveryStatus,
    strings: FlareStrings,
    locale: Locale,
    conversationKind: FlareConversationKind = FlareConversationKind.Single,
    readSummary: FlareMessageReadSummary? = null,
): String {
    val receipt = flareMessageReceiptPresentation(conversationKind, self, status, readSummary)
    val state = when {
        !self -> ""
        receipt.summary != null -> receipt.summary.text(strings)
        status == FlareMessageDeliveryStatus.Failed -> strings.messageSendFailedRetry
        else -> flareMessageStatusLabel(status, strings)
    }
    val separator = if (locale.language == "zh") "，" else ", "
    return listOf(sender, preview, time, state).map { it.trim() }.filter { it.isNotEmpty() }.joinToString(separator)
}
