import SwiftUI

/// Connection-status tone — spec union `'ok' | 'warn' | 'error'`.
public enum FlareConnectionTone: Sendable {
    case ok, warn, error
}

/// The conversation info/settings panel — counts, connection state, and
/// per-conversation actions. Spec: Conversation/ConversationDetails
/// (`ConversationDetailsView`).
public struct ConversationDetailsView: View {
    private let conversation: FlareConversationSummary
    private let connectionText: String?
    private let connectionTone: FlareConnectionTone
    private let messageCount: Int?

    private let onMute: ((Bool) -> Void)?
    private let onPin: ((Bool) -> Void)?
    private let onArchive: (() -> Void)?
    private let onClearHistory: (() -> Void)?
    private let onDelete: (() -> Void)?
    private let onMarkRead: (() -> Void)?
    private let onMarkUnread: (() -> Void)?
    private let onSync: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @State private var muted: Bool
    @State private var pinned: Bool

    public init(
        conversation: FlareConversationSummary,
        connectionText: String? = nil,
        connectionTone: FlareConnectionTone = .ok,
        messageCount: Int? = nil,
        onMute: ((Bool) -> Void)? = nil,
        onPin: ((Bool) -> Void)? = nil,
        onArchive: (() -> Void)? = nil,
        onClearHistory: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onMarkRead: (() -> Void)? = nil,
        onMarkUnread: (() -> Void)? = nil,
        onSync: (() -> Void)? = nil
    ) {
        self.conversation = conversation
        self.connectionText = connectionText
        self.connectionTone = connectionTone
        self.messageCount = messageCount
        self.onMute = onMute
        self.onPin = onPin
        self.onArchive = onArchive
        self.onClearHistory = onClearHistory
        self.onDelete = onDelete
        self.onMarkRead = onMarkRead
        self.onMarkUnread = onMarkUnread
        self.onSync = onSync
        _muted = State(initialValue: conversation.muted)
        _pinned = State(initialValue: conversation.pinned)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        List {
            Section {
                VStack(spacing: FlareSizes.spacingSm) {
                    AvatarView(userId: conversation.id, displayName: conversation.title,
                               avatarURL: conversation.avatarURL, size: 64)
                    Text(conversation.title)
                        .font(.system(size: FlareSizes.fontSize4xl, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                    if conversation.kind == .group, let n = conversation.memberCount {
                        Text("\(n) 名成员")
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary)
                    }
                    if let text = connectionText, !text.isEmpty {
                        HStack(spacing: FlareSizes.spacingSm) {
                            Circle().fill(toneColor(colors)).frame(width: 8, height: 8)
                            Text(text).font(.system(size: FlareSizes.fontSizeMd))
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
            }

            if let count = messageCount {
                Section {
                    HStack {
                        Text("消息数").foregroundColor(colors.textSecondary)
                        Spacer()
                        Text("\(count)").foregroundColor(colors.textPrimary)
                    }
                }
            }

            Section {
                if onMute != nil {
                    Toggle(isOn: Binding(get: { muted }, set: { muted = $0; onMute?($0) })) {
                        Label("免打扰", systemImage: "bell.slash")
                    }
                }
                if onPin != nil {
                    Toggle(isOn: Binding(get: { pinned }, set: { pinned = $0; onPin?($0) })) {
                        Label("置顶会话", systemImage: "pin")
                    }
                }
            }

            Section {
                if let onMarkRead { row("标记已读", "envelope.open", onMarkRead, colors) }
                if let onMarkUnread { row("标记未读", "envelope.badge", onMarkUnread, colors) }
                if let onSync { row("同步会话", "arrow.triangle.2.circlepath", onSync, colors) }
            }

            Section {
                if let onArchive {
                    row(conversation.archived ? "取消归档" : "归档会话", "archivebox", onArchive, colors)
                }
                if let onClearHistory { row("清空聊天记录", "trash.slash", onClearHistory, colors) }
                if let onDelete { row("删除会话", "trash", onDelete, colors, danger: true) }
            }
        }
    }

    private func row(_ title: String, _ icon: String, _ action: @escaping () -> Void,
                     _ colors: FlareColors, danger: Bool = false) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .foregroundColor(danger ? colors.error : colors.textPrimary)
        }
    }

    private func toneColor(_ colors: FlareColors) -> Color {
        switch connectionTone {
        case .ok: return colors.success
        case .warn: return colors.warning
        case .error: return colors.error
        }
    }
}
