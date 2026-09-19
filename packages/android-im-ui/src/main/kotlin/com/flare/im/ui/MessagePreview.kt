package com.flare.im.ui

/*
 * What a conversation row, a reply strip and a bubble's quote say about a message whose body is not
 * plain text. One vocabulary (`FlareStrings.preview*`) and one rule for all four kits; the rule table
 * is `spec/message-preview-vectors.json`, which every platform's test reads.
 */

/**
 * The one-line summary of [content] in the words of [strings], or "" when the body carries nothing
 * readable — a conversation row may then show nothing at all.
 *
 * A body with text of its own (a text message, a picture's description, a link card's title, a task's
 * title) reads as that text; the rest read as the word for their type, with the `…Named` variant when
 * they carry a name and the `…Count` variant when they carry a number of items. A motion picture reads
 * as a GIF, not a picture. Nothing is invented here: a reply strip or a quote, which must never be a
 * blank line, adds the fallback itself ([flareMessageReplySummary]).
 */
fun flareMessagePreviewText(content: FlareMessageContent?, strings: FlareStrings, locale: String? = null): String = when (content) {
    null -> ""
    // Markdown first, then the pack keys — the order Vue reads a preview in, so a line that is both
    // marked up and full of pack tokens comes out the same on every platform.
    is FlareTextContent -> FlareEmojiStickerCatalog.localizePackKeysInText(
        flareMarkdownToPlainText(content.text.trim(), strings),
        locale ?: java.util.Locale.getDefault().toLanguageTag(),
    )
    // The core's flat text, after the title when there is one — Vue's reading of a document whose Markdown source
    // it does not have.
    is FlareRichTextContent -> listOf(content.title.trim(), content.plainText.trim()).filter { it.isNotEmpty() }
        .joinToString(" ").ifEmpty { strings.previewRichText }
    is FlareImageContent -> when {
        content.animated -> strings.previewGif
        else -> content.alt?.trim().orEmpty().ifEmpty { strings.previewImage }
    }
    // An album says how many it carries; one with none says only what it is.
    is FlareImageGroupContent -> if (content.images.isEmpty()) strings.previewImageGroup else strings.previewImageGroupCount(content.images.size)
    is FlareVideoContent -> strings.previewVideo
    is FlareAudioContent -> strings.previewAudio
    is FlareFileContent -> content.name.trim().let { if (it.isEmpty()) strings.previewFile else strings.previewFileNamed(it) }
    is FlareLocationContent -> content.name.trim().ifEmpty { content.address.trim() }
        .let { if (it.isEmpty()) strings.previewLocation else strings.previewLocationNamed(it) }
    is FlareCardContent -> content.title.trim().let { if (it.isEmpty()) strings.previewCard else strings.previewCardNamed(it) }
    is FlareStickerContent -> strings.previewSticker
    // A pack key is not a word: a row reads the pack's name in the reader's language
    // (`emoji-locales.json`, the same file in all four kits), and falls back to the key itself only for a
    // key the table does not know.
    is FlareEmojiContent -> content.emoji.trim()
        // No locale from the caller: read the one the device is in, the way Vue reads
        // `navigator.language`. A test passes its own, so it stays deterministic.
        .let { key ->
            if (key.isEmpty()) "" else FlareEmojiStickerCatalog.emojiLabel(key, locale ?: java.util.Locale.getDefault().toLanguageTag())
        }
        .ifEmpty { strings.previewEmoji }
    is FlareLinkCardContent -> content.title.trim().ifEmpty { strings.previewLink }
    is FlarePollContent -> strings.previewVote
    is FlareTaskContent -> content.title.trim().ifEmpty { strings.previewTask }
    is FlareCalendarContent -> content.title.trim().ifEmpty { strings.previewSchedule }
    is FlareMiniAppContent -> content.title.trim().ifEmpty { strings.previewMiniProgram }
    is FlareAnnouncementContent -> content.title.trim().ifEmpty { content.body.trim() }.ifEmpty { strings.previewAnnouncement }
    // One type for both centred lines: an event with no words of its own reads as a system message.
    is FlareNotificationContent -> content.text.trim().ifEmpty { strings.previewSystem }
    is FlarePlaceholderContent -> content.label.trim().ifEmpty { strings.previewPlaceholder }
    is FlareGenericContent -> genericPreviewText(content, strings)
    else -> ""
}

