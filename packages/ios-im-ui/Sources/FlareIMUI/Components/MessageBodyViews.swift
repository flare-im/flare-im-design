import SwiftUI

// Standalone, presentational per-type message bodies (clean params, no SDK /
// media coupling) — drop any single one into your own layout. Interaction is
// surfaced as closures: the host owns the URLs/handlers. The SDK-driven
// dispatcher `MessageContentView` stays the batteries-included path.
// Spec: Message/MessageContentView content types, decomposed into components.

private struct MessageBodyForegroundKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}
extension EnvironmentValues {
    var flareMessageBodyForeground: Color? {
        get { self[MessageBodyForegroundKey.self] }
        set { self[MessageBodyForegroundKey.self] = newValue }
    }
}

private extension View {
    /// Attach an optional tap handler without changing layout.
    @ViewBuilder func onTapIf(_ action: (() -> Void)?) -> some View {
        if let action {
            Button(action: action) {
                self.frame(minHeight: FlareSizes.touchTarget).contentShape(Rectangle())
            }.buttonStyle(.plain)
        } else { self }
    }
}

extension View {
    /// Text selection when `enabled`: the text and rich-text bodies share it.
    @ViewBuilder func textSelectableIf(_ enabled: Bool) -> some View {
        if enabled { self.textSelection(.enabled) } else { self }
    }
}

/// A network image (host-provided URL) with a placeholder fallback.
struct NetImage<Placeholder: View>: View {
    let url: String?
    @ViewBuilder let placeholder: () -> Placeholder
    var body: some View {
        if let s = url, !s.isEmpty, let u = URL(string: s) {
            AsyncImage(url: u) { image in
                image.resizable().scaledToFill()
            } placeholder: { placeholder() }
        } else {
            placeholder()
        }
    }
}

/// Linkify bare URLs into an AttributedString (built incrementally so ranges
/// stay correct even with repeated links).
private func linkified(_ text: String, linkColor: Color) -> AttributedString {
    var result = AttributedString("")
    let ns = text as NSString
    guard let re = try? NSRegularExpression(
        pattern: "((?:https?://)?[a-z0-9.-]+\\.[a-z]{2,}(?:/\\S*)?)", options: .caseInsensitive)
    else { return AttributedString(text) }
    var last = 0
    re.enumerateMatches(in: text, range: NSRange(location: 0, length: ns.length)) { m, _, _ in
        guard let m else { return }
        if m.range.location > last {
            result += AttributedString(ns.substring(with: NSRange(location: last, length: m.range.location - last)))
        }
        let href = ns.substring(with: m.range)
        var link = AttributedString(href)
        link.link = URL(string: href.hasPrefix("http") ? href : "https://\(href)")
        link.foregroundColor = linkColor
        link.underlineStyle = .single
        result += link
        last = m.range.location + m.range.length
    }
    if last < ns.length { result += AttributedString(ns.substring(from: last)) }
    return result
}

