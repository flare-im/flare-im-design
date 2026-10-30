package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
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
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.NumberFormat
import java.util.Locale

/**
 * Context passed to every content renderer. [messageId] is the message's id in the core (its server id, else the
 * client id it was sent with) and [conversationId] the conversation the list shows; both are null where the body is
 * drawn outside a message (a preview, a standalone body without them).
 */
data class FlareContentContext(
    val isSelf: Boolean,
    val previewMode: Boolean = false,
    /**
     * The display name the host gave the message's sender, trimmed; null when it gave none — never the id or a
     * placeholder, so a renderer writes "X 的红包" without looking the sender up by message id (spec MessageRenderContext).
     */
    val senderName: String? = null,
    val mediaState: FlareMediaDownloadState? = null,
    val onMediaAction: ((FlareMessageContent) -> Unit)? = null,
    val messageId: String? = null,
    val conversationId: String? = null,
    /**
     * The row is in multi-select: every control of the body (keys, menus, options, links, media) is inert and a tap goes
     * to the row, which toggles its selection. A renderer draws its content read-only then.
     */
    val selectionMode: Boolean = false,
    /** The surface the row draws this body on ([FlareMessageSurface]); null outside a message row. */
    val surface: FlareMessageSurface? = null,
    /**
     * A card's quoted reply: a card surface draws the quote inside its own shell, at the top. [PluginView] picks it up
     * by itself; a renderer that draws another shell places it there.
     */
    val quote: (@Composable () -> Unit)? = null,
    /** The message's sender id; null outside a message row. */
    val senderId: String? = null,
)

typealias FlareContentBuilder = @Composable (FlareMessageContent, FlareContentContext) -> Unit

private val LocalFlareContentBuilders = staticCompositionLocalOf<Map<String, FlareContentBuilder>> { emptyMap() }
private val LocalFlareContentSurfaces = staticCompositionLocalOf<Map<String, FlareMessageSurface>> { emptyMap() }

/** The surface of the message row a body is drawn in, and the quote its card shell carries (set by [MessageBubble]). */
internal val LocalFlareMessageSurface = staticCompositionLocalOf<FlareMessageSurface?> { null }
internal val LocalFlareCardQuote = staticCompositionLocalOf<(@Composable () -> Unit)?> { null }

/** The tone of the bubble a body is drawn in (set by [MessageBubble]); without one the body's side decides. */
internal val LocalFlareMessageBubbleTone = staticCompositionLocalOf<FlareMessageBubbleTone?> { null }

/**
 * Scope extension callbacks to one session/view tree, never a global tenant.
 *
 * [surfaces] registers the surface of a content key the kit does not know ([FlareMessageSurface.Card] or
 * [FlareMessageSurface.BareMedia]; spec/message-surface-vectors.json `rules.registration`), looked up as
 * `contentType:subtype`, then the content's own key, then its type. Every custom and plugin body (red packets, polls,
 * every `flare.plugin.message.v1` card) is already a card by default, so a host registers only a new content type: the
 * row then draws no bubble around a card — the body's own shell is the surface — and draws bare media as it draws a
 * picture, while it keeps the avatar, the sender's name, the time, multi-select and the long-press menu.
 */
@Composable
fun FlareContentScope(
    builders: Map<String, FlareContentBuilder>,
    surfaces: Map<String, FlareMessageSurface> = emptyMap(),
    content: @Composable () -> Unit,
) {
    CompositionLocalProvider(
        LocalFlareContentBuilders provides builders,
        LocalFlareContentSurfaces provides surfaces,
        content = content,
    )
}

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

/** The surfaces the scope registered ([FlareContentScope] `surfaces`). */
@Composable
internal fun flareContentSurfaces(): Map<String, FlareMessageSurface> = LocalFlareContentSurfaces.current

