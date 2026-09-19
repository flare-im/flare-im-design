import SwiftUI

// MARK: - ProfileCard

/// Mini profile card — avatar popover + message / voice / video.
/// Spec: Profile/ProfileCard (`ProfileCardView`).
///
/// The meta line shows the public Flare ID (``Contact/flareId``) and the region, only when set: the account
/// id is internal and never shown. Message, voice and video appear only when the host handles them, as on
/// ``FlareContactDetail``.
public struct ProfileCardView: View {
    private let user: Contact
    private let onMessage: (() -> Void)?
    private let onCall: (() -> Void)?
    private let onVideo: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(user: Contact, onMessage: (() -> Void)? = nil, onCall: (() -> Void)? = nil, onVideo: (() -> Void)? = nil) {
        self.user = user; self.onMessage = onMessage; self.onCall = onCall; self.onVideo = onVideo
    }

    /// "Flare ID · {handle} · {region}", with only the parts that are set; nil when neither is.
    static func meta(_ user: Contact, flareIdLabel: String) -> String? {
        var parts: [String] = []
        if let handle = user.flareId, !handle.isEmpty { parts.append("\(flareIdLabel) · \(handle)") }
        if let region = user.region, !region.isEmpty { parts.append(region) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
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
            if let meta = Self.meta(user, flareIdLabel: strings.contactDetailFlareId) {
                Text(meta).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                    .padding(.top, FlareSizes.spacingSm)
            }
            if !user.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(user.tags, id: \.self) { t in
                        Text(t).font(.system(size: FlareSizes.fontSizeXs)).foregroundColor(colors.primaryText)
                            .padding(.horizontal, 9).padding(.vertical, 2)
                            .background(Capsule().fill(colors.bgSelected))
                    }
                }.padding(.top, 10)
            }
            if onMessage != nil || onCall != nil || onVideo != nil {
                HStack(spacing: FlareSizes.spacingSm) {
                    if let onMessage { action(colors, "message", strings.sendMessage, name: nil, onMessage, primary: true) }
                    if let onCall { action(colors, "phone", nil, name: strings.contactDetailVoice, onCall) }
                    if let onVideo { action(colors, "video", nil, name: strings.contactDetailVideo, onVideo) }
                }.padding(.top, FlareSizes.spacingLg)
            }
        }
        .padding(FlareSizes.spacingLg)
        .frame(width: 260)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    /// An action key: the message key shows its label; the voice and video keys are icons named by `name`.
    @ViewBuilder
    private func action(_ colors: FlareColors, _ icon: String, _ label: String?, name: String?, _ onTap: @escaping () -> Void,
                        primary: Bool = false) -> some View {
        let key = Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 17))
                if let label { Text(label).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)) }
            }
            .foregroundColor(primary ? .white : colors.textPrimary)
            .frame(minWidth: FlareSizes.touchTargetMin, maxWidth: primary ? .infinity : FlareSizes.touchTargetMin,
                   minHeight: FlareSizes.touchTargetMin)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(primary ? colors.primary : colors.bgSecondary))
        }
        .buttonStyle(.plain)
        if let name { key.accessibilityLabel(name) } else { key }
    }
}
