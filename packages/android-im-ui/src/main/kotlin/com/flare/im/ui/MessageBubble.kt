package com.flare.im.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.RadioButtonUnchecked
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** What the multi-select layer of [MessageBubble] renders for one row. */
internal data class MessageSelectionUi(
    /** Leading check control is shown. */
    val showCheck: Boolean,
    /** Tapping the whole row toggles selection. */
    val toggles: Boolean,
    /** Row background uses the message-selection semantic. */
    val highlighted: Boolean,
)

/**
 * Multi-select rules, same as Flutter `FlareMessageBubble`: the check control
 * appears in multi-select mode only; the row toggles only when the host also
 * supplied `onToggleSelect`; the highlight follows `selected` regardless of
 * mode (so a host can keep the tint while the toolbar animates away). System
 * notices are never selectable.
 */
internal fun messageSelectionUi(
    multiSelectMode: Boolean,
    selected: Boolean,
    hasToggle: Boolean,
    isSystem: Boolean = false,
): MessageSelectionUi {
    if (isSystem) return MessageSelectionUi(showCheck = false, toggles = false, highlighted = false)
    return MessageSelectionUi(
        showCheck = multiSelectMode,
        toggles = multiSelectMode && hasToggle,
        highlighted = selected,
    )
}

/**
 * The quoted message's core id a bubble's quote locates, or null when the quote is plain text: it
 * needs a known id, someone to locate it, and taps that are not selecting rows. Which row that id is
 * on — and whether it is loaded at all — is the list's question, answered by [messageRowIndexByAnyId].
 */
internal fun messageQuoteLocateId(replyTo: FlareReplyTarget?, hasOnLocate: Boolean, multiSelectMode: Boolean): String? =
    replyTo?.messageId?.takeIf { hasOnLocate && !multiSelectMode }

/** The width of the timeline pane a [MessageList] lays its rows out in; bubbles size against it, not the screen. */
internal val LocalFlareTimelinePaneWidth = staticCompositionLocalOf<Dp?> { null }

/** What a bubble's own chrome draws on its surface: a background, padding, tail and shadow only on a bubble. */
internal data class MessageSurfaceChrome(val background: Boolean, val padding: Boolean, val tail: Boolean, val shadow: Boolean)

/** A bubble draws its chrome; bare media and cards draw none — a card's own shell is the surface. */
internal fun messageSurfaceChrome(surface: FlareMessageSurface, tail: Boolean): MessageSurfaceChrome =
    if (surface == FlareMessageSurface.Bubble) MessageSurfaceChrome(background = true, padding = true, tail = tail, shadow = true)
    else MessageSurfaceChrome(background = false, padding = false, tail = false, shadow = false)

/**
 * One message in a thread — content, sender, grouping, receipt. Spec: Message/MessageBubble (`MessageBubble`). Status
 * comes from host lifecycle state (optimistic), never a network wait.
 *
 * Surface (spec/message-surface-vectors.json): [surface], or the kit's own derivation — the content type, the quote, the
 * recall or deletion and the scope's registrations ([FlareContentScope] `surfaces`). A bubble is the coloured bubble;
 * bare media (pictures, videos without a caption, stickers, a lone emoji) draws no bubble; a card (every plugin card, red
 * packets, locations, contact and link cards, polls, tasks…) draws no background, border, padding, tail or shadow around
 * the content, whose own shell is the surface, and carries a quoted reply inside that shell; a centred row is one notice
 * line (system lines, recalls, and "Message deleted").
 *
 * Meta (spec/message-meta-placement-vectors.json): a text bubble ends its last line with the time and receipt and moves
 * them to their own row when they do not fit; other bubbles keep them in a footer row; bare media and cards have them
 * under the surface at the trailing edge in the default palette, where a failed message reads "Failed to send. Retry".
 * The retry — that key, or the failed glyph inside a bubble, whose bubble keeps a red edge — takes [onResend] with a hit
 * area of at least the touch target. The receipt is the SDK's (spec/message-receipt-vectors.json): five states, no
 * delivered, and in a group the viewer's own messages show [FlareMessageData.readSummary] as "N unread" / "Read by all",
 * a key that hands the message's core id to [onReadReceiptOpen].
 *
 * The time is [FlareMessageData.timeLabel], else the clock of [FlareMessageData.sentAtMs] in the kit's locale
 * ([flareLocale]) — never the device's. The bubble is at most the timeline pane's width times the bubble ratio, capped by
 * `bubbleMaxWidth`. The avatar draws [FlareMessageData.senderAvatarUrl]; [onAvatarTap] makes it a key.
 *
 * Multi-select (names shared with Flutter/iOS): [multiSelectMode] shows a leading check control, makes the content
 * read-only (no key, option, link or media reacts) and the whole row tap-to-toggle via [onToggleSelect] (receives the
 * message id); [selected] tints the row.
 *
 * Media taps follow [MessageContentView]: [onMediaAction] takes them all; without it the kit previews images, plays
 * videos and voice, and a file tap goes to [onOpenFile]. [onMediaDownload] is the download key of the image preview, the
 * video player and a file card; once [mediaState] says the media is saved it is a folder that calls [onMediaReveal].
 * Links in the text and link cards go to [onOpenLink]; without it the kit opens only safe web addresses.
 *
 * Accessibility: the row is one reading unit — sender, content summary, time and status or read summary
 * ([flareMessageAccessibilityLabel]) — with a retry action while the message failed.
 */
