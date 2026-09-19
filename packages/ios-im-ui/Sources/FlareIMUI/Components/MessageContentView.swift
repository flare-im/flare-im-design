import SwiftUI

/// Context passed to every content renderer.
public struct FlareContentContext {
    public let isSelf: Bool
    public let previewMode: Bool
    public let senderName: String?
    public let mediaState: FlareMediaDownloadState?
    public let onMediaAction: ((FlareMessageContent) -> Void)?

    public init(
        isSelf: Bool,
        previewMode: Bool = false,
        senderName: String? = nil,
        mediaState: FlareMediaDownloadState? = nil,
        onMediaAction: ((FlareMessageContent) -> Void)? = nil
    ) {
        self.isSelf = isSelf
        self.previewMode = previewMode
        self.senderName = senderName
        self.mediaState = mediaState
        self.onMediaAction = onMediaAction
    }
}

public typealias FlareContentBuilder = (FlareMessageContent, FlareContentContext) -> AnyView

/// Registry for product content types (`vote`, `task`…). Built-in types are
/// rendered directly by ``MessageContentView``; register a builder to add or
/// override a type.
public enum FlareContentRegistry {
    private static var builders: [String: FlareContentBuilder] = [:]
    public static func register(_ type: String, _ builder: @escaping FlareContentBuilder) {
        builders[type] = builder
    }
    public static func unregister(_ type: String) { builders.removeValue(forKey: type) }
    public static func lookup(_ type: String) -> FlareContentBuilder? { builders[type] }
}

