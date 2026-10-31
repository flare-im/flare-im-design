import Foundation

/// The one line the core's stored summary of a message reads as — a conversation's last message, a quote, a
/// search hit — in the words of ``FlareStrings``.
///
/// The core stores a stable token, not display text: `{"k":"im.preview.image","a":{"d":"说明","m":true}}`
/// (flare-im-core-sdk `preview_storage.rs`). The rule is the shared table's `stored` list
/// (`spec/message-preview-vectors.json`), the one Vue's `displayTextFromStoredPreview` and the Compose and
/// Flutter kits' `flareStoredPreviewText` answer to:
///
/// - A token with words of its own (a caption, a file name, a title, the server's fallback line for a system
///   event) reads as those words; the rest read as their `preview*` word, with the `…Named` variant when they
///   carry a name and the `…Count` variant when they carry a number.
/// - A system or notification line without words is named by its event key (`ek`): `systemEventText` first,
///   for the events a host names itself, then the kit's `systemEvent*` words, else ``FlareStrings/previewSystem``.
/// - Text that is not a token is history from before the tokens and reads as it is. A token the kit does not
///   know, or one with no words where words are the whole message, reads as "" — never its raw JSON.
/// - Markdown reads as plain text and pack keys as their names, as in ``flareMessagePreviewText(_:strings:locale:)``.
public func flareStoredPreviewText(
    _ raw: String?,
    strings s: FlareStrings,
    locale: String? = nil,
    systemEventText: ((String) -> String)? = nil
) -> String {
    let text = storedTrimmed(raw)
    guard !text.isEmpty else { return "" }
    let words: String
    if let token = storedPreviewToken(text) {
        words = storedTokenText(token.kind, token.args, s, locale: locale, systemEventText: systemEventText)
    } else {
        words = text
    }
    // Markdown first, then the pack keys — the order Vue reads a preview in.
    return storedTrimmed(FlareEmojiStickerCatalog.shared.localizePackKeysInText(
        flareMarkdownToPlainText(words, strings: s), locale: locale ?? Locale.current.identifier))
}

/// The token's kind and arguments, or nil when `text` is not a token.
private func storedPreviewToken(_ text: String) -> (kind: String, args: [String: Any])? {
    guard text.hasPrefix("{"), let data = text.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let kind = object["k"] as? String else { return nil }
    return (kind, object["a"] as? [String: Any] ?? [:])
}

