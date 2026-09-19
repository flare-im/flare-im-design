package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.RadioButtonUnchecked
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
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

/**
 * One message in a thread — content, sender, grouping, delivery status. Spec:
 * Message/MessageBubble (`MessageBubble`). Status comes from host lifecycle state
 * (optimistic), never a network wait.
 *
 * Multi-select (names shared with Flutter/iOS): [multiSelectMode] shows a leading
 * check control and makes the whole row tap-to-toggle via [onToggleSelect]
 * (receives the message id); [selected] tints the row. Default appearance is
 * unchanged when [multiSelectMode] is false.
 *
 * A message with [FlareMessageData.replyTo] shows the quoted message at the top of its
 * bubble (never chromeless). Tapping the quote calls [onLocateMessage] with the quoted
 * message's core id when that id is known and multi-select is off; otherwise the quote is text.
 *
 * Media taps follow [MessageContentView]: [onMediaAction] takes them all; without it the kit
 * previews images, plays videos and voice, and a file tap goes to [onOpenFile]. [onMediaDownload] is the download key
 * of the image preview (the message, and the picture on screen); without it the preview has none. Links in the text and
 * link cards go to [onOpenLink]; without it the kit opens only safe web addresses with the platform opener.
 */
@Composable
fun MessageBubble(
    message: FlareMessageData,
    currentUserId: String,
    conversationKind: FlareConversationKind = FlareConversationKind.Single,
    groupPosition: MessageGroupPosition = MessageGroupPosition.Single,
    rowPresentation: MessageRowPresentation = MessageRowPresentation(),
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
    /** The image preview's download key (message, the picture on screen); without it the preview has none. */
    onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
) {
    val colors = flareColors()
    val self = message.senderId == currentUserId

    if (message.isSystem) {
        NoticeLine((message.content as FlareNotificationContent).text, colors)
        return
    }
    if (message.isRecalled) {
        val strings = flareStrings()
        NoticeLine(
            when {
                self -> strings.messageRecalledSelf
                conversationKind == FlareConversationKind.Group -> strings.messageRecalledGroupOther(message.senderName)
                else -> strings.messageRecalledPeer
            },
            colors,
        )
        return
    }

    val showAvatar = rowPresentation.showAvatar
    val groupStart = groupPosition == MessageGroupPosition.Single || groupPosition == MessageGroupPosition.First
    val groupEnd = groupPosition == MessageGroupPosition.Single || groupPosition == MessageGroupPosition.Last
    val selection = messageSelectionUi(multiSelectMode, selected, onToggleSelect != null)
    val selectLabel = flareStrings().select
    val onLocateQuote = messageQuoteLocateId(message.replyTo, onLocateMessage != null, multiSelectMode)
        ?.let { id -> { onLocateMessage?.invoke(id); Unit } }
    Row(
        // Group-aware rhythm (matches Flutter/iOS/web): a clear breath before a
        // new sender's run, tight within a run.
        Modifier.fillMaxWidth()
            .then(if (selection.highlighted) Modifier.background(colors.messageSelectedBackground) else Modifier)
            .then(
                if (selection.toggles) Modifier.selectable(selected = selected, onClick = { onToggleSelect?.invoke(message.id) })
                else Modifier,
            )
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
                contentDescription = selectLabel,
                tint = if (selected) colors.primaryText else colors.textTertiary,
                modifier = Modifier.size(22.dp).align(Alignment.CenterVertically),
            )
            Spacer(Modifier.width(FlareSizes.spacingSm))
            if (self) Spacer(Modifier.weight(1f))
        }
        if (!self && rowPresentation.reserveAvatarSpace) {
            if (showAvatar) Avatar(userId = message.senderId, displayName = message.senderName, size = 34.dp)
            else Spacer(Modifier.width(34.dp))
            Spacer(Modifier.width(FlareSizes.spacingSm))
        }
        Column(horizontalAlignment = if (self) Alignment.End else Alignment.Start) {
            if (rowPresentation.showSenderName) Text(message.senderName, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            // Multi-select taps select the row: a poll or a task is not a control then.
            val intents = MessageBodyIntents(
                vote = onVote?.takeIf { !multiSelectMode }?.let { cb -> { index -> cb(message, index) } },
                taskToggle = onTaskToggle?.takeIf { !multiSelectMode }?.let { cb -> { done -> cb(message, done) } },
            )
            bubble(message, self, groupEnd, colors, mediaState, onResend, onMediaAction, onMediaDownload, onOpenFile, onOpenLink, onLocateQuote, intents)
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
            if (showAvatar) Avatar(userId = message.senderId, displayName = message.senderName, size = 34.dp)
            else Spacer(Modifier.width(34.dp))
        }
    }
}

/** A poll's and a task's intents for one bubble's body; null where the body is read-only. */
private class MessageBodyIntents(val vote: ((Int) -> Unit)?, val taskToggle: ((Boolean) -> Unit)?)