/// text — linkifies bare URLs, draws the emoji-pack tokens it knows, and reports `onLinkTap`;
/// `selectable` allows copy.
///
/// A tapped link goes to `onLinkTap`. Without one the body opens a web address itself (`http` and
/// `https`, after ``safeExternalURL(_:)``) rather than swallowing the tap; any other scheme opens
/// nothing (``linkTap(_:hostHandles:)``).
///
/// An emoji-pack token (`[key]`) whose key the bundled catalog has is drawn inline at text size, as
/// the pack image's first frame; a token the catalog does not know stays the text it was written as.
///
/// `mentions` emphasize mention runs, which read as names, not links: in an incoming bubble the
/// primary text colour at weight 500, and a mention of the reader or of everyone also sits on the
/// selected ground (small radius, 2pt past the run on each side; square and flush before iOS 18 and
/// macOS 15, where Text cannot draw a rounded run); in an outgoing bubble the bubble foreground at
/// weight 600 with no ground. Without mentions the text renders exactly as it always has.
public struct TextMessageView: View {
    private let text: String
    private let isSelf: Bool
    private let selectable: Bool
    private let mentions: [FlareTextMentionSpan]
    private let onLinkTap: ((String) -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    @ObservedObject private var emojiCatalog = FlareEmojiStickerCatalog.shared
    public init(text: String, isSelf: Bool = false, selectable: Bool = false,
                mentions: [FlareTextMentionSpan] = [], onLinkTap: ((String) -> Void)? = nil) {
        self.text = text
        self.isSelf = isSelf
        self.selectable = selectable
        self.mentions = mentions
        self.onLinkTap = onLinkTap
    }
    @ViewBuilder public var body: some View {
        if let loneEmoji = flareLoneEmojiPackKey(text) {
            FlareEmojiPackMessage(emoji: loneEmoji, isSelf: isSelf)
        } else {
            let colors = FlareColors.of(scheme, brand: flareBrandTheme)
            let segments = mentions.isEmpty ? [] : Self.segments(text, mentions: mentions)
            // 消息正文取 message 角色 —— 四端同一个出处(15/1.45)。
            // lineSpacing 是额外行距而不是倍数,4pt 在 15pt 上正是 1.45 的那一档。
            let messageSize = FlareTextRoles.message.fontSize * textScale
            textContent(segments, colors: colors, fontSize: messageSize)
                .font(.system(size: messageSize))
                .lineSpacing(4)
                .foregroundColor(isSelf ? colors.messageOutgoingForeground : colors.messageIncomingForeground)
                .textSelectableIf(selectable)
                .environment(\.openURL, OpenURLAction { url in
                    switch Self.linkTap(url.absoluteString, hostHandles: onLinkTap != nil) {
                    case .host(let raw):
                        onLinkTap?(raw)
                        return .handled
                    case .system(let safe):
                        return .systemAction(safe)
                    case .ignored:
                        return .handled
                    }
                })
        }
    }

    /// What a tap on a link inside the body does.
    enum LinkTap: Equatable {
        /// The host was given the raw URL.
        case host(String)
        /// No host handler: the platform opens this web address, which passed ``safeExternalURL(_:)``.
        case system(URL)
        /// No host handler and no web address: nothing opens. Message text is written by other people,
        /// so a `javascript:`, `data:` or `file:` link is never followed.
        case ignored
    }

    /// Where a tapped link goes: to the host when it takes links, else to the platform opener for a
    /// web address, and nowhere for any other scheme.
    static func linkTap(_ url: String, hostHandles: Bool) -> LinkTap {
        if hostHandles { return .host(url) }
        guard let safe = safeExternalURL(url), let parsed = URL(string: safe) else { return .ignored }
        return .system(parsed)
    }

    @ViewBuilder
    private func textContent(_ segments: [Segment], colors: FlareColors, fontSize: CGFloat) -> some View {
        let linkColor = isSelf ? colors.messageOutgoingForeground : colors.primary
        let inlineEmoji = flareHasInlineEmoji(text)
        if !segments.contains(where: { $0.mention != nil }) {
            Self.plainText(text, linkColor: linkColor, fontSize: fontSize)
        } else if Self.drawsRoundedHighlight(segments, outgoing: isSelf) {
            if #available(iOS 18.0, macOS 15.0, *) {
                Self.highlightedText(segments, colors: colors, fontSize: fontSize, linkColor: linkColor)
                    .textRenderer(FlareMentionHighlightRenderer(fill: colors.bgSelected))
            } else if inlineEmoji {
                Self.runsText(segments, outgoing: isSelf, colors: colors, fontSize: fontSize,
                              linkColor: linkColor, flatHighlight: true)
            } else {
                Text(Self.attributed(segments, outgoing: isSelf, colors: colors, fontSize: fontSize,
                                     linkColor: linkColor, flatHighlight: true))
            }
        } else if inlineEmoji {
            Self.runsText(segments, outgoing: isSelf, colors: colors, fontSize: fontSize,
                          linkColor: linkColor, flatHighlight: false)
        } else {
            Text(Self.attributed(segments, outgoing: isSelf, colors: colors, fontSize: fontSize,
                                 linkColor: linkColor, flatHighlight: false))
        }
    }

    /// One run of the body: plain text (linkified when drawn) or a mention.
    struct Segment: Equatable {
        let text: String
        let mention: FlareTextMentionSpan?
    }

