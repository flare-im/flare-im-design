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
    /// The phone row's title is a step larger (Vue `.im-conv-item--mobile .im-conv-item__title`).
    @ScaledMetric(relativeTo: .headline) private var mobileTitleSize = FlareSizes.fontSize2xl
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
    private var mention: String {
        (mentionLabel ?? strings.conversationRowMention)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    }
    private var prefix: String {
        switch item.previewKind {
        case "failed": return "[\(strings.messageFailed)] "
        case "draft": return draftLabel ?? strings.conversationRowDraft
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
         item.mentioned ? mention : "",
         item.pinned ? strings.conversationActionSheetPin : "", item.muted ? strings.muted : "",
         prefix + preview, item.timestampLabel].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    public var body: some View {
        Group {
            if let onLongPress {
                // A long press on a Button never fires (the button's own gesture wins), so a row with a menu takes
                // the tap and the hold as two gestures: a quick tap opens it, a hold opens the menu and not the row.
                rowBody
                    .onTapGesture { onSelect?(item) }
                    .onLongPressGesture(minimumDuration: 0.5) { onLongPress(item) }
            } else {
                selectableRow
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(active ? .isSelected : [])
        .accessibilityAddTraits(onSelect == nil ? [] : .isButton)
        .accessibilityAction { onSelect?(item) }
        .accessibilityActions {
            if let onLongPress { Button(strings.more) { onLongPress(item) } }
        }
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
        HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: item.id, displayName: item.title, avatarURL: item.avatarURL,
                       size: compact ? 40 : avatarSize, presence: item.presence, group: item.kind == .group)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(item.title).font(.system(size: compact ? titleSize : mobileTitleSize,
                                                  weight: item.titleEmphasis == "strong" ? .bold : .medium))
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
                    .monospacedDigit().lineLimit(1).frame(maxWidth: FlareSizes.componentConversationRowMetaWidth, alignment: .trailing)
                HStack(spacing: FlareSizes.spacingXs) {
                    if item.mentioned {
                        Text(mention).font(.caption2.weight(.semibold))
                            .foregroundColor(colors.primaryText).fixedSize()
                            .padding(.horizontal, FlareSizes.spacingXs).padding(.vertical, 2)
                            .background(Capsule().fill(colors.bgSelected))
                    }
                    if item.hasUnread {
                        Text(item.unreadLabel).font(.caption2.weight(.semibold)).monospacedDigit()
                            .foregroundColor(item.muted ? colors.textSecondary : colors.messageOutgoingForeground)
                            .padding(.horizontal, 5).frame(minWidth: 18, minHeight: 20)
                            .background(Capsule().fill(item.muted ? colors.bgTertiary : colors.primary))
                    }
                }.frame(minHeight: 20)
            }.frame(minWidth: FlareSizes.componentConversationRowMetaWidth, alignment: .trailing)
        }
        // Phone: a full-bleed 68 pt row with a hairline under it from the text's edge (Vue `.im-conv-item--mobile`);
        // the desktop list keeps its rounded selected row.
        .padding(.horizontal, compact ? FlareSizes.spacingSm : FlareSizes.spacingLg)
        .padding(.vertical, compact ? 10 : FlareSizes.spacingMd)
        .frame(minHeight: compact ? 72 : FlareSizes.conversationRowMobileHeight)
        .background(active ? colors.bgSelected : hovered ? colors.bgHover : .clear)
        .clipShape(RoundedRectangle(cornerRadius: compact ? FlareSizes.radiusMd : 0))
        .overlay(alignment: .bottom) {
            if !compact {
                Rectangle().fill(colors.borderSecondary).opacity(0.55).frame(height: 1)
                    .padding(.leading, 72).padding(.trailing, FlareSizes.spacingLg)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).stroke(focused ? colors.borderSelected : .clear, lineWidth: 2))
        .contentShape(Rectangle()).onHover { hovered = $0 }
    }
}
