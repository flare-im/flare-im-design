package com.flare.im.ui

/**
 * Message body content — the data behind [MessageContentView] and the
 * content-type registry (spec `contentTypes.registered`). Products may add a
 * conforming type and register a builder via [FlareContentRegistry].
 */
interface FlareMessageContent {
    /** Registry key (e.g. `text`, `image`, `card`). */
    val type: String
}

/**
 * A text body. [mentions] are the mention runs inside [text] in UTF-16 indices; build them from the
 * core's mention entities with [textMentionSpans].
 */
data class FlareTextContent(val text: String, val mentions: List<FlareTextMentionSpan> = emptyList()) : FlareMessageContent {
    override val type get() = "text"
}

/**
 * A rich-text message: the RichDoc v2 document the core stores ([docJson]), the core's flat [plainText] of it,
 * and the message's own [title]. Drawn by [RichTextMessage]; the sender's Markdown source is not part of it.
 */
data class FlareRichTextContent(val docJson: String, val plainText: String = "", val title: String = "") : FlareMessageContent {
    override val type get() = "richText"
}

/**
 * A picture. [alt] is its own description, which a one-line summary prefers over the word for the
 * type. [animated] marks a motion image (a GIF): it renders the same, and reads as one
 * ([flareMessagePreviewText]).
 */
data class FlareImageContent(
    val url: String,
    val thumbnailUrl: String? = null,
    val alt: String? = null,
    val animated: Boolean = false,
) : FlareMessageContent {
    override val type get() = "image"
}

/** An image-group (album) message: its [images] in order, each drawn and opened like an image message, and the album's [description]. */
data class FlareImageGroupContent(val images: List<FlareImageContent>, val description: String = "") : FlareMessageContent {
    override val type get() = "imageGroup"
}

data class FlareVideoContent(val url: String, val poster: String? = null, val durationSec: Int = 0) : FlareMessageContent {
    override val type get() = "video"
}

data class FlareAudioContent(val url: String, val durationSec: Int = 0) : FlareMessageContent {
    override val type get() = "audio"
}

data class FlareFileContent(val name: String, val url: String, val sizeBytes: Int = 0) : FlareMessageContent {
    override val type get() = "file"
}

data class FlareLocationContent(val name: String, val address: String = "") : FlareMessageContent {
    override val type get() = "location"
}

data class FlareStickerContent(
    val url: String = "",
    /** Protocol pack identity — when set, resolves a bundled pack asset before [url]. */
    val packageId: String? = null,
    val stickerId: String? = null,
    val width: Int? = null,
    val height: Int? = null,
) : FlareMessageContent {
    override val type get() = "sticker"
}

data class FlareEmojiContent(val emoji: String) : FlareMessageContent {
    override val type get() = "emoji"
}

data class FlareCardContent(
    val title: String,
    val subtitle: String? = null,
    val imageUrl: String? = null,
    val sourceLabel: String? = null,
) : FlareMessageContent {
    override val type get() = "card"
}

/** System/notification line — rendered centred without a bubble. */
data class FlareNotificationContent(val text: String) : FlareMessageContent {
    override val type get() = "notification"
}

data class FlarePlaceholderContent(val label: String) : FlareMessageContent {
    override val type get() = "placeholder"
}

/** Product/registered type (`vote`, `task`…) with a plain fallback label. */
data class FlarePollContent(
    val id: String,
    val title: String,
    val options: List<String> = emptyList(),
) : FlareMessageContent {
    override val type get() = "vote"
}

data class FlareTaskContent(
    val id: String,
    val title: String,
    val detail: String = "",
    val done: Boolean = false,
) : FlareMessageContent {
    override val type get() = "task"
}

data class FlareCalendarContent(
    val id: String,
    val title: String,
    val timeRange: String = "",
) : FlareMessageContent {
    override val type get() = "schedule"
}

data class FlareMiniAppContent(
    val appId: String,
    val title: String,
    val pagePath: String = "",
    val thumbnailUrl: String? = null,
    val description: String? = null,
) : FlareMessageContent {
    override val type get() = "miniProgram"
}

data class FlareAnnouncementContent(
    val id: String,
    val title: String,
    val body: String = "",
) : FlareMessageContent {
    override val type get() = "announcement"
}

data class FlareLinkCardContent(val url: String, val title: String, val description: String? = null, val imageUrl: String? = null) : FlareMessageContent {
    override val type get() = "linkCard"
}

/**
 * A content type this kit has no body for, carried by its wire type (`forward`, `image_group`,
 * `quote`, `rich_text`…) with a plain [label] to show in its place. A one-line summary reads the
 * label when there is one, else the word for [contentType]; [itemCount] is how many items a
 * collection type carries (a forward's messages, an album's images), 0 when it carries none.
 */
data class FlareGenericContent(
    val contentType: String,
    val label: String,
    val itemCount: Int = 0,
) : FlareMessageContent {
    override val type get() = contentType
}

enum class FlareMediaDownloadStatus { Idle, Downloading, Done, Failed }

data class FlareMediaDownloadState(
    val status: FlareMediaDownloadStatus = FlareMediaDownloadStatus.Idle,
    val progressPct: Int = 0,
) {
    val isDownloading: Boolean get() = status == FlareMediaDownloadStatus.Downloading
}

/**
 * Neutral, presentational data for one message in a thread — the spec's
 * `Message` type consumed by [MessageBubble] / [MessageList].
 */
data class FlareMessageData(
    val id: String,
    val senderId: String,
    val senderName: String,
    val content: FlareMessageContent,
    /**
     * This message's id in the core (Vue `MessageLike.serverId`) — it matters only when that is not [id].
     * A message this device sent keeps its client id as the row id from the optimistic insert on, while the
     * core knows it by the id the server gave it, and a quote names its original by that core id. The list
     * matches a located id against both, so null means the two are the same id (or none was given).
     */
    val serverId: String? = null,
    val senderAvatarUrl: String? = null,
    val timeLabel: String = "",
    val sentAtMs: Long = 0,
    val status: FlareMessageDeliveryStatus = FlareMessageDeliveryStatus.Sent,
    val lifecycle: FlareMessageLifecycle? = null,
    val edited: Boolean = false,
    /** Aggregated reactions shown under the bubble; empty shows none. */
    val reactions: List<ReactionGroup> = emptyList(),
    /** The message this one replies to, quoted at the top of the bubble. */
    val replyTo: FlareReplyTarget? = null,
) {
    val isSystem: Boolean get() = content is FlareNotificationContent

    /** A recalled message renders as a notice in place of its content (lifecycle mutation outranks everything). */
    val isRecalled: Boolean get() = lifecycle?.mutation == FlareMessageMutationState.Recalled
}