@Composable
fun MessageBubble(
    message: FlareMessageData,
    currentUserId: String,
    conversationKind: FlareConversationKind = FlareConversationKind.Single,
    groupPosition: MessageGroupPosition = MessageGroupPosition.Single,
    rowPresentation: MessageRowPresentation = MessageRowPresentation(),
    surface: FlareMessageSurface? = null,
    mediaState: FlareMediaDownloadState? = null,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
    onResend: ((FlareMessageData) -> Unit)? = null,
    multiSelectMode: Boolean = false,
    selected: Boolean = false,
    onToggleSelect: ((String) -> Unit)? = null,
    /** Tapping a reaction pill toggles the current user's reaction; without it the pills are display-only. */
    onReact: ((FlareMessageData, String) -> Unit)? = null,
    onLocateMessage: ((String) -> Unit)? = null,
    onOpenFile: ((FlareMessageData, FlareFileContent) -> Unit)? = null,
    onOpenLink: ((String) -> Unit)? = null,
    /** A tapped poll option (message, option index); without it, or in multi-select mode, the poll is read-only. */
    onVote: ((FlareMessageData, Int) -> Unit)? = null,
    /** A tapped task checkbox (message, the done state asked for); without it, or in multi-select mode, the task is read-only. */
    onTaskToggle: ((FlareMessageData, Boolean) -> Unit)? = null,
    /** The download key of the image preview (message, the picture on screen), the video player (message, the video) and the file card; without it none has one. */
    onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
    /** The folder key those keys become once [mediaState] says the media is saved: the host shows the file in its folder. */
    onMediaReveal: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
    /** A tapped contact card (message, the user id it shares), for the host to open the profile; before [onMediaAction]. */
    onCardOpen: ((FlareMessageData, String) -> Unit)? = null,
    /** A tapped location (message, the location); before [onMediaAction]. Without either the card opens the map app. */
    onLocationOpen: ((FlareMessageData, FlareLocationContent) -> Unit)? = null,
    /** The read summary key of an own group message: the message's core id, for the host to open its read list. */
    onReadReceiptOpen: ((String) -> Unit)? = null,
    /** A tapped avatar: the host opens the sender's profile. */
    onAvatarTap: ((FlareMessageData) -> Unit)? = null,
) {
    val row: @Composable () -> Unit = {
        MessageBubbleRow(
            message = message, currentUserId = currentUserId, conversationKind = conversationKind, groupPosition = groupPosition,
            rowPresentation = rowPresentation, surface = surface, mediaState = mediaState, onMediaAction = onMediaAction,
            onResend = onResend, multiSelectMode = multiSelectMode, selected = selected, onToggleSelect = onToggleSelect,
            onReact = onReact, onLocateMessage = onLocateMessage, onOpenFile = onOpenFile, onOpenLink = onOpenLink, onVote = onVote,
            onTaskToggle = onTaskToggle, onMediaDownload = onMediaDownload, onMediaReveal = onMediaReveal, onCardOpen = onCardOpen,
            onLocationOpen = onLocationOpen, onReadReceiptOpen = onReadReceiptOpen, onAvatarTap = onAvatarTap,
            onLongPress = null, onReply = null,
        )
    }
    // Outside a list the bubble measures its own row as the pane.
    if (LocalFlareTimelinePaneWidth.current != null) row()
    else BoxWithConstraints(Modifier.fillMaxWidth()) {
        CompositionLocalProvider(LocalFlareTimelinePaneWidth provides maxWidth) { row() }
    }
}

