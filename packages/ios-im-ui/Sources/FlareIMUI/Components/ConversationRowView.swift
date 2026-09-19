import SwiftUI

/// Canonical row: identity and preview flex; timestamp and unread never compete with them.
public struct ConversationRowView: View {
    private let item: ConversationRowData
    private let active: Bool
    private let avatarSize: CGFloat
    private let draftLabel: String?
    private let mentionLabel: String?
    private let compact: Bool
    private let onSelect: ((ConversationRowData) -> Void)?
    private let onLongPress: ((ConversationRowData) -> Void)?
    @ScaledMetric(relativeTo: .headline) private var titleSize = FlareSizes.fontSizeLg
    @ScaledMetric(relativeTo: .body) private var previewSize = FlareSizes.fontSizeMd
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    @Environment(\.flareStrings) private var strings
    @FocusState private var focused: Bool
    @State private var hovered = false

    public init(item: ConversationRowData, active: Bool = false, avatarSize: CGFloat = FlareSizes.avatarSize,
                draftLabel: String? = nil, mentionLabel: String? = nil,
                onSelect: ((ConversationRowData) -> Void)? = nil,
                onLongPress: ((ConversationRowData) -> Void)? = nil, compact: Bool? = nil) {
        self.item = item; self.active = active; self.avatarSize = avatarSize
        self.draftLabel = draftLabel; self.mentionLabel = mentionLabel
        self.onSelect = onSelect; self.onLongPress = onLongPress
        #if os(macOS)
        self.compact = compact ?? true
        #else
        self.compact = compact ?? false
        #endif
    }

    private var colors: FlareColors { FlareColors.of(scheme, brand: brand) }
    private var prefix: String {
        switch item.previewKind {
        case "failed": return "[\(strings.messageFailed)] "
        case "draft": return draftLabel ?? strings.conversationRowDraft
        case "mention": return mentionLabel ?? strings.conversationRowMention
        default: return ""
        }
    }
    private var preview: String {
        switch item.previewKind {
        case "draft": return (item.draftPreview ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case "typing": return strings.typing
        default: return item.preview
        }
    }
    private var label: String {
        [item.title, item.hasUnread ? strings.unreadTab(item.unreadCount) : "",
         item.mentioned ? (mentionLabel ?? strings.conversationRowMention) : "",
         item.pinned ? strings.conversationActionSheetPin : "", item.muted ? strings.muted : "",
         prefix + preview, item.timestampLabel].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    public var body: some View {
        Group {
            if let onLongPress {
                selectableRow.onLongPressGesture { onLongPress(item) }
            } else {
                selectableRow
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    @ViewBuilder private var selectableRow: some View {
        if let onSelect {
            Button { onSelect(item) } label: { rowBody }
                .buttonStyle(.plain).focused($focused)
        } else {
            rowBody
        }
    }

    private var rowBody: some View {
        HStack(spacing: 10) {
            AvatarView(userId: item.id, displayName: item.title, avatarURL: item.avatarURL,
                       size: compact ? 40 : avatarSize, presence: item.presence)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(item.title).font(.system(size: titleSize, weight: item.titleEmphasis == "strong" ? .bold : .medium))
                        .foregroundColor(colors.textPrimary).lineLimit(1)
                    if item.pinned { Image(systemName: "pin").font(.system(size: 12)).foregroundColor(colors.textTertiary).fixedSize() }
                    if item.muted { Image(systemName: "bell.slash").font(.system(size: 12)).foregroundColor(colors.textTertiary).fixedSize() }
                }
                (Text(prefix).foregroundColor(item.previewKind == "draft" ? colors.primaryText : colors.errorText)
                    + Text(preview).foregroundColor(colors.textSecondary))
                    .font(.system(size: previewSize)).lineLimit(1)
            }.frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.timestampLabel).font(.caption2).foregroundColor(active ? colors.textSecondary : colors.textTertiary)
                    .monospacedDigit().lineLimit(1).frame(maxWidth: .infinity, alignment: .trailing)
                Group {
                    if item.hasUnread {
                        Text(item.unreadLabel).font(.caption2.weight(.semibold)).monospacedDigit()
                            .foregroundColor(item.muted && !item.mentioned ? colors.textSecondary : colors.messageOutgoingForeground)
                            .padding(.horizontal, 5).frame(minWidth: 18, minHeight: 20)
                            .background(Capsule().fill(item.muted && !item.mentioned ? colors.bgTertiary : colors.primary))
                    } else {
                        Color.clear.frame(height: 20)
                    }
                }
            }.frame(width: 60)
        }
        .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, compact ? 10 : 14)
        .frame(minHeight: compact ? 72 : 80)
        .background(active ? colors.bgSelected : hovered ? colors.bgHover : .clear)
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).stroke(focused ? colors.borderSelected : .clear, lineWidth: 2))
        .contentShape(Rectangle()).onHover { hovered = $0 }
    }
}
