import Foundation

/// The message a reply quotes: the composer's reply strip while writing, and the quote at the
/// top of the reply's bubble once sent. `messageId` is the quoted message's **core id** — the id the
/// core names that message by, one meaning whether or not the thread has it loaded (nil when the
/// original is unknown). The bubble's quote locates it only when it is set, and the list recognises
/// the row it points at by either of the row's two ids (``FlareMessageData/serverId``), so a host
/// never translates an id before asking ``FlareMessageListController/scrollToMessage(_:)``.
public struct FlareReplyTarget: Equatable, Sendable {
    public let senderName: String
    public let summary: String
    public let messageId: String?
    public init(senderName: String, summary: String, messageId: String? = nil) {
        self.senderName = senderName; self.summary = summary; self.messageId = messageId
    }
}

/// Neutral, presentational data for one message in a thread — the spec's
/// `Message` type consumed by ``MessageBubbleView`` / ``MessageListView``.
public struct FlareMessageData: Identifiable {
    /// The id the list draws this row under, and the id a scroll goes to.
    public let id: String
    /// This row's id in the core, when that is a different string from ``id`` — a message this device
    /// sent keeps its client id as the row id after the server names it. A quote points at its
    /// original by the core's id, so the list recognises a row by this as well as by ``id``. Nil when
    /// the row id is already the core's id (same name as Vue's `MessageLike.serverId`).
    public let serverId: String?
    public let senderId: String
    public let senderName: String
    public let senderAvatarURL: String?
    public let content: FlareMessageContent
    public let timeLabel: String
    public let sentAtMs: Int64
    public let status: FlareMessageDeliveryStatus
    public let lifecycle: FlareMessageLifecycle?
    public let edited: Bool
    /// Aggregated reactions shown under the bubble; empty shows none.
    public let reactions: [ReactionGroup]
    /// The message this one replies to, quoted at the top of the bubble; nil shows no quote.
    public let replyTo: FlareReplyTarget?

    public init(
        id: String,
        senderId: String,
        senderName: String,
        content: FlareMessageContent,
        serverId: String? = nil,
        senderAvatarURL: String? = nil,
        timeLabel: String = "",
        sentAtMs: Int64 = 0,
        status: FlareMessageDeliveryStatus = .sent,
        lifecycle: FlareMessageLifecycle? = nil,
        edited: Bool = false,
        reactions: [ReactionGroup] = [],
        replyTo: FlareReplyTarget? = nil
    ) {
        self.id = id
        self.serverId = serverId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.senderAvatarURL = senderAvatarURL
        self.timeLabel = timeLabel
        self.sentAtMs = sentAtMs
        self.status = status
        self.lifecycle = lifecycle
        self.edited = edited
        self.reactions = reactions
        self.replyTo = replyTo
    }

    /// System/notification lines render centred, without a bubble.
    public var isSystem: Bool { content is FlareNotificationContent }

    /// A recalled message renders as a notice in place of its content (lifecycle mutation outranks everything).
    public var isRecalled: Bool { lifecycle?.mutation == .recalled }
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