    /// Splits `text` at the mention spans that fit it: inside the text's UTF-16 range, on
    /// Unicode-scalar boundaries, each starting at or after the end of the one kept before it.
    /// Any other span is ignored and its text stays plain.
    static func segments(_ text: String, mentions: [FlareTextMentionSpan]) -> [Segment] {
        let scalars = text.unicodeScalars
        let units = text.utf16.count
        var result: [Segment] = []
        var cursor = text.startIndex
        var cursorOffset = 0
        func piece(_ range: Range<String.Index>) -> String {
            String(String.UnicodeScalarView(scalars[range]))
        }
        for span in mentions.sorted(by: { $0.start < $1.start }) {
            guard span.start >= cursorOffset, span.length > 0, span.length <= units - span.start else { continue }
            let from = String.Index(utf16Offset: span.start, in: text)
            let to = String.Index(utf16Offset: span.start + span.length, in: text)
            guard from.samePosition(in: scalars) != nil, to.samePosition(in: scalars) != nil else { continue }
            if from > cursor { result.append(Segment(text: piece(cursor..<from), mention: nil)) }
            result.append(Segment(text: piece(from..<to), mention: span))
            cursor = to
            cursorOffset = span.start + span.length
        }
        if cursor < text.endIndex { result.append(Segment(text: piece(cursor..<text.endIndex), mention: nil)) }
        return result
    }

    /// Whether the body sets a mention on the selected ground: incoming bubbles, for a mention of the
    /// reader or of everyone.
    static func drawsRoundedHighlight(_ segments: [Segment], outgoing: Bool) -> Bool {
        !outgoing && segments.contains { $0.mention?.highlighted == true }
    }

    /// A mention run's look: weight 500 in the primary text colour (incoming), or weight 600 in the
    /// bubble's own foreground (outgoing: no colour of its own).
    static func mentionRun(_ text: String, outgoing: Bool, colors: FlareColors, fontSize: CGFloat) -> AttributedString {
        var run = AttributedString(text)
        run.font = .system(size: fontSize, weight: outgoing ? .semibold : .medium)
        if !outgoing { run.foregroundColor = colors.primaryText }
        return run
    }

    /// The body as one attributed string; `flatHighlight` sets a highlighted incoming mention's ground
    /// as a run background (the form Text draws before iOS 18 and macOS 15).
    static func attributed(_ segments: [Segment], outgoing: Bool, colors: FlareColors, fontSize: CGFloat,
                           linkColor: Color, flatHighlight: Bool) -> AttributedString {
        segments.reduce(into: AttributedString()) { result, segment in
            guard let mention = segment.mention else {
                result += linkified(segment.text, linkColor: linkColor)
                return
            }
            var run = mentionRun(segment.text, outgoing: outgoing, colors: colors, fontSize: fontSize)
            if flatHighlight && !outgoing && mention.highlighted { run.backgroundColor = colors.bgSelected }
            result += run
        }
    }

    /// The body as Text runs, the highlighted mentions marked for ``FlareMentionHighlightRenderer``.
    @available(iOS 18.0, macOS 15.0, *)
    static func highlightedText(_ segments: [Segment], colors: FlareColors, fontSize: CGFloat, linkColor: Color) -> Text {
        segments.reduce(Text(verbatim: "")) { text, segment in
            guard let mention = segment.mention else {
                return text + plainText(segment.text, linkColor: linkColor, fontSize: fontSize)
            }
            let run = Text(mentionRun(segment.text, outgoing: false, colors: colors, fontSize: fontSize))
            return text + (mention.highlighted ? run.customAttribute(FlareMentionHighlight()) : run)
        }
    }

    /// The body as Text runs on a system that cannot mark runs for a renderer: the same look as
    /// ``attributed(_:outgoing:colors:fontSize:linkColor:flatHighlight:)``, built by concatenation so the
    /// plain runs can carry inline emoji images (an AttributedString cannot).
    static func runsText(_ segments: [Segment], outgoing: Bool, colors: FlareColors, fontSize: CGFloat,
                         linkColor: Color, flatHighlight: Bool) -> Text {
        segments.reduce(Text(verbatim: "")) { text, segment in
            guard let mention = segment.mention else {
                return text + plainText(segment.text, linkColor: linkColor, fontSize: fontSize)
            }
            var run = mentionRun(segment.text, outgoing: outgoing, colors: colors, fontSize: fontSize)
            if flatHighlight && !outgoing && mention.highlighted { run.backgroundColor = colors.bgSelected }
            return text + Text(run)
        }
    }

