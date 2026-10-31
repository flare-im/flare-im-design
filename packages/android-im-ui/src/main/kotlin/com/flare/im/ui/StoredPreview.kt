package com.flare.im.ui

/*
 * The core's stored summary of a message — a conversation's last message, a quote, a search hit — is a stable
 * token, not display text: `{"k":"im.preview.image","a":{"d":"说明","m":true}}` (flare-im-core-sdk
 * `preview_storage.rs`). The rule for reading it is the shared table's `stored` list
 * (`spec/message-preview-vectors.json`), the one Vue's `displayTextFromStoredPreview` and the SwiftUI and
 * Flutter kits' `flareStoredPreviewText` answer to.
 */

/**
 * The one line [raw] reads as in the words of [strings].
 *
 * A token with words of its own (a caption, a file name, a title, the server's fallback line for a system event)
 * reads as those words; the rest read as their `preview*` word, with the `…Named` variant when they carry a name
 * and the `…Count` variant when they carry a number. A system or notification line without words is named by its
 * event key (`ek`): [systemEventText] first, for the events a host names itself, then the kit's `systemEvent*`
 * words, else [FlareStrings.previewSystem]. Text that is not a token is history from before the tokens and reads
 * as it is; a token the kit does not know, or one with no words where words are the whole message, reads as "" —
 * never its raw JSON. Markdown reads as plain text and pack keys as their names, as in [flareMessagePreviewText].
 */
fun flareStoredPreviewText(
    raw: String?,
    strings: FlareStrings,
    locale: String? = null,
    systemEventText: ((String) -> String)? = null,
): String {
    val text = raw?.trim().orEmpty()
    if (text.isEmpty()) return ""
    val words = storedPreviewToken(text)?.let { (kind, args) -> storedTokenText(kind, args, strings, locale, systemEventText) } ?: text
    // Markdown first, then the pack keys — the order Vue reads a preview in.
    return FlareEmojiStickerCatalog.localizePackKeysInText(
        flareMarkdownToPlainText(words, strings),
        locale ?: java.util.Locale.getDefault().toLanguageTag(),
    ).trim()
}

/** The token's kind and arguments, or null when [text] is not a token. */
private fun storedPreviewToken(text: String): Pair<String, Map<*, *>>? {
    if (!text.startsWith("{")) return null
    val parsed = runCatching { FlareJson.parse(text) }.getOrNull() as? Map<*, *> ?: return null
    val kind = parsed["k"] as? String ?: return null
    return kind to (parsed["a"] as? Map<*, *> ?: emptyMap<String, Any?>())
}