private func storedTokenText(
    _ kind: String,
    _ args: [String: Any],
    _ s: FlareStrings,
    locale: String?,
    systemEventText: ((String) -> String)?
) -> String {
    func arg(_ names: String...) -> String {
        for name in names {
            let value = storedTrimmed(args[name] as? String)
            if !value.isEmpty { return value }
        }
        return ""
    }
    func or(_ text: String, _ word: String) -> String { text.isEmpty ? word : text }
    func named(_ name: String, _ withName: (String) -> String, _ word: String) -> String {
        name.isEmpty ? word : withName(name)
    }
    func event(_ words: String, _ word: String) -> String {
        if !words.isEmpty { return words }
        let eventKey = arg("ek")
        guard !eventKey.isEmpty else { return word }
        let hosted = storedTrimmed(systemEventText?(eventKey))
        return or(hosted.isEmpty ? kitSystemEventText(eventKey, name: storedEventName(args), s) : hosted, word)
    }

    switch kind {
    case "im.preview.user_text":
        return arg("t")
    case "im.preview.rich_text":
        return or([arg("title"), arg("body"), arg("markdown")].filter { !$0.isEmpty }.joined(separator: " "),
                  s.previewRichText)
    case "im.preview.file":
        return named(arg("n"), s.previewFileNamed, s.previewFile)
    case "im.preview.image":
        if args["m"] as? Bool == true { return s.previewGif }
        return or(arg("d"), s.previewImage)
    case "im.preview.video":
        return or(arg("d"), s.previewVideo)
    case "im.preview.audio":
        return or(arg("d"), s.previewAudio)
    case "im.preview.location":
        return named(arg("label"), s.previewLocationNamed, s.previewLocation)
    case "im.preview.card":
        return named(arg("label"), s.previewCardNamed, s.previewCard)
    case "im.preview.sticker":
        return s.previewSticker
    case "im.preview.emoji":
        let packKey = arg("e", "emoji", "key")
        let label = packKey.isEmpty ? ""
            : FlareEmojiStickerCatalog.shared.emojiLabel(packKey, locale: locale ?? Locale.current.identifier)
        return or(storedTrimmed(label), s.previewEmoji)
    case "im.preview.quote":
        if let inner = args["inner"] as? [String: Any], let innerKind = inner["k"] as? String {
            let text = storedTokenText(innerKind, inner["a"] as? [String: Any] ?? [:], s,
                                       locale: locale, systemEventText: systemEventText)
            if !text.isEmpty { return text }
        }
        return s.previewQuote
    case "im.preview.link":
        return or(arg("t"), s.previewLink)
    case "im.preview.forward_empty":
        return s.previewForward
    case "im.preview.forward_many":
        let count = (args["n"] as? Int) ?? Int((args["n"] as? Double) ?? 0)
        return count > 0 ? s.previewForwardCount(count) : s.previewForward
    case "im.preview.thread":
        return or(arg("t"), s.previewThread)
    case "im.preview.mini_program":
        return or(arg("t"), s.previewMiniProgram)
    case "im.preview.image_group":
        return s.previewImageGroup
    case "im.preview.system":
        return event(arg("fb", "t", "body", "title"), s.previewSystem)
    case "im.preview.notification":
        return event(arg("fb", "body", "title"), s.previewNotification)
    case "im.preview.vote":
        return s.previewVote
    case "im.preview.task":
        return or(arg("t"), s.previewTask)
    case "im.preview.schedule":
        return s.previewSchedule
    case "im.preview.announcement":
        return or(arg("t"), s.previewAnnouncement)
    case "im.preview.custom":
        return or(arg("d"), s.previewCustom)
    case "im.preview.placeholder":
        return or(arg("t"), s.previewPlaceholder)
    case "im.preview.unknown":
        return s.previewUnknown
    default:
        return ""
    }
}

/// The kit's words for a system event key (Vue's `systemEvent.*`), or "" for a key it does not name. The keys are
/// the `SystemContent.event_kind` values the social server writes; `name` is the name the event's parameters carry,
/// for the events whose words include one.
private func kitSystemEventText(_ eventKey: String, name: String, _ s: FlareStrings) -> String {
    switch eventKey {
    case "group.created": return s.systemEventGroupCreated
    case "group.member_joined": return s.systemEventGroupMemberJoined
    case "group.member_kicked": return s.systemEventGroupMemberRemoved
    case "group.member_left": return s.systemEventGroupMemberLeft
    case "group.member_muted": return s.systemEventGroupMemberMuted
    case "group.member_unmuted": return s.systemEventGroupMemberUnmuted
    case "group.owner_transferred": return s.systemEventGroupOwnerTransferred
    case "group.dissolved": return s.systemEventGroupDissolved
    case "group.announcement": return s.systemEventGroupAnnouncementUpdated
    case "group.profile_updated":
        return name.isEmpty ? s.systemEventGroupProfileUpdated : s.systemEventGroupProfileUpdatedNamed(name)
    case "group.member_roles_changed": return s.systemEventGroupMemberRolesChanged
    case "group.muted": return s.systemEventGroupMuted
    case "group.unmuted": return s.systemEventGroupUnmuted
    case "relation.friendship_established": return s.systemEventFriendshipEstablished
    default: return ""
    }
}

/// The name a system event's parameters (`p`) carry: a group's new display name, else its name.
private func storedEventName(_ args: [String: Any]) -> String {
    guard let params = args["p"] as? [String: Any] else { return "" }
    for key in ["display_name", "name"] {
        let value = storedTrimmed(params[key] as? String)
        if !value.isEmpty { return value }
    }
    return ""
}

private func storedTrimmed(_ text: String?) -> String {
    (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
}
