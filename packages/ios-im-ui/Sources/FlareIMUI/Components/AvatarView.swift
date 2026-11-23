import SwiftUI

/// A compact avatar with a full touch target for a page header.
public struct ScreenHeaderAvatarLink<Destination: View>: View {
    private let userId: String
    private let displayName: String
    private let avatarURL: String?
    private let label: String
    private let destination: () -> Destination

    public init(userId: String, displayName: String, avatarURL: String? = nil,
                label: String, @ViewBuilder destination: @escaping () -> Destination) {
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.label = label
        self.destination = destination
    }

    public var body: some View {
        NavigationLink(destination: destination) {
            AvatarView(userId: userId, displayName: displayName, avatarURL: avatarURL, size: FlareSizes.iconSizeXl)
                .frame(width: FlareSizes.touchTarget, height: FlareSizes.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

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
    private let group: Bool

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(
        userId: String,
        displayName: String,
        avatarURL: String? = nil,
        size: CGFloat = FlareSizes.avatarSize,
        presence: FlarePresence? = nil,
        group: Bool = false
    ) {
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.size = size
        self.presence = presence
        self.group = group
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        ZStack(alignment: .bottomTrailing) {
            avatarBody
                .frame(width: size, height: size)
                .clipShape(Circle())

            if group {
                // A group's people mark (Vue `FlareAvatar` `group`), in place of the presence dot a group never has:
                // the avatar's palette inverted, ringed in the surface colour so it stands off any tint or photo.
                let mark = (size * 0.45).rounded()
                let tint = Self.seedTint(displayName.isEmpty ? userId : displayName, colors)
                ZStack {
                    Circle().fill(colors.bgPrimary)
                    Circle().fill(tint.fg).padding(2)
                    // `person.2.fill`, not the `group` symbol (`person.3`): three people are too wide for the disc.
                    Image(systemName: "person.2.fill")
                        .font(.system(size: (mark * 0.4).rounded(), weight: .semibold))
                        .foregroundColor(tint.bg)
                }
                .frame(width: mark, height: mark)
                .offset(x: 3, y: 3)
                .accessibilityElement()
                .accessibilityLabel(strings.displayNameGroup)
            } else if let presence {
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

    /// The name's first character, upper-cased (Vue `FlareAvatar`: one letter for "Lab Bob", 「群」 for a group).
    static func initials(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
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
        return pairs[tintIndex(seed)]
    }

    /// The palette slot of `seed`, computed exactly as Vue `avatarTint` does (JS: per code point its first UTF-16
    /// unit `c`, `hash = c + ((hash << 5) - hash)` with the shift on int32, then `|hash| % 6`; a blank seed is
    /// "user"), so one name gets one colour on every platform.
    static func tintIndex(_ seed: String) -> Int {
        var hash: Int64 = 0
        for scalar in (seed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "user" : seed).unicodeScalars {
            let unit = scalar.value > 0xFFFF ? 0xD800 + ((scalar.value - 0x10000) >> 10) : scalar.value
            hash = Int64(Int32(truncatingIfNeeded: hash) << 5) - hash + Int64(unit)
        }
        return Int(hash.magnitude % 6)
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