/**
 * [MessageBubble] as a [MessageList] draws it: [onLongPress] opens the message menu (and is the row's "open menu"
 * accessibility action), [onReply] is the row's "reply" action (the swipe's twin).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun MessageBubbleRow(
    message: FlareMessageData,
    currentUserId: String,
    conversationKind: FlareConversationKind,
    groupPosition: MessageGroupPosition,
    rowPresentation: MessageRowPresentation,
    surface: FlareMessageSurface?,
    mediaState: FlareMediaDownloadState?,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)?,
    onResend: ((FlareMessageData) -> Unit)?,
    multiSelectMode: Boolean,
    selected: Boolean,
    onToggleSelect: ((String) -> Unit)?,
    onReact: ((FlareMessageData, String) -> Unit)?,
    onLocateMessage: ((String) -> Unit)?,
    onOpenFile: ((FlareMessageData, FlareFileContent) -> Unit)?,
    onOpenLink: ((String) -> Unit)?,
    onVote: ((FlareMessageData, Int) -> Unit)?,
    onTaskToggle: ((FlareMessageData, Boolean) -> Unit)?,
    onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Unit)?,
    onMediaReveal: ((FlareMessageData, FlareMessageContent) -> Unit)?,
    onCardOpen: ((FlareMessageData, String) -> Unit)?,
    onLocationOpen: ((FlareMessageData, FlareLocationContent) -> Unit)?,
    onReadReceiptOpen: ((String) -> Unit)?,
    onAvatarTap: ((FlareMessageData) -> Unit)?,
    onLongPress: (() -> Unit)?,
    onReply: (() -> Unit)?,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val locale = flareLocale()
    val self = message.senderId == currentUserId
    val resolved = surface ?: rememberFlareMessageSurface(message)

    if (resolved == FlareMessageSurface.Centered) {
        NoticeLine(messageNoticeText(message, self, conversationKind, strings), colors)
        return
    }

    val showAvatar = rowPresentation.showAvatar
    val groupStart = groupPosition == MessageGroupPosition.Single || groupPosition == MessageGroupPosition.First
    val groupEnd = groupPosition == MessageGroupPosition.Single || groupPosition == MessageGroupPosition.Last
    val selection = messageSelectionUi(multiSelectMode, selected, onToggleSelect != null)
    val onLocateQuote = messageQuoteLocateId(message.replyTo, onLocateMessage != null, multiSelectMode)
        ?.let { id -> { onLocateMessage?.invoke(id); Unit } }
    val status = message.lifecycle?.visualStatus ?: message.status
    val time = message.timeLabel.ifEmpty { if (message.sentAtMs > 0) FlareTimeFormat.messageTime(message.sentAtMs, locale) else "" }
    val receipt = flareMessageReceiptPresentation(conversationKind, self, status, message.readSummary)
    val label = flareMessageAccessibilityLabel(
        sender = message.senderName,
        preview = flareMessagePreviewText(message.content, strings, locale.toLanguageTag()),
        time = time, self = self, status = status, strings = strings, locale = locale,
        conversationKind = conversationKind, readSummary = message.readSummary,
    )
    val resend = onResend?.takeIf { self && status == FlareMessageDeliveryStatus.Failed }
    val actions = buildList {
        if (!multiSelectMode) {
            onReply?.let { reply -> add(CustomAccessibilityAction(strings.messageActionReply) { reply(); true }) }
            onLongPress?.let { open -> add(CustomAccessibilityAction(strings.actionMenuLabel) { open(); true }) }
            resend?.let { retry -> add(CustomAccessibilityAction(strings.retry) { retry(message); true }) }
        }
    }
    val toggle = onToggleSelect?.let { cb -> { cb(message.id) } }
    val currentToggle by rememberUpdatedState(toggle)
    val rowGesture = when {
        selection.toggles -> Modifier.selectable(selected = selected, onClick = { toggle?.invoke() })
        onLongPress != null && !multiSelectMode ->
            Modifier.combinedClickable(onClick = {}, onLongClick = onLongPress, onLongClickLabel = strings.actionMenuLabel)
        else -> Modifier.semantics(mergeDescendants = true) {}
    }
    Box(
        // Group-aware rhythm (matches Flutter/iOS/web): a clear breath before a new sender's run, tight within a run.
        Modifier.fillMaxWidth()
            .then(if (selection.highlighted) Modifier.background(colors.messageSelectedBackground) else Modifier)
            .then(rowGesture)
            .semantics {
                contentDescription = label
                if (actions.isNotEmpty()) customActions = actions
            },
    ) {
        Row(
            Modifier.fillMaxWidth()
                .padding(
                    start = FlareSizes.spacingMd,
                    end = FlareSizes.spacingMd,
                    top = if (groupStart) FlareSizes.spacingSm else 2.dp,
                    bottom = if (groupEnd) FlareSizes.spacingSm else 2.dp,
                ),
            horizontalArrangement = if (self) Arrangement.End else Arrangement.Start,
            verticalAlignment = Alignment.Top,
        ) {
            if (selection.showCheck) {
                Icon(
                    if (selected) Icons.Rounded.CheckCircle else Icons.Rounded.RadioButtonUnchecked,
                    contentDescription = strings.select,
                    tint = if (selected) colors.primaryText else colors.textTertiary,
                    modifier = Modifier.size(22.dp).align(Alignment.CenterVertically),
                )
                Spacer(Modifier.width(FlareSizes.spacingSm))
                if (self) Spacer(Modifier.weight(1f))
            }
            if (!self && rowPresentation.reserveAvatarSpace) {
                MessageAvatarSlot(message, showAvatar, onAvatarTap.takeUnless { multiSelectMode })
                Spacer(Modifier.width(FlareSizes.spacingSm))
            }
            Column(horizontalAlignment = if (self) Alignment.End else Alignment.Start) {
                if (rowPresentation.showSenderName) {
                    Text(message.senderName, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                }
                // Multi-select taps select the row: a poll or a task is not a control then.
                val intents = MessageBodyIntents(
                    vote = onVote?.takeIf { !multiSelectMode }?.let { cb -> { index -> cb(message, index) } },
                    taskToggle = onTaskToggle?.takeIf { !multiSelectMode }?.let { cb -> { done -> cb(message, done) } },
                    cardOpen = onCardOpen?.let { cb -> { userId -> cb(message, userId) } },
                    locationOpen = onLocationOpen?.let { cb -> { location -> cb(message, location) } },
                )
                MessageSurfaceBody(
                    message = message, self = self, surface = resolved, tail = groupEnd,
                    colors = colors, mediaState = mediaState, time = time, status = status, receipt = receipt,
                    onResend = resend, onMediaAction = onMediaAction, onMediaDownload = onMediaDownload, onMediaReveal = onMediaReveal,
                    onOpenFile = onOpenFile, onOpenLink = onOpenLink, onLocateQuote = onLocateQuote, intents = intents,
                    selectionMode = multiSelectMode,
                    onReadReceiptOpen = onReadReceiptOpen?.takeIf { !multiSelectMode }?.let { cb -> { cb(message.serverId ?: message.id) } },
                )
                if (message.reactions.isNotEmpty()) {
                    Box(Modifier.padding(top = FlareSizes.spacingXs)) {
                        // Multi-select taps select the row; pills toggle only outside it.
                        ReactionSummary(
                            message.reactions,
                            hideAdd = true,
                            onToggle = onReact?.takeIf { !multiSelectMode }?.let { cb -> { emoji -> cb(message, emoji) } },
                        )
                    }
                }
            }
            if (self && rowPresentation.reserveAvatarSpace) {
                Spacer(Modifier.width(FlareSizes.spacingSm))
                MessageAvatarSlot(message, showAvatar, onAvatarTap.takeUnless { multiSelectMode })
            }
        }
        // Multi-select: a tap anywhere on the row selects it; nothing under it reacts.
        if (multiSelectMode) {
            Box(Modifier.matchParentSize().pointerInput(Unit) { detectTapGestures { currentToggle?.invoke() } })
        }
    }
}

/** The surface of [message] as the kit derives it: the scope's registrations and, for a text, the emoji catalog. */
@Composable
internal fun rememberFlareMessageSurface(message: FlareMessageData): FlareMessageSurface {
    val surfaces = flareContentSurfaces()
    val mayHoldEmoji = (message.content as? FlareTextContent)?.text?.let(::flareMayHoldEmojiTokens) == true
    val catalogLoaded = if (mayHoldEmoji) rememberCatalogLoaded() else false
    return remember(message, surfaces, catalogLoaded) {
        flareMessageSurface(message, surfaces, if (catalogLoaded) FlareEmojiStickerCatalog::hasEmojiKey else { _ -> false })
    }
}

