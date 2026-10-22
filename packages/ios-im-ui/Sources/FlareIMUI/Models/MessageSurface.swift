import Foundation

// Which surface a timeline row draws its content on, and where its time and receipt sit
// (docs/design/message-surface-and-meta.md C1 / C2). Pure rules, run against
// spec/message-surface-vectors.json and spec/message-meta-placement-vectors.json by all four kits.

/// The surface a message row draws its content on (`spec/message-surface-vectors.json`).
///
/// - `bubble`: the coloured bubble (incoming / outgoing fill, tail on the last of a run).
/// - `bareMedia`: no bubble; the picture, sticker or emoji is the surface.
/// - `card`: no bubble; the content's own shell is the surface (plugin cards, red packets, locations, contact
///   cards, link cards, ...). Outgoing and incoming cards differ by alignment only.
/// - `centered`: one centred notice line (system lines, recalls, deletions).
public enum FlareMessageSurface: String, Sendable, CaseIterable {
    case bubble, bareMedia, card, centered
}

/// A surface a host registers for a content key the kit does not know (``flareContentRenderers(_:surfaces:)``).
public enum FlareMessageRegisteredSurface: String, Sendable, CaseIterable {
    case card, bareMedia

    public var surface: FlareMessageSurface { self == .card ? .card : .bareMedia }
}

/// Where a message's time, edited / ephemeral labels and receipt sit (`spec/message-meta-placement-vectors.json`).
///
/// - `inline`: inside a text bubble at the end of its last line; it drops to its own trailing row when the line
///   has no room for it.
/// - `bubbleFooter`: inside the bubble, its own row at the trailing edge.
/// - `below`: under a bare picture or a card, `spacing.xs` away, at the trailing edge, in the default palette.
/// - `none`: centred notices carry no meta.
public enum FlareMessageMetaPlacement: String, Sendable, CaseIterable {
    case inline, bubbleFooter, below, none
}

/// The meta's palette: `onOutgoing` only inside an outgoing bubble that has not failed.
public enum FlareMessageMetaTone: String, Sendable { case `default`, onOutgoing }

/// How a failed outgoing message offers its retry: the failed glyph inside a bubble, a text key below a surface.
public enum FlareMessageRetryForm: String, Sendable { case glyph, text }

/// The facts the surface rule reads (`spec/message-surface-vectors.json` inputs).
public struct FlareMessageSurfaceInput: Equatable, Sendable {
    /// Spec content type (`richText`, `linkCard`, ...); wire spellings (`rich_text`, ...) are accepted too.
    public var contentType: String
    public var subtype: String?
    /// The message replies to another one.
    public var hasQuote: Bool
    /// A video with a non-blank description or caption.
    public var hasCaption: Bool
    /// A text that is a single emoji (pack token or emoji), without mentions or markdown.
    public var loneEmoji: Bool
    public var recalled: Bool
    public var deleted: Bool
    /// The surface the host registered for this content's key.
    public var registered: FlareMessageRegisteredSurface?

    public init(contentType: String, subtype: String? = nil, hasQuote: Bool = false, hasCaption: Bool = false,
                loneEmoji: Bool = false, recalled: Bool = false, deleted: Bool = false,
                registered: FlareMessageRegisteredSurface? = nil) {
        self.contentType = contentType; self.subtype = subtype; self.hasQuote = hasQuote
        self.hasCaption = hasCaption; self.loneEmoji = loneEmoji; self.recalled = recalled
        self.deleted = deleted; self.registered = registered
    }
}

/// The spec name of a content type: the wire spellings the kit also meets (`rich_text`, `link_card`, ...) folded
/// onto the camelCase vocabulary of `spec/components.json`.
public func flareSpecContentType(_ contentType: String) -> String {
    switch contentType {
    case "rich_text": return "richText"
    case "image_group": return "imageGroup"
    case "link_card": return "linkCard"
    case "mini_program": return "miniProgram"
    case "merged_forward", "mergedForward": return "forward"
    case "voice": return "audio"
    default: return contentType
    }
}

private let bubbleTypes: Set<String> = ["text", "richText", "audio", "file", "imageGroup", "quote", "placeholder"]
private let bareMediaTypes: Set<String> = ["image", "sticker", "emoji"]
private let cardTypes: Set<String> = [
    "location", "card", "linkCard", "vote", "task", "schedule", "announcement", "miniProgram", "forward", "thread", "custom",
]
private let centeredTypes: Set<String> = ["system", "notification"]

/// The surface for a content (spec rules.order): recall / delete and notices are centred; a host registration
/// wins next (a quoted bare media is still a bubble); a quote keeps a card a card and makes anything else a
/// bubble; a video is bare without a caption; a lone emoji text is bare; then the defaults table. A type the kit
/// does not know draws its unknown-message body in a bubble.
public func flareMessageSurface(_ input: FlareMessageSurfaceInput) -> FlareMessageSurface {
    let type = flareSpecContentType(input.contentType)
    if input.recalled || input.deleted { return .centered }
    if centeredTypes.contains(type) { return .centered }
    if let registered = input.registered {
        return registered == .bareMedia && input.hasQuote ? .bubble : registered.surface
    }
    if input.hasQuote { return cardTypes.contains(type) ? .card : .bubble }
    if type == "video" { return input.hasCaption ? .bubble : .bareMedia }
    if type == "text" { return input.loneEmoji ? .bareMedia : .bubble }
    if bareMediaTypes.contains(type) { return .bareMedia }
    if cardTypes.contains(type) { return .card }
    return .bubble
}

