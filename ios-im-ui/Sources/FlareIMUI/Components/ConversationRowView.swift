import SwiftUI

/// A single inbox row — avatar, title, preview/draft, unread badge, time, and
/// mute/pin markers. Spec: Conversation/ConversationRow (`ConversationRowView`).
public struct ConversationRowView: View {
    private let item: ConversationRowData
    private let active: Bool
    private let avatarSize: CGFloat
    @Environment(\.colorScheme) private var scheme

    public init(item: ConversationRowData, active: Bool = false, avatarSize: CGFloat = 48) {
        self.item = item
        self.active = active
        self.avatarSize = avatarSize
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingMd) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    userId: item.id,
                    displayName: item.title,
                    avatarURL: item.avatarURL,
                    size: avatarSize,
                    presence: item.presence
                )
                if item.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundColor(colors.pinned)
                        .padding(3)
                        .background(Circle().fill(colors.bgPrimary))
                        .overlay(Circle().stroke(colors.borderSecondary, lineWidth: 1))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.system(size: FlareSizes.fontSize3xl,
                                      weight: item.hasUnread ? .bold : .semibold))
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: FlareSizes.spacingSm)
                    TimeStampView(label: item.timestampLabel)
                }
                HStack {
                    previewLine(colors)
                    Spacer(minLength: FlareSizes.spacingSm)
                    if item.hasUnread { unreadBadge(colors) }
                }
            }
        }
        .padding(.vertical, FlareSizes.spacingMd)
        .padding(.horizontal, FlareSizes.spacingSm)
        .background(active ? colors.bgSelected : Color.clear)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func previewLine(_ colors: FlareColors) -> some View {
        HStack(spacing: 4) {
            if item.muted {
                Image(systemName: "bell.slash")
                    .font(.system(size: 12))
                    .foregroundColor(colors.textTertiary)
            }
            if item.hasDraft {
                Text("[Draft] ").foregroundColor(colors.error)
                    + Text(item.draftPreview ?? "").foregroundColor(colors.textSecondary)
            } else if item.mentioned {
                (Text("[@me] ").foregroundColor(colors.error).bold()
                    + Text(item.preview).foregroundColor(colors.textSecondary))
            } else {
                Text(item.preview).foregroundColor(colors.textSecondary)
            }
        }
        .font(.system(size: FlareSizes.fontSizeLg))
        .lineLimit(1)
    }

    private func unreadBadge(_ colors: FlareColors) -> some View {
        Text(item.unreadCount > 99 ? "99+" : "\(item.unreadCount)")
            .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .frame(minWidth: 22, minHeight: 22)
            .background(Capsule().fill(colors.primary))
    }
}
