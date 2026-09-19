import Foundation

public enum MessageGroupPosition: String, Sendable { case single, first, middle, last }
public enum MessageAvatarPlacement: String, Sendable { case leading, trailing }

public struct MessageRowPresentation: Sendable {
    public let showAvatar: Bool
    public let reserveAvatarSpace: Bool
    public let showSenderName: Bool
    public let avatarPlacement: MessageAvatarPlacement

    public init(
        showAvatar: Bool = false,
        reserveAvatarSpace: Bool = false,
        showSenderName: Bool = false,
        avatarPlacement: MessageAvatarPlacement = .leading
    ) {
        self.showAvatar = showAvatar; self.reserveAvatarSpace = reserveAvatarSpace
        self.showSenderName = showSenderName; self.avatarPlacement = avatarPlacement
    }
}

public func messagesShareGroup(
    _ previous: FlareMessageData?,
    _ current: FlareMessageData?,
    timeGapMs: Int64 = 300_000
) -> Bool {
    // Notices (system lines, recalled messages) stand alone and end a sender's run.
    guard let previous, let current, !previous.isSystem, !current.isSystem, !previous.isRecalled, !current.isRecalled else { return false }
    guard previous.senderId == current.senderId else { return false }
    guard previous.sentAtMs > 0, current.sentAtMs > 0 else { return true }
    return abs(current.sentAtMs - previous.sentAtMs) <= timeGapMs
}

public func messageGroupPosition(
    _ messages: [FlareMessageData],
    index: Int,
    timeGapMs: Int64 = 300_000
) -> MessageGroupPosition {
    let current = messages[index]
    if current.isSystem || current.isRecalled { return .single }
    let previous = index > 0 ? messages[index - 1] : nil
    let next = index + 1 < messages.count ? messages[index + 1] : nil
    let joinsPrevious = messagesShareGroup(previous, current, timeGapMs: timeGapMs)
    let joinsNext = messagesShareGroup(current, next, timeGapMs: timeGapMs)
    if !joinsPrevious && !joinsNext { return .single }
    if !joinsPrevious { return .first }
    if !joinsNext { return .last }
    return .middle
}

public func messageRowPresentation(
    message: FlareMessageData,
    position: MessageGroupPosition,
    currentUserId: String,
    groupConversation: Bool,
    showIncomingAvatar: Bool = true,
    showSelfAvatar: Bool = false,
    showGroupSenderName: Bool = true
) -> MessageRowPresentation {
    let own = message.senderId == currentUserId
    let edge = position == .single || position == .first
    return MessageRowPresentation(
        showAvatar: (own ? showSelfAvatar : showIncomingAvatar) && edge,
        reserveAvatarSpace: own ? showSelfAvatar : showIncomingAvatar,
        showSenderName: !own && groupConversation && showGroupSenderName && edge,
        avatarPlacement: own ? .trailing : .leading
    )
}