    /// One plain run drawn: the emoji-pack tokens the catalog knows become inline images at text size,
    /// everything around them stays linkified text.
    static func plainText(_ text: String, linkColor: Color, fontSize: CGFloat) -> Text {
        let runs = flareInlineEmojiRuns(text)
        guard runs.contains(where: { if case .emoji = $0 { return true }; return false }) else {
            return Text(linkified(text, linkColor: linkColor))
        }
        return runs.reduce(Text(verbatim: "")) { result, run in
            switch run {
            case .text(let plain):
                return result + Text(linkified(plain, linkColor: linkColor))
            case .emoji(let key):
                guard let image = flareInlineEmojiImage(key: key, side: fontSize * 1.2) else {
                    return result + Text(verbatim: "[\(key)]")
                }
                return result + Text(Image(flarePlatformImage: image))
            }
        }
    }
}

/// Marks a Text run as a highlighted mention.
@available(iOS 18.0, macOS 15.0, *)
struct FlareMentionHighlight: TextAttribute {}

/// Draws the selected ground behind highlighted mention runs — the small radius, 2pt past the run
/// on each side — then the text over it.
@available(iOS 18.0, macOS 15.0, *)
struct FlareMentionHighlightRenderer: TextRenderer {
    /// How far the ground reaches past the run on each side.
    static let padding: CGFloat = 2
    let fill: Color

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let ground = RoundedRectangle(cornerRadius: FlareSizes.radiusSm, style: .continuous)
        for line in layout {
            for run in line where run[FlareMentionHighlight.self] != nil {
                let bounds = run.typographicBounds.rect.insetBy(dx: -Self.padding, dy: 0)
                context.fill(ground.path(in: bounds), with: .color(fill))
            }
        }
        for line in layout { context.draw(line) }
    }
}

/// image — a rounded thumbnail named by its description (else 图片); emits `onTap`.
public struct ImageMessageView: View {
    private let src: String?
    private let width: CGFloat
    private let height: CGFloat
    private let alt: String?
    private let onTap: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(src: String? = nil, width: CGFloat = 132, height: CGFloat = 92,
                alt: String? = nil, onTap: (() -> Void)? = nil) {
        self.src = src; self.width = width; self.height = height; self.alt = alt; self.onTap = onTap
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        NetImage(url: src) {
            colors.bgTertiary.overlay(
                Image(systemName: "photo").font(.system(size: 26 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary))
        }
        .frame(width: width, height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusCard, style: .continuous))
        .accessibilityElement(children: .ignore)
        .onTapIf(onTap)
        .accessibilityLabel(alt?.isEmpty == false ? alt! : strings.messageImage)
    }
}

/// video — thumbnail with play overlay + duration badge, named by its description (else 视频) with
/// the duration as its value; emits `onPlay`.
public struct VideoMessageView: View {
    private let poster: String?
    private let duration: String
    private let alt: String?
    private let onPlay: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(poster: String? = nil, duration: String = "00:00", alt: String? = nil,
                onPlay: (() -> Void)? = nil) {
        self.poster = poster; self.duration = duration; self.alt = alt; self.onPlay = onPlay
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        ZStack {
            NetImage(url: poster) {
                colors.bgTertiary.overlay(
                    Image(systemName: "video").font(.system(size: FlareSizes.fontSize5xl * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary).opacity(0.5))
            }
            Color.black.opacity(0.28)
            Image(systemName: "play.fill").font(.system(size: 34 * textScale)).foregroundColor(.white)
                .accessibilityHidden(true)
            VStack { Spacer(); HStack { Spacer()
                Text(duration).font(.system(size: FlareSizes.fontSize2xs * textScale)).foregroundColor(.white)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Color.black.opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: 5))
            } }.padding(6)
        }
        .frame(width: 148, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusCard, style: .continuous))
        .accessibilityElement(children: .ignore)
        .onTapIf(onPlay)
        .accessibilityLabel(alt?.isEmpty == false ? alt! : strings.messageVideo)
        .accessibilityValue(duration)
    }
}

/// audio / voice — glyph, waveform and duration; emits `onPlay`.
///
/// The glyph is what a tap does: play, pause while `playing`, or try again when `failed`. While a
/// playback is under way (`elapsedSeconds` set) the time counts down what is left — or up, when the
/// length is unknown (0) — and the waveform fills with what has played; `failed` says the playback
/// failed. With `onPlay` the body is one button named by that action, valued by the seconds shown.
public struct VoiceMessageView: View {
    private let seconds: Int
    private let playing: Bool
    private let elapsedSeconds: Int?
    private let failed: Bool
    private let onPlay: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(seconds: Int = 1, playing: Bool = false, elapsedSeconds: Int? = nil, failed: Bool = false,
                onPlay: (() -> Void)? = nil) {
        self.seconds = seconds; self.playing = playing; self.elapsedSeconds = elapsedSeconds
        self.failed = failed; self.onPlay = onPlay
    }

