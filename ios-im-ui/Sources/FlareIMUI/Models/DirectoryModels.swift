import Foundation

/// A directory contact.
public struct Contact: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let signature: String?
    public let presence: FlarePresence?
    /// Explicit A-Z index letter; derived from name when nil.
    public let indexKey: String?
    /// Optional profile detail — surfaced by ContactDetail / ProfileCard.
    public let remark: String?
    public let region: String?
    public let phone: String?
    public let tags: [String]

    public init(id: String, name: String, avatarURL: String? = nil, signature: String? = nil,
                presence: FlarePresence? = nil, indexKey: String? = nil,
                remark: String? = nil, region: String? = nil, phone: String? = nil, tags: [String] = []) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.signature = signature
        self.presence = presence; self.indexKey = indexKey
        self.remark = remark; self.region = region; self.phone = phone; self.tags = tags
    }
}

/// One participant in a group (multi-party) call.
public struct CallParticipant: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let muted: Bool
    public let cameraOff: Bool
    public let speaking: Bool
    public let isSelf: Bool
    public init(id: String, name: String, avatarURL: String? = nil, muted: Bool = false,
                cameraOff: Bool = false, speaking: Bool = false, isSelf: Bool = false) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.muted = muted
        self.cameraOff = cameraOff; self.speaking = speaking; self.isSelf = isSelf
    }
}

public struct FriendRequest: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let message: String?
    public init(id: String, name: String, avatarURL: String? = nil, message: String? = nil) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.message = message
    }
}

public struct GroupSummary: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let memberCount: Int
    public init(id: String, name: String, avatarURL: String? = nil, memberCount: Int = 0) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.memberCount = memberCount
    }
}

public struct UserProfile: Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let signature: String?
    public let flareId: String?
    public init(id: String, name: String, avatarURL: String? = nil, signature: String? = nil, flareId: String? = nil) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.signature = signature; self.flareId = flareId
    }
}

public enum FlareSettingKind: Sendable { case navigation, toggle, value }

public struct FlareSettingsItem: Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let label: String
    public let systemImage: String?
    public let kind: FlareSettingKind
    public var value: Bool
    public let detail: String?
    public init(key: String, label: String, systemImage: String? = nil,
                kind: FlareSettingKind = .navigation, value: Bool = false, detail: String? = nil) {
        self.key = key; self.label = label; self.systemImage = systemImage
        self.kind = kind; self.value = value; self.detail = detail
    }
}

public struct FlareSettingsSection: Identifiable {
    public let id = UUID()
    public let title: String?
    public let items: [FlareSettingsItem]
    public init(title: String? = nil, items: [FlareSettingsItem]) {
        self.title = title; self.items = items
    }
}

public struct ReactionGroup: Identifiable, Sendable { public var id: String { emoji }; public let emoji: String; public let count: Int; public let reactedBySelf: Bool; public let users: [String]; public init(emoji: String, count: Int, reactedBySelf: Bool = false, users: [String] = []) { self.emoji = emoji; self.count = count; self.reactedBySelf = reactedBySelf; self.users = users } }
public struct MentionCandidate: Identifiable, Sendable { public let id: String; public let name: String; public let avatarURL: String?; public let detail: String?; public let isEveryone: Bool; public init(id: String, name: String, avatarURL: String? = nil, detail: String? = nil, isEveryone: Bool = false) { self.id = id; self.name = name; self.avatarURL = avatarURL; self.detail = detail; self.isEveryone = isEveryone } }
public struct QuickPhrase: Identifiable, Sendable { public let id: String; public let text: String; public init(id: String, text: String) { self.id = id; self.text = text } }
public struct QuickPhraseGroup: Identifiable, Sendable { public var id: String { key }; public let key: String; public let title: String; public let phrases: [QuickPhrase]; public init(key: String, title: String, phrases: [QuickPhrase] = []) { self.key = key; self.title = title; self.phrases = phrases } }
public enum SearchResultKind: String, Sendable { case contact, group, message }
public struct SearchResultItem: Identifiable, Sendable { public let id: String; public let kind: SearchResultKind; public let title: String; public let subtitle: String?; public let avatarURL: String?; public let meta: String?; public init(id: String, kind: SearchResultKind, title: String, subtitle: String? = nil, avatarURL: String? = nil, meta: String? = nil) { self.id = id; self.kind = kind; self.title = title; self.subtitle = subtitle; self.avatarURL = avatarURL; self.meta = meta } }
public struct SearchResultGroup: Identifiable, Sendable { public var id: String { kind.rawValue }; public let kind: SearchResultKind; public let label: String; public let items: [SearchResultItem]; public let total: Int?; public init(kind: SearchResultKind, label: String, items: [SearchResultItem] = [], total: Int? = nil) { self.kind = kind; self.label = label; self.items = items; self.total = total } }

