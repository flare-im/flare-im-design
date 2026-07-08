import Foundation

/// Neutral, presentational data for one inbox row — the spec's `ConversationRow`
/// data type. The host maps a core conversation-list-view item into this; all
/// product-specific formatting is resolved upstream into `preview`.
public struct ConversationRowData: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let avatarURL: String?
    public let preview: String
    public let timestampLabel: String
    public let unreadCount: Int
    public let pinned: Bool
    public let muted: Bool
    public let mentioned: Bool
    public let draftPreview: String?
    public let presence: FlarePresence?

    public init(
        id: String,
        title: String,
        avatarURL: String? = nil,
        preview: String = "",
        timestampLabel: String = "",
        unreadCount: Int = 0,
        pinned: Bool = false,
        muted: Bool = false,
        mentioned: Bool = false,
        draftPreview: String? = nil,
        presence: FlarePresence? = nil
    ) {
        self.id = id
        self.title = title
        self.avatarURL = avatarURL
        self.preview = preview
        self.timestampLabel = timestampLabel
        self.unreadCount = unreadCount
        self.pinned = pinned
        self.muted = muted
        self.mentioned = mentioned
        self.draftPreview = draftPreview
        self.presence = presence
    }

    public var hasUnread: Bool { unreadCount > 0 }
    public var hasDraft: Bool { !(draftPreview ?? "").isEmpty }
}