/**
 * What a reply strip or a bubble's quote shows for [content]: its summary, or the word for a message
 * with nothing readable. Never blank, so a reply is never an empty line.
 */
fun flareMessageReplySummary(content: FlareMessageContent?, strings: FlareStrings, locale: String? = null): String =
    flareMessagePreviewText(content, strings, locale).ifEmpty { strings.previewMessage }

/**
 * What a screen reader is told once a jump lands: which row it is, and what it says. The ring says the same
 * thing to everyone who can see it. The sender is named, or the word for a message whose sender is unknown;
 * the line is the one a reply strip would show, so a message reads the same wherever it is named.
 */
fun flareLocatedAnnouncement(message: FlareMessageData, strings: FlareStrings, locale: String? = null): String =
    strings.jumpedToMessage(
        message.senderName.trim().ifEmpty { strings.previewMessage },
        flareMessageReplySummary(message.content, strings, locale),
    )

/**
 * The quote of [message] — who sent it, what it said, and which message it is. Build a reply target
 * with this rather than by hand, so the reply strip above the composer and the quote inside the
 * bubble read the same on every platform.
 *
 * [FlareReplyTarget.messageId] is the quoted message's core id ([FlareMessageData.serverId]) whenever it
 * has one: one id with one meaning, for the host to send with the reply and for every other client to
 * resolve. A message still waiting for its acknowledgement has only the id its row was drawn with, and that
 * is what the quote carries then — the list locates it either way.
 */
fun flareReplyTarget(message: FlareMessageData, strings: FlareStrings, locale: String? = null): FlareReplyTarget = FlareReplyTarget(
    senderName = message.senderName,
    summary = flareMessageReplySummary(message.content, strings, locale),
    messageId = message.serverId ?: message.id,
)

/**
 * A body the kit has no renderer for reads as its own label when it has one; a forward and an album
 * read as how many they carry, and everything else as the word for its wire type.
 */
private fun genericPreviewText(content: FlareGenericContent, strings: FlareStrings): String {
    val label = content.label.trim()
    val count = content.itemCount
    return when {
        isForward(content.contentType) && count > 1 -> strings.previewForwardCount(count)
        isImageGroup(content.contentType) && count > 0 -> strings.previewImageGroupCount(count)
        label.isNotEmpty() -> label
        else -> contentTypeWord(content.contentType, strings)
    }
}

private fun isForward(contentType: String) = contentType == "forward"

private fun isImageGroup(contentType: String) = contentType == "image_group" || contentType == "imageGroup"

/** The word for a wire content type, in either spelling the core and the kit use for it. */
private fun contentTypeWord(contentType: String, strings: FlareStrings): String = when (contentType) {
    "text" -> strings.previewMessage
    "rich_text", "richText" -> strings.previewRichText
    "image" -> strings.previewImage
    "video" -> strings.previewVideo
    "audio", "voice" -> strings.previewAudio
    "file" -> strings.previewFile
    "location" -> strings.previewLocation
    "card" -> strings.previewCard
    "sticker" -> strings.previewSticker
    "emoji" -> strings.previewEmoji
    "quote" -> strings.previewQuote
    "link_card", "linkCard" -> strings.previewLink
    "forward" -> strings.previewForward
    "thread" -> strings.previewThread
    "mini_program", "miniProgram" -> strings.previewMiniProgram
    "image_group", "imageGroup" -> strings.previewImageGroup
    "system" -> strings.previewSystem
    "notification" -> strings.previewNotification
    "vote" -> strings.previewVote
    "task" -> strings.previewTask
    "schedule" -> strings.previewSchedule
    "announcement" -> strings.previewAnnouncement
    "custom" -> strings.previewCustom
    "placeholder" -> strings.previewPlaceholder
    else -> strings.previewUnknown
}
