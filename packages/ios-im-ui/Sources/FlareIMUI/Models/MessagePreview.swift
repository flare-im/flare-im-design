import Foundation

/// One line that says what a message is — what a conversation row, the composer's reply strip and a
/// bubble's quote show for a message whose body is not plain text.
///
/// The words come from ``FlareStrings`` (`preview*`), never from the host: four kits, one vocabulary.
/// The rule table is shared too — `spec/message-preview-vectors.json`, which Vue's
/// `utils/messagePreview.ts` and this function both answer to.
///
/// - A body that carries its own text (a text message, an image's description, a link card's title,
///   a task's title, a quote's preview) is summarized by that text.
/// - A body that carries none is named by its type (`[图片]`), by its type and a name
///   (`[文件] 报价单.pdf`), or by its type and a count (`[转发] 3 条消息`).
/// - A body with nothing readable at all summarizes to the empty string: a conversation row may then
///   show nothing. Callers that must not show a blank line (a reply strip, a quote) fall back to
///   ``FlareStrings/previewMessage`` — ``FlareReplyTarget/init(replyingTo:strings:)`` does that for you.
///
/// Stored preview tokens (`{k:"im.preview.…"}`) are the core's wire format and are decoded by the
/// host's SDK adapter, not here; what the decoded result is *called* still comes from this table.
public func flareMessagePreviewText(_ content: FlareMessageContent?, strings s: FlareStrings, locale: String? = nil) -> String {
    guard let content else { return "" }
    switch content {
    case let c as FlareTextContent:
        // Markdown first, then the pack keys — the order Vue reads a preview in, so a line that is both
        // marked up and full of pack tokens comes out the same on every platform.
        return FlareEmojiStickerCatalog.shared.localizePackKeysInText(
            flareMarkdownToPlainText(trimmed(c.text), strings: s), locale: locale ?? Locale.current.identifier)
    case let c as FlareRichTextContent:
        // The core's flat text, after the title when there is one — Vue's reading of a document whose
        // Markdown source it does not have.
        return fallback([trimmed(c.title), trimmed(c.plainText)].filter { !$0.isEmpty }.joined(separator: " "),
                        s.previewRichText)
    case let c as FlareImageContent:
        if c.animated || urlLooksAnimated(c.url) { return s.previewGif }
        return fallback(c.alt, s.previewImage)
    case let c as FlareImageGroupContent:
        // An album says how many it carries; one with none says only what it is.
        return c.images.isEmpty ? s.previewImageGroup : s.previewImageGroupCount(c.images.count)
    case is FlareVideoContent:
        return s.previewVideo
    case is FlareAudioContent:
        return s.previewAudio
    case let c as FlareFileContent:
        return named(c.name, s.previewFileNamed, s.previewFile)
    case let c as FlareLocationContent:
        return named(firstText(c.name, c.address), s.previewLocationNamed, s.previewLocation)
    case let c as FlareCardContent:
        return named(c.title, s.previewCardNamed, s.previewCard)
    case is FlareStickerContent:
        return s.previewSticker
    case let c as FlareEmojiContent:
        // A pack key is not a word: a row reads the pack's name in the reader's language
        // (`emoji-locales.json`, the same file in all four kits), and falls back to the key itself
        // only for a key the table does not know.
        let packKey = c.emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        // No locale from the caller: read the one the device is in, the way Vue reads
        // `navigator.language`. A test passes its own, so it stays deterministic.
        let packLabel = packKey.isEmpty ? ""
            : FlareEmojiStickerCatalog.shared.emojiLabel(packKey, locale: locale ?? Locale.current.identifier)
        return fallback(packLabel, s.previewEmoji)
    case let c as FlareLinkCardContent:
        return fallback(c.title, s.previewLink)
    case is FlarePollContent:
        return s.previewVote
    case let c as FlareTaskContent:
        return fallback(c.title, s.previewTask)
    case let c as FlareCalendarContent:
        return fallback(c.title, s.previewSchedule)
    case let c as FlareMiniAppContent:
        return fallback(c.title, s.previewMiniProgram)
    case let c as FlareAnnouncementContent:
        return fallback(firstText(c.title, c.body), s.previewAnnouncement)
    case let c as FlareNotificationContent:
        return fallback(c.text, s.previewNotification)
    case let c as FlarePlaceholderContent:
        return fallback(c.label, s.previewPlaceholder)
    case let c as FlareGenericContent:
        return genericPreview(c, s)
    default:
        return ""
    }
}