/// Content-type dispatcher — renders a message body by type. Spec:
/// Message/MessageContentView (`MessageContentView`).
///
/// Media without `onMediaAction` is still consumable: an image opens the kit ``ImagePreviewView``
/// full screen (with a download key only when `onMediaDownload` is given; in a ``MessageListView`` as the
/// conversation's gallery, `spec/image-gallery-vectors.json`), a video opens the kit
/// ``VideoPlayerView`` full screen and plays, and a voice message plays inside its body, one at a time
/// in a ``MessageListView``. With `onMediaAction` every media tap goes to the host, as before. Files
/// and locations always go to the host — a file tap goes to `onMediaAction`, else to `onOpenFile`
/// (which leaves the image, video and voice defaults on).
///
/// A poll's option and a task's checkbox are controls only with `onVote` (the option's index) and
/// `onTaskToggle` (the state the user asks for); without them the bodies are read-only.
///
/// Links (in a text body and on a link card) go to `onOpenLink`; without it the body opens a web
/// address with the platform opener after ``safeExternalURL(_:)``, and opens nothing for any other
/// scheme. A link card whose URL is not a web address has no tap at all.
public struct MessageContentView: View {
    private let content: FlareMessageContent
    private let ctx: FlareContentContext
    private let onMediaDownload: ((FlareMessageContent) -> Void)?
    private let onOpenFile: ((FlareFileContent) -> Void)?
    private let onOpenLink: ((String) -> Void)?
    private let onVote: ((Int) -> Void)?
    private let onTaskToggle: ((Bool) -> Void)?
    /// The list's media defaults; nil outside a list, where a media body owns its own.
    private var mediaSession: FlareMediaSession?
    /// The message this body belongs to: a voice message's playback identity, and where its pictures are in
    /// the timeline's gallery.
    private var messageId: String?
    /// The timeline's gallery; nil outside a list, where a picture opens alone.
    private var gallery: FlareImageGallerySource?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.openURL) private var openURL
    @Environment(\.flareStrings) private var strings

    public init(
        content: FlareMessageContent,
        isSelf: Bool = false,
        previewMode: Bool = false,
        senderName: String? = nil,
        mediaState: FlareMediaDownloadState? = nil,
        onMediaAction: ((FlareMessageContent) -> Void)? = nil,
        onMediaDownload: ((FlareMessageContent) -> Void)? = nil,
        onOpenFile: ((FlareFileContent) -> Void)? = nil,
        onOpenLink: ((String) -> Void)? = nil,
        onVote: ((Int) -> Void)? = nil,
        onTaskToggle: ((Bool) -> Void)? = nil
    ) {
        self.content = content
        self.ctx = FlareContentContext(
            isSelf: isSelf, previewMode: previewMode, senderName: senderName,
            mediaState: mediaState, onMediaAction: onMediaAction)
        self.onMediaDownload = onMediaDownload
        self.onOpenFile = onOpenFile
        self.onOpenLink = onOpenLink
        self.onVote = onVote
        self.onTaskToggle = onTaskToggle
    }

    /// This body inside a timeline: `session` is the list's media defaults, `messageId` the message, `gallery` the
    /// timeline's pictures.
    func mediaDefaults(_ session: FlareMediaSession?, messageId: String?,
                       gallery: FlareImageGallerySource? = nil) -> MessageContentView {
        var copy = self
        copy.mediaSession = session
        copy.messageId = messageId
        copy.gallery = gallery
        return copy
    }

    /// Whether a tap on `content` uses the kit default: an image, album, video or voice message whose host
    /// passed no media handler.
    static func usesMediaDefaults(_ content: FlareMessageContent, hostHandles: Bool) -> Bool {
        !hostHandles && (content is FlareImageContent || content is FlareImageGroupContent || content is FlareVideoContent
            || content is FlareAudioContent)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let foreground = ctx.isSelf ? colors.messageOutgoingForeground : colors.messageIncomingForeground
        if let custom = FlareContentRegistry.lookup(content.type) {
            custom(content, ctx)
        } else if mediaSession == nil, Self.usesMediaDefaults(content, hostHandles: ctx.onMediaAction != nil) {
            FlareOwnedMediaSession { session in
                framedBody(session, foreground: foreground)
            }
        } else {
            framedBody(mediaSession, foreground: foreground)
        }
    }

    private func framedBody(_ session: FlareMediaSession?, foreground: Color) -> some View {
        VStack(alignment: .leading) {
            canonicalBody(session)
            if let media = ctx.mediaState, media.isDownloading {
                ProgressView(value: Double(min(max(media.progressPct, 0), 100)), total: 100)
            }
        }
        .environment(\.flareMessageBodyForeground, foreground)
        .foregroundStyle(foreground)
    }

    private var action: (() -> Void)? {
        guard let handler = ctx.onMediaAction else { return nil }
        return { handler(content) }
    }

    /// The host's download handler for this body, as the preview's download key.
    private var download: (() -> Void)? {
        guard let onMediaDownload else { return nil }
        return { onMediaDownload(content) }
    }

    /// Opening an album tile: the host's media handler takes the whole album; without one the kit previews the
    /// tile's image — in a timeline, the conversation's gallery from it — which the host's download handler can save.
    private func albumOpener(_ album: FlareImageGroupContent, session: FlareMediaSession?) -> ((Int) -> Void)? {
        if let handler = ctx.onMediaAction { return { _ in handler(album) } }
        guard let session else { return nil }
        return { index in
            let image = album.images[index]
            session.open(image, messageId: messageId, index: index, gallery: gallery,
                         onDownload: onMediaDownload.map { download in { download(image) } })
        }
    }

    /// Opening a link card: the host's link handler, else the platform opener for a web address. A card
    /// whose URL is not one has no tap, so nothing looks actionable that cannot act.
    private func openCard(_ url: String) -> (() -> Void)? {
        if let onOpenLink { return { onOpenLink(url) } }
        guard case .system(let safe) = TextMessageView.linkTap(url, hostHandles: false) else { return nil }
        return { openURL(safe) }
    }

    @ViewBuilder private func canonicalBody(_ session: FlareMediaSession?) -> some View {
        switch content {
        case let c as FlareTextContent:
            TextMessageView(text: c.text, isSelf: ctx.isSelf, mentions: c.mentions, onLinkTap: onOpenLink)
        case let c as FlareRichTextContent:
            RichTextMessageView(docJson: c.docJson, plainText: c.plainText, title: c.title, isSelf: ctx.isSelf,
                                onLinkTap: onOpenLink)
        case let c as FlareEmojiContent:
            EmojiMessageView(emoji: c.emoji, onTap: action)
        case let c as FlareStickerContent:
            StickerMessageView(url: c.url, packageId: c.packageId, stickerId: c.stickerId,
                width: c.width, height: c.height, onTap: action)
        case let c as FlareImageContent:
            ImageMessageView(src: c.thumbnailURL ?? c.url, width: 240, height: 180, alt: c.alt,
                             onTap: action ?? session.map { session in
                                 { session.open(c, messageId: messageId, index: 0, gallery: gallery, onDownload: download) }
                             })
        case let c as FlareImageGroupContent:
            ImageGroupMessageView(images: c.images, description: c.description, isSelf: ctx.isSelf,
                                  onOpen: albumOpener(c, session: session))
        case let c as FlareVideoContent:
            VideoMessageView(poster: c.poster, duration: Self.duration(c.durationSec),
                             onPlay: action ?? session.map { session in { session.present(c) } })
        case let c as FlareAudioContent:
            if let action {
                VoiceMessageView(seconds: c.durationSec, onPlay: action)
            } else if let session {
                FlareVoiceMessageBody(content: c, id: messageId ?? c.url, playback: session.voice)
            } else {
                VoiceMessageView(seconds: c.durationSec)
            }
        case let c as FlareFileContent:
            FileMessageView(name: c.name, size: Self.bytes(c.sizeBytes),
                            onOpen: action ?? onOpenFile.map { open in { open(c) } })
        case let c as FlareLocationContent:
            LocationMessageView(title: c.name, address: c.address, onOpen: action)
        case let c as FlareCardContent:
            ContactMessageView(name: c.title, subtitle: c.subtitle, avatarUrl: c.imageURL, onOpen: action)
        case let c as FlareLinkCardContent:
            LinkCardMessageView(title: c.title, domain: c.url, thumb: c.imageURL, description: c.description,
                                onOpen: action ?? openCard(c.url))
        case let c as FlarePollContent:
            VoteMessageView(title: c.title, options: c.options.map { FlareVoteOption($0) },
                            onSelect: onVote.map { vote in { _, index in vote(index) } })
        case let c as FlareTaskContent:
            TaskMessageView(title: c.title, meta: c.detail, done: c.done,
                            onToggle: onTaskToggle.map { toggle in { toggle(!c.done) } })
        case let c as FlareCalendarContent:
            LinkCardMessageView(title: c.title, description: c.timeRange, onOpen: action,
                icon: AnyView(Image(systemName: "calendar")))
        case let c as FlareMiniAppContent:
            LinkCardMessageView(title: c.title, domain: c.appId, thumb: c.thumbnailUrl,
                description: c.description, onOpen: action)
        case let c as FlareAnnouncementContent:
            LinkCardMessageView(title: c.title, description: c.body, onOpen: action,
                icon: AnyView(Image(systemName: "megaphone")), descriptionMaxLines: nil)
        case let c as FlareNotificationContent:
            SystemMessageView(text: c.text)
        case let c as FlarePlaceholderContent:
            SystemMessageView(text: c.label)
        case let c as FlareGenericContent:
            // The kit's own one-line summary: the body's label when it has one, else the word for
            // its wire type. Wrapping the label in brackets drew a literal "[]" for a body without one.
            UnknownMessageView(contentType: c.type, summary: flareMessagePreviewText(c, strings: strings), isSelf: ctx.isSelf)
        default:
            UnknownMessageView(contentType: content.type, isSelf: ctx.isSelf)
        }
    }

    static func duration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    static func bytes(_ b: Int) -> String {
        if b < 1024 { return "\(b) B" }
        if b < 1024 * 1024 { return String(format: "%.1f KB", Double(b) / 1024) }
        if b < 1024 * 1024 * 1024 { return String(format: "%.1f MB", Double(b) / 1024 / 1024) }
        return String(format: "%.1f GB", Double(b) / 1024 / 1024 / 1024)
    }
}

/// A voice message played by the kit: ``VoiceMessageView`` over the timeline's voice playback.
struct FlareVoiceMessageBody: View {
    let content: FlareAudioContent
    let id: String
    @ObservedObject var playback: FlareVoicePlayback

    var body: some View {
        let active = playback.activeId == id
        let phase = active ? playback.phase : .idle
        VoiceMessageView(seconds: content.durationSec,
                         playing: phase == .playing,
                         elapsedSeconds: active ? Int(playback.elapsed) : nil,
                         failed: phase == .failed,
                         onPlay: { playback.toggle(id: id, url: content.url) })
    }
}
