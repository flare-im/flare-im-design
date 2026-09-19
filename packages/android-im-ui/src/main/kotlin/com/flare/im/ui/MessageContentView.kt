package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Movie
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Apps
import androidx.compose.material.icons.automirrored.outlined.Announcement
import androidx.compose.material.icons.rounded.PlayCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Context passed to every content renderer. */
data class FlareContentContext(
    val isSelf: Boolean,
    val previewMode: Boolean = false,
    val senderName: String? = null,
    val mediaState: FlareMediaDownloadState? = null,
    val onMediaAction: ((FlareMessageContent) -> Unit)? = null,
)

typealias FlareContentBuilder = @Composable (FlareMessageContent, FlareContentContext) -> Unit

/**
 * Registry for product content types (`vote`, `task`…). Built-in types are
 * rendered directly by [MessageContentView]; register a builder to add/override.
 */
object FlareContentRegistry {
    private val builders = mutableMapOf<String, FlareContentBuilder>()
    fun register(type: String, builder: FlareContentBuilder) { builders[type] = builder }
    fun unregister(type: String) { builders.remove(type) }
    fun lookup(type: String): FlareContentBuilder? = builders[type]
}

/**
 * Content-type dispatcher — renders a message body by type. Spec:
 * Message/MessageContentView (`MessageContentView`). Built-in bodies are also the standalone public components; media uses the package's Coil loader.
 *
 * Taps: [onMediaAction], when passed, receives every tap on a media body and the kit opens nothing
 * itself. Without it the kit consumes received media: an image opens the image preview, a video opens
 * the video player, and a voice message plays in its bubble (one at a time inside a [MessageList]); a
 * file goes to [onOpenFile], which opens it outside the app after the host's URL gate. Location and cards
 * stay host actions, reached through [onMediaAction].
 *
 * Downloads: [onMediaDownload] is the download key of the kit's image preview, with the picture on screen; without it
 * the preview has no download key. Inside a [MessageList] a picture opens the conversation's gallery instead, whose
 * key downloads each picture through the list's `onMediaDownload`.
 *
 * Links: a link in a text body and a link card go to [onOpenLink] with the address. Without it the kit opens
 * an http or https address that passes [safeExternalUrl] with the platform opener ([LocalUriHandler]) and
 * never opens any other scheme; a link card whose address cannot be opened is not tappable.
 */
