import SwiftUI

/// Context passed to every content renderer. `messageId` is the message's id in the core (its server id, else the
/// client id it was sent with) and `conversationId` the conversation the list shows; both are nil where the body is
/// drawn outside a message (a preview, a standalone body without them).
///
/// `selectionMode` is true while the row is in multi-select: the content is inert (the kit also stops it taking
/// taps) and a tap anywhere on the row toggles its selection. `surface` is the surface the row draws the body on;
/// on ``FlareMessageSurface/card`` the renderer's own shell is the surface and nothing is drawn around it.
public struct FlareContentContext {
    public let isSelf: Bool
    public let previewMode: Bool
    public let senderName: String?
    public let mediaState: FlareMediaDownloadState?
    public let onMediaAction: ((FlareMessageContent) -> Void)?
    public let messageId: String?
    public let conversationId: String?
    public let selectionMode: Bool
    public let surface: FlareMessageSurface?

    public init(
        isSelf: Bool,
        previewMode: Bool = false,
        senderName: String? = nil,
        mediaState: FlareMediaDownloadState? = nil,
        onMediaAction: ((FlareMessageContent) -> Void)? = nil,
        messageId: String? = nil,
        conversationId: String? = nil,
        selectionMode: Bool = false,
        surface: FlareMessageSurface? = nil
    ) {
        self.isSelf = isSelf
        self.previewMode = previewMode
        self.senderName = senderName
        self.mediaState = mediaState
        self.onMediaAction = onMediaAction
        self.messageId = messageId
        self.conversationId = conversationId
        self.selectionMode = selectionMode
        self.surface = surface
    }

    /// The same context with some fields replaced.
    func with(messageId: String?? = nil, conversationId: String?? = nil, selectionMode: Bool? = nil,
              surface: FlareMessageSurface?? = nil) -> FlareContentContext {
        FlareContentContext(isSelf: isSelf, previewMode: previewMode, senderName: senderName, mediaState: mediaState,
                            onMediaAction: (selectionMode ?? self.selectionMode) ? nil : onMediaAction,
                            messageId: messageId ?? self.messageId, conversationId: conversationId ?? self.conversationId,
                            selectionMode: selectionMode ?? self.selectionMode, surface: surface ?? self.surface)
    }
}

public typealias FlareContentBuilder = (FlareMessageContent, FlareContentContext) -> AnyView

private struct ContentRenderersKey: EnvironmentKey {
    static let defaultValue: [String: FlareContentBuilder] = [:]
}
private struct ContentSurfacesKey: EnvironmentKey {
    static let defaultValue: [String: FlareMessageRegisteredSurface] = [:]
}
private struct MessageCardQuoteKey: EnvironmentKey {
    static let defaultValue: AnyView? = nil
}
private struct MessageCardShellKey: EnvironmentKey {
    static let defaultValue = false
}
extension EnvironmentValues {
    /// The body sits in the kit card shell: it fills the shell's width (a location's map runs edge to edge).
    var flareInMessageCardShell: Bool {
        get { self[MessageCardShellKey.self] }
        set { self[MessageCardShellKey.self] = newValue }
    }
}
public extension EnvironmentValues {
    var flareContentRenderers: [String: FlareContentBuilder] {
        get { self[ContentRenderersKey.self] }
        set { self[ContentRenderersKey.self] = newValue }
    }

    /// The surfaces the host registered by content key (`type:subtype` or `type`), for content the kit does not
    /// know: ``FlareMessageRegisteredSurface/card`` or ``FlareMessageRegisteredSurface/bareMedia``. Every custom body
    /// (plugin cards, red packets) is already a card without registering.
    var flareContentSurfaces: [String: FlareMessageRegisteredSurface] {
        get { self[ContentSurfacesKey.self] }
        set { self[ContentSurfacesKey.self] = newValue }
    }

    /// The quote of a quoting card message, which the card's shell draws inside itself at its top
    /// (``FlareMessageCardQuoteSlot``). Nil everywhere else.
    var flareMessageCardQuote: AnyView? {
        get { self[MessageCardQuoteKey.self] }
        set { self[MessageCardQuoteKey.self] = newValue }
    }
}