public struct ForwardTarget: Identifiable, Sendable { public let id: String; public let name: String; public let avatarURL: String?; public let subtitle: String?; public init(id: String, name: String, avatarURL: String? = nil, subtitle: String? = nil) { self.id = id; self.name = name; self.avatarURL = avatarURL; self.subtitle = subtitle } }

public struct SlashCommand: Identifiable, Sendable { public var id: String { command }; public let command: String; public let description: String?; public let hint: String?; public init(command: String, description: String? = nil, hint: String? = nil) { self.command = command; self.description = description; self.hint = hint } }

public struct GridImage: Identifiable, Sendable { public let id = UUID(); public let url: String?; public let alt: String?; public init(url: String? = nil, alt: String? = nil) { self.url = url; self.alt = alt } }
public struct WallpaperOption: Identifiable, Sendable { public let id: String; public let color: String?; public let imageURL: String?; public let label: String?; public init(id: String, color: String? = nil, imageURL: String? = nil, label: String? = nil) { self.id = id; self.color = color; self.imageURL = imageURL; self.label = label } }

public struct EmojiCategory: Identifiable, Sendable { public var id: String { key }; public let key: String; public let label: String; public let symbol: String?; public let emojis: [String]; public init(key: String, label: String, symbol: String? = nil, emojis: [String] = []) { self.key = key; self.label = label; self.symbol = symbol; self.emojis = emojis } }
public struct StickerItem: Identifiable, Sendable { public let id: String; public let url: String?; public let placeholder: String?; public init(id: String, url: String? = nil, placeholder: String? = nil) { self.id = id; self.url = url; self.placeholder = placeholder } }
public struct StickerPack: Identifiable, Sendable { public var id: String { key }; public let key: String; public let label: String; public let coverURL: String?; public let coverEmoji: String?; public let stickers: [StickerItem]; public init(key: String, label: String, coverURL: String? = nil, coverEmoji: String? = nil, stickers: [StickerItem] = []) { self.key = key; self.label = label; self.coverURL = coverURL; self.coverEmoji = coverEmoji; self.stickers = stickers } }

// MARK: - Moments (social feed)

public struct MomentAuthor: Identifiable, Sendable { public let id: String; public let name: String; public let avatarURL: String?; public init(id: String, name: String, avatarURL: String? = nil) { self.id = id; self.name = name; self.avatarURL = avatarURL } }
public struct MomentLike: Identifiable, Sendable { public let id: String; public let name: String; public init(id: String, name: String) { self.id = id; self.name = name } }
public struct MomentComment: Identifiable, Sendable { public let id: String; public let author: MomentAuthor; public let text: String; public let replyToName: String?; public let time: String?; public init(id: String, author: MomentAuthor, text: String, replyToName: String? = nil, time: String? = nil) { self.id = id; self.author = author; self.text = text; self.replyToName = replyToName; self.time = time } }
public struct Moment: Identifiable, Sendable { public let id: String; public let author: MomentAuthor; public let text: String?; public let images: [GridImage]; public let location: String?; public let time: String?; public let likes: [MomentLike]; public let comments: [MomentComment]; public let likedBySelf: Bool; public init(id: String, author: MomentAuthor, text: String? = nil, images: [GridImage] = [], location: String? = nil, time: String? = nil, likes: [MomentLike] = [], comments: [MomentComment] = [], likedBySelf: Bool = false) { self.id = id; self.author = author; self.text = text; self.images = images; self.location = location; self.time = time; self.likes = likes; self.comments = comments; self.likedBySelf = likedBySelf } }

// MARK: - Form / control models

public enum FlareButtonVariant: Sendable { case primary, secondary, ghost, danger, text }
public enum FlareControlSize: Sendable { case sm, md, lg }
public struct FlareSelectOption: Identifiable, Sendable { public var id: String { value }; public let value: String; public let label: String; public let disabled: Bool; public init(value: String, label: String, disabled: Bool = false) { self.value = value; self.label = label; self.disabled = disabled } }

public struct FlareNavItem: Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let label: String
    public let systemImage: String
    public let badge: Int
    public init(key: String, label: String, systemImage: String, badge: Int = 0) {
        self.key = key; self.label = label; self.systemImage = systemImage; self.badge = badge
    }
}
