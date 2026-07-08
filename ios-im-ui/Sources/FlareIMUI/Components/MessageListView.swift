import SwiftUI

/// The message thread — grouping, media state, load-older. Spec:
/// Message/MessageList (`MessageListView`). Uses a lazy stack (O(visible));
/// order is oldest→newest. The host feeds `messages` from the timeline view.
public struct MessageListView: View {
    private let messages: [FlareMessageData]
    private let currentUserId: String
    private let conversationKind: FlareConversationKind
    private let loading: Bool
    private let loadingOlder: Bool
    private let mediaDownloadStates: [String: FlareMediaDownloadState]
    private let onMessageLongPress: ((FlareMessageData) -> Void)?
    private let onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onResend: ((FlareMessageData) -> Void)?

    @Environment(\.colorScheme) private var scheme

    public init(
        messages: [FlareMessageData],
        currentUserId: String,
        conversationKind: FlareConversationKind = .single,
        loading: Bool = false,
        loadingOlder: Bool = false,
        mediaDownloadStates: [String: FlareMediaDownloadState] = [:],
        onMessageLongPress: ((FlareMessageData) -> Void)? = nil,
        onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onResend: ((FlareMessageData) -> Void)? = nil
    ) {
        self.messages = messages
        self.currentUserId = currentUserId
        self.conversationKind = conversationKind
        self.loading = loading
        self.loadingOlder = loadingOlder
        self.mediaDownloadStates = mediaDownloadStates
        self.onMessageLongPress = onMessageLongPress
        self.onMediaAction = onMediaAction
        self.onResend = onResend
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if messages.isEmpty {
            if loading {
                ProgressView()
            } else {
                Text("No messages yet")
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textTertiary)
            }
        } else {
            ScrollView {
                if loadingOlder {
                    ProgressView().padding(FlareSizes.spacingMd)
                }
                LazyVStack(spacing: 0) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                        MessageBubbleView(
                            message: msg,
                            currentUserId: currentUserId,
                            conversationKind: conversationKind,
                            groupStart: isGroupStart(index),
                            groupEnd: isGroupEnd(index),
                            mediaState: mediaDownloadStates[msg.id],
                            onMediaAction: onMediaAction,
                            onResend: onResend
                        )
                        .contentShape(Rectangle())
                        .onLongPressGesture { onMessageLongPress?(msg) }
                    }
                }
            }
            .background(colors.bgSecondary)  // faint chat canvas
        }
    }

    private func isGroupStart(_ i: Int) -> Bool {
        guard i > 0 else { return true }
        let prev = messages[i - 1], cur = messages[i]
        return prev.senderId != cur.senderId || prev.isSystem || cur.isSystem
    }

    private func isGroupEnd(_ i: Int) -> Bool {
        guard i < messages.count - 1 else { return true }
        let next = messages[i + 1], cur = messages[i]
        return next.senderId != cur.senderId || next.isSystem || cur.isSystem
    }
}