/** The line a centred row reads: the recall wording by who recalled it, "Message deleted", or the notice itself. */
internal fun messageNoticeText(message: FlareMessageData, self: Boolean, conversationKind: FlareConversationKind, strings: FlareStrings): String =
    when {
        message.isRecalled -> when {
            self -> strings.messageRecalledSelf
            conversationKind == FlareConversationKind.Group -> strings.messageRecalledGroupOther(message.senderName)
            else -> strings.messageRecalledPeer
        }
        message.isDeleted -> strings.messageDeleted
        message.content is FlareNotificationContent -> message.content.text
        else -> flareMessagePreviewText(message.content, strings)
    }

/** The avatar of a row (its URL, initials meanwhile), or its gutter; with [onTap] a key named by the sender. */
@Composable
private fun MessageAvatarSlot(message: FlareMessageData, show: Boolean, onTap: ((FlareMessageData) -> Unit)?) {
    if (!show) { Spacer(Modifier.width(FlareSizes.componentMessageAvatarSize)); return }
    val avatar = @Composable {
        Avatar(
            userId = message.senderId, displayName = message.senderName, size = FlareSizes.componentMessageAvatarSize,
            avatarUrl = message.senderAvatarUrl,
        )
    }
    if (onTap == null) {
        // The row's name already says who sent it.
        Box(Modifier.clearAndSetSemantics {}) { avatar() }
    } else {
        FlareIconControl(
            label = message.senderName,
            onClick = { onTap(message) },
            modifier = Modifier.flareTouchTargetBeyond(FlareSizes.componentMessageAvatarSize),
        ) { Box(Modifier.clearAndSetSemantics {}) { avatar() } }
    }
}