    private static let bars = 9

    /// The seconds shown: the whole message until a playback starts, then what is left of it; the
    /// seconds played when the length is unknown.
    static func shownSeconds(_ seconds: Int, elapsed: Int?) -> Int {
        let played = max(0, elapsed ?? 0)
        return seconds > 0 ? max(0, seconds - played) : played
    }

    /// The kit icon for what a tap does.
    static func glyph(playing: Bool, failed: Bool) -> String {
        failed ? "refresh" : playing ? "pause" : "play"
    }

    /// How many waveform bars have played; every bar is drawn full until a playback starts, and while
    /// the length is unknown.
    static func playedBars(_ seconds: Int, elapsed: Int?) -> Int {
        guard let elapsed, seconds > 0 else { return bars }
        return min(bars, Int((Double(max(0, elapsed)) / Double(seconds) * Double(bars)).rounded()))
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shown = Self.shownSeconds(seconds, elapsed: elapsedSeconds)
        let played = Self.playedBars(seconds, elapsed: elapsedSeconds)
        HStack(spacing: 8) {
            Image(systemName: flareIconSymbol(Self.glyph(playing: playing, failed: failed)))
                .font(.system(size: 17 * textScale))
                .foregroundColor(bodyForeground ?? (failed ? colors.errorText : playing ? colors.primaryText : colors.textSecondary))
            HStack(spacing: 2) {
                ForEach(1...Self.bars, id: \.self) { n in
                    RoundedRectangle(cornerRadius: 2).fill(bodyForeground ?? colors.primary)
                        .opacity(n <= played ? 1 : 0.4)
                        .frame(width: 2, height: CGFloat(4 + ((n * 5) % 13)))
                }
            }
            Text(failed ? strings.voicePlaybackFailed : "\(shown)\"")
                .font(.system(size: 12 * textScale).monospacedDigit())
                .foregroundColor(bodyForeground ?? (failed ? colors.errorText : colors.textTertiary))
        }
        .accessibilityElement(children: .ignore)
        .onTapIf(onPlay)
        .accessibilityLabel(onPlay == nil ? strings.messageVoice : failed ? strings.retry : playing ? strings.pause : strings.play)
        .accessibilityValue(failed ? strings.voicePlaybackFailed : strings.voiceSeconds(shown))
    }
}

/// file — icon / name / size / ext; emits `onOpen` (card) and `onDownload`.
/// Override the leading [icon] to show a per-file-type glyph.
public struct FileMessageView: View {
    private let name: String
    private let size: String
    private let ext: String?
    private let icon: AnyView?
    private let onOpen: (() -> Void)?
    private let onDownload: (() -> Void)?
    private let downloadLabel: String
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(name: String, size: String = "", ext: String? = nil, icon: AnyView? = nil,
                onOpen: (() -> Void)? = nil, onDownload: (() -> Void)? = nil, downloadLabel: String = "Download") {
        self.name = name; self.size = size; self.ext = ext; self.icon = icon
        self.onOpen = onOpen; self.onDownload = onDownload
        self.downloadLabel = downloadLabel
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let sub = (ext?.isEmpty == false) ? "\(size) · \(ext!)" : size
        HStack(spacing: FlareSizes.spacing2sm) {
            HStack(spacing: FlareSizes.spacingSm) {
                icon ?? AnyView(Image(systemName: "doc").font(.system(size: 20 * textScale)).foregroundColor(bodyForeground ?? colors.primaryText))
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .medium))
                        .foregroundColor(bodyForeground ?? colors.textPrimary).lineLimit(2)
                    Text(sub).font(.system(size: 11 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary)
                }
            }.onTapIf(onOpen)
            if let onDownload {
                Button(action: onDownload) {
                    Image(systemName: "square.and.arrow.down").foregroundColor(bodyForeground ?? colors.textTertiary)
                        .frame(width: FlareSizes.touchTarget, height: FlareSizes.touchTarget)
                }.buttonStyle(.plain).accessibilityLabel(downloadLabel)
            }
        }
        .frame(maxWidth: 300, alignment: .leading)
    }
}

