package com.flare.im.ui

enum class MessageGroupPosition { Single, First, Middle, Last }

enum class MessageAvatarPlacement { Leading, Trailing }

data class MessageRowPresentation(
    val showAvatar: Boolean = false,
    val reserveAvatarSpace: Boolean = false,
    val showSenderName: Boolean = false,
    val avatarPlacement: MessageAvatarPlacement = MessageAvatarPlacement.Leading,
)

fun messagesShareGroup(previous: FlareMessageData?, current: FlareMessageData?, timeGapMs: Long = 300_000): Boolean {
    // Notices (system lines, recalled messages) stand alone and end a sender's run.
    if (previous == null || current == null || previous.isSystem || current.isSystem || previous.isRecalled || current.isRecalled) return false
    if (previous.senderId != current.senderId) return false
    if (previous.sentAtMs <= 0 || current.sentAtMs <= 0) return true
    return kotlin.math.abs(current.sentAtMs - previous.sentAtMs) <= timeGapMs
}

fun messageGroupPosition(messages: List<FlareMessageData>, index: Int, timeGapMs: Long = 300_000): MessageGroupPosition {
    val current = messages[index]
    if (current.isSystem || current.isRecalled) return MessageGroupPosition.Single
    val joinsPrevious = messagesShareGroup(messages.getOrNull(index - 1), current, timeGapMs)
    val joinsNext = messagesShareGroup(current, messages.getOrNull(index + 1), timeGapMs)
    return when {
        !joinsPrevious && !joinsNext -> MessageGroupPosition.Single
        !joinsPrevious -> MessageGroupPosition.First
        !joinsNext -> MessageGroupPosition.Last
        else -> MessageGroupPosition.Middle
    }
}

fun messageRowPresentation(
    message: FlareMessageData,
    position: MessageGroupPosition,
    currentUserId: String,
    groupConversation: Boolean,
    showIncomingAvatar: Boolean = true,
    showSelfAvatar: Boolean = false,
    showGroupSenderName: Boolean = true,
): MessageRowPresentation {
    val self = message.senderId == currentUserId
    val edge = position == MessageGroupPosition.Single || position == MessageGroupPosition.First
    return MessageRowPresentation(
        showAvatar = (if (self) showSelfAvatar else showIncomingAvatar) && edge,
        reserveAvatarSpace = if (self) showSelfAvatar else showIncomingAvatar,
        showSenderName = !self && groupConversation && showGroupSenderName && edge,
        avatarPlacement = if (self) MessageAvatarPlacement.Trailing else MessageAvatarPlacement.Leading,
    )
}