/** A poll's, a task's, a contact card's and a location's intents for one bubble's body; null where the host takes none. */
private class MessageBodyIntents(
    val vote: ((Int) -> Unit)?,
    val taskToggle: ((Boolean) -> Unit)?,
    val cardOpen: ((String) -> Unit)? = null,
    val locationOpen: ((FlareLocationContent) -> Unit)? = null,
)

/** Centred notice pill for system lines, recalled and deleted messages. */
@Composable
private fun NoticeLine(text: String, colors: FlareColors) {
    Box(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingSm), contentAlignment = Alignment.Center) {
        Box(
            Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgTertiary)
                .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
        ) { Text(text, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp) }
    }
}

@Composable
private fun MessageSurfaceBody(
    message: FlareMessageData,
    self: Boolean,
    surface: FlareMessageSurface,
    tail: Boolean,
    colors: FlareColors,
    mediaState: FlareMediaDownloadState?,
    time: String,
    status: FlareMessageDeliveryStatus,
    receipt: FlareMessageReceiptPresentation,
    onResend: ((FlareMessageData) -> Unit)?,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)?,
    onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Unit)?,
    onMediaReveal: ((FlareMessageData, FlareMessageContent) -> Unit)?,
    onOpenFile: ((FlareMessageData, FlareFileContent) -> Unit)?,
    onOpenLink: ((String) -> Unit)?,
    onLocateQuote: (() -> Unit)?,
    intents: MessageBodyIntents,
    selectionMode: Boolean,
    onReadReceiptOpen: (() -> Unit)?,
) {
    val quote = message.replyTo
    val conversationId = LocalFlareConversationId.current
    val contentType = flareMessageContentType(message.content).first
    val placement = flareMessageMetaPlacement(surface, contentType)
    val maxWidth = flareBubbleMaxWidth()
    val quoteView: (@Composable () -> Unit)? = quote?.let { q -> { MessageQuote(q, colors, onLocateQuote, onCard = surface == FlareMessageSurface.Card) } }
    val body: @Composable () -> Unit = {
        // The message id keys this body's voice playback in the list; a card carries its quote into its own shell.
        CompositionLocalProvider(
            LocalFlareMessageKey provides message.id,
            LocalFlareMessageSurface provides surface,
            LocalFlareCardQuote provides (if (surface == FlareMessageSurface.Card) quoteView else null),
        ) {
            MessageContentView(
                content = message.content, isSelf = self, senderName = message.senderName, mediaState = mediaState,
                // The core's id: the server's once it has one, else the client id the message was sent with.
                messageId = message.serverId ?: message.id,
                conversationId = conversationId,
                onMediaAction = onMediaAction?.let { cb -> { c -> cb(message, c) } },
                onOpenFile = onOpenFile?.let { cb -> { file -> cb(message, file) } },
                onOpenLink = onOpenLink,
                onVote = intents.vote,
                onTaskToggle = intents.taskToggle,
                onMediaDownload = onMediaDownload?.let { cb -> { c -> cb(message, c) } },
                onMediaReveal = onMediaReveal?.let { cb -> { c -> cb(message, c) } },
                onCardOpen = intents.cardOpen,
                onLocationOpen = intents.locationOpen,
                selectionMode = selectionMode,
                senderId = message.senderId,
            )
        }
    }
    val hasMeta = time.isNotEmpty() || message.edited || message.lifecycle != null || self
    val meta: @Composable (Modifier) -> Unit = { modifier ->
        MessageMetaContent(
            timestamp = time,
            edited = message.edited,
            status = if (self) status else null,
            lifecycle = if (self) message.lifecycle else null,
            ephemeral = message.lifecycle?.ephemeral ?: FlareMessageEphemeralState.None,
            density = FlareMessageMetaDensity.Compact,
            placement = placement,
            outgoing = self,
            readSummary = message.readSummary.takeIf { receipt.summary != null },
            onResend = onResend?.let { cb -> { cb(message) } },
            onReadReceiptOpen = onReadReceiptOpen,
            modifier = modifier,
            inRow = true,
        )
    }

    if (surface != FlareMessageSurface.Bubble) {
        // Bare media and cards: the content is the surface, the meta goes under it at the trailing edge.
        val markShape = RoundedCornerShape(if (surface == FlareMessageSurface.Card) FlareSizes.radiusLg else FlareSizes.radiusCard)
        Column(
            modifier = Modifier.widthIn(max = maxWidth),
            horizontalAlignment = if (self) Alignment.End else Alignment.Start,
        ) {
            Box(Modifier.locateMark(message.id, markShape, colors.primary)) { body() }
            if (hasMeta) meta(Modifier.align(Alignment.End).padding(top = FlareSizes.spacingXs))
        }
        return
    }

    // Flare thread grammar: radius 16 with a 4dp tail on the last of a run; received = a tertiary surface with a
    // restrained lift, no outline; outgoing uses message semantics; a failed outgoing bubble keeps a red edge.
    val chrome = messageSurfaceChrome(surface, tail)
    val shape = RoundedCornerShape(
        topStart = FlareSizes.radiusBubble, topEnd = FlareSizes.radiusBubble,
        bottomStart = if (self || !chrome.tail) FlareSizes.radiusBubble else FlareSizes.radiusBubbleTail,
        bottomEnd = if (!self || !chrome.tail) FlareSizes.radiusBubble else FlareSizes.radiusBubbleTail,
    )
    val failed = self && status == FlareMessageDeliveryStatus.Failed
    val quotedBody: @Composable () -> Unit = {
        if (quoteView == null) body() else QuotedBody(quote = quoteView, body = body, alignEnd = self)
    }
    val inner: @Composable () -> Unit = {
        when {
            !hasMeta -> quotedBody()
            placement == FlareMessageMetaPlacement.Inline -> InlineMetaLayout(body = quotedBody, meta = { meta(Modifier) }, alignEnd = self)
            else -> Column(horizontalAlignment = if (self) Alignment.End else Alignment.Start) {
                quotedBody()
                // The footer: the time and the receipt in their own row at the bubble's bottom trailing corner.
                meta(Modifier.align(Alignment.End).padding(top = 3.dp))
            }
        }
    }
    Box(
        Modifier.widthIn(max = maxWidth)
            .then(Modifier.locateMark(message.id, shape, colors.primary))
            .then(if (!self && chrome.shadow) Modifier.shadow(2.dp, shape, clip = false) else Modifier)
            .clip(shape)
            // Fill only: the incoming surface is a tertiary tone the chat canvas never uses, so the bubble reads as its
            // own surface without a hairline around it.
            .background(if (self) colors.messageOutgoingBackground else colors.messageIncomingBackground)
            .then(if (failed) Modifier.border(1.dp, colors.messageFailedBorder, shape) else Modifier)
            .padding(horizontal = FlareSizes.componentBubblePaddingX, vertical = FlareSizes.componentBubblePaddingY),
    ) { inner() }
}