/**
 * Content-type dispatcher — renders a message body by type. Spec:
 * Message/MessageContentView (`MessageContentView`). Built-in bodies are also the standalone public components; media uses the package's Coil loader.
 *
 * Taps: [onMediaAction], when passed, receives every tap on a media body and the kit opens nothing
 * itself. Without it the kit consumes received media: an image opens the image preview, a video opens
 * the video player, and a voice message plays in its bubble (one at a time inside a [MessageList]); a
 * file goes to [onOpenFile], which opens it outside the app after the host's URL gate.
 *
 * A location tap goes to [onLocationOpen] with the location, else to [onMediaAction]; without either the card opens the
 * device's map app ([LocationMessage]). A contact card's tap goes to [onCardOpen] with the person it shares, else to
 * [onMediaAction]; without either the card has no tap.
 *
 * Downloads: [onMediaDownload] is the download key of the kit's image preview, with the picture on screen, of its
 * video player, with the video, and of a file card, with the file; without it none has a download key. Inside a
 * [MessageList] a picture opens the conversation's gallery instead, whose key downloads each picture through the
 * list's `onMediaDownload`. The key follows [mediaState]: a download, its progress while it runs, and once the file is
 * saved on this device a folder that hands the content to [onMediaReveal] (the host shows the file in its folder, or
 * passes an idle state again when the file is gone).
 *
 * Pictures: an image or album tile draws the picture's local copy ([FlareImageContent.localPath]) when the host has
 * one, else its thumbnail, else its full-size address; the preview opens the copy, else the full size
 * ([flarePictureSource]).
 *
 * Links: a link in a text body and a link card go to [onOpenLink] with the address. Without it the kit opens
 * an http or https address that passes [safeExternalUrl] with the platform opener ([LocalUriHandler]) and
 * never opens any other scheme; a link card whose address cannot be opened is not tappable.
 *
 * Surface (spec/message-surface-vectors.json): inside a [MessageBubble] the body follows the row's surface. On a card
 * surface the kit's own cards (location, contact, link, poll, task, schedule, announcement, mini program, forwards and
 * threads) draw their shell — `componentRichCardWidth` wide within the parent, radius lg, primary ground, hairline border,
 * the card shadow — with a quoted reply inside it at the top; on a card or bare surface the body keeps the default
 * palette (no outgoing foreground). A text that is a lone emoji draws large on its bare surface.
 *
 * [selectionMode]: the row is in multi-select, so the body is read-only — no key, option, link or media reacts.
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
    /** The download key of the image preview (the picture on screen), the video player (the video) and the file card (the file); without it none has one. */
    onMediaDownload: ((FlareMessageContent) -> Unit)? = null,
    /** The folder key those keys become once [mediaState] says the media is saved: the host shows the file in its folder. */
    onMediaReveal: ((FlareMessageContent) -> Unit)? = null,
    /** The message's id in the core, for a custom renderer ([FlareContentContext.messageId]); a list fills it. */
    messageId: String? = null,
    /** The conversation, for a custom renderer ([FlareContentContext.conversationId]); a list fills it. */
    conversationId: String? = null,
    /** A tapped contact card, with the user id it shares, for the host to open the profile; before [onMediaAction]. */
    onCardOpen: ((String) -> Unit)? = null,
    /** A tapped location, with the location; before [onMediaAction]. Without either the card opens the map app. */
    onLocationOpen: ((FlareLocationContent) -> Unit)? = null,
    /** The row is in multi-select: the body is read-only and its taps belong to the row. */
    selectionMode: Boolean = false,
    /** The sender's id, for a custom renderer ([FlareContentContext.senderId]); a message row fills it. */
    senderId: String? = null,
) {
    val surface = LocalFlareMessageSurface.current
    val cardQuote = LocalFlareCardQuote.current
    // Multi-select: nothing in the body acts.
    val onMediaAction = onMediaAction.takeUnless { selectionMode }
    val onOpenFile = onOpenFile.takeUnless { selectionMode }
    val onVote = onVote.takeUnless { selectionMode }
    val onTaskToggle = onTaskToggle.takeUnless { selectionMode }
    val onMediaDownload = onMediaDownload.takeUnless { selectionMode }
    val onMediaReveal = onMediaReveal.takeUnless { selectionMode }
    val onCardOpen = onCardOpen.takeUnless { selectionMode }
    val onLocationOpen = onLocationOpen.takeUnless { selectionMode }
    val ctx = FlareContentContext(
        isSelf, senderName = senderName?.trim()?.takeIf { it.isNotEmpty() }, mediaState = mediaState, onMediaAction = onMediaAction,
        messageId = messageId, conversationId = conversationId, selectionMode = selectionMode,
        surface = surface, quote = cardQuote, senderId = senderId?.takeIf { it.isNotEmpty() },
    )
    val custom = LocalFlareContentBuilders.current[content.type] ?: FlareContentRegistry.lookup(content.type)
    if (custom != null) { custom(content, ctx); return }

    val openLink = rememberFlareLinkOpener(onOpenLink)
    val tap = if (selectionMode) null
    else flareContentTap(content, hasMediaHandler = onMediaAction != null, hasFileHandler = onOpenFile != null, hasLinkHandler = onOpenLink != null)
    val inherited = LocalFlareMediaHost.current
    // Outside a MessageList the body presents its own media.
    val media = when {
        tap !is FlareContentTap.PreviewImage && tap !is FlareContentTap.PreviewAlbumImage && tap !is FlareContentTap.PlayVideo &&
            tap !is FlareContentTap.PlayVoice -> inherited
        inherited != null -> inherited
        else -> rememberFlareMediaHost().also { host -> FlareMediaOverlay(host) { mediaState } }
    }
    val messageKey = LocalFlareMessageKey.current
    val gallery = LocalFlareImageGallery.current
    val voiceKey = messageKey ?: (content as? FlareAudioContent)?.url.orEmpty()
    val action: (() -> Unit)? = when (tap) {
        null -> null
        FlareContentTap.Host -> { { onMediaAction?.invoke(content) } }
        is FlareContentTap.PreviewImage -> { {
            media?.present(flareImagePresentation(gallery, messageKey, 0, tap.src, onMediaDownload?.let { download -> { download(content) } },
                onMediaReveal?.let { reveal -> { reveal(content) } }))
        } }
        // An album's tiles open their own images; the body reports which one (below).
        FlareContentTap.PreviewAlbumImage -> null
        is FlareContentTap.PlayVideo -> { { media?.present(flareVideoPresentation(tap.src, content, messageKey, onReveal = onMediaReveal, onDownload = onMediaDownload)) } }
        is FlareContentTap.PlayVoice -> { { media?.voice?.toggle(voiceKey, tap.src) } }
        FlareContentTap.OpenFile -> { { (content as? FlareFileContent)?.let { onOpenFile?.invoke(it) } } }
        is FlareContentTap.OpenLink -> { { openLink(tap.url) } }
    }
    val linkTap: ((String) -> Unit)? = if (selectionMode) null else openLink

    val colors = flareColors()
    // Only a bubble's own surface recolours the body: a card's shell and bare media sit on the default palette.
    val onBubble = surface == null || surface == FlareMessageSurface.Bubble
    // The bubble's tone: a failed outgoing message is the failure surface, whose body takes the failure foreground.
    val tone = LocalFlareMessageBubbleTone.current
        ?: if (isSelf) FlareMessageBubbleTone.Outgoing else FlareMessageBubbleTone.Incoming
    val outgoing = onBubble && tone == FlareMessageBubbleTone.Outgoing
    val foreground = flareMessageBubblePalette(tone, colors).foreground
    val palette = if (!onBubble) colors else colors.copy(
        textPrimary = foreground, textSecondary = foreground,
        textTertiary = foreground.copy(alpha = 0.8f),
        // Text and rich text read their side's foreground: inside the bubble both sides are the bubble's, so the
        // failure surface reaches them too.
        messageOutgoingForeground = foreground, messageIncomingForeground = foreground,
        primary = if (outgoing) foreground else colors.primary,
        // An accent glyph (a file's icon, a voice's play key) on the outgoing surface is its foreground: the accent
        // text colour on the accent bubble drew nothing.
        primaryText = if (outgoing) foreground else colors.primaryText,
    )
    val card = surface == FlareMessageSurface.Card
    val locale = flareLocale()
    val strings = flareStrings()
    FlareThemeProvider(colors = palette) {
        Column {
            when (content) {
                is FlareTextContent -> if (surface == FlareMessageSurface.BareMedia) FlareEmojiPackMessage(content.text.trim(), isSelf = isSelf)
                else TextMessage(content.text, self = outgoing, onLinkTap = linkTap, mentions = content.mentions)
                is FlareRichTextContent -> RichTextMessage(content.docJson, plainText = content.plainText, title = content.title,
                    self = outgoing, onLinkTap = linkTap)
                is FlareEmojiContent -> EmojiMessage(content.emoji, onTap = action)
                is FlareStickerContent -> StickerMessage(url = content.url, packageId = content.packageId,
                    stickerId = content.stickerId, width = content.width, height = content.height, onTap = action)
                is FlareImageContent -> ImageMessageBody(model = flarePictureModel(flarePictureSource(content)),
                    maxWidth = 240, maxHeight = 240, alt = content.alt, onTap = action)
                is FlareImageGroupContent -> ImageGroupMessage(
                    content.images, description = content.description, self = outgoing,
                    onOpen = when (tap) {
                        FlareContentTap.Host -> { _ -> onMediaAction?.invoke(content) }
                        FlareContentTap.PreviewAlbumImage -> { index ->
                            val image = content.images[index]
                            val source = flarePictureSource(image, preferThumbnail = false).src
                            media?.present(flareImagePresentation(gallery, messageKey, index, source, onMediaDownload?.let { download -> { download(image) } },
                                onMediaReveal?.let { reveal -> { reveal(image) } }))
                        }
                        else -> null
                    },
                )
                is FlareVideoContent -> VideoMessage(poster = content.poster, duration = videoDurationLabel(content.durationSec), onPlay = action)
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
                is FlareFileContent -> FileMessage(
                    name = content.name, size = flareFileSize(content.sizeBytes.toLong(), strings, locale), ext = flareFileExtension(content.name),
                    onOpen = action,
                    onDownload = onMediaDownload?.let { download -> { download(content) } },
                    downloadState = mediaState,
                    onReveal = onMediaReveal?.let { reveal -> { reveal(content) } },
                )
                is FlareLocationContent -> FlareMessageCardShell(card, cardQuote, padded = false) { fill ->
                    LocationMessageBody(
                        title = content.name, address = content.address, latitude = content.latitude, longitude = content.longitude,
                        snapshotUrl = content.snapshotUrl, provider = content.provider,
                        onOpen = onLocationOpen?.let { open -> { open(content) } } ?: action,
                        openMaps = !selectionMode,
                        modifier = fill,
                    )
                }
                is FlareCardContent -> FlareMessageCardShell(card, cardQuote) { fill ->
                    ContactMessage(name = content.title, subtitle = content.subtitle,
                        avatarUrl = content.imageUrl, userId = content.userId,
                        onOpen = contactCardOpener(content, onCardOpen, onMediaAction), modifier = fill)
                }
                is FlareLinkCardContent -> FlareMessageCardShell(card, cardQuote, padded = false) { fill ->
                    LinkCardMessage(title = content.title, domain = content.url,
                        description = content.description, thumb = content.imageUrl, onOpen = action, modifier = fill)
                }
                is FlarePollContent -> FlareMessageCardShell(card, cardQuote, padded = false) { fill ->
                    VoteMessage(
                        title = content.title,
                        options = content.options.map { FlareVoteOption(it) },
                        onSelect = onVote?.let { vote -> { _, index -> vote(index) } },
                        modifier = fill,
                    )
                }
                is FlareTaskContent -> FlareMessageCardShell(card, cardQuote) { fill ->
                    TaskMessage(
                        title = content.title,
                        meta = content.detail,
                        done = content.done,
                        onToggle = onTaskToggle?.let { toggle -> { toggle(!content.done) } },
                        modifier = fill,
                    )
                }
                is FlareCalendarContent -> FlareMessageCardShell(card, cardQuote, padded = false) { fill ->
                    LinkCardMessage(title = content.title, description = content.timeRange,
                        onOpen = action, icon = { Icon(Icons.Outlined.CalendarMonth, null, tint = foreground) }, modifier = fill)
                }
                is FlareMiniAppContent -> FlareMessageCardShell(card, cardQuote, padded = false) { fill ->
                    LinkCardMessage(title = content.title, domain = content.appId,
                        description = content.description, thumb = content.thumbnailUrl, onOpen = action, modifier = fill)
                }
                is FlareAnnouncementContent -> FlareMessageCardShell(card, cardQuote, padded = false) { fill ->
                    LinkCardMessage(title = content.title, description = content.body,
                        descriptionMaxLines = Int.MAX_VALUE, onOpen = action,
                        icon = { Icon(Icons.AutoMirrored.Outlined.Announcement, null, tint = foreground) }, modifier = fill)
                }
                is FlareForwardContent -> ForwardRecordMessage(content, card = card, quote = cardQuote, selectionMode = selectionMode)
                is FlareNotificationContent -> SystemMessage(content.text)
                is FlarePlaceholderContent -> SystemMessage(content.label)
                // A picture or a video whose address is missing waits or failed: its placeholder, never "unsupported".
                is FlareGenericContent -> when (flareMessageContentType(content).first) {
                    "image" -> ImageMessageBody(model = null, alt = content.label.takeIf { it.isNotEmpty() })
                    "video" -> VideoMessage(alt = content.label.takeIf { it.isNotEmpty() })
                    // The kit's own one-line summary: the body's label when it has one, else the word for its
                    // wire type. Wrapping the label in brackets drew a literal "[]" for a body without one.
                    else -> FlareMessageCardShell(card, cardQuote) { _ ->
                        UnknownMessage(contentType = content.type, summary = flareMessagePreviewText(content, strings), isSelf = outgoing)
                    }
                }
                else -> UnknownMessage(contentType = content.type, isSelf = outgoing)
            }
            // A picture or video downloading from its viewer shows the progress under its body too; a file card's own key
            // is its progress. Progress not known yet (0) runs without a share.
            if (mediaState?.isDownloading == true && content !is FlareFileContent) {
                val pct = mediaState.progressPct.coerceIn(0, 100)
                if (pct > 0) androidx.compose.material3.LinearProgressIndicator(progress = { pct / 100f })
                else androidx.compose.material3.LinearProgressIndicator()
            }
        }
    }
}