/** Centred notice pill for system lines and recalled messages. */
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
private fun bubble(
    message: FlareMessageData,
    self: Boolean,
    groupEnd: Boolean,
    colors: FlareColors,
    mediaState: FlareMediaDownloadState?,
    onResend: ((FlareMessageData) -> Unit)?,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)?,
    onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Unit)?,
    onOpenFile: ((FlareMessageData, FlareFileContent) -> Unit)?,
    onOpenLink: ((String) -> Unit)?,
    onLocateQuote: (() -> Unit)?,
    intents: MessageBodyIntents,
) {
    val quote = message.replyTo
    val bare = messageBubbleChromeless(message)
    val body: @Composable () -> Unit = {
        // The message id keys this body's voice playback in the list.
        CompositionLocalProvider(LocalFlareMessageKey provides message.id) {
            MessageContentView(
                content = message.content, isSelf = self, senderName = message.senderName, mediaState = mediaState,
                onMediaAction = onMediaAction?.let { cb -> { c -> cb(message, c) } },
                onOpenFile = onOpenFile?.let { cb -> { file -> cb(message, file) } },
                onOpenLink = onOpenLink,
                onVote = intents.vote,
                onTaskToggle = intents.taskToggle,
                onMediaDownload = onMediaDownload?.let { cb -> { c -> cb(message, c) } },
            )
        }
    }
    if (bare) {
        Column(
            modifier = Modifier.widthIn(max = 320.dp),
            horizontalAlignment = if (self) Alignment.End else Alignment.Start,
        ) {
            body()
            if (message.timeLabel.isNotEmpty() || message.edited || message.lifecycle != null || self) {
                MessageMeta(
                    timestamp = message.timeLabel,
                    edited = message.edited,
                    status = if (self) message.status else null,
                    lifecycle = if (self) message.lifecycle else null,
                    ephemeral = message.lifecycle?.ephemeral ?: FlareMessageEphemeralState.None,
                    tint = null,
                    onResend = onResend?.let { cb -> { cb(message) } },
                    modifier = Modifier.padding(top = FlareSizes.spacingXs),
                )
            }
        }
        return
    }

    // Flare thread grammar: radius 16 with a 4dp tail; received = white card +
    // Hairline border plus a restrained lift; outgoing uses message semantics.
    val shape = RoundedCornerShape(
        topStart = 16.dp, topEnd = 16.dp,
        bottomStart = if (self || !groupEnd) 16.dp else 4.dp,
        bottomEnd = if (!self || !groupEnd) 16.dp else 4.dp,
    )
    val inner: @Composable () -> Unit = {
        val content: @Composable () -> Unit = {
            Column(horizontalAlignment = if (self) Alignment.End else Alignment.Start) {
                body()
                // Inline meta: time + (self) delivery status, kept inside the bubble.
                if (message.timeLabel.isNotEmpty() || message.edited || message.lifecycle != null || self) {
                    MessageMeta(
                        timestamp = message.timeLabel,
                        edited = message.edited,
                        status = if (self) message.status else null,
                        lifecycle = if (self) message.lifecycle else null,
                        ephemeral = message.lifecycle?.ephemeral ?: FlareMessageEphemeralState.None,
                        tint = if (self) {
                            if (message.status == FlareMessageDeliveryStatus.Read) colors.messageStatusReadOnOutgoing
                            else colors.messageStatusOnOutgoing
                        } else null,
                        onResend = onResend?.let { cb -> { cb(message) } },
                        modifier = Modifier.padding(top = 3.dp),
                    )
                }
            }
        }
        if (quote == null) content()
        else QuotedBody(quote = { MessageQuote(quote, colors, onLocateQuote) }, body = content, alignEnd = self)
    }
    val locateMark = Modifier.locateMark(message.id, shape, colors.primary)
    if (self) {
        Box(
            Modifier.widthIn(max = 320.dp)
                .then(locateMark)
                .clip(shape).background(colors.messageOutgoingBackground)
                .padding(horizontal = 14.dp, vertical = 9.dp),
        ) { inner() }
    } else {
        Box(
            Modifier.widthIn(max = 320.dp)
                .then(locateMark)
                .shadow(2.dp, shape, clip = false)
                .clip(shape)
                .background(colors.messageIncomingBackground)
                .border(1.dp, colors.messageIncomingBorder, shape)
                .padding(horizontal = 14.dp, vertical = 9.dp),
        ) { inner() }
    }
}

/**
 * The ring a row wears after a jump landed on it (`spec/locate-highlight-vectors.json`). Only the marked
 * row draws it, and the clock is read inside the draw lambda, so a running mark repaints one bubble
 * instead of recomposing the rows in the viewport.
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
 * button named "Quoted {name}: {summary}"; without, the lines are grouped text.
 */
@Composable
private fun MessageQuote(quote: FlareReplyTarget, colors: FlareColors, onLocate: (() -> Unit)?) {
    val label = flareStrings().messageQuoteLabel(quote.senderName, quote.summary)
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    // The 3dp accent rule; radius.xs is the token that carries 3dp.
    val bar = FlareSizes.radiusXs
    Column(
        Modifier
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

/** Media draws without a bubble — except when it quotes a message: the quote needs the bubble around it. */
internal fun messageBubbleChromeless(message: FlareMessageData): Boolean =
    message.replyTo == null && isBareMedia(message.content)

internal fun isBareMedia(content: FlareMessageContent): Boolean =
    content is FlareImageContent || content is FlareVideoContent ||
        content is FlareStickerContent || content is FlareEmojiContent
