import Foundation

/// Conversation kind — spec union `'single' | 'group' | 'ai'`.
public enum FlareConversationKind: Sendable {
    case single, group, ai
}

/// Neutral summary of a conversation for the details/settings panel — the
/// spec's `Conversation` type as consumed by ``ConversationDetailsView``.
public struct FlareConversationSummary: Sendable {
    public let id: String
    public let title: String
    public let avatarURL: String?
    public let kind: FlareConversationKind
    public let memberCount: Int?
    public let muted: Bool
    public let pinned: Bool
    public let archived: Bool

    public init(
        id: String,
        title: String,
        avatarURL: String? = nil,
        kind: FlareConversationKind = .single,
        memberCount: Int? = nil,
        muted: Bool = false,
        pinned: Bool = false,
        archived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.avatarURL = avatarURL
        self.kind = kind
        self.memberCount = memberCount
        self.muted = muted
        self.pinned = pinned
        self.archived = archived
    }
}

/// A selectable contact/directory entry for ``StartConversationView``.
public struct FlareContactOption: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let subtitle: String?

    public init(id: String, name: String, avatarURL: String? = nil, subtitle: String? = nil) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
        self.subtitle = subtitle
    }
}