/// A type the kit has no body renderer for still has a wire type and whatever text came with it.
/// Keys here are the core's wire types (``FlareMessageContentKind/wireType``).
private func genericPreview(_ c: FlareGenericContent, _ s: FlareStrings) -> String {
    let label = trimmed(c.label)
    switch c.contentType {
    case "text":
        return label
    case "rich_text", "richText":
        return fallback(label, s.previewRichText)
    case "image":
        return fallback(label, s.previewImage)
    case "image_group", "imageGroup":
        return c.itemCount > 0 ? s.previewImageGroupCount(c.itemCount) : s.previewImageGroup
    case "video":
        return s.previewVideo
    case "audio":
        return s.previewAudio
    case "file":
        return named(label, s.previewFileNamed, s.previewFile)
    case "location":
        return named(label, s.previewLocationNamed, s.previewLocation)
    case "card":
        return named(label, s.previewCardNamed, s.previewCard)
    case "sticker":
        return s.previewSticker
    case "emoji":
        return fallback(label, s.previewEmoji)
    case "quote":
        return fallback(label, s.previewQuote)
    case "link_card", "linkCard":
        return fallback(label, s.previewLink)
    case "forward", "merged_forward", "mergedForward":
        if c.itemCount > 1 { return s.previewForwardCount(c.itemCount) }
        return fallback(label, s.previewForward)
    case "thread":
        return fallback(label, s.previewThread)
    case "mini_program", "miniProgram":
        return fallback(label, s.previewMiniProgram)
    case "system":
        return fallback(label, s.previewSystem)
    case "notification":
        return fallback(label, s.previewNotification)
    case "vote":
        return s.previewVote
    case "task":
        return fallback(label, s.previewTask)
    case "schedule":
        return fallback(label, s.previewSchedule)
    case "announcement":
        return fallback(label, s.previewAnnouncement)
    case "custom":
        return fallback(label, s.previewCustom)
    case "placeholder":
        return fallback(label, s.previewPlaceholder)
    case "unknown":
        return fallback(label, s.previewUnknown)
    default:
        // Some other registered type: whatever text it came with, or nothing to say about it.
        return label
    }
}

/// What a screen reader is told once a jump lands: which row it is, and what it says. The ring says the
/// same thing to everyone who can see it. The sender is named, or the word for a message whose sender is
/// unknown; the line is the one a reply strip would show, so a message reads the same wherever it is named.
public func flareLocatedAnnouncement(
    _ message: FlareMessageData, strings s: FlareStrings, locale: String? = nil
) -> String {
    let sender = message.senderName.trimmingCharacters(in: .whitespacesAndNewlines)
    let summary = flareMessagePreviewText(message.content, strings: s, locale: locale)
    return s.jumpedToMessage(
        sender.isEmpty ? s.previewMessage : sender,
        summary.isEmpty ? s.previewMessage : summary)
}

public extension FlareReplyTarget {
    /// The message a reply quotes, read from the quoted row: who sent it, what it says in one line,
    /// and which row to locate. A body with no readable text is named ``FlareStrings/previewMessage``
    /// rather than left blank — the reply strip and the bubble's quote are never an empty line.
    init(replyingTo message: FlareMessageData, strings: FlareStrings, locale: String? = nil) {
        let summary = flareMessagePreviewText(message.content, strings: strings, locale: locale)
        // The quoted message's core id, the one every other client knows it by; a row still on its
        // way has only the id it was drawn with, which is all that exists yet.
        let core = (message.serverId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let quotedId = core.isEmpty ? message.id : core
        self.init(
            senderName: message.senderName,
            summary: summary.isEmpty ? strings.previewMessage : summary,
            messageId: quotedId.isEmpty ? nil : quotedId
        )
    }
}

private func trimmed(_ text: String?) -> String {
    (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
}

private func firstText(_ values: String?...) -> String {
    for value in values where !trimmed(value).isEmpty { return trimmed(value) }
    return ""
}

private func fallback(_ text: String?, _ generic: String) -> String {
    let body = trimmed(text)
    return body.isEmpty ? generic : body
}

private func named(_ name: String?, _ withName: (String) -> String, _ generic: String) -> String {
    let label = trimmed(name)
    return label.isEmpty ? generic : withName(label)
}

/// A still image and a moving one are different things to a reader. The source may say so directly
/// (``FlareImageContent/animated``); a plain file address is the other way to know.
private func urlLooksAnimated(_ url: String) -> Bool {
    let path = (URL(string: url)?.path ?? url).lowercased()
    return path.hasSuffix(".gif") || path.hasSuffix(".apng")
}
