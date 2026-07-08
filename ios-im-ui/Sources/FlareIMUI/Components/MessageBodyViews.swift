import SwiftUI

// Standalone, presentational per-type message bodies (clean params, no SDK /
// media coupling) — drop any single one into your own layout. The SDK-driven
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
}

/// text — a plain text bubble (self flips to the brand-purple side).
public struct TextMessageView: View {
    private let text: String
    private let isSelf: Bool
    @Environment(\.colorScheme) private var scheme
    public init(text: String, isSelf: Bool = false) {
        self.text = text
        self.isSelf = isSelf
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        Text(text)
            .font(.system(size: FlareSizes.fontSizeXl))
            .lineSpacing(4)
            .foregroundColor(isSelf ? .white : colors.textPrimary)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(isSelf ? colors.bubbleSelf : colors.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                isSelf ? nil : RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(colors.borderSecondary, lineWidth: 1)
            )
    }
}

/// image — a rounded thumbnail placeholder.
public struct ImageMessageView: View {
    private let width: CGFloat
    private let height: CGFloat
    @Environment(\.colorScheme) private var scheme
    public init(width: CGFloat = 132, height: CGFloat = 92) {
        self.width = width
        self.height = height
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        colors.bgTertiary
            .frame(width: width, height: height)
            .overlay(Image(systemName: "photo").font(.system(size: 26)).foregroundColor(colors.textTertiary))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// video — a thumbnail with a play overlay and duration badge.
public struct VideoMessageView: View {
    private let duration: String
    @Environment(\.colorScheme) private var scheme
    public init(duration: String = "00:00") { self.duration = duration }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        ZStack {
            colors.bgTertiary
            Image(systemName: "video").font(.system(size: 24)).foregroundColor(colors.textTertiary).opacity(0.5)
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
    }
}

/// audio / voice — a compact bubble with a waveform and duration.
public struct VoiceMessageView: View {
    private let seconds: Int
    @Environment(\.colorScheme) private var scheme
    public init(seconds: Int = 1) { self.seconds = seconds }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 8) {
            Image(systemName: "speaker.wave.2").font(.system(size: 17)).foregroundColor(colors.textSecondary)
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
    }
}

/// file — a file card with name / size / ext and a download affordance.
public struct FileMessageView: View {
    private let name: String
    private let size: String
    private let ext: String?
    @Environment(\.colorScheme) private var scheme
    public init(name: String, size: String = "", ext: String? = nil) {
        self.name = name
        self.size = size
        self.ext = ext
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        let sub = (ext?.isEmpty == false) ? "\(size) · \(ext!)" : size
        HStack(spacing: 10) {
            Image(systemName: "folder").font(.system(size: 20)).foregroundColor(colors.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                    .foregroundColor(colors.textPrimary).lineLimit(1)
                Text(sub).font(.system(size: 11)).foregroundColor(colors.textTertiary)
            }
            Image(systemName: "square.and.arrow.down").font(.system(size: 17)).foregroundColor(colors.textTertiary)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .frame(maxWidth: 300, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .bubbleCard(colors)
    }
}

/// location — a map placeholder over a title / address.
public struct LocationMessageView: View {
    private let title: String
    private let address: String
    @Environment(\.colorScheme) private var scheme
    public init(title: String, address: String = "") {
        self.title = title
        self.address = address
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            colors.bgTertiary.overlay(colors.primary.opacity(0.08))
                .frame(height: 84)
                .overlay(Image(systemName: "mappin.and.ellipse").font(.system(size: 22)).foregroundColor(colors.primary))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(colors.textPrimary)
                Text(address).font(.system(size: 11)).foregroundColor(colors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .frame(width: 264)
        .bubbleCard(colors)
    }
}

/// contact / business card — pastel avatar + name / id.
public struct ContactMessageView: View {
    private let name: String
    private let flareId: String?
    @Environment(\.colorScheme) private var scheme
    public init(name: String, flareId: String? = nil) {
        self.name = name
        self.flareId = flareId
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        let tint = AvatarView.seedTint(name)
        HStack(spacing: 12) {
            Text(AvatarView.initials(name)).font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint.fg).frame(width: 44, height: 44)
                .background(tint.bg).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
                if let id = flareId, !id.isEmpty {
                    Text("Flare ID: \(id)").font(.system(size: 11)).foregroundColor(colors.textTertiary)
                }
            }
            Image(systemName: "chevron.right").font(.system(size: 16)).foregroundColor(colors.textTertiary)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .frame(minWidth: 240, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .bubbleCard(colors)
    }
}

/// link card — thumbnail + title + domain.
public struct LinkCardMessageView: View {
    private let title: String
    private let domain: String
    @Environment(\.colorScheme) private var scheme
    public init(title: String, domain: String = "") {
        self.title = title
        self.domain = domain
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 10) {
            colors.bgTertiary.frame(width: 48, height: 48)
                .overlay(Image(systemName: "photo").font(.system(size: 22)).foregroundColor(colors.textTertiary))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(colors.textPrimary).lineLimit(1)
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

/// vote — a title over option rows with proportional bars.
public struct VoteMessageView: View {
    private let title: String
    private let options: [FlareVoteOption]
    @Environment(\.colorScheme) private var scheme
    public init(title: String, options: [FlareVoteOption] = []) {
        self.title = title
        self.options = options
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar").font(.system(size: 16)).foregroundColor(colors.textPrimary)
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(colors.textPrimary)
            }
            ForEach(Array(options.enumerated()), id: \.offset) { _, o in
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
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(minWidth: 220, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .bubbleCard(colors)
    }
}

/// task — checkbox + title (struck through when done) + meta.
public struct TaskMessageView: View {
    private let title: String
    private let meta: String?
    private let done: Bool
    @Environment(\.colorScheme) private var scheme
    public init(title: String, meta: String? = nil, done: Bool = false) {
        self.title = title
        self.meta = meta
        self.done = done
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(done ? colors.primary : Color.clear)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(done ? colors.primary : colors.borderPrimary, lineWidth: 1.5)
                if done { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white) }
            }.frame(width: 20, height: 20)
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

/// sticker — a bare, larger glyph (no bubble).
public struct StickerMessageView: View {
    private let emoji: String
    public init(emoji: String = "🐱") { self.emoji = emoji }
    public var body: some View { Text(emoji).font(.system(size: 72)) }
}

/// emoji — a bare, large emoji (no bubble).
public struct EmojiMessageView: View {
    private let emoji: String
    public init(emoji: String = "🎉") { self.emoji = emoji }
    public var body: some View { Text(emoji).font(.system(size: 40)) }
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
