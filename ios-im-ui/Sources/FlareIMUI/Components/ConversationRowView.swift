import SwiftUI

/// A single inbox row — avatar, title, preview/draft, unread badge, time, and
/// mute/pin markers. Spec: Conversation/ConversationRow (`ConversationRowView`).
public struct ConversationRowView: View {
    private let item: ConversationRowData
    private let active: Bool
    private let avatarSize: CGFloat
    /// Inline preview prefixes — overridable so hosts can localize them.
    private let draftLabel: String
    private let mentionLabel: String
    /// Press callbacks. Previously absent on iOS (Android had them), which meant a row used outside
    /// a `List` had no way to report taps.
    private let onSelect: ((ConversationRowData) -> Void)?
    private let onLongPress: ((ConversationRowData) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(item: ConversationRowData, active: Bool = false, avatarSize: CGFloat = 48,
                draftLabel: String = "[Draft] ", mentionLabel: String = "[@me] ",
                onSelect: ((ConversationRowData) -> Void)? = nil,
                onLongPress: ((ConversationRowData) -> Void)? = nil) {
        self.draftLabel = draftLabel; self.mentionLabel = mentionLabel
        self.onSelect = onSelect; self.onLongPress = onLongPress
        self.item = item
        self.active = active
        self.avatarSize = avatarSize
    }

    public var body: some View {
        rowBody
            .contentShape(Rectangle())
            .modifier(RowGestures(onSelect: onSelect.map { cb in { cb(item) } },
                                  onLongPress: onLongPress.map { cb in { cb(item) } }))
    }

    @ViewBuilder
    private var rowBody: some View {
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
                HStack(spacing: FlareSizes.spacingSm) {
                    Text(item.title)
                        .font(.system(size: FlareSizes.fontSize3xl,
                                      weight: item.hasUnread ? .bold : .semibold))
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1)
                    if !item.tags.isEmpty { tagStrip(colors) }
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
                Text(draftLabel).foregroundColor(colors.error)
                    + Text(item.draftPreview ?? "").foregroundColor(colors.textSecondary)
            } else if item.mentioned {
                (Text(mentionLabel).foregroundColor(colors.error).bold()
                    + Text(item.preview).foregroundColor(colors.textSecondary))
            } else {
                Text(item.preview).foregroundColor(colors.textSecondary)
            }
        }
        .font(.system(size: FlareSizes.fontSizeLg))
        .lineLimit(1)
    }

    @ViewBuilder
    private func tagStrip(_ colors: FlareColors) -> some View {
        HStack(spacing: 4) {
            ForEach(item.tags) { tag in
                let tint = tagTint(tag.tone, colors)
                Text(tag.text)
                    .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                    .foregroundColor(tint)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(tint.opacity(0.12)))
            }
        }
    }

    private func tagTint(_ tone: FlareTagTone, _ colors: FlareColors) -> Color {
        switch tone {
        case .info: return colors.info
        case .warning: return colors.warning
        case .neutral: return colors.textTertiary
        }
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

/// Attaches tap / long-press only when the host supplied a handler (so a row inside a `List` keeps
/// the List's own selection behaviour untouched when no callbacks are given).
private struct RowGestures: ViewModifier {
    let onSelect: (() -> Void)?
    let onLongPress: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onTapGesture { onSelect?() }
            .onLongPressGesture { onLongPress?() }
    }
}
