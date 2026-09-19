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
    /// Mentions the text body emphasizes, as UTF-16 offsets into `text`. Build them from the core's
    /// mention entities with ``FlareTextMentionSpan/spans(from:in:currentUserId:)``.
    public let mentions: [FlareTextMentionSpan]
    public init(_ text: String, mentions: [FlareTextMentionSpan] = []) {
        self.text = text; self.mentions = mentions
    }
    public var type: String { "text" }
}

/// A rich-text message: the RichDoc v2 document the core stores (`docJson`), the core's flat `plainText` of
/// it, and the message's own `title`. Drawn by ``RichTextMessageView``; the sender's Markdown source is not
/// part of it.
public struct FlareRichTextContent: FlareMessageContent {
    /// The document's JSON text, as the core sends it.
    public let docJson: String
    public let plainText: String
    public let title: String
    public init(docJson: String, plainText: String = "", title: String = "") {
        self.docJson = docJson; self.plainText = plainText; self.title = title
    }
    public var type: String { "richText" }
}

public struct FlareImageContent: FlareMessageContent {
    public let url: String
    public let thumbnailURL: String?
    public let alt: String?
    /// The image moves (GIF / APNG). Its one-line summary says so — a moving image reads as
    /// `[动图]`, not `[图片]` — so fill it from the source's format or MIME type.
    public let animated: Bool
    public init(url: String, thumbnailURL: String? = nil, alt: String? = nil, animated: Bool = false) {
        self.url = url; self.thumbnailURL = thumbnailURL; self.alt = alt; self.animated = animated
    }
    public var type: String { "image" }
}

/// An image-group (album) message: its `images` in order, each drawn and opened like an image message, and
/// the album's `description`.
public struct FlareImageGroupContent: FlareMessageContent {
    public let images: [FlareImageContent]
    public let description: String
    public init(images: [FlareImageContent], description: String = "") {
        self.images = images; self.description = description
    }
    public var type: String { "imageGroup" }
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
public struct FlarePollContent: FlareMessageContent {
    public let id: String
    public let title: String
    public let options: [String]
    public init(id: String, title: String, options: [String] = []) {
        self.id = id
        self.title = title
        self.options = options
    }
    public var type: String { "vote" }
}

public struct FlareTaskContent: FlareMessageContent {
    public let id: String
    public let title: String
    public let detail: String
    public let done: Bool
    public init(id: String, title: String, detail: String = "", done: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.done = done
    }
    public var type: String { "task" }
}

public struct FlareCalendarContent: FlareMessageContent {
    public let id: String
    public let title: String
    public let timeRange: String
    public init(id: String, title: String, timeRange: String = "") {
        self.id = id
        self.title = title
        self.timeRange = timeRange
    }
    public var type: String { "schedule" }
}

public struct FlareMiniAppContent: FlareMessageContent {
    public let appId: String
    public let title: String
    public let pagePath: String
    public let thumbnailUrl: String?
    public let description: String?
    public init(appId: String, title: String, pagePath: String = "", thumbnailUrl: String? = nil, description: String? = nil) {
        self.appId = appId
        self.title = title
        self.pagePath = pagePath
        self.thumbnailUrl = thumbnailUrl
        self.description = description
    }
    public var type: String { "miniProgram" }
}

public struct FlareAnnouncementContent: FlareMessageContent {
    public let id: String
    public let title: String
    public let body: String
    public init(id: String, title: String, body: String = "") {
        self.id = id
        self.title = title
        self.body = body
    }
    public var type: String { "announcement" }
}

public struct FlareLinkCardContent: FlareMessageContent {
    public let url: String
    public let title: String
    public let description: String?
    public let imageURL: String?
    public init(url: String, title: String, description: String? = nil, imageURL: String? = nil) {
        self.url = url; self.title = title; self.description = description; self.imageURL = imageURL
    }
    public var type: String { "linkCard" }
}

public struct FlareGenericContent: FlareMessageContent {
    public let contentType: String
    public let label: String
    /// How many items the type carries — a merged forward's messages, an album's images; 0 when it
    /// carries none. Its one-line summary counts them (`[多图] 4 张`). Same name and meaning as
    /// Compose's `FlareGenericContent.itemCount`.
    public let itemCount: Int
    public init(contentType: String, label: String, itemCount: Int = 0) {
        self.contentType = contentType; self.label = label; self.itemCount = itemCount
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
