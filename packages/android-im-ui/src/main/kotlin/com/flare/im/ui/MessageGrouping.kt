package com.flare.im.ui

enum class MessageGroupPosition { Single, First, Middle, Last }

enum class MessageAvatarPlacement { Leading, Trailing }

/**
 * How one message row presents its sender (spec/message-grouping-vectors.json `rules.presentation` and `rules.tail`).
 * [tail]: the bubble draws its tail — a bubble surface that ends its run; bare media and cards never do.
 */
data class MessageRowPresentation(
    val showAvatar: Boolean = false,
    val reserveAvatarSpace: Boolean = false,
    val showSenderName: Boolean = false,
    val avatarPlacement: MessageAvatarPlacement = MessageAvatarPlacement.Leading,
    val tail: Boolean = false,
)

/** One message as the grouping rule reads it: who sent it, when, and on which surface it is drawn. */
data class FlareMessageGroupingItem(
    val id: String,
    val senderId: String,
    val atMs: Long,
    val surface: FlareMessageSurface,
)

/** The grouping facts of [message] drawn on [surface] (its derived surface by default, with no host registrations). */
fun FlareMessageData.groupingItem(surface: FlareMessageSurface = flareMessageSurface(this)): FlareMessageGroupingItem =
    FlareMessageGroupingItem(id, senderId, sentAtMs, surface)

/**
 * Two neighbouring messages share a run when both have the same non-empty sender, at most [timeGapMs] apart, neither
 * is a centred notice (system, recall, deletion) and both are cards or neither is: bubbles and bare media mix, a switch
 * between a card and the others ends the run. An undated message (0) joins by sender alone.
 */
fun messagesShareGroup(previous: FlareMessageGroupingItem?, current: FlareMessageGroupingItem?, timeGapMs: Long = 300_000): Boolean {
    if (previous == null || current == null) return false
    if (previous.surface == FlareMessageSurface.Centered || current.surface == FlareMessageSurface.Centered) return false
    if (previous.senderId.isEmpty() || previous.senderId != current.senderId) return false
    if ((previous.surface == FlareMessageSurface.Card) != (current.surface == FlareMessageSurface.Card)) return false
    if (previous.atMs <= 0 || current.atMs <= 0) return true
    return kotlin.math.abs(current.atMs - previous.atMs) <= timeGapMs
}

/** [messagesShareGroup] for message data, each on its derived surface. */
fun messagesShareGroup(previous: FlareMessageData?, current: FlareMessageData?, timeGapMs: Long = 300_000): Boolean =
    messagesShareGroup(previous?.groupingItem(), current?.groupingItem(), timeGapMs)

/** Where [index] sits in its run: single, first, middle or last. A centred row is always single. */
@JvmName("messageGroupPositionOfItems")
fun messageGroupPosition(items: List<FlareMessageGroupingItem>, index: Int, timeGapMs: Long = 300_000): MessageGroupPosition {
    val current = items[index]
    if (current.surface == FlareMessageSurface.Centered) return MessageGroupPosition.Single
    val joinsPrevious = messagesShareGroup(items.getOrNull(index - 1), current, timeGapMs)
    val joinsNext = messagesShareGroup(current, items.getOrNull(index + 1), timeGapMs)
    return when {
        !joinsPrevious && !joinsNext -> MessageGroupPosition.Single
        !joinsPrevious -> MessageGroupPosition.First
        !joinsNext -> MessageGroupPosition.Last
        else -> MessageGroupPosition.Middle
    }
}

/** [messageGroupPosition] for message data, each on its derived surface. */
fun messageGroupPosition(messages: List<FlareMessageData>, index: Int, timeGapMs: Long = 300_000): MessageGroupPosition =
    messageGroupPosition(messages.map { it.groupingItem() }, index, timeGapMs)

/**
 * The row presentation of a message at [position] (spec/message-grouping-vectors.json `rules.presentation`): the edge
 * of a run (single or first) carries the avatar and, in groups, the incoming sender's name; incoming rows keep the
 * avatar gutter when incoming avatars show, own rows only when the viewer's avatar shows; single chats keep the peer's
 * avatar. A centred row has no avatar, name, gutter or tail; only a bubble ending its run has a tail.
 */
fun messageRowPresentation(
    senderId: String,
    surface: FlareMessageSurface,
    position: MessageGroupPosition,
    currentUserId: String,
    groupConversation: Boolean,
    showIncomingAvatar: Boolean = true,
    showSelfAvatar: Boolean = false,
    showGroupSenderName: Boolean = true,
): MessageRowPresentation {
    if (surface == FlareMessageSurface.Centered) return MessageRowPresentation()
    val self = senderId == currentUserId
    val edge = position == MessageGroupPosition.Single || position == MessageGroupPosition.First
    val ending = position == MessageGroupPosition.Single || position == MessageGroupPosition.Last
    return MessageRowPresentation(
        showAvatar = (if (self) showSelfAvatar else showIncomingAvatar) && edge,
        reserveAvatarSpace = if (self) showSelfAvatar else showIncomingAvatar,
        showSenderName = !self && groupConversation && showGroupSenderName && edge,
        avatarPlacement = if (self) MessageAvatarPlacement.Trailing else MessageAvatarPlacement.Leading,
        tail = surface == FlareMessageSurface.Bubble && ending,
    )
}

/** [messageRowPresentation] of [message] on [surface] (its derived surface by default). */
fun messageRowPresentation(
    message: FlareMessageData,
    position: MessageGroupPosition,
    currentUserId: String,
    groupConversation: Boolean,
    showIncomingAvatar: Boolean = true,
    showSelfAvatar: Boolean = false,
    showGroupSenderName: Boolean = true,
    surface: FlareMessageSurface = flareMessageSurface(message),
): MessageRowPresentation = messageRowPresentation(
    message.senderId, surface, position, currentUserId, groupConversation, showIncomingAvatar, showSelfAvatar, showGroupSenderName,
)
