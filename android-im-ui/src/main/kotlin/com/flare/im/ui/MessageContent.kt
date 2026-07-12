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

data class FlareTextContent(val text: String, val mentionsSelf: Boolean = false) : FlareMessageContent {
    override val type get() = "text"
}

data class FlareImageContent(val url: String, val thumbnailUrl: String? = null, val alt: String? = null) : FlareMessageContent {
    override val type get() = "image"
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
data class FlareGenericContent(val contentType: String, val label: String) : FlareMessageContent {
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
    val senderAvatarUrl: String? = null,
    val timeLabel: String = "",
    val status: FlareMessageDeliveryStatus = FlareMessageDeliveryStatus.Sent,
) {
    val isSystem: Boolean get() = content is FlareNotificationContent
}