/**
 * A text bubble's body with its meta after the last line (spec/message-meta-placement-vectors.json `rules.inline`): when
 * the last line leaves room for the meta beside it, the meta sits at the bubble's bottom trailing corner on that line and
 * the bubble widens to hold both; otherwise — a full last line, right-to-left text, or a body that reports no line — it
 * takes its own trailing row under the body (bubbleFooter).
 */
@Composable
private fun InlineMetaLayout(body: @Composable () -> Unit, meta: @Composable () -> Unit, alignEnd: Boolean) {
    val probe = remember { FlareTextLastLineProbe() }
    val gap = FlareSizes.spacingSm
    val footerGap = 3.dp
    CompositionLocalProvider(LocalFlareTextLastLine provides probe) {
        Layout(contents = listOf(body, meta)) { (bodyMeasurables, metaMeasurables), constraints ->
            val loose = constraints.copy(minWidth = 0, minHeight = 0)
            val bodies = bodyMeasurables.map { it.measure(loose) }
            val metas = metaMeasurables.map { it.measure(loose) }
            val bodyWidth = bodies.maxOfOrNull { it.width } ?: 0
            val bodyHeight = bodies.sumOf { it.height }
            val metaWidth = metas.maxOfOrNull { it.width } ?: 0
            val metaHeight = metas.sumOf { it.height }
            val gapPx = gap.roundToPx()
            // Where the last line ends inside the bubble: the text sits at the body's end in an outgoing bubble whose
            // quote is wider than it, at its start otherwise.
            val lineEnd = if (probe.lastLineEnd < 0) -1 else (if (alignEnd) bodyWidth - probe.textWidth else 0) + probe.lastLineEnd
            val beside = lineEnd >= 0 && lineEnd + gapPx + metaWidth <= constraints.maxWidth
            if (beside) {
                val width = maxOf(bodyWidth, lineEnd + gapPx + metaWidth).coerceIn(constraints.minWidth, constraints.maxWidth)
                val height = maxOf(bodyHeight, metaHeight)
                layout(width, height) {
                    var y = 0
                    bodies.forEach { it.placeRelative(0, y); y += it.height }
                    metas.forEach { it.placeRelative(width - it.width, height - metaHeight) }
                }
            } else {
                val width = maxOf(bodyWidth, metaWidth).coerceIn(constraints.minWidth, constraints.maxWidth)
                val spacing = footerGap.roundToPx()
                layout(width, bodyHeight + spacing + metaHeight) {
                    var y = 0
                    bodies.forEach { it.placeRelative(if (alignEnd) width - it.width else 0, y); y += it.height }
                    y += spacing
                    metas.forEach { it.placeRelative(width - it.width, y) }
                }
            }
        }
    }
}

