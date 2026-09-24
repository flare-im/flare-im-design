import SwiftUI

/// Actions a ``ConversationActionSheetView`` can emit. Names match the
/// cross-platform contract (Vue `action` payload / Flutter / Compose enums).
public enum FlareConversationAction: String, CaseIterable, Sendable {
    case pin, unpin, mute, unmute, markRead, markUnread, archive, unarchive, hide, clearHistory, delete
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
    public let pin, mute, markRead, markUnread, archive, clearHistory, delete, hide: Bool
    public init(pin: Bool = false, mute: Bool = false, markRead: Bool = false, markUnread: Bool = false,
                archive: Bool = false, clearHistory: Bool = false, delete: Bool = false, hide: Bool = false) {
        self.pin = pin; self.mute = mute; self.markRead = markRead; self.markUnread = markUnread
        self.archive = archive; self.clearHistory = clearHistory; self.delete = delete; self.hide = hide
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
/// with unread > 0 and markUnread only without; clearHistory and delete close
/// the list in the danger group.
public func conversationActions(_ conversation: FlareConversationActionSnapshot,
                                capabilities: FlareConversationActionCapabilities) -> [FlareConversationActionEntry] {
    var out: [FlareConversationActionEntry] = []
    if capabilities.pin { out.append(.init(conversation.pinned ? .unpin : .pin)) }
    if capabilities.mute { out.append(.init(conversation.muted ? .unmute : .mute)) }
    if conversation.unreadCount > 0 {
        if capabilities.markRead { out.append(.init(.markRead)) }
    } else if capabilities.markUnread {
        out.append(.init(.markUnread))
    }
    if capabilities.archive { out.append(.init(conversation.archived ? .unarchive : .archive)) }
    if capabilities.hide { out.append(.init(.hide)) }
    if capabilities.clearHistory { out.append(.init(.clearHistory, danger: true)) }
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
    let pinText, unpinText, muteText, unmuteText, markReadText: String?
    let archiveText, unarchiveText, hideText, deleteText, emptyText: String?
    let onAction: ((String, FlareConversationAction) -> Void)?
    let onClose: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(conversation: FlareConversationActionSnapshot,
                capabilities: FlareConversationActionCapabilities = .init(),
                busy: Bool = false,
                pinText: String? = nil, unpinText: String? = nil,
                muteText: String? = nil, unmuteText: String? = nil,
                markReadText: String? = nil,
                archiveText: String? = nil, unarchiveText: String? = nil,
                hideText: String? = nil, deleteText: String? = nil,
                emptyText: String? = nil,
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
        case .pin: return copy.pinText
        case .unpin: return copy.unpinText
        case .mute: return copy.muteText
        case .unmute: return copy.unmuteText
        case .markRead: return copy.markReadText
        case .markUnread: return copy.markUnreadText
        case .archive: return copy.archiveText
        case .unarchive: return copy.unarchiveText
        case .hide: return copy.hideText
        case .clearHistory: return copy.clearHistoryText
        case .delete: return copy.deleteText
        }
    }

    static func symbol(for action: FlareConversationAction) -> String {
        switch action {
        case .pin: return flareIconSymbol("pin")
        case .unpin: return flareIconSymbol("unpin")
        case .mute: return "bell.slash"
        case .unmute: return "bell"
        case .markRead: return flareIconSymbol("read")
        case .markUnread: return flareIconSymbol("mark-unread")
        case .archive: return flareIconSymbol("archive")
        case .unarchive: return flareIconSymbol("unarchive")
        case .hide: return "eye.slash"
        // Clearing local history is not deleting the conversation: two glyphs.
        case .clearHistory: return flareIconSymbol("clear-history")
        case .delete: return flareIconSymbol("delete")
        }
    }

    /// Plain `Button`s for `.confirmationDialog { ... }` — same action set, the danger group
    /// (clear history, delete) as `.destructive`.
    @ViewBuilder
    public func dialogButtons() -> some View {
        ForEach(conversationActions(conversation, capabilities: capabilities), id: \.action) { entry in
            Button(role: entry.danger ? .destructive : nil) {
                onAction?(conversation.id, entry.action)
            } label: { Text(label(for: entry.action)) }
            .disabled(busy || onAction == nil)
        }
    }

    /// Copy in effect: an explicit parameter wins, otherwise the `flareStrings` provider.
    /// Mark-as-unread and clear-history come from the provider only, as on Vue.
    struct Copy {
        let pinText, unpinText, muteText, unmuteText: String
        let markReadText, markUnreadText, archiveText, unarchiveText, hideText: String
        let clearHistoryText, deleteText, emptyText: String
    }
    func resolveCopy(_ strings: FlareStrings) -> Copy {
        Copy(
            pinText: pinText ?? strings.conversationActionSheetPin,
            unpinText: unpinText ?? strings.conversationActionSheetUnpin,
            muteText: muteText ?? strings.conversationActionSheetMute,
            unmuteText: unmuteText ?? strings.conversationActionSheetUnmute,
            markReadText: markReadText ?? strings.conversationActionSheetMarkRead,
            markUnreadText: strings.conversationActionSheetMarkUnread,
            archiveText: archiveText ?? strings.conversationActionSheetArchive,
            unarchiveText: unarchiveText ?? strings.conversationActionSheetUnarchive,
            hideText: hideText ?? strings.conversationActionSheetHide,
            clearHistoryText: strings.conversationActionSheetClearHistory,
            deleteText: deleteText ?? strings.delete,
            emptyText: emptyText ?? strings.conversationActionSheetEmpty
        )
    }
    private var copy: Copy { resolveCopy(strings) }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
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
                Text(copy.emptyText)
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
        let fg = enabled ? (entry.danger ? colors.errorText : colors.textPrimary) : colors.textDisabled
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
