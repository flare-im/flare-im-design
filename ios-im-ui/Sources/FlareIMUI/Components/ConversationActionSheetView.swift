import SwiftUI

/// Actions a ``ConversationActionSheetView`` can emit. Names match the
/// cross-platform contract (Vue `action` payload / Flutter / Compose enums).
public enum FlareConversationAction: String, CaseIterable, Sendable {
    case pin, unpin, mute, unmute, markRead, archive, unarchive, hide, delete
}

/// Snapshot of the conversation the sheet acts on; `id` must be stable.
public struct FlareConversationActionSnapshot: Sendable {
    public let id: String
    public let title: String
    public let pinned: Bool
    public let muted: Bool
    public let unreadCount: Int
    public let archived: Bool
    public init(id: String, title: String, pinned: Bool = false, muted: Bool = false,
                unreadCount: Int = 0, archived: Bool = false) {
        self.id = id; self.title = title; self.pinned = pinned; self.muted = muted
        self.unreadCount = unreadCount; self.archived = archived
    }
}

/// Capabilities the host can honour. `false` → the action is not rendered.
public struct FlareConversationActionCapabilities: Sendable {
    public let pin, mute, markRead, archive, delete, hide: Bool
    public init(pin: Bool = false, mute: Bool = false, markRead: Bool = false,
                archive: Bool = false, delete: Bool = false, hide: Bool = false) {
        self.pin = pin; self.mute = mute; self.markRead = markRead
        self.archive = archive; self.delete = delete; self.hide = hide
    }
}

/// One displayable entry; `danger` entries render in the trailing group.
public struct FlareConversationActionEntry: Equatable, Sendable {
    public let action: FlareConversationAction
    public let danger: Bool
    public init(_ action: FlareConversationAction, danger: Bool = false) {
        self.action = action; self.danger = danger
    }
}

/// Ordered, displayable actions — same rule set as the other platforms:
/// pin/unpin, mute/unmute, archive/unarchive invert by state; markRead only
/// with unread > 0; delete always last and flagged danger.
public func conversationActions(_ conversation: FlareConversationActionSnapshot,
                                capabilities: FlareConversationActionCapabilities) -> [FlareConversationActionEntry] {
    var out: [FlareConversationActionEntry] = []
    if capabilities.pin { out.append(.init(conversation.pinned ? .unpin : .pin)) }
    if capabilities.mute { out.append(.init(conversation.muted ? .unmute : .mute)) }
    if capabilities.markRead && conversation.unreadCount > 0 { out.append(.init(.markRead)) }
    if capabilities.archive { out.append(.init(conversation.archived ? .unarchive : .archive)) }
    if capabilities.hide { out.append(.init(.hide)) }
    if capabilities.delete { out.append(.init(.delete, danger: true)) }
    return out
}

/// Conversation action menu — the body of a long-press / context / "more" sheet
/// for ONE conversation. Owns no positioning: place it in `.sheet` or a popover;
/// use ``dialogButtons(...)`` for `.confirmationDialog`. Spec: Conversation/ConversationActionSheet.
public struct ConversationActionSheetView: View {
    let conversation: FlareConversationActionSnapshot
    let capabilities: FlareConversationActionCapabilities
    let busy: Bool
    let pinText, unpinText, muteText, unmuteText, markReadText: String
    let archiveText, unarchiveText, hideText, deleteText, emptyText: String
    let onAction: ((String, FlareConversationAction) -> Void)?
    let onClose: (() -> Void)?

    @Environment(\.colorScheme) private var scheme

    public init(conversation: FlareConversationActionSnapshot,
                capabilities: FlareConversationActionCapabilities = .init(),
                busy: Bool = false,
                pinText: String = "置顶", unpinText: String = "取消置顶",
                muteText: String = "免打扰", unmuteText: String = "取消免打扰",
                markReadText: String = "标为已读",
                archiveText: String = "归档", unarchiveText: String = "取消归档",
                hideText: String = "隐藏", deleteText: String = "删除",
                emptyText: String = "暂无可用操作",
                onAction: ((String, FlareConversationAction) -> Void)? = nil,
                onClose: (() -> Void)? = nil) {
        self.conversation = conversation; self.capabilities = capabilities; self.busy = busy
        self.pinText = pinText; self.unpinText = unpinText; self.muteText = muteText
        self.unmuteText = unmuteText; self.markReadText = markReadText
        self.archiveText = archiveText; self.unarchiveText = unarchiveText
        self.hideText = hideText; self.deleteText = deleteText; self.emptyText = emptyText
        self.onAction = onAction; self.onClose = onClose
    }

