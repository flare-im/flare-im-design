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
/// data type. The host maps authoritative conversation data into this; all
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
    public let typing: Bool
    public let failed: Bool
    public let draftPreview: String?
    public let presence: FlarePresence?
    /// Inline title tags (group / role / mention). Empty by default.
    public let tags: [ConversationRowTag]
    /// Member count for group conversations (Feishu-style "N 人" header subtitle).
    /// `nil` when unknown or not a group.
    public let memberCount: Int?

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
        tags: [ConversationRowTag] = [],
        memberCount: Int? = nil,
        typing: Bool = false,
        failed: Bool = false
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
        self.typing = typing
        self.failed = failed
        self.draftPreview = draftPreview
        self.presence = presence
        self.tags = tags
        self.memberCount = memberCount
    }


    /// The facts a host feeds a row after the core built it: the draft this device is holding for the
    /// conversation, whether anyone is typing in it, and the peer's presence. Everything else on a row comes
    /// from the core's own summary and is not the host's to rewrite. Kotlin gets this from `data class`;
    /// Dart and Swift need it written, and without it an app cannot feed `typing` at all — which is why the
    /// `typing` branch of `previewKind` sat on four kits for rounds with nothing ever setting it.
    ///
    /// Each argument left out keeps what the row had. Presence in particular is only ever *set* here: a
    /// presence nobody could look up stays nil, and a nil presence draws no dot — unknown is not offline.
    public func hostFacts(draftPreview: String? = nil, typing: Bool? = nil, presence: FlarePresence? = nil) -> ConversationRowData {
        ConversationRowData(
            id: id, title: title, avatarURL: avatarURL, preview: preview, timestampLabel: timestampLabel,
            unreadCount: unreadCount, pinned: pinned, muted: muted, mentioned: mentioned,
            draftPreview: draftPreview ?? self.draftPreview, presence: presence ?? self.presence, tags: tags,
            memberCount: memberCount, typing: typing ?? self.typing, failed: failed)
    }

    public var hasUnread: Bool { unreadCount > 0 }
    public var hasDraft: Bool { !(draftPreview ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var previewKind: String {
        if failed { return "failed" }
        if hasDraft { return "draft" }
        if typing { return "typing" }
        return mentioned ? "mention" : "normal"
    }
    /// Title weight tier: strong only when unread and not quiet (muted without a mention).
    public var titleEmphasis: String { hasUnread && !(muted && !mentioned) ? "strong" : "quiet" }
    public var unreadLabel: String { unreadCount > 999 ? "999+" : String(max(0, unreadCount)) }
}