/// Where the meta sits for a surface (spec rules.placement): a text bubble inline, any other bubble in its
/// footer, bare media and cards below, centred rows nowhere.
public func flareMessageMetaPlacement(surface: FlareMessageSurface, contentType: String) -> FlareMessageMetaPlacement {
    switch surface {
    case .centered: return .none
    case .bareMedia, .card: return .below
    case .bubble: return flareSpecContentType(contentType) == "text" ? .inline : .bubbleFooter
    }
}

/// The meta palette (spec rules.tone): onOutgoing only inside an outgoing bubble that has not failed.
public func flareMessageMetaTone(placement: FlareMessageMetaPlacement, isSelf: Bool,
                                 status: FlareMessageDeliveryStatus?) -> FlareMessageMetaTone {
    guard isSelf, status != .failed else { return .default }
    return placement == .inline || placement == .bubbleFooter ? .onOutgoing : .default
}

/// The retry of a failed outgoing message (spec rules.failed): the glyph inside a bubble, the text key
/// ("发送失败，重试") below a surface; nil for incoming, unfailed or centred rows.
public func flareMessageRetryForm(placement: FlareMessageMetaPlacement, isSelf: Bool,
                                  status: FlareMessageDeliveryStatus?) -> FlareMessageRetryForm? {
    guard isSelf, status == .failed, placement != .none else { return nil }
    return placement == .below ? .text : .glyph
}

// MARK: - Messages

extension FlareMessageContent {
    /// The spec content type of this body (`spec/components.json` contentTypes, plus the generic ones).
    var specContentType: String {
        switch self {
        case is FlareTextContent: return "text"
        case is FlareRichTextContent: return "richText"
        case is FlareImageContent: return "image"
        case is FlareImageGroupContent: return "imageGroup"
        case is FlareVideoContent: return "video"
        case is FlareAudioContent: return "audio"
        case is FlareFileContent: return "file"
        case is FlareLocationContent: return "location"
        case is FlareStickerContent: return "sticker"
        case is FlareEmojiContent: return "emoji"
        case is FlareCardContent: return "card"
        case is FlareNotificationContent: return "notification"
        case is FlarePlaceholderContent: return "placeholder"
        case is FlarePollContent: return "vote"
        case is FlareTaskContent: return "task"
        case is FlareCalendarContent: return "schedule"
        case is FlareMiniAppContent: return "miniProgram"
        case is FlareAnnouncementContent: return "announcement"
        case is FlareLinkCardContent: return "linkCard"
        default: return flareSpecContentType(type)
        }
    }

    /// The keys a host registration is looked up by, most specific first: `type:subtype`, then `type`.
    var rendererKeys: [String] {
        if let generic = self as? FlareGenericContent, let subtype = generic.subtype?.trimmingCharacters(in: .whitespaces),
           !subtype.isEmpty {
            return ["\(type):\(subtype)", type]
        }
        return [type]
    }
}

/// Whether a text body is one emoji: a pack token the catalog knows (`[smile]`) or a single emoji character.
func flareIsLoneEmojiText(_ text: String) -> Bool {
    if flareLoneEmojiPackKey(text) != nil { return true }
    return flareSingleEmoji(text) != nil
}

/// The text when it is exactly one emoji character (a single grapheme drawn as emoji), else nil.
func flareSingleEmoji(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count == 1, let first = trimmed.unicodeScalars.first else { return nil }
    let properties = first.properties
    let scalars = trimmed.unicodeScalars
    // A digit or "#" is an emoji base but reads as text unless a keycap or presentation selector follows.
    let emoji = properties.isEmojiPresentation || (properties.isEmoji && (scalars.count > 1 || first.value > 0x238C))
    return emoji ? trimmed : nil
}

public extension FlareMessageData {
    /// The surface facts of this row (`spec/message-surface-vectors.json` inputs), with the host's registration
    /// for its content key.
    func surfaceInput(registered: FlareMessageRegisteredSurface? = nil) -> FlareMessageSurfaceInput {
        let text = content as? FlareTextContent
        return FlareMessageSurfaceInput(
            contentType: content.specContentType,
            subtype: (content as? FlareGenericContent)?.subtype,
            hasQuote: replyTo != nil,
            hasCaption: false,
            loneEmoji: text.map { $0.mentions.isEmpty && flareIsLoneEmojiText($0.text) } ?? false,
            recalled: isRecalled,
            deleted: isDeleted,
            registered: registered)
    }

    /// The surface this row draws its content on, given the host's registrations by content key.
    func surface(registry: [String: FlareMessageRegisteredSurface] = [:]) -> FlareMessageSurface {
        let registered = content.rendererKeys.lazy.compactMap { registry[$0] }.first
        return flareMessageSurface(surfaceInput(registered: registered))
    }
}
