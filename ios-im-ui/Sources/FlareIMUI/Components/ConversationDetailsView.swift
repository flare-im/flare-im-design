import SwiftUI

/// Connection-status tone — spec union `'ok' | 'warn' | 'error'`.
public enum FlareConnectionTone: Sendable {
    case ok, warn, error
}

/// The conversation info/settings panel — counts, connection state, and
/// per-conversation actions. Spec: Conversation/ConversationDetails
/// (`ConversationDetailsView`).
/// Localizable row labels for ``ConversationDetailsView``. Defaults keep today's English copy.
public struct FlareConversationDetailsLabels: Sendable {
    public var messages: String
    public var mute: String
    public var pin: String
    public var markRead: String
    public var markUnread: String
    public var sync: String
    public var archive: String
    public var unarchive: String
    public var clearHistory: String
    public var delete: String

    public init(
        messages: String = "Messages",
        mute: String = "Mute",
        pin: String = "Pin conversation",
        markRead: String = "Mark as read",
        markUnread: String = "Mark as unread",
        sync: String = "Sync conversation",
        archive: String = "Archive conversation",
        unarchive: String = "Unarchive",
        clearHistory: String = "Clear chat history",
        delete: String = "Delete conversation"
    ) {
        self.messages = messages
        self.mute = mute
        self.pin = pin
        self.markRead = markRead
        self.markUnread = markUnread
        self.sync = sync
        self.archive = archive
        self.unarchive = unarchive
        self.clearHistory = clearHistory
        self.delete = delete
    }
}

public struct ConversationDetailsView: View {
    private let conversation: FlareConversationSummary
    private let labels: FlareConversationDetailsLabels
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
        labels: FlareConversationDetailsLabels = FlareConversationDetailsLabels(),
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
        self.labels = labels
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
                        Text("\(n) members")
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
                        Text(labels.messages).foregroundColor(colors.textSecondary)
                        Spacer()
                        Text("\(count)").foregroundColor(colors.textPrimary)
                    }
                }
            }

            Section {
                if onMute != nil {
                    Toggle(isOn: Binding(get: { muted }, set: { muted = $0; onMute?($0) })) {
                        Label(labels.mute, systemImage: "bell.slash")
                    }
                }
                if onPin != nil {
                    Toggle(isOn: Binding(get: { pinned }, set: { pinned = $0; onPin?($0) })) {
                        Label(labels.pin, systemImage: "pin")
                    }
                }
            }

            Section {
                if let onMarkRead { row(labels.markRead, "envelope.open", onMarkRead, colors) }
                if let onMarkUnread { row(labels.markUnread, "envelope.badge", onMarkUnread, colors) }
                if let onSync { row(labels.sync, "arrow.triangle.2.circlepath", onSync, colors) }
            }

            Section {
                if let onArchive {
                    row(conversation.archived ? labels.unarchive : labels.archive, "archivebox", onArchive, colors)
                }
                if let onClearHistory { row(labels.clearHistory, "trash.slash", onClearHistory, colors) }
                if let onDelete { row(labels.delete, "trash", onDelete, colors, danger: true) }
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
