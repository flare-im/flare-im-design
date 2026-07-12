import Foundation

/// Message body content — the data behind ``MessageContentView`` and the
/// content-type registry (spec `contentTypes.registered`). Products may add a
/// conforming type and register a builder via ``FlareContentRegistry``.
public protocol FlareMessageContent {
    /// Registry key (e.g. `text`, `image`, `card`).
    var type: String { get }
}

public struct FlareTextContent: FlareMessageContent {
    public let text: String
    public let mentionsSelf: Bool
    public init(_ text: String, mentionsSelf: Bool = false) {
        self.text = text; self.mentionsSelf = mentionsSelf
    }
    public var type: String { "text" }
}

public struct FlareImageContent: FlareMessageContent {
    public let url: String
    public let thumbnailURL: String?
    public let alt: String?
    public init(url: String, thumbnailURL: String? = nil, alt: String? = nil) {
        self.url = url; self.thumbnailURL = thumbnailURL; self.alt = alt
    }
    public var type: String { "image" }
}

public struct FlareVideoContent: FlareMessageContent {
    public let url: String
    public let poster: String?
    public let durationSec: Int
    public init(url: String, poster: String? = nil, durationSec: Int = 0) {
        self.url = url; self.poster = poster; self.durationSec = durationSec
    }
    public var type: String { "video" }
}

public struct FlareAudioContent: FlareMessageContent {
    public let url: String
    public let durationSec: Int
    public init(url: String, durationSec: Int = 0) {
        self.url = url; self.durationSec = durationSec
    }
    public var type: String { "audio" }
}

public struct FlareFileContent: FlareMessageContent {
    public let name: String
    public let url: String
    public let sizeBytes: Int
    public init(name: String, url: String, sizeBytes: Int = 0) {
        self.name = name; self.url = url; self.sizeBytes = sizeBytes
    }
    public var type: String { "file" }
}

public struct FlareLocationContent: FlareMessageContent {
    public let name: String
    public let address: String
    public init(name: String, address: String = "") {
        self.name = name; self.address = address
    }
    public var type: String { "location" }
}

public struct FlareStickerContent: FlareMessageContent {
    public let url: String
    /// Protocol pack identity — when set, resolves a bundled pack asset before `url`.
    public let packageId: String?
    public let stickerId: String?
    public let width: Int?
    public let height: Int?
    public init(url: String, packageId: String? = nil, stickerId: String? = nil,
                width: Int? = nil, height: Int? = nil) {
        self.url = url
        self.packageId = packageId
        self.stickerId = stickerId
        self.width = width
        self.height = height
    }
    public var type: String { "sticker" }
}

public struct FlareEmojiContent: FlareMessageContent {
    public let emoji: String
    public init(_ emoji: String) { self.emoji = emoji }
    public var type: String { "emoji" }
}

public struct FlareCardContent: FlareMessageContent {
    public let title: String
    public let subtitle: String?
    public let imageURL: String?
    public let sourceLabel: String?
    public init(title: String, subtitle: String? = nil, imageURL: String? = nil, sourceLabel: String? = nil) {
        self.title = title; self.subtitle = subtitle; self.imageURL = imageURL; self.sourceLabel = sourceLabel
    }
    public var type: String { "card" }
}

/// System/notification line — rendered centred without a bubble.
public struct FlareNotificationContent: FlareMessageContent {
    public let text: String
    public init(_ text: String) { self.text = text }
    public var type: String { "notification" }
}

public struct FlarePlaceholderContent: FlareMessageContent {
    public let label: String
    public init(_ label: String) { self.label = label }
    public var type: String { "placeholder" }
}

/// Carries a product/registered type (`vote`, `task`…) with a plain fallback
/// label; register a builder for `contentType` to render it natively.
public struct FlareGenericContent: FlareMessageContent {
    public let contentType: String
    public let label: String
    public init(contentType: String, label: String) {
        self.contentType = contentType; self.label = label
    }
    public var type: String { contentType }
}

/// Media (image/video/file) download progress overlay state.
public enum FlareMediaDownloadStatus: Sendable { case idle, downloading, done, failed }

public struct FlareMediaDownloadState: Sendable {
    public let status: FlareMediaDownloadStatus
    public let progressPct: Int
    public init(status: FlareMediaDownloadStatus = .idle, progressPct: Int = 0) {
        self.status = status; self.progressPct = progressPct
    }
    public var isDownloading: Bool { status == .downloading }
}