@Composable
fun MessageContentView(
    content: FlareMessageContent,
    isSelf: Boolean = false,
    senderName: String? = null,
    mediaState: FlareMediaDownloadState? = null,
    onMediaAction: ((FlareMessageContent) -> Unit)? = null,
    onOpenFile: ((FlareFileContent) -> Unit)? = null,
    onOpenLink: ((String) -> Unit)? = null,
    /** A tapped poll option (its index); without it the poll is read-only. */
    onVote: ((Int) -> Unit)? = null,
    /** A tapped task checkbox (the done state asked for); without it the task is read-only. */
    onTaskToggle: ((Boolean) -> Unit)? = null,
    /** The image preview's download key, with the picture on screen; without it the preview has none. */
    onMediaDownload: ((FlareMessageContent) -> Unit)? = null,
) {
    val ctx = FlareContentContext(isSelf, senderName = senderName, mediaState = mediaState, onMediaAction = onMediaAction)
    val custom = FlareContentRegistry.lookup(content.type)
    if (custom != null) { custom(content, ctx); return }

    val openLink = rememberFlareLinkOpener(onOpenLink)
    val tap = flareContentTap(content, hasMediaHandler = onMediaAction != null, hasFileHandler = onOpenFile != null, hasLinkHandler = onOpenLink != null)
    val inherited = LocalFlareMediaHost.current
    // Outside a MessageList the body presents its own media.
    val media = when {
        tap !is FlareContentTap.PreviewImage && tap !is FlareContentTap.PreviewAlbumImage && tap !is FlareContentTap.PlayVideo &&
            tap !is FlareContentTap.PlayVoice -> inherited
        inherited != null -> inherited
        else -> rememberFlareMediaHost().also { FlareMediaOverlay(it) }
    }
    val messageKey = LocalFlareMessageKey.current
    val gallery = LocalFlareImageGallery.current
    val voiceKey = messageKey ?: (content as? FlareAudioContent)?.url.orEmpty()
    val action: (() -> Unit)? = when (tap) {
        null -> null
        FlareContentTap.Host -> { { onMediaAction?.invoke(content) } }
        is FlareContentTap.PreviewImage -> { {
            media?.present(flareImagePresentation(gallery, messageKey, 0, tap.src, onMediaDownload?.let { download -> { download(content) } }))
        } }
        // An album's tiles open their own images; the body reports which one (below).
        FlareContentTap.PreviewAlbumImage -> null
        is FlareContentTap.PlayVideo -> { { media?.present(FlareMediaPresentation.Video(tap.src)) } }
        is FlareContentTap.PlayVoice -> { { media?.voice?.toggle(voiceKey, tap.src) } }
        FlareContentTap.OpenFile -> { { (content as? FlareFileContent)?.let { onOpenFile?.invoke(it) } } }
        is FlareContentTap.OpenLink -> { { openLink(tap.url) } }
    }

    val colors = flareColors()
    val foreground = if (isSelf) colors.messageOutgoingForeground else colors.messageIncomingForeground
    FlareThemeProvider(colors = colors.copy(
        textPrimary = foreground, textSecondary = foreground,
        textTertiary = foreground.copy(alpha = 0.8f),
        primary = if (isSelf) foreground else colors.primary,
    )) {
        Column {
            when (content) {
                is FlareTextContent -> TextMessage(content.text, self = isSelf, onLinkTap = openLink, mentions = content.mentions)
                is FlareRichTextContent -> RichTextMessage(content.docJson, plainText = content.plainText, title = content.title,
                    self = isSelf, onLinkTap = openLink)
                is FlareEmojiContent -> EmojiMessage(content.emoji, onTap = action)
                is FlareStickerContent -> StickerMessage(url = content.url, packageId = content.packageId,
                    stickerId = content.stickerId, width = content.width, height = content.height, onTap = action)
                is FlareImageContent -> ImageMessage(src = content.thumbnailUrl ?: content.url,
                    maxWidth = 240, maxHeight = 240, alt = content.alt, onTap = action)
                is FlareImageGroupContent -> ImageGroupMessage(
                    content.images, description = content.description, self = isSelf,
                    onOpen = when (tap) {
                        FlareContentTap.Host -> { _ -> onMediaAction?.invoke(content) }
                        FlareContentTap.PreviewAlbumImage -> { index ->
                            val image = content.images[index]
                            val source = image.url.ifBlank { image.thumbnailUrl.orEmpty() }
                            media?.present(flareImagePresentation(gallery, messageKey, index, source, onMediaDownload?.let { download -> { download(image) } }))
                        }
                        else -> null
                    },
                )
                is FlareVideoContent -> VideoMessage(poster = content.poster, duration = duration(content.durationSec), onPlay = action)
                is FlareAudioContent -> {
                    val voice = media?.voice?.takeIf { tap is FlareContentTap.PlayVoice }
                    val phase = voice?.phaseOf(voiceKey) ?: FlareVoicePhase.Idle
                    val learntMs = voice?.durations?.get(voiceKey) ?: 0
                    VoiceMessage(
                        seconds = if (content.durationSec > 0) content.durationSec else (learntMs + 500) / 1000,
                        playing = phase == FlareVoicePhase.Preparing || phase == FlareVoicePhase.Playing,
                        onPlay = action,
                        elapsedSeconds = if (phase == FlareVoicePhase.Playing || phase == FlareVoicePhase.Paused) voice?.positionMs?.div(1000) ?: 0 else 0,
                        failed = phase == FlareVoicePhase.Failed,
                    )
                }
                is FlareFileContent -> FileMessage(name = content.name, size = bytes(content.sizeBytes), onOpen = action)
                is FlareLocationContent -> LocationMessage(title = content.name, address = content.address, onOpen = action)
                is FlareCardContent -> ContactMessage(name = content.title, subtitle = content.subtitle,
                    avatarUrl = content.imageUrl, onOpen = action)
                is FlareLinkCardContent -> LinkCardMessage(title = content.title, domain = content.url,
                    description = content.description, thumb = content.imageUrl, onOpen = action)
                is FlarePollContent -> VoteMessage(
                    title = content.title,
                    options = content.options.map { FlareVoteOption(it) },
                    onSelect = onVote?.let { vote -> { _, index -> vote(index) } },
                )
                is FlareTaskContent -> TaskMessage(
                    title = content.title,
                    meta = content.detail,
                    done = content.done,
                    onToggle = onTaskToggle?.let { toggle -> { toggle(!content.done) } },
                )
                is FlareCalendarContent -> LinkCardMessage(title = content.title, description = content.timeRange,
                    onOpen = action, icon = { Icon(Icons.Outlined.CalendarMonth, null, tint = foreground) })
                is FlareMiniAppContent -> LinkCardMessage(title = content.title, domain = content.appId,
                    description = content.description, thumb = content.thumbnailUrl, onOpen = action)
                is FlareAnnouncementContent -> LinkCardMessage(title = content.title, description = content.body,
                    descriptionMaxLines = Int.MAX_VALUE, onOpen = action,
                    icon = { Icon(Icons.AutoMirrored.Outlined.Announcement, null, tint = foreground) })
                is FlareNotificationContent -> SystemMessage(content.text)
                is FlarePlaceholderContent -> SystemMessage(content.label)
                // The kit's own one-line summary: the body's label when it has one, else the word for its
                // wire type. Wrapping the label in brackets drew a literal "[]" for a body without one.
                is FlareGenericContent -> UnknownMessage(contentType = content.type, summary = flareMessagePreviewText(content, flareStrings()), isSelf = isSelf)
                else -> UnknownMessage(contentType = content.type, isSelf = isSelf)
            }
            if (mediaState?.isDownloading == true) {
                androidx.compose.material3.LinearProgressIndicator(progress = { mediaState.progressPct.coerceIn(0, 100) / 100f })
            }
        }
    }
}

internal fun duration(seconds: Int): String = "%02d:%02d".format(seconds / 60, seconds % 60)

internal fun bytes(b: Int): String = when {
    b < 1024 -> "$b B"
    b < 1024 * 1024 -> "%.1f KB".format(b / 1024.0)
    b < 1024 * 1024 * 1024 -> "%.1f MB".format(b / 1024.0 / 1024)
    else -> "%.1f GB".format(b / 1024.0 / 1024 / 1024)
}
