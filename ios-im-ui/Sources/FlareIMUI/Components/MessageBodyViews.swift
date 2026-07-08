import SwiftUI

// Standalone, presentational per-type message bodies (clean params, no SDK /
// media coupling) — drop any single one into your own layout. Interaction is
// surfaced as closures: the host owns the URLs/handlers. The SDK-driven
// dispatcher `MessageContentView` stays the batteries-included path.
// Spec: Message/MessageContentView content types, decomposed into components.

private struct BubbleCard: ViewModifier {
    let colors: FlareColors
    func body(content: Content) -> some View {
        content
            .background(colors.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(colors.borderSecondary, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

private extension View {
    func bubbleCard(_ colors: FlareColors) -> some View { modifier(BubbleCard(colors: colors)) }
    /// Attach an optional tap handler without changing layout.
    @ViewBuilder func onTapIf(_ action: (() -> Void)?) -> some View {
        if let action {
            self.contentShape(Rectangle()).onTapGesture(perform: action)
        } else { self }
    }
    @ViewBuilder func textSelectableIf(_ enabled: Bool) -> some View {
        if enabled { self.textSelection(.enabled) } else { self }
    }
}

/// A network image (host-provided URL) with a placeholder fallback.
private struct NetImage<Placeholder: View>: View {
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

/// text — linkifies bare URLs and reports `onLinkTap`; `selectable` allows copy.
public struct TextMessageView: View {
    private let text: String
    private let isSelf: Bool
    private let selectable: Bool
    private let onLinkTap: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme
    public init(text: String, isSelf: Bool = false, selectable: Bool = false,
                onLinkTap: ((String) -> Void)? = nil) {
        self.text = text
        self.isSelf = isSelf
        self.selectable = selectable
        self.onLinkTap = onLinkTap
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        Text(linkified(text, linkColor: isSelf ? .white : colors.primary))
            .font(.system(size: FlareSizes.fontSizeXl))
            .lineSpacing(4)
            .foregroundColor(isSelf ? .white : colors.textPrimary)
            .textSelectableIf(selectable)
            .environment(\.openURL, OpenURLAction { url in
                onLinkTap?(url.absoluteString)
                return .handled
            })
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(isSelf ? colors.bubbleSelf : colors.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                isSelf ? nil : RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(colors.borderSecondary, lineWidth: 1)
            )
    }
}

/// image — a rounded thumbnail; emits `onTap`.
public struct ImageMessageView: View {
    private let src: String?
    private let width: CGFloat
    private let height: CGFloat
    private let alt: String?
    private let onTap: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    public init(src: String? = nil, width: CGFloat = 132, height: CGFloat = 92,
                alt: String? = nil, onTap: (() -> Void)? = nil) {
        self.src = src; self.width = width; self.height = height; self.alt = alt; self.onTap = onTap
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        NetImage(url: src) {
            colors.bgTertiary.overlay(
                Image(systemName: "photo").font(.system(size: 26)).foregroundColor(colors.textTertiary))
        }
        .frame(width: width, height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel(alt ?? "")
        .onTapIf(onTap)
    }
}

/// video — thumbnail with play overlay + duration badge; emits `onPlay`.
public struct VideoMessageView: View {
    private let poster: String?
    private let duration: String
    private let alt: String?
    private let onPlay: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    public init(poster: String? = nil, duration: String = "00:00", alt: String? = nil,
                onPlay: (() -> Void)? = nil) {
        self.poster = poster; self.duration = duration; self.alt = alt; self.onPlay = onPlay
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        ZStack {
            NetImage(url: poster) {
                colors.bgTertiary.overlay(
                    Image(systemName: "video").font(.system(size: 24)).foregroundColor(colors.textTertiary).opacity(0.5))
            }
            Color.black.opacity(0.28)
            Image(systemName: "play.fill").font(.system(size: 30)).foregroundColor(.white)
            VStack { Spacer(); HStack { Spacer()
                Text(duration).font(.system(size: 10)).foregroundColor(.white)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Color.black.opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: 5))
            } }.padding(6)
        }
        .frame(width: 148, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel(alt ?? "")
        .onTapIf(onPlay)
    }
}

/// audio / voice — waveform + duration; `playing` drives the look, emits `onPlay`.
public struct VoiceMessageView: View {
    private let seconds: Int
    private let playing: Bool
    private let onPlay: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    public init(seconds: Int = 1, playing: Bool = false, onPlay: (() -> Void)? = nil) {
        self.seconds = seconds; self.playing = playing; self.onPlay = onPlay
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 8) {
            Image(systemName: playing ? "speaker.wave.2" : "play.fill")
                .font(.system(size: 17)).foregroundColor(playing ? colors.primary : colors.textSecondary)
            HStack(spacing: 2) {
                ForEach(1...9, id: \.self) { n in
                    RoundedRectangle(cornerRadius: 2).fill(colors.primary)
                        .frame(width: 2, height: CGFloat(4 + ((n * 5) % 13)))
                }
            }
            Text("\(seconds)\"").font(.system(size: 12)).foregroundColor(colors.textTertiary)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .bubbleCard(colors)
        .onTapIf(onPlay)
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
    @Environment(\.colorScheme) private var scheme
    public init(name: String, size: String = "", ext: String? = nil, icon: AnyView? = nil,
                onOpen: (() -> Void)? = nil, onDownload: (() -> Void)? = nil) {
        self.name = name; self.size = size; self.ext = ext; self.icon = icon
        self.onOpen = onOpen; self.onDownload = onDownload
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        let sub = (ext?.isEmpty == false) ? "\(size) · \(ext!)" : size
        HStack(spacing: 10) {
            icon ?? AnyView(Image(systemName: "folder").font(.system(size: 20)).foregroundColor(colors.primary))
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                    .foregroundColor(colors.textPrimary).lineLimit(1)
                Text(sub).font(.system(size: 11)).foregroundColor(colors.textTertiary)
            }
            Button { onDownload?() } label: {
                Image(systemName: "square.and.arrow.down").font(.system(size: 17)).foregroundColor(colors.textTertiary)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .frame(maxWidth: 300, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .bubbleCard(colors)
        .onTapIf(onOpen)
    }
}

/// location — a map image (or placeholder) over title / address; emits `onOpen`.
public struct LocationMessageView: View {
    private let title: String
    private let address: String
    private let mapImage: String?
    private let onOpen: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    public init(title: String, address: String = "", mapImage: String? = nil, onOpen: (() -> Void)? = nil) {
        self.title = title; self.address = address; self.mapImage = mapImage; self.onOpen = onOpen
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            NetImage(url: mapImage) {
                colors.bgTertiary.overlay(colors.primary.opacity(0.08)).overlay(
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 22)).foregroundColor(colors.primary))
            }
            .frame(height: 84).clipped()
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(colors.textPrimary)
                Text(address).font(.system(size: 11)).foregroundColor(colors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .frame(width: 264)
        .bubbleCard(colors)
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
    @Environment(\.colorScheme) private var scheme
    public init(name: String, subtitle: String? = nil, avatarUrl: String? = nil, onOpen: (() -> Void)? = nil) {
        self.name = name; self.subtitle = subtitle; self.avatarUrl = avatarUrl; self.onOpen = onOpen
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        let tint = AvatarView.seedTint(name)
        HStack(spacing: 12) {
            NetImage(url: avatarUrl) {
                Text(AvatarView.initials(name)).font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint.fg).frame(maxWidth: .infinity, maxHeight: .infinity).background(tint.bg)
            }
            .frame(width: 44, height: 44).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
                if let s = subtitle, !s.isEmpty {
                    Text(s).font(.system(size: 11)).foregroundColor(colors.textTertiary).lineLimit(1)
                }
            }
            Image(systemName: "chevron.right").font(.system(size: 16)).foregroundColor(colors.textTertiary)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .frame(minWidth: 240, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .bubbleCard(colors)
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
    @Environment(\.colorScheme) private var scheme
    public init(title: String, domain: String = "", thumb: String? = nil,
                description: String? = nil, onOpen: (() -> Void)? = nil) {
        self.title = title; self.domain = domain; self.thumb = thumb
        self.description = description; self.onOpen = onOpen
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 10) {
            NetImage(url: thumb) {
                colors.bgTertiary.overlay(
                    Image(systemName: "photo").font(.system(size: 22)).foregroundColor(colors.textTertiary))
            }
            .frame(width: 48, height: 48).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(colors.textPrimary).lineLimit(1)
                if let d = description, !d.isEmpty {
                    Text(d).font(.system(size: 12)).foregroundColor(colors.textSecondary).lineLimit(1)
                }
                HStack(spacing: 3) {
                    Image(systemName: "link").font(.system(size: 12)).foregroundColor(colors.textTertiary)
                    Text(domain).font(.system(size: 11)).foregroundColor(colors.textTertiary).lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: 300, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .bubbleCard(colors)
        .onTapIf(onOpen)
    }
}

/// A vote option for ``VoteMessageView``.
public struct FlareVoteOption: Sendable {
    public let text: String
    public let pct: Int
    public init(_ text: String, _ pct: Int) {
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
    @Environment(\.colorScheme) private var scheme
    public init(title: String, options: [FlareVoteOption] = [], total: String? = nil,
                onSelect: ((FlareVoteOption, Int) -> Void)? = nil) {
        self.title = title; self.options = options; self.total = total; self.onSelect = onSelect
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar").font(.system(size: 16)).foregroundColor(colors.textPrimary)
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(colors.textPrimary)
            }
            ForEach(Array(options.enumerated()), id: \.offset) { i, o in
                ZStack(alignment: .leading) {
                    colors.bgSecondary
                    GeometryReader { geo in
                        colors.primary.opacity(0.16)
                            .frame(width: geo.size.width * CGFloat(min(max(o.pct, 0), 100)) / 100)
                    }
                    HStack {
                        Text(o.text).font(.system(size: 13)).foregroundColor(colors.textPrimary)
                        Spacer()
                        Text("\(o.pct)%").font(.system(size: 12)).foregroundColor(colors.textSecondary)
                    }.padding(.horizontal, 10)
                }
                .frame(height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .onTapIf(onSelect == nil ? nil : { onSelect?(o, i) })
            }
            if let t = total, !t.isEmpty {
                Text(t).font(.system(size: 11)).foregroundColor(colors.textTertiary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(minWidth: 220, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .bubbleCard(colors)
    }
}

/// task — checkbox + title (struck through when done) + meta; emits `onToggle`.
public struct TaskMessageView: View {
    private let title: String
    private let meta: String?
    private let done: Bool
    private let onToggle: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    public init(title: String, meta: String? = nil, done: Bool = false, onToggle: (() -> Void)? = nil) {
        self.title = title; self.meta = meta; self.done = done; self.onToggle = onToggle
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(done ? colors.primary : Color.clear)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(done ? colors.primary : colors.borderPrimary, lineWidth: 1.5)
                if done { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white) }
            }.frame(width: 20, height: 20).onTapIf(onToggle)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                    .foregroundColor(done ? colors.textTertiary : colors.textPrimary)
                    .strikethrough(done)
                if let m = meta, !m.isEmpty {
                    Text(m).font(.system(size: 11)).foregroundColor(colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .frame(minWidth: 220, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .bubbleCard(colors)
    }
}

/// sticker — a bare, larger glyph (no bubble); emits `onTap`.
public struct StickerMessageView: View {
    private let emoji: String
    private let onTap: (() -> Void)?
    public init(emoji: String = "🐱", onTap: (() -> Void)? = nil) { self.emoji = emoji; self.onTap = onTap }
    public var body: some View { Text(emoji).font(.system(size: 72)).onTapIf(onTap) }
}

/// emoji — a bare, large emoji (no bubble); emits `onTap`.
public struct EmojiMessageView: View {
    private let emoji: String
    private let onTap: (() -> Void)?
    public init(emoji: String = "🎉", onTap: (() -> Void)? = nil) { self.emoji = emoji; self.onTap = onTap }
    public var body: some View { Text(emoji).font(.system(size: 40)).onTapIf(onTap) }
}

/// notification / system — a centered pill.
public struct SystemMessageView: View {
    private let text: String
    @Environment(\.colorScheme) private var scheme
    public init(text: String) { self.text = text }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        Text(text).font(.system(size: 12)).foregroundColor(colors.textTertiary)
            .padding(.horizontal, 12).padding(.vertical, 4)
            .background(colors.bgTertiary).clipShape(Capsule())
    }
}
