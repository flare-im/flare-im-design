import Foundation

/// What a conversation is, in one vocabulary for every kit (FR-056): `channel` and `system` join the
/// three that were always here, so a header never needs words of its own.
/// Spec union `'single' | 'group' | 'channel' | 'ai' | 'system'`.
public enum FlareConversationKind: String, CaseIterable, Sendable {
    case single, group, channel, ai, system
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

/// Who a moment is for (FR-100). The kit only ever sees the names; a host maps its own numbers once
/// (`spec/moments-privacy.json` records what the reference apps mapped from).
public enum FlareMomentVisibility: String, CaseIterable, Sendable {
    case friends, `public`, `private`
}

/// On top of the visibility: nobody is singled out, only these people, or everyone but these.
public enum FlareMomentAudienceMode: String, CaseIterable, Sendable {
    case everyone, include, exclude
}

/// How far back a stranger sees someone's moments.
public enum FlareMomentHistoryRange: String, CaseIterable, Sendable {
    case all, threeDays, oneMonth, sixMonths
}

/// A private moment has no audience list: nobody sees it, so adding or excluding people changes nothing.
public func flareMomentAudienceApplies(_ visibility: FlareMomentVisibility) -> Bool {
    visibility != .private
}

/// A host action the kit cannot know about (report, share a profile, an admin tool), shown in the
/// detail surfaces beside the ones the kit owns (FR-046). The kit reports the id back and nothing else.
public struct FlareDetailExtraAction: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let danger: Bool
    public init(id: String, label: String, danger: Bool = false) {
        self.id = id; self.label = label; self.danger = danger
    }
}
