import Foundation

/// A mention entity as the core sends it on text content (`content.mentions`, or
/// `content.text.mentions`): flare-proto `Mention`. `start` and `length` count Unicode code points
/// (scalars) of the text, not UTF-16 units or characters.
public struct FlareMentionEntity: Equatable, Sendable {
    /// flare-proto `MentionType.USER`: one member.
    public static let typeUser = 1
    /// flare-proto `MentionType.ALL`: everyone in the conversation.
    public static let typeAll = 2
    /// flare-proto `MentionType.ROLE`: a role.
    public static let typeRole = 3
    /// flare-proto `MentionType.MULTI`: several members (`userIds`).
    public static let typeMulti = 4

    public let type: Int
    public let userId: String
    public let userIds: [String]
    public let roleId: String
    public let start: Int
    public let length: Int

    public init(type: Int, userId: String = "", userIds: [String] = [], roleId: String = "",
                start: Int, length: Int) {
        self.type = type; self.userId = userId; self.userIds = userIds; self.roleId = roleId
        self.start = start; self.length = length
    }
}

/// A mention inside a text body, as UTF-16 offsets into the text: the index units of `NSString` and
/// `NSRange`, and the same numbers the Vue, Flutter and Compose kits use for the same message.
public struct FlareTextMentionSpan: Equatable, Sendable {
    public let start: Int
    public let length: Int
    /// The mention names the current user.
    public let mentionsSelf: Bool
    /// The mention is @all.
    public let mentionsAll: Bool

    public init(start: Int, length: Int, mentionsSelf: Bool = false, mentionsAll: Bool = false) {
        self.start = start; self.length = length
        self.mentionsSelf = mentionsSelf; self.mentionsAll = mentionsAll
    }

    /// A mention of the reader or of everyone, which an incoming bubble sets on the selected ground.
    public var highlighted: Bool { mentionsSelf || mentionsAll }

    /// The spans a text body draws for the core's `mentions` in `text`, in text order.
    ///
    /// An entity is kept only when it lands on an "@" token: `start` ≥ 0, `length` ≥ 2, the range
    /// inside the text's code points, and its first code point "@". Code-point offsets become UTF-16
    /// offsets through `unicodeScalars`, so an emoji before a mention (a surrogate pair, or several
    /// scalars in one character) moves the span by its UTF-16 width. A span overlapping the one kept
    /// before it is dropped. `mentionsSelf` is set when `currentUserId` is the entity's `userId` or
    /// one of its `userIds`; `mentionsAll` when the entity is `typeAll`.
    public static func spans(from mentions: [FlareMentionEntity], in text: String,
                             currentUserId: String) -> [FlareTextMentionSpan] {
        guard !mentions.isEmpty, !text.isEmpty else { return [] }
        let scalars = text.unicodeScalars
        let count = scalars.count
        var found: [(order: Int, span: FlareTextMentionSpan)] = []
        for (order, mention) in mentions.enumerated() {
            guard mention.start >= 0, mention.length >= 2, mention.start < count,
                  mention.length <= count - mention.start else { continue }
            let from = scalars.index(scalars.startIndex, offsetBy: mention.start)
            guard scalars[from] == "@" else { continue }
            let to = scalars.index(from, offsetBy: mention.length)
            let utf16Start = from.utf16Offset(in: text)
            let ids = [mention.userId] + mention.userIds
            found.append((order, FlareTextMentionSpan(
                start: utf16Start,
                length: to.utf16Offset(in: text) - utf16Start,
                mentionsSelf: !currentUserId.isEmpty && ids.contains(currentUserId),
                mentionsAll: mention.type == FlareMentionEntity.typeAll)))
        }
        // Text order; entities at the same start keep the core's order, so the first one wins.
        found.sort { $0.span.start != $1.span.start ? $0.span.start < $1.span.start : $0.order < $1.order }
        var kept: [FlareTextMentionSpan] = []
        for (_, span) in found where kept.last.map({ span.start >= $0.start + $0.length }) ?? true {
            kept.append(span)
        }
        return kept
    }
}