/**
 * The ring a row wears after a jump landed on it (`spec/locate-highlight-vectors.json`), around a bubble, a picture or
 * a card alike. Only the marked row draws it, and the clock is read inside the draw lambda, so a running mark repaints
 * one surface instead of recomposing the rows in the viewport.
 */
@Composable
private fun Modifier.locateMark(messageId: String, shape: Shape, tint: Color): Modifier {
    val host = LocalLocateHighlight.current
    if (host == null || host.messageId != messageId) return this
    return drawBehind {
        val mark = locateHighlight(host.elapsedMs.value, host.reducedMotion)
        if (!mark.marked) return@drawBehind
        val spread = mark.spread.dp.toPx()
        val outline = shape.createOutline(
            Size(size.width + spread * 2, size.height + spread * 2),
            layoutDirection,
            this,
        )
        translate(-spread, -spread) { drawOutline(outline, color = tint, alpha = mark.alpha) }
    }
}

/**
 * The quote above the bubble body. The quote spans at least the body's width (the body keeps
 * its own), measured without intrinsics so every content renderer can sit under a quote.
 */
@Composable
private fun QuotedBody(quote: @Composable () -> Unit, body: @Composable () -> Unit, alignEnd: Boolean) {
    val gap = FlareSizes.spacingSm
    Layout(contents = listOf(quote, body)) { (quoteMeasurables, bodyMeasurables), constraints ->
        val loose = constraints.copy(minWidth = 0, minHeight = 0)
        val bodies = bodyMeasurables.map { it.measure(loose) }
        val bodyWidth = bodies.maxOfOrNull { it.width } ?: 0
        val quotes = quoteMeasurables.map { it.measure(loose.copy(minWidth = bodyWidth)) }
        val width = maxOf(bodyWidth, quotes.maxOfOrNull { it.width } ?: 0)
        val spacing = gap.roundToPx()
        layout(width, quotes.sumOf { it.height } + spacing + bodies.sumOf { it.height }) {
            var y = 0
            quotes.forEach { it.placeRelative(0, y); y += it.height }
            y += spacing
            bodies.forEach { it.placeRelative(if (alignEnd) width - it.width else 0, y); y += it.height }
        }
    }
}

