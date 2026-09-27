package com.flare.im.ui

import androidx.compose.runtime.staticCompositionLocalOf

/*
 * A conversation's image gallery: the pictures a full-screen preview opened from a timeline pages through. The rule
 * is shared with the other three kits (`spec/image-gallery-vectors.json`).
 */

/** One picture of the gallery: the message it belongs to, its place in that message, and the picture. */
data class FlareImageGalleryItem(val messageId: String, val index: Int, val image: FlareImageContent) {
    /** The address the preview loads: the picture's local copy, else the full-size image, else its thumbnail ([flarePictureSource]). */
    val source: String get() = flarePictureSource(image, preferThumbnail = false).src
}

/**
 * Every picture of every image and album message in [messages] (timeline order, oldest first), skipping recalled
 * messages and pictures with nothing to load.
 */
fun flareImageGalleryItems(messages: List<FlareMessageData>): List<FlareImageGalleryItem> = buildList {
    for (message in messages) {
        if (message.isRecalled) continue
        val images = when (val content = message.content) {
            is FlareImageContent -> listOf(content)
            is FlareImageGroupContent -> content.images
            else -> emptyList()
        }
        images.forEachIndexed { index, image ->
            val item = FlareImageGalleryItem(message.id, index, image)
            if (item.source.isNotBlank()) add(item)
        }
    }
}

/** Where a gallery of [items] starts for a tap on the picture at [index] of message [messageId]; null when it is not in it. */
fun flareImageGalleryStart(items: List<FlareImageGalleryItem>, messageId: String, index: Int): Int? =
    items.indexOfFirst { it.messageId == messageId && it.index == index }.takeIf { it >= 0 }

/**
 * The gallery of a [MessageList]: its pictures, and [download] — the list's `onMediaDownload` for one picture, with
 * the message it belongs to — or null when the host offers no download; [reveal] is the list's `onMediaReveal` the
 * same way, for a picture that is saved.
 */
internal class FlareTimelineGallery(
    val items: List<FlareImageGalleryItem>,
    val reveal: ((FlareImageGalleryItem) -> Unit)? = null,
    val download: ((FlareImageGalleryItem) -> Unit)?,
)

/** The gallery of the enclosing [MessageList]; null outside one. */
internal val LocalFlareImageGallery = staticCompositionLocalOf<FlareTimelineGallery?> { null }

/**
 * What a tap on a picture opens: the timeline's gallery starting at it when the picture is in [gallery], each page
 * downloaded and shown in its folder through the gallery's own download and reveal, its key following the page's
 * message; else the picture alone ([fallback], its own address) of message [messageId], downloaded through
 * [onDownload] and shown through [onReveal] — the body's keys, which a gallery does not use.
 */
internal fun flareImagePresentation(
    gallery: FlareTimelineGallery?,
    messageId: String?,
    index: Int,
    fallback: String,
    onDownload: (() -> Unit)? = null,
    onReveal: (() -> Unit)? = null,
): FlareMediaPresentation {
    val alone = FlareMediaPresentation.Image(fallback, onDownload, messageId, onReveal)
    if (gallery == null || messageId == null) return alone
    val items = gallery.items
    val start = flareImageGalleryStart(items, messageId, index) ?: return alone
    val download = gallery.download
    val reveal = gallery.reveal
    return FlareMediaPresentation.Gallery(
        sources = items.map { it.source },
        index = start,
        onDownload = download?.let { save -> { page -> save(items[page]) } },
        messageIds = items.map { it.messageId },
        onReveal = if (download == null) null else reveal?.let { show -> { page -> show(items[page]) } },
    )
}