/**
 * The shell of a kit card on a card surface: `componentRichCardWidth` wide within the parent, radius lg, the primary
 * ground, a hairline border and the card shadow, with the row's quoted reply inside at the top. [padded] gives the body
 * the shell's md padding (a body that pads itself, or a map that runs to the edges, passes false). Off a card surface
 * (a standalone body, a bubble) the body draws as it is. [content] gets the modifier that makes it fill the shell.
 */
@Composable
internal fun FlareMessageCardShell(
    card: Boolean,
    quote: (@Composable () -> Unit)?,
    padded: Boolean = true,
    content: @Composable (Modifier) -> Unit,
) {
    if (!card) { content(Modifier); return }
    val colors = flareColors()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    Column(
        Modifier.widthIn(max = FlareSizes.componentRichCardWidth).fillMaxWidth()
            .shadow(flareShadowElevation(flareShadows().card), shape, clip = false)
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderSecondary, shape),
    ) {
        if (quote != null) Box(Modifier.fillMaxWidth().padding(start = FlareSizes.spacingMd, end = FlareSizes.spacingMd, top = FlareSizes.spacingMd)) { quote() }
        Box(if (padded) Modifier.fillMaxWidth().padding(FlareSizes.spacingMd) else Modifier.fillMaxWidth()) { content(Modifier.fillMaxWidth()) }
    }
}

