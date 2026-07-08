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
        let colors = FlareColors.of(scheme)
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
        let tint = Self.seedTint(userId)
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
    static func seedTint(_ seed: String) -> (bg: Color, fg: Color) {
        let pairs: [(Color, Color)] = [
            (Color(.sRGB, red: 0.859, green: 0.918, blue: 0.996, opacity: 1), Color(.sRGB, red: 0.114, green: 0.306, blue: 0.847, opacity: 1)), // blue
            (Color(.sRGB, red: 0.914, green: 0.835, blue: 1.000, opacity: 1), Color(.sRGB, red: 0.427, green: 0.157, blue: 0.851, opacity: 1)), // purple
            (Color(.sRGB, red: 0.984, green: 0.812, blue: 0.910, opacity: 1), Color(.sRGB, red: 0.745, green: 0.094, blue: 0.365, opacity: 1)), // pink
            (Color(.sRGB, red: 0.820, green: 0.980, blue: 0.898, opacity: 1), Color(.sRGB, red: 0.016, green: 0.471, blue: 0.341, opacity: 1)), // green
            (Color(.sRGB, red: 0.996, green: 0.953, blue: 0.780, opacity: 1), Color(.sRGB, red: 0.706, green: 0.325, blue: 0.035, opacity: 1)), // amber
            (Color(.sRGB, red: 0.898, green: 0.906, blue: 0.922, opacity: 1), Color(.sRGB, red: 0.216, green: 0.255, blue: 0.318, opacity: 1)), // slate
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