private fun storedTokenText(
    kind: String,
    args: Map<*, *>,
    s: FlareStrings,
    locale: String?,
    systemEventText: ((String) -> String)?,
): String {
    fun arg(vararg names: String): String =
        names.firstNotNullOfOrNull { (args[it] as? String)?.trim()?.takeIf(String::isNotEmpty) }.orEmpty()
    fun named(name: String, withName: (String) -> String, word: String) = if (name.isEmpty()) word else withName(name)
    fun event(words: String, word: String): String {
        if (words.isNotEmpty()) return words
        val eventKey = arg("ek")
        if (eventKey.isEmpty()) return word
        val hosted = systemEventText?.invoke(eventKey)?.trim().orEmpty()
        return hosted.ifEmpty { kitSystemEventText(eventKey, eventName(args), s) }.ifEmpty { word }
    }

    return when (kind) {
        "im.preview.user_text" -> arg("t")
        "im.preview.rich_text" -> listOf(arg("title"), arg("body"), arg("markdown")).filter { it.isNotEmpty() }
            .joinToString(" ").ifEmpty { s.previewRichText }
        "im.preview.file" -> named(arg("n"), s.previewFileNamed, s.previewFile)
        "im.preview.image" -> if (args["m"] == true) s.previewGif else arg("d").ifEmpty { s.previewImage }
        "im.preview.video" -> arg("d").ifEmpty { s.previewVideo }
        "im.preview.audio" -> arg("d").ifEmpty { s.previewAudio }
        "im.preview.location" -> named(arg("label"), s.previewLocationNamed, s.previewLocation)
        "im.preview.card" -> named(arg("label"), s.previewCardNamed, s.previewCard)
        "im.preview.sticker" -> s.previewSticker
        "im.preview.emoji" -> arg("e", "emoji", "key")
            .let { key -> if (key.isEmpty()) "" else FlareEmojiStickerCatalog.emojiLabel(key, locale ?: java.util.Locale.getDefault().toLanguageTag()) }
            .ifEmpty { s.previewEmoji }
        "im.preview.quote" -> (args["inner"] as? Map<*, *>)?.let { inner ->
            (inner["k"] as? String)?.let { innerKind ->
                storedTokenText(innerKind, inner["a"] as? Map<*, *> ?: emptyMap<String, Any?>(), s, locale, systemEventText)
            }
        }.orEmpty().ifEmpty { s.previewQuote }
        "im.preview.link" -> arg("t").ifEmpty { s.previewLink }
        "im.preview.forward_empty" -> s.previewForward
        "im.preview.forward_many" -> ((args["n"] as? Number)?.toInt() ?: 0)
            .let { count -> if (count > 0) s.previewForwardCount(count) else s.previewForward }
        "im.preview.thread" -> arg("t").ifEmpty { s.previewThread }
        "im.preview.mini_program" -> arg("t").ifEmpty { s.previewMiniProgram }
        "im.preview.image_group" -> s.previewImageGroup
        "im.preview.system" -> event(arg("fb", "t", "body", "title"), s.previewSystem)
        "im.preview.notification" -> event(arg("fb", "body", "title"), s.previewNotification)
        "im.preview.vote" -> s.previewVote
        "im.preview.task" -> arg("t").ifEmpty { s.previewTask }
        "im.preview.schedule" -> s.previewSchedule
        "im.preview.announcement" -> arg("t").ifEmpty { s.previewAnnouncement }
        "im.preview.custom" -> arg("d").ifEmpty { s.previewCustom }
        "im.preview.placeholder" -> arg("t").ifEmpty { s.previewPlaceholder }
        "im.preview.unknown" -> s.previewUnknown
        else -> ""
    }
}

/**
 * The kit's words for a system event key (Vue's `systemEvent.*`), or "" for a key it does not name. The keys are the
 * `SystemContent.event_kind` values the social server writes; [name] is the name the event's parameters carry, for
 * the events whose words include one.
 */
private fun kitSystemEventText(eventKey: String, name: String, s: FlareStrings): String = when (eventKey) {
    "group.created" -> s.systemEventGroupCreated
    "group.member_joined" -> s.systemEventGroupMemberJoined
    "group.member_kicked" -> s.systemEventGroupMemberRemoved
    "group.member_left" -> s.systemEventGroupMemberLeft
    "group.member_muted" -> s.systemEventGroupMemberMuted
    "group.member_unmuted" -> s.systemEventGroupMemberUnmuted
    "group.owner_transferred" -> s.systemEventGroupOwnerTransferred
    "group.dissolved" -> s.systemEventGroupDissolved
    "group.announcement" -> s.systemEventGroupAnnouncementUpdated
    "group.profile_updated" -> if (name.isEmpty()) s.systemEventGroupProfileUpdated else s.systemEventGroupProfileUpdatedNamed(name)
    "group.member_roles_changed" -> s.systemEventGroupMemberRolesChanged
    "group.muted" -> s.systemEventGroupMuted
    "group.unmuted" -> s.systemEventGroupUnmuted
    "relation.friendship_established" -> s.systemEventFriendshipEstablished
    else -> ""
}

/** The name a system event's parameters (`p`) carry: a group's new display name, else its name. */
private fun eventName(args: Map<*, *>): String {
    val params = args["p"] as? Map<*, *> ?: return ""
    return listOf("display_name", "name").firstNotNullOfOrNull { (params[it] as? String)?.trim()?.takeIf(String::isNotEmpty) }.orEmpty()
}