/**
 * The quoted message: a start accent bar in the reply border token on the reply background,
 * the sender (left out when unknown) and a one-line summary. With [onLocate] it is one
 * button named "Quoted {name}: {summary}"; without, the lines are grouped text. [onCard]: inside a card's shell, on
 * the default palette and the full width of the shell.
 */
@Composable
private fun MessageQuote(quote: FlareReplyTarget, colors: FlareColors, onLocate: (() -> Unit)?, onCard: Boolean = false) {
    val label = flareStrings().messageQuoteLabel(quote.senderName, quote.summary)
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    // The 3dp accent rule; radius.xs is the token that carries 3dp.
    val bar = FlareSizes.radiusXs
    Column(
        Modifier
            .then(if (onCard) Modifier.fillMaxWidth() else Modifier)
            .clip(RoundedCornerShape(topEnd = FlareSizes.radiusMd, bottomEnd = FlareSizes.radiusMd))
            .background(colors.messageReplyBackground)
            .drawBehind {
                val width = bar.toPx()
                drawRect(colors.messageReplyBorder, topLeft = Offset(if (rtl) size.width - width else 0f, 0f), size = Size(width, size.height))
            }
            .then(
                if (onLocate != null) Modifier.heightIn(min = FlareSizes.touchTarget)
                    .clickable(role = Role.Button) { onLocate() }
                    .semantics { contentDescription = label }
                else Modifier.semantics(mergeDescendants = true) {},
            )
            .padding(start = bar + FlareSizes.spacingSm, end = FlareSizes.spacingSm, top = FlareSizes.spacingXs, bottom = FlareSizes.spacingXs),
        verticalArrangement = Arrangement.Center,
    ) {
        if (quote.senderName.isNotEmpty()) {
            Text(quote.senderName, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        Text(quote.summary, color = colors.textPrimary, fontSize = FlareSizes.fontSizeSm.value.sp,
            maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

/**
 * 气泡最大宽 = 时间线窗格宽 × 比例，再被 `layout.bubbleMaxWidth` 封顶 —— 四端同一条规则（窄窗格给得更满）。
 * 基准是窗格宽，不是屏宽：双栏布局下时间线只占一栏，按屏宽算气泡会偏宽。
 */
internal fun flareBubbleMaxWidth(pane: Dp): Dp {
    val ratio = if (pane < FlareSizes.navigationRailMinWidth) {
        FlareSizes.componentBubbleMaxWidthRatioCompact
    } else {
        FlareSizes.componentBubbleMaxWidthRatioRegular
    }
    return minOf(pane * ratio, FlareSizes.bubbleMaxWidth)
}

/**
 * The bubble cap of the row being drawn: against the pane a [MessageList] measured ([LocalFlareTimelinePaneWidth]);
 * a bubble outside a list measures its own row.
 */
@Composable
internal fun flareBubbleMaxWidth(): Dp = LocalFlareTimelinePaneWidth.current?.let(::flareBubbleMaxWidth) ?: FlareSizes.bubbleMaxWidth