    public func label(for action: FlareConversationAction) -> String {
        switch action {
        case .pin: return pinText
        case .unpin: return unpinText
        case .mute: return muteText
        case .unmute: return unmuteText
        case .markRead: return markReadText
        case .archive: return archiveText
        case .unarchive: return unarchiveText
        case .hide: return hideText
        case .delete: return deleteText
        }
    }

    static func symbol(for action: FlareConversationAction) -> String {
        switch action {
        case .pin, .unpin: return "pin"
        case .mute: return "bell.slash"
        case .unmute: return "bell"
        case .markRead: return "checkmark.circle"
        case .archive: return "archivebox"
        case .unarchive: return "tray.and.arrow.up"
        case .hide: return "eye.slash"
        case .delete: return "trash"
        }
    }

    /// Plain `Button`s for `.confirmationDialog { ... }` — same action set, delete as `.destructive`.
    @ViewBuilder
    public func dialogButtons() -> some View {
        ForEach(conversationActions(conversation, capabilities: capabilities), id: \.action) { entry in
            Button(role: entry.danger ? .destructive : nil) {
                onAction?(conversation.id, entry.action)
            } label: { Text(label(for: entry.action)) }
            .disabled(busy || onAction == nil)
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let entries = conversationActions(conversation, capabilities: capabilities)
        let primary = entries.filter { !$0.danger }
        let danger = entries.filter { $0.danger }
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            Text(conversation.title)
                .font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
                .foregroundColor(colors.textTertiary)
                .lineLimit(1)
                .padding(.horizontal, FlareSizes.spacingMd)
                .padding(.vertical, FlareSizes.spacingXs)
            if entries.isEmpty {
                Text(emptyText)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(FlareSizes.spacingMd)
            }
            if !primary.isEmpty { group(primary, colors: colors, danger: false) }
            if !danger.isEmpty { group(danger, colors: colors, danger: true) }
        }
        .padding(.horizontal, FlareSizes.spacingSm)
        .padding(.vertical, FlareSizes.spacingXs)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(conversation.title)
        .modifier(ConversationActionEscape(onClose: onClose))
    }

    private func group(_ entries: [FlareConversationActionEntry], colors: FlareColors, danger: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(entries, id: \.action) { entry in row(entry, colors: colors) }
        }
        .padding(.vertical, FlareSizes.spacingXs)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radius2xl).fill(colors.bgPrimary))
        .overlay(alignment: .top) {
            if danger { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
        }
    }

    private func row(_ entry: FlareConversationActionEntry, colors: FlareColors) -> some View {
        let enabled = !busy && onAction != nil
        let accent = entry.danger ? colors.error : colors.primary
        let fg = enabled ? (entry.danger ? colors.error : colors.textPrimary) : colors.textDisabled
        let iconFg = enabled ? accent : colors.textDisabled
        let iconBg = enabled ? accent.opacity(entry.danger ? 0.12 : 0.10) : colors.bgDisabled
        return Button {
            onAction?(conversation.id, entry.action)
        } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                ZStack {
                    Circle().fill(iconBg).frame(width: 44, height: 44)
                    Image(systemName: Self.symbol(for: entry.action))
                        .font(.system(size: 20))
                        .foregroundColor(iconFg)
                }
                Text(label(for: entry.action))
                    .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                    .foregroundColor(fg)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.vertical, FlareSizes.spacingSm)
            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
        }
        .buttonStyle(ConversationActionRowStyle(highlight: colors.bgHover))
        .disabled(!enabled)
        .accessibilityLabel(label(for: entry.action))
    }
}

/// Escape (hardware keyboard on macOS / iPad) closes the menu; a no-op elsewhere.
struct ConversationActionEscape: ViewModifier {
    let onClose: (() -> Void)?
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onExitCommand { onClose?() }
        #else
        content
        #endif
    }
}

/// Pressed / hovered / keyboard-focused rows share the neutral hover surface.
struct ConversationActionRowStyle: ButtonStyle {
    let highlight: Color
    @State private var hovered = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: FlareSizes.radiusXl)
                    .fill(configuration.isPressed || hovered ? highlight : Color.clear)
            )
            .onHover { hovered = $0 }
    }
}
