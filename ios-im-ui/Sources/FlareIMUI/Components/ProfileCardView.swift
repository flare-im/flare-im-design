import SwiftUI

// MARK: - ProfileCard

/// Mini profile card — avatar popover + message / voice / video.
/// Spec: Profile/ProfileCard (`ProfileCardView`).
public struct ProfileCardView: View {
    private let user: Contact
    private let onMessage: (() -> Void)?
    private let onCall: (() -> Void)?
    private let onVideo: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(user: Contact, onMessage: (() -> Void)? = nil, onCall: (() -> Void)? = nil, onVideo: (() -> Void)? = nil) {
        self.user = user; self.onMessage = onMessage; self.onCall = onCall; self.onVideo = onVideo
    }

    private var meta: String {
        var parts = ["Flare ID · \(user.id)"]
        if let r = user.region, !r.isEmpty { parts.append(r) }
        return parts.joined(separator: " · ")
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: user.id, displayName: user.name, avatarURL: user.avatarURL, size: 56, presence: user.presence)
                Text(user.name).font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary).lineLimit(1)
                Spacer(minLength: 0)
            }
            if let s = user.signature, !s.isEmpty {
                Text(s).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textSecondary).padding(.top, FlareSizes.spacingMd)
            }
            Text(meta).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1).padding(.top, FlareSizes.spacingSm)
            if !user.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(user.tags, id: \.self) { t in
                        Text(t).font(.system(size: FlareSizes.fontSizeXs)).foregroundColor(colors.primary)
                            .padding(.horizontal, 9).padding(.vertical, 2)
                            .background(Capsule().fill(colors.bgSelected))
                    }
                }.padding(.top, 10)
            }
            HStack(spacing: FlareSizes.spacingSm) {
                action(colors, "message", "发消息", onMessage, primary: true)
                action(colors, "phone", nil, onCall)
                action(colors, "video", nil, onVideo)
            }.padding(.top, FlareSizes.spacingLg)
        }
        .padding(FlareSizes.spacingLg)
        .frame(width: 260)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func action(_ colors: FlareColors, _ icon: String, _ label: String?, _ onTap: (() -> Void)?, primary: Bool = false) -> some View {
        Button { onTap?() } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 17))
                if let label { Text(label).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)) }
            }
            .foregroundColor(primary ? .white : colors.textPrimary)
            .frame(maxWidth: primary ? .infinity : 44, minHeight: 38)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(primary ? colors.primary : colors.bgSecondary))
        }
        .buttonStyle(.plain)
    }
}