/**
 * A contact card's tap: [onCardOpen] with the person the card shares, else the host's media handler with the card; null
 * without either, and [onCardOpen] alone does not make a card that names no one tappable.
 */
internal fun contactCardOpener(
    card: FlareCardContent,
    onCardOpen: ((String) -> Unit)?,
    onMediaAction: ((FlareMessageContent) -> Unit)?,
): ((String) -> Unit)? {
    val userId = card.userId?.takeIf { it.isNotEmpty() }
    if (onCardOpen != null && userId != null) return { _ -> onCardOpen(userId) }
    return onMediaAction?.let { handler -> { _ -> handler(card) } }
}

internal fun duration(seconds: Int): String = "%02d:%02d".format(seconds / 60, seconds % 60)

/** A video body's badge: its length, or nothing when the message does not carry one — unknown, not a "00:00" video. */
internal fun videoDurationLabel(seconds: Int): String = if (seconds > 0) duration(seconds) else ""

/**
 * A file's size in the kit's words and the kit's locale: whole bytes, else one decimal of KB, MB or GB with the locale's
 * decimal mark (`fileSizeBytes` … `fileSizeGigabytes`, "{n} KB").
 */
internal fun flareFileSize(bytes: Long, strings: FlareStrings, locale: Locale): String {
    if (bytes < 1024) return strings.fileSizeBytes.replace("{n}", bytes.coerceAtLeast(0).toString())
    val format = NumberFormat.getNumberInstance(locale).apply {
        minimumFractionDigits = 1
        maximumFractionDigits = 1
        isGroupingUsed = true
    }
    val (value, template) = when {
        bytes < 1024L * 1024 -> bytes / 1024.0 to strings.fileSizeKilobytes
        bytes < 1024L * 1024 * 1024 -> bytes / 1024.0 / 1024 to strings.fileSizeMegabytes
        else -> bytes / 1024.0 / 1024 / 1024 to strings.fileSizeGigabytes
    }
    return template.replace("{n}", format.format(value))
}