/// location — a map image (or placeholder) over title / address; emits `onOpen`.
public struct LocationMessageView: View {
    private let title: String
    private let address: String
    private let mapImage: String?
    private let onOpen: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(title: String, address: String = "", mapImage: String? = nil, onOpen: (() -> Void)? = nil) {
        self.title = title; self.address = address; self.mapImage = mapImage; self.onOpen = onOpen
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 0) {
            NetImage(url: mapImage) {
                colors.bgTertiary.overlay(colors.primary.opacity(0.08)).overlay(
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 22 * textScale)).foregroundColor(bodyForeground ?? colors.primaryText))
            }
            .frame(height: 84).clipped()
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .medium)).foregroundColor(bodyForeground ?? colors.textPrimary)
                Text(address).font(.system(size: 11 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .frame(maxWidth: 264)
        .onTapIf(onOpen)
    }
}

/// contact / business card — avatar (image or pastel initials) + name /
/// subtitle; emits `onOpen`.
public struct ContactMessageView: View {
    private let name: String
    private let subtitle: String?
    private let avatarUrl: String?
    private let onOpen: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(name: String, subtitle: String? = nil, avatarUrl: String? = nil, onOpen: (() -> Void)? = nil) {
        self.name = name; self.subtitle = subtitle; self.avatarUrl = avatarUrl; self.onOpen = onOpen
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let tint = AvatarView.seedTint(name, colors)
        HStack(spacing: 12) {
            NetImage(url: avatarUrl) {
                Text(AvatarView.initials(name)).font(.system(size: 14 * textScale, weight: .semibold))
                    .foregroundColor(tint.fg).frame(maxWidth: .infinity, maxHeight: .infinity).background(tint.bg)
            }
            .frame(width: 44, height: 44).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: FlareSizes.fontSizeXl * textScale, weight: .semibold)).foregroundColor(bodyForeground ?? colors.textPrimary)
                if let s = subtitle, !s.isEmpty {
                    Text(s).font(.system(size: 11 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary).lineLimit(1)
                }
            }
            Image(systemName: "chevron.right").font(.system(size: 16 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary)
        }
        .frame(maxWidth: 300, alignment: .leading)
        .onTapIf(onOpen)
    }
}

/// link card — thumbnail + title + optional description + domain; emits `onOpen`.
public struct LinkCardMessageView: View {
    private let title: String
    private let domain: String
    private let thumb: String?
    private let description: String?
    private let onOpen: (() -> Void)?
    private let icon: AnyView?
    private let descriptionMaxLines: Int?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(title: String, domain: String = "", thumb: String? = nil,
                description: String? = nil, onOpen: (() -> Void)? = nil,
                icon: AnyView? = nil, descriptionMaxLines: Int? = 2) {
        self.title = title; self.domain = domain; self.thumb = thumb
        self.description = description; self.onOpen = onOpen
        self.icon = icon; self.descriptionMaxLines = descriptionMaxLines
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacing2sm) {
            if let icon { icon } else { NetImage(url: thumb) {
                colors.bgTertiary.overlay(
                    Image(systemName: "photo").font(.system(size: 22 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary))
            }
            .frame(width: 48, height: 48).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)) }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .medium)).foregroundColor(bodyForeground ?? colors.textPrimary).lineLimit(2)
                if let d = description, !d.isEmpty {
                    Text(d).font(.system(size: 12 * textScale)).foregroundColor(bodyForeground ?? colors.textSecondary).lineLimit(descriptionMaxLines)
                }
                if !domain.isEmpty { HStack(spacing: 3) {
                    Image(systemName: "link").font(.system(size: 12 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary)
                    Text(domain).font(.system(size: 11 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary).lineLimit(1)
                } }
            }
        }
        .padding(.horizontal, FlareSizes.spacing2sm).padding(.vertical, 8)
        .frame(maxWidth: 300, alignment: .leading)
        .onTapIf(onOpen)
    }
}

/// A vote option for ``VoteMessageView``.
public struct FlareVoteOption: Sendable {
    public let text: String
    public let pct: Int?
    public init(_ text: String, _ pct: Int? = nil) {
        self.text = text
        self.pct = pct
    }
}

