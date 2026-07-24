import SwiftUI

// MARK: - RedPacketCard

/// Red packet card — festive lucky-money envelope with open / claimed states.
/// Spec: Message/RedPacketCard (`RedPacketCardView`).
public struct RedPacketCardView: View {
    private let blessing: String
    private let amount: String?
    private let opened: Bool
    private let finished: Bool
    private let onOpen: (() -> Void)?

    public init(blessing: String, amount: String? = nil, opened: Bool = false,
                finished: Bool = false, onOpen: (() -> Void)? = nil) {
        self.blessing = blessing; self.amount = amount; self.opened = opened
        self.finished = finished; self.onOpen = onOpen
    }

    private let gold = Color(.sRGB, red: 1.0, green: 0.831, blue: 0.463, opacity: 1)

    public var body: some View {
        Button { onOpen?() } label: { card }
            .buttonStyle(.plain)
            .disabled(finished)
    }

    private var card: some View {
        HStack(spacing: FlareSizes.spacingMd) {
            ZStack {
                Circle().fill(
                    RadialGradient(colors: [Color(.sRGB, red: 1.0, green: 0.914, blue: 0.722, opacity: 1),
                                            Color(.sRGB, red: 0.965, green: 0.769, blue: 0.325, opacity: 1)],
                                   center: .center, startRadius: 2, endRadius: 24))
                    .frame(width: 42, height: 42)
                Image(systemName: "gift.fill").font(.system(size: 18))
                    .foregroundColor(Color(.sRGB, red: 0.784, green: 0.161, blue: 0.122, opacity: 1))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(blessing).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                status
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 248)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(
                LinearGradient(colors: [Color(.sRGB, red: 0.941, green: 0.314, blue: 0.235, opacity: 1),
                                        Color(.sRGB, red: 0.886, green: 0.231, blue: 0.180, opacity: 1),
                                        Color(.sRGB, red: 0.784, green: 0.161, blue: 0.122, opacity: 1)],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            Text("Flare 红包").font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                .padding(10),
            alignment: .bottomTrailing
        )
        .saturation(finished ? 0.55 : 1)
        .brightness(finished ? -0.03 : 0)
        .shadow(color: Color(.sRGB, red: 0.784, green: 0.161, blue: 0.122, opacity: 1).opacity(0.35), radius: 16, y: 8)
    }

    @ViewBuilder
    private var status: some View {
        if opened, let amount {
            HStack(spacing: 4) {
                Text("已领取 · ").font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
                    + Text(amount).font(.system(size: 12, weight: .semibold)).foregroundColor(gold)
            }
        } else if finished {
            Text("已被抢光").font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
        } else {
            Text("点击拆开").font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
        }
    }
}

// MARK: - SlashCommandMenu

/// Slash command menu — filterable "/command" palette for the composer.
/// Spec: Composer/SlashCommandMenu (`SlashCommandMenuView`).
public struct SlashCommandMenuView: View {
    private let commands: [SlashCommand]
    private let query: String
    private let onSelect: ((SlashCommand) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(commands: [SlashCommand], query: String = "",
                onSelect: ((SlashCommand) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.commands = commands; self.query = query; self.onSelect = onSelect; self.onClose = onClose
    }

    private var filtered: [SlashCommand] {
        var q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.hasPrefix("/") { q.removeFirst() }
        if q.isEmpty { return commands }
        return commands.filter {
            $0.command.lowercased().contains(q) || ($0.description?.lowercased().contains(q) ?? false)
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "terminal").font(.system(size: 11)).foregroundColor(colors.textTertiary)
                Text("命令").font(.system(size: 11, weight: .semibold)).foregroundColor(colors.textTertiary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)

            if filtered.isEmpty {
                Text("没有匹配的命令")
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 22)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filtered) { c in row(colors, c) }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(6)
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func row(_ colors: FlareColors, _ c: SlashCommand) -> some View {
        Button { onSelect?(c) } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("/\(c.command)").font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(colors.primary)
                    if let hint = c.hint, !hint.isEmpty {
                        Text(hint).font(.system(size: 13, design: .monospaced)).foregroundColor(colors.textTertiary)
                    }
                    Spacer(minLength: 0)
                }
                if let desc = c.description, !desc.isEmpty {
                    Text(desc).font(.system(size: 12)).foregroundColor(colors.textSecondary).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Translation

/// Translation bubble — machine-translated text with original toggle.
/// Spec: Message/Translation (`TranslationView`).
public struct TranslationView: View {
    private let translated: String
    private let original: String?
    private let provider: String?
    private let pending: Bool
    @Environment(\.colorScheme) private var scheme
    @State private var showOriginal = false
    @State private var spinning = false

    public init(translated: String, original: String? = nil, provider: String? = nil, pending: Bool = false) {
        self.translated = translated; self.original = original; self.provider = provider; self.pending = pending
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            Rectangle().fill(colors.primary.opacity(0.4)).frame(width: 2)
            content(colors)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func content(_ colors: FlareColors) -> some View {
        if pending {
            HStack(spacing: 6) {
                Image(systemName: "globe").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                    .rotationEffect(.degrees(spinning ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: spinning)
                Text("翻译中…").font(.system(size: 14)).foregroundColor(colors.textTertiary)
            }
            .onAppear { spinning = true }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(translated).font(.system(size: 14)).foregroundColor(colors.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "globe").font(.system(size: 11)).foregroundColor(colors.textTertiary)
                    Text(provider != nil ? "由 \(provider!) 翻译" : "已翻译")
                        .font(.system(size: 11)).foregroundColor(colors.textTertiary)
                    Spacer(minLength: FlareSizes.spacingMd)
                    if original != nil {
                        Button { showOriginal.toggle() } label: {
                            HStack(spacing: 3) {
                                Text(showOriginal ? "隐藏原文" : "显示原文")
                                    .font(.system(size: 11, weight: .medium))
                                Image(systemName: "chevron.down").font(.system(size: 9))
                                    .rotationEffect(.degrees(showOriginal ? 180 : 0))
                            }.foregroundColor(colors.primary)
                        }.buttonStyle(.plain)
                    }
                }
                if let original, showOriginal {
                    Divider().overlay(colors.borderPrimary)
                    Text(original).font(.system(size: 13)).foregroundColor(colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - QRCard

/// QR card — personal add-me card with avatar + decorative QR matrix.
/// Spec: Profile/QRCard (`QRCardView`).
public struct QRCardView: View {
    private let name: String
    private let subtitle: String?
    private let avatarURL: String?
    private let qrImageURL: String?
    @Environment(\.colorScheme) private var scheme

    public init(name: String, subtitle: String? = nil, avatarURL: String? = nil, qrImageURL: String? = nil) {
        self.name = name; self.subtitle = subtitle; self.avatarURL = avatarURL; self.qrImageURL = qrImageURL
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: FlareSizes.spacingMd) {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: name, displayName: name, avatarURL: avatarURL, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 16, weight: .semibold)).foregroundColor(colors.textPrimary).lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle).font(.system(size: 12)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            qrPanel(colors)

            Text("扫一扫加我").font(.system(size: 12)).foregroundColor(colors.textTertiary)
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(width: 240)
        .background(RoundedRectangle(cornerRadius: 16).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.14), radius: 24, y: 10)
    }

    private func qrPanel(_ colors: FlareColors) -> some View {
        Group {
            if let qrImageURL, let url = URL(string: qrImageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    matrix(colors)
                }
            } else {
                matrix(colors)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
    }

    private func matrix(_ colors: FlareColors) -> some View {
        let seed = name.unicodeScalars.reduce(7) { $0 + Int($1.value) }
        let color = colors.textPrimary
        return Canvas { ctx, size in
            let n = 11
            let cell = size.width / CGFloat(n)
            let inset = cell * 0.14
            for y in 0..<n {
                for x in 0..<n {
                    // skip finder-pattern corners
                    if (x < 3 && y < 3) || (x > 7 && y < 3) || (x < 3 && y > 7) { continue }
                    if ((x * 31 + y * 17 + seed) % 5) == 0 {
                        let rect = CGRect(x: CGFloat(x) * cell + inset, y: CGFloat(y) * cell + inset,
                                          width: cell - inset * 2, height: cell - inset * 2)
                        ctx.fill(Path(roundedRect: rect, cornerRadius: cell * 0.22), with: .color(color))
                    }
                }
            }
            // finder patterns at three corners
            let finderOrigins: [(Int, Int)] = [(0, 0), (8, 0), (0, 8)]
            for (fx, fy) in finderOrigins {
                let outer = CGRect(x: CGFloat(fx) * cell + inset, y: CGFloat(fy) * cell + inset,
                                   width: cell * 3 - inset * 2, height: cell * 3 - inset * 2)
                ctx.stroke(Path(roundedRect: outer, cornerRadius: cell * 0.5),
                           with: .color(color), lineWidth: cell * 0.34)
                let dot = outer.insetBy(dx: cell * 0.75, dy: cell * 0.75)
                ctx.fill(Path(roundedRect: dot, cornerRadius: cell * 0.3), with: .color(color))
            }
        }
    }
}
