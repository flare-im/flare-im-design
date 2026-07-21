import SwiftUI

/// The active conversation's header — title, subtitle/presence, and actions.
/// Spec: Message/ChatHeader (`ChatHeaderView`).
public struct ChatHeaderView: View {
    private let title: String
    private let subtitle: String?
    private let presence: FlarePresence?
    private let avatarUserId: String?
    private let avatarURL: String?
    private let onBack: (() -> Void)?
    private let onSearch: (() -> Void)?
    private let onCall: (() -> Void)?
    private let onDetails: (() -> Void)?

    @Environment(\.colorScheme) private var scheme

    public init(
        title: String,
        subtitle: String? = nil,
        presence: FlarePresence? = nil,
        avatarUserId: String? = nil,
        avatarURL: String? = nil,
        onBack: (() -> Void)? = nil,
        onSearch: (() -> Void)? = nil,
        onCall: (() -> Void)? = nil,
        onDetails: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.presence = presence
        self.avatarUserId = avatarUserId
        self.avatarURL = avatarURL
        self.onBack = onBack
        self.onSearch = onSearch
        self.onCall = onCall
        self.onDetails = onDetails
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingSm) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").foregroundColor(colors.textPrimary)
                }
            }
            if let uid = avatarUserId {
                AvatarView(userId: uid, displayName: title, avatarURL: avatarURL, size: 36, presence: presence)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: FlareSizes.fontSize3xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary).lineLimit(1)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(presence == .online ? colors.success : colors.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let onSearch { action("magnifyingglass", onSearch, colors) }
            if let onCall { action("phone", onCall, colors) }
            if let onDetails { action("ellipsis", onDetails, colors) }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .frame(height: FlareSizes.headerHeight)
        // Transparent bar — no filled surface or divider; it blends into the chat
        // canvas (no white top area). Back sits to the left of the avatar.
    }

    private func action(_ icon: String, _ handler: @escaping () -> Void, _ colors: FlareColors) -> some View {
        Button(action: handler) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(colors.textSecondary)
        }
    }
}