/// vote — title over option rows with proportional bars; emits `onSelect`.
public struct VoteMessageView: View {
    private let title: String
    private let options: [FlareVoteOption]
    private let total: String?
    private let onSelect: ((FlareVoteOption, Int) -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(title: String, options: [FlareVoteOption] = [], total: String? = nil,
                onSelect: ((FlareVoteOption, Int) -> Void)? = nil) {
        self.title = title; self.options = options; self.total = total; self.onSelect = onSelect
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar").font(.system(size: 16 * textScale)).foregroundColor(bodyForeground ?? colors.textPrimary)
                Text(title).font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .semibold)).foregroundColor(bodyForeground ?? colors.textPrimary)
            }
            ForEach(Array(options.enumerated()), id: \.offset) { i, o in
                ZStack(alignment: .leading) {
                    (bodyForeground ?? colors.textPrimary).opacity(0.08)
                    if let pct = o.pct { GeometryReader { geo in
                        colors.primary.opacity(0.16)
                            .frame(width: geo.size.width * CGFloat(min(max(pct, 0), 100)) / 100)
                    } }
                    HStack {
                        Text(o.text).font(.system(size: 13 * textScale)).foregroundColor(bodyForeground ?? colors.textPrimary)
                        Spacer()
                        if let pct = o.pct { Text("\(pct)%").font(.system(size: 12 * textScale)).foregroundColor(bodyForeground ?? colors.textSecondary) }
                    }.padding(.horizontal, FlareSizes.spacing2sm)
                }
                .frame(minHeight: FlareSizes.touchTarget)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .onTapIf(onSelect == nil ? nil : { onSelect?(o, i) })
            }
            if let t = total, !t.isEmpty {
                Text(t).font(.system(size: 11 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, FlareSizes.spacing2sm)
        .frame(maxWidth: 300, alignment: .leading)
    }
}

/// task — checkbox + title (struck through when done) + meta; emits `onToggle`.
public struct TaskMessageView: View {
    private let title: String
    private let meta: String?
    private let done: Bool
    private let onToggle: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(title: String, meta: String? = nil, done: Bool = false, onToggle: (() -> Void)? = nil) {
        self.title = title; self.meta = meta; self.done = done; self.onToggle = onToggle
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacing2sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(done ? colors.primary : Color.clear)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(done ? colors.primary : colors.borderPrimary, lineWidth: 1.5)
                if done { Image(systemName: "checkmark").font(.system(size: 11 * textScale, weight: .bold)).foregroundColor(.white) }
            }.frame(width: 20, height: 20).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .medium))
                    .foregroundColor(bodyForeground ?? (done ? colors.textTertiary : colors.textPrimary))
                    .strikethrough(done)
                if let m = meta, !m.isEmpty {
                    Text(m).font(.system(size: 11 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: 300, alignment: .leading)
        .onTapIf(onToggle)
        .accessibilityAddTraits(done ? .isSelected : [])
    }
}

/// sticker — a bare, larger glyph (no bubble); emits `onTap`.
public struct StickerMessageView: View {
    private let emoji: String
    private let url: String?
    private let packageId: String?
    private let stickerId: String?
    private let width: Int?
    private let height: Int?
    private let onTap: (() -> Void)?
    public init(emoji: String = "🐱", url: String? = nil, packageId: String? = nil,
                stickerId: String? = nil, width: Int? = nil, height: Int? = nil,
                onTap: (() -> Void)? = nil) {
        self.emoji = emoji; self.url = url; self.packageId = packageId
        self.stickerId = stickerId; self.width = width; self.height = height; self.onTap = onTap
    }
    public var body: some View {
        Group {
            if !(url ?? "").isEmpty || !(stickerId ?? "").isEmpty {
                FlareStickerPackMessage(stickerId: stickerId ?? "", packageId: packageId,
                    url: url, width: width, height: height)
            } else {
                EmojiMessageView(emoji: emoji)
            }
        }.onTapIf(onTap)
    }
}

/// emoji — a bare, large emoji (no bubble); emits `onTap`.
public struct EmojiMessageView: View {
    private let emoji: String
    private let onTap: (() -> Void)?
    public init(emoji: String = "🎉", onTap: (() -> Void)? = nil) { self.emoji = emoji; self.onTap = onTap }
    public var body: some View { FlareEmojiPackMessage(emoji: emoji).onTapIf(onTap) }
}

/// notification / system — a centered pill.
public struct SystemMessageView: View {
    private let text: String
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareMessageBodyForeground) private var bodyForeground
    public init(text: String) { self.text = text }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Text(text).font(.system(size: 12 * textScale)).foregroundColor(bodyForeground ?? colors.textTertiary)
            .padding(.horizontal, 12).padding(.vertical, 4)
            .background(colors.bgTertiary).clipShape(Capsule())
    }
}
