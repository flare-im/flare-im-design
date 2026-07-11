import Foundation

/// Tone for a small inline row tag (group / bot / official / mention markers).
public enum FlareTagTone: Sendable {
    case info
    case warning
    case neutral
}

/// A small inline label rendered next to a conversation title (e.g. "Group",
/// "Bot", "Official", "@"). Product decides the text/tone; the kit renders it.
public struct ConversationRowTag: Identifiable, Sendable {
    public let id: String
    public let text: String
    public let tone: FlareTagTone

    public init(text: String, tone: FlareTagTone = .neutral) {
        self.id = text
        self.text = text
        self.tone = tone
    }
}

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
    /// Inline title tags (group / role / mention). Empty by default.
    public let tags: [ConversationRowTag]

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
        presence: FlarePresence? = nil,
        tags: [ConversationRowTag] = []
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
        self.tags = tags
    }

    public var hasUnread: Bool { unreadCount > 0 }
    public var hasDraft: Bool { !(draftPreview ?? "").isEmpty }
}
