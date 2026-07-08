import Foundation

/// Neutral, presentational data for one message in a thread — the spec's
/// `Message` type consumed by ``MessageBubbleView`` / ``MessageListView``.
public struct FlareMessageData: Identifiable {
    public let id: String
    public let senderId: String
    public let senderName: String
    public let senderAvatarURL: String?
    public let content: FlareMessageContent
    public let timeLabel: String
    public let status: FlareMessageDeliveryStatus

    public init(
        id: String,
        senderId: String,
        senderName: String,
        content: FlareMessageContent,
        senderAvatarURL: String? = nil,
        timeLabel: String = "",
        status: FlareMessageDeliveryStatus = .sent
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.senderAvatarURL = senderAvatarURL
        self.timeLabel = timeLabel
        self.status = status
    }

    /// System/notification lines render centred, without a bubble.
    public var isSystem: Bool { content is FlareNotificationContent }
}

/// One pinned message shown in ``PinnedMessageBarView``.
public struct FlarePinnedMessage: Identifiable {
    public let id: String
    public let summary: String
    public let senderName: String?
    public init(id: String, summary: String, senderName: String? = nil) {
        self.id = id; self.summary = summary; self.senderName = senderName
    }
}