/// The quote slot of a card shell: a quoting card message's quote, drawn inside the shell at its top. The kit's card
/// shells (``PluginView``, the shell of the built-in card bodies) place it; a custom card renderer places it at the
/// top of its own shell. Draws nothing outside a quoting card.
public struct FlareMessageCardQuoteSlot: View {
    @Environment(\.flareMessageCardQuote) private var quote
    public init() {}
    public var body: some View {
        if let quote { quote }
    }
}

private struct MessageConversationIdKey: EnvironmentKey {
    static let defaultValue: String? = nil
}
extension EnvironmentValues {
    /// The conversation a ``MessageListView`` shows, for the context of its custom content renderers.
    var flareMessageConversationId: String? {
        get { self[MessageConversationIdKey.self] }
        set { self[MessageConversationIdKey.self] = newValue }
    }
}
public extension View {
    /// Renderer lifetime is scoped to this view tree, so two sessions never
    /// overwrite one another's callbacks in a process-global registry. A key is a content type, or
    /// `type:subtype` for one custom body type (``FlareGenericContent/subtype``), which wins over its type.
    func flareContentRenderers(_ builders: [String: FlareContentBuilder]) -> some View {
        environment(\.flareContentRenderers, builders)
    }

    /// The same, registering the surface of content keys the kit does not know (`spec/message-surface-vectors.json`
    /// rules.registration): `.card` draws the renderer's own shell with nothing around it, `.bareMedia` draws it as
    /// the row draws a picture. Either way the row keeps the avatar, the sender's name, the time, multi-select and the
    /// long-press menu. Custom bodies are cards already; register only a new kind of content.
    func flareContentRenderers(_ builders: [String: FlareContentBuilder],
                               surfaces: [String: FlareMessageRegisteredSurface]) -> some View {
        environment(\.flareContentRenderers, builders).environment(\.flareContentSurfaces, surfaces)
    }
}

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
/// full screen (in a ``MessageListView`` as the conversation's gallery, `spec/image-gallery-vectors.json`), a
/// video opens the kit ``VideoPlayerView`` full screen and plays — each with a download key only when
/// `onMediaDownload` is given, which it calls with the image or the video — and a voice message plays inside
/// its body, one at a time in a ``MessageListView``. With `onMediaAction` every media tap goes to the host, as
/// before. Files always go to the host — a file tap goes to `onMediaAction`, else to `onOpenFile` (which leaves the
/// image, video and voice defaults on).
///
/// A location tap goes to `onLocationOpen` with the location, else to `onMediaAction`; without either the card opens
/// Apple Maps at the point (``LocationMessageView``). A contact card's tap goes to `onCardOpen` with the person it
/// shares, else to `onMediaAction`; without either the card has no tap.
///
/// A file card carries its key at the trailing edge whenever `onMediaDownload` is given. The key, and the one in the
/// preview and the player, follow `mediaState`, the host's view of the media on this device: a download, the save's
/// progress, and once it is saved a folder that calls `onMediaReveal` — the host shows it where it was saved, or finds
/// it gone and passes `idle` again. A viewer that is open follows the state as it changes.
///
/// A picture — in the bubble, an album tile, the preview and the gallery — is drawn from its local copy when the
/// host resolved one through the SDK media cache (``FlareImageContent/localPath``,
/// ``flarePictureSource(_:preferThumbnail:)``). A file address in the message's own `url` is never drawn.
///
/// A poll's option and a task's checkbox are controls only with `onVote` (the option's index) and
/// `onTaskToggle` (the state the user asks for); without them the bodies are read-only.
///
/// Links (in a text body and on a link card) go to `onOpenLink`; without it the body opens a web
/// address with the platform opener after ``safeExternalURL(_:)``, and opens nothing for any other
/// scheme. A link card whose URL is not a web address has no tap at all.
///
/// `selectionMode` (the row is in multi-select) makes every control of the body inert — poll options, the task box,
/// card and location taps, plugin card keys and menus, links, media — so the row's tap toggles its selection.
///
/// On a ``FlareMessageSurface/card`` surface the kit's own card bodies (location, contact card, link card, poll,
/// task, schedule, announcement, mini program, an unrendered custom body) draw in the kit card shell — the
/// surface itself, radius lg on the primary background with a hairline — and in the neutral palette whoever sent
/// them; a quoting card's quote sits inside that shell at its top.
public struct MessageContentView: View {
    @Environment(\.flareContentRenderers) private var renderers
    private let content: FlareMessageContent
    private var ctx: FlareContentContext
    private let onMediaDownload: ((FlareMessageContent) -> Void)?
    private let onMediaReveal: ((FlareMessageContent) -> Void)?
    private let onOpenFile: ((FlareFileContent) -> Void)?
    private let onOpenLink: ((String) -> Void)?
    private let onVote: ((Int) -> Void)?
    private let onTaskToggle: ((Bool) -> Void)?
    private let onCardOpen: ((String) -> Void)?
    private let onLocationOpen: ((FlareLocationContent) -> Void)?
    private let selectionMode: Bool
    /// The surface the row draws this body on; nil outside a row (the body's own look).
    private var surface: FlareMessageSurface?
    /// The row is a failed outgoing message: its bubble is the failure surface, so the body takes its foreground.
    private var failed = false
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
        onMediaReveal: ((FlareMessageContent) -> Void)? = nil,
        onOpenFile: ((FlareFileContent) -> Void)? = nil,
        onOpenLink: ((String) -> Void)? = nil,
        onVote: ((Int) -> Void)? = nil,
        onTaskToggle: ((Bool) -> Void)? = nil,
        onCardOpen: ((String) -> Void)? = nil,
        onLocationOpen: ((FlareLocationContent) -> Void)? = nil,
        messageId: String? = nil,
        conversationId: String? = nil,
        selectionMode: Bool = false
    ) {
        self.content = content
        // In multi-select nothing in the body acts: the row's tap selects it.
        self.ctx = FlareContentContext(
            isSelf: isSelf, previewMode: previewMode, senderName: senderName,
            mediaState: mediaState, onMediaAction: selectionMode ? nil : onMediaAction,
            messageId: messageId, conversationId: conversationId, selectionMode: selectionMode)
        self.selectionMode = selectionMode
        self.onMediaDownload = selectionMode ? nil : onMediaDownload
        self.onMediaReveal = selectionMode ? nil : onMediaReveal
        self.onOpenFile = selectionMode ? nil : onOpenFile
        self.onOpenLink = selectionMode ? nil : onOpenLink
        self.onVote = selectionMode ? nil : onVote
        self.onTaskToggle = selectionMode ? nil : onTaskToggle
        self.onCardOpen = selectionMode ? nil : onCardOpen
        self.onLocationOpen = selectionMode ? nil : onLocationOpen
    }

    /// The message this body draws, for a custom renderer's context: the core's id and the conversation.
    func messageIdentity(messageId: String?, conversationId: String?) -> MessageContentView {
        var copy = self
        copy.ctx = ctx.with(messageId: .some(messageId), conversationId: .some(conversationId))
        return copy
    }

    /// This body on `surface`, as the row draws it; `failed` is a failed outgoing bubble (the failure surface).
    func onSurface(_ surface: FlareMessageSurface?, failed: Bool = false) -> MessageContentView {
        var copy = self
        copy.surface = surface
        copy.failed = failed
        copy.ctx = ctx.with(surface: .some(surface))
        return copy
    }

    /// The renderer the host registered for `content`, most specific key first (`type:subtype`, then `type`).
    static func renderer(for content: FlareMessageContent,
                         in renderers: [String: FlareContentBuilder]) -> FlareContentBuilder? {
        for key in content.rendererKeys {
            if let builder = renderers[key] ?? FlareContentRegistry.lookup(key) { return builder }
        }
        return nil
    }

    /// Whether the kit draws this body in its card shell: one of its own card bodies on a card surface.
    static func drawsCardShell(_ content: FlareMessageContent, surface: FlareMessageSurface?, custom: Bool) -> Bool {
        surface == .card && !custom
    }

    /// The kit card bodies that have no inner padding of their own.
    static func cardShellPadded(_ content: FlareMessageContent) -> Bool {
        content is FlareCardContent || content is FlareTaskContent || content is FlareGenericContent
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
        dispatched
            // Multi-select: the body takes no taps, so the row's own tap selects it.
            .allowsHitTesting(!selectionMode)
    }

    @ViewBuilder private var dispatched: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        // Only a bubble is coloured by its side; a card or a bare picture sits on the canvas in the neutral palette.
        let onBubble = surface == nil || surface == .bubble
        let foreground: Color? = !onBubble ? nil
            : failed ? colors.messageFailedForeground
            : ctx.isSelf ? colors.messageOutgoingForeground : colors.messageIncomingForeground
        if let custom = Self.renderer(for: content, in: renderers) {
            custom(content, ctx)
        } else if mediaSession == nil, Self.usesMediaDefaults(content, hostHandles: ctx.onMediaAction != nil),
                  !selectionMode {
            // Outside a list the body owns its viewer, which follows this body's state.
            FlareOwnedMediaSession(downloads: ctx.mediaState.map { [downloadId: $0] } ?? [:]) { session in
                shelled(framedBody(session, foreground: foreground))
            }
        } else {
            shelled(framedBody(selectionMode ? nil : mediaSession, foreground: foreground))
        }
    }

    /// The kit's own card bodies on a card surface draw in the kit card shell.
    @ViewBuilder private func shelled<Body: View>(_ body: Body) -> some View {
        if Self.drawsCardShell(content, surface: surface, custom: false) {
            FlareMessageCardShell(padded: Self.cardShellPadded(content)) { body }
        } else {
            body
        }
    }

    @ViewBuilder private func framedBody(_ session: FlareMediaSession?, foreground: Color?) -> some View {
        if let foreground {
            measuredBody(session).environment(\.flareMessageBodyForeground, foreground).foregroundStyle(foreground)
        } else {
            measuredBody(session)
        }
    }

    private func measuredBody(_ session: FlareMediaSession?) -> some View {
        canonicalBody(session)
            // A picture or a video being saved shows it along its bottom edge, inside the media, so the bubble keeps
            // the media's width; a file card shows it in its own key.
            .overlay(alignment: .bottom) {
                if let media = ctx.mediaState, media.isDownloading, !(content is FlareFileContent) {
                    ProgressView(value: Double(min(max(media.progressPct, 0), 100)), total: 100)
                        .tint(.white)
                        .padding(FlareSizes.spacingSm)
                }
            }
    }

    private var action: (() -> Void)? {
        guard let handler = ctx.onMediaAction else { return nil }
        return { handler(content) }
    }

    /// The host's download handler for this body, as the download key of the image preview or the video player.
    private var download: (() -> Void)? {
        guard let onMediaDownload else { return nil }
        return { onMediaDownload(content) }
    }

    /// The host's reveal handler for this body: the folder key of the file card, the preview and the player.
    private var reveal: (() -> Void)? {
        guard let onMediaReveal else { return nil }
        return { onMediaReveal(content) }
    }

    /// Where the viewer finds this body's state: the message in a list; outside one, the body's own session holds
    /// only this body's.
    private var downloadId: String { messageId ?? "" }

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
            if surface == .bareMedia, c.mentions.isEmpty, flareLoneEmojiPackKey(c.text) == nil,
               let emoji = flareSingleEmoji(c.text) {
                // One emoji on its own is drawn large, as an emoji message is.
                EmojiMessageView(emoji: emoji)
            } else {
                TextMessageView(text: c.text, isSelf: ctx.isSelf, mentions: c.mentions, onLinkTap: onOpenLink)
            }
        case let c as FlareRichTextContent:
            RichTextMessageView(docJson: c.docJson, plainText: c.plainText, title: c.title, isSelf: ctx.isSelf,
                                onLinkTap: onOpenLink)
        case let c as FlareEmojiContent:
            EmojiMessageView(emoji: c.emoji, onTap: action)
        case let c as FlareStickerContent:
            StickerMessageView(url: c.url, packageId: c.packageId, stickerId: c.stickerId,
                width: c.width, height: c.height, onTap: action)
        case let c as FlareImageContent:
            let picture = flarePictureSource(c)
            let frame = Self.imageSize(c)
            ImageMessageView(src: picture.src, width: frame.width, height: frame.height, alt: c.alt,
                             onTap: action ?? session.map { session in
                                 { session.open(c, messageId: messageId, index: 0, gallery: gallery, onDownload: download,
                                                onReveal: reveal, downloadId: downloadId) }
                             },
                             allowLocalFile: picture.local)
        case let c as FlareImageGroupContent:
            ImageGroupMessageView(images: c.images, description: c.description, isSelf: ctx.isSelf,
                                  onOpen: albumOpener(c, session: session))
        case let c as FlareVideoContent:
            VideoMessageView(poster: c.poster, duration: c.durationSec > 0 ? Self.duration(c.durationSec) : "",
                             onPlay: action ?? session.map { session in
                                 { session.present(c, onDownload: download, onReveal: reveal, downloadId: downloadId) }
                             })
        case let c as FlareAudioContent:
            if let action {
                VoiceMessageView(seconds: c.durationSec, onPlay: action)
            } else if let session {
                FlareVoiceMessageBody(content: c, id: messageId ?? c.url, playback: session.voice)
            } else {
                VoiceMessageView(seconds: c.durationSec)
            }
        case let c as FlareFileContent:
            FileMessageView(name: c.name, size: Self.bytes(c.sizeBytes), ext: Self.fileExtension(c.name),
                            onOpen: action ?? onOpenFile.map { open in { open(c) } },
                            onDownload: download, downloadState: ctx.mediaState, onReveal: reveal)
        case let c as FlareLocationContent:
            LocationMessageView(title: c.name, address: c.address, latitude: c.latitude, longitude: c.longitude,
                                snapshotUrl: c.snapshotUrl, provider: c.provider,
                                onOpen: onLocationOpen.map { open in { open(c) } } ?? action)
        case let c as FlareCardContent:
            ContactMessageView(name: c.title, subtitle: c.subtitle, avatarUrl: c.imageURL, userId: c.userId,
                               onOpen: Self.cardOpener(c, onCardOpen: onCardOpen, onMediaAction: ctx.onMediaAction))
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

    /// A contact card's tap: `onCardOpen` with the person the card shares, else the host's media handler with the
    /// card; nil without either, and `onCardOpen` alone does not make a card that names no one tappable.
    static func cardOpener(_ card: FlareCardContent, onCardOpen: ((String) -> Void)?,
                           onMediaAction: ((FlareMessageContent) -> Void)?) -> ((String) -> Void)? {
        if let onCardOpen, let userId = card.userId, !userId.isEmpty { return { _ in onCardOpen(userId) } }
        guard let onMediaAction else { return nil }
        return { _ in onMediaAction(card) }
    }

    /// The timeline's picture frame: the image width, and the height its aspect gives when the host knows its size —
    /// kept between a strip and a square — else 4:3. The same rule as the other kits.
    static func imageSize(_ image: FlareImageContent) -> CGSize {
        let width: CGFloat = 240
        guard let w = image.width, let h = image.height, w > 0, h > 0 else { return CGSize(width: width, height: 180) }
        return CGSize(width: width, height: min(max(width * CGFloat(h / w), 48), 240))
    }

    /// A file's type as its card names it: the name's extension, upper-cased; nil without one.
    static func fileExtension(_ name: String) -> String? {
        let ext = (name as NSString).pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        return ext.isEmpty || ext.count > 8 ? nil : ext.uppercased()
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

/// The kit card shell: the card surface of the kit's own card bodies (`spec/message-surface-vectors.json`
/// rules.cardShell) — radius lg, the primary background and a hairline, at most ``FlareSizes/componentRichCardWidth``
/// wide — with the quote slot inside it at its top. `padded` gives a body without inner padding the shell's md.
struct FlareMessageCardShell<Content: View>: View {
    let padded: Bool
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageCardQuote) private var quote

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusLg, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            if quote != nil {
                FlareMessageCardQuoteSlot()
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .padding(.top, FlareSizes.spacingMd)
                    .padding(.bottom, padded ? 0 : FlareSizes.spacingSm)
            }
            content
                .environment(\.flareInMessageCardShell, true)
                .padding(padded ? FlareSizes.spacingMd : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // One width for every card: richCardWidth, or the column when that is narrower.
        .frame(maxWidth: FlareSizes.componentRichCardWidth, alignment: .leading)
        .background(shape.fill(colors.bgPrimary))
        .clipShape(shape)
        // Decoration only: a stroke over the body must not take the taps meant for its controls.
        .overlay(shape.stroke(colors.borderSecondary, lineWidth: 1).allowsHitTesting(false))
        .fixedSize(horizontal: false, vertical: true)
    }
}
