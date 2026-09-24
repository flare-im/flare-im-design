import SwiftUI

/// Presence state shown as a corner dot on ``AvatarView``. Neutral spec union
/// `'online' | 'offline' | 'busy' | 'away'`.
public enum FlarePresence: Sendable {
    case online, offline, busy, away
}

/// Round user avatar — image, or deterministic initials fallback, plus an
/// optional presence dot. Spec: General/Avatar (`AvatarView`).
public struct AvatarView: View {
    private let userId: String
    private let displayName: String
    private let avatarURL: String?
    private let size: CGFloat
    private let presence: FlarePresence?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(
        userId: String,
        displayName: String,
        avatarURL: String? = nil,
        size: CGFloat = FlareSizes.avatarSize,
        presence: FlarePresence? = nil
    ) {
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.size = size
        self.presence = presence
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        ZStack(alignment: .bottomTrailing) {
            avatarBody
                .frame(width: size, height: size)
                .clipShape(Circle())

            if let presence {
                Circle()
                    .fill(Self.presenceColor(colors, presence))
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(Circle().stroke(colors.bgPrimary, lineWidth: 2))
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var avatarBody: some View {
        if let avatarURL, let url = URL(string: avatarURL), !avatarURL.isEmpty {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                initials
            }
        } else {
            initials
        }
    }

    private var initials: some View {
        // Seed by the stable display name (not the id, which varies by surface —
        // peer id vs conversation id vs sender id) so a person is one colour
        // everywhere: list, chat header, message bubbles.
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let tint = Self.seedTint(displayName.isEmpty ? userId : displayName, colors)
        return ZStack {
            tint.bg
            Text(Self.initials(displayName))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(tint.fg)
        }
    }

    static func initials(_ name: String) -> String {
        let parts = name
            .trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .filter { !$0.isEmpty }
        if parts.isEmpty { return "?" }
        if parts.count == 1 { return String(parts[0].prefix(1)).uppercased() }
        return (String(parts[0].prefix(1)) + String(parts[parts.count - 1].prefix(1)))
            .uppercased()
    }

    /// Soft pastel identity — matches the reference app (avatarPastelForKey): a
    /// tinted surface + dark initials reads more premium than a saturated solid
    /// and stays legible in both themes.
    /// 身份色板现在来自 token 真源(`colors.avatarTint.*`),四端同一组值、**并且有暗色**。
    /// 原来这里是 6 组 sRGB 浮点三元组:肉眼核对不了,三端各写一份,暗色下还会当作
    /// 浅色马卡龙直接糊在深色表面上 —— 只有 web 侧做过暗色处理。
    /// 顺序是契约的一部分(按种子哈希取模选色),生成器不排序,按真源里的插入序走。
    static func seedTint(_ seed: String, _ colors: FlareColors) -> (bg: Color, fg: Color) {
        let pairs: [(Color, Color)] = [
            (colors.avatarTintBlueBg, colors.avatarTintBlueFg),
            (colors.avatarTintPurpleBg, colors.avatarTintPurpleFg),
            (colors.avatarTintPinkBg, colors.avatarTintPinkFg),
            (colors.avatarTintGreenBg, colors.avatarTintGreenFg),
            (colors.avatarTintAmberBg, colors.avatarTintAmberFg),
            (colors.avatarTintSlateBg, colors.avatarTintSlateFg),
        ]
        var hash = 0
        for byte in seed.unicodeScalars {
            hash = (hash &* 31 &+ Int(byte.value)) & 0x7fffffff
        }
        return pairs[hash % pairs.count]
    }

    static func presenceColor(_ colors: FlareColors, _ presence: FlarePresence) -> Color {
        switch presence {
        case .online: return colors.success
        case .busy: return colors.error
        case .away: return colors.warning
        case .offline: return colors.textTertiary
        }
    }
}
