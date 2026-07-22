import SwiftUI

/// One message in a thread — content, sender, grouping, delivery status.
/// Spec: Message/MessageBubble (`MessageBubbleView`). Status comes from the core
/// view (optimistic), never a network wait.
public struct MessageBubbleView: View {
    private let message: FlareMessageData
    private let currentUserId: String
    private let conversationKind: FlareConversationKind
    private let groupStart: Bool
    private let groupEnd: Bool
    private let mediaState: FlareMediaDownloadState?
    private let onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onResend: ((FlareMessageData) -> Void)?

    @Environment(\.colorScheme) private var scheme

    public init(
        message: FlareMessageData,
        currentUserId: String,
        conversationKind: FlareConversationKind = .single,
        groupStart: Bool = true,
        groupEnd: Bool = true,
        mediaState: FlareMediaDownloadState? = nil,
        onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onResend: ((FlareMessageData) -> Void)? = nil
    ) {
        self.message = message
        self.currentUserId = currentUserId
        self.conversationKind = conversationKind
        self.groupStart = groupStart
        self.groupEnd = groupEnd
        self.mediaState = mediaState
        self.onMediaAction = onMediaAction
        self.onResend = onResend
    }

    private var isSelf: Bool { message.senderId == currentUserId }

    public var body: some View {
        let colors = FlareColors.of(scheme)

        if message.isSystem, let n = message.content as? FlareNotificationContent {
            Text(n.text)
                .font(.system(size: FlareSizes.fontSizeSm))
                .foregroundColor(colors.textTertiary)
                .padding(.horizontal, FlareSizes.spacingMd)
                .padding(.vertical, FlareSizes.spacingXs)
                .background(Capsule().fill(colors.bgTertiary))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, FlareSizes.spacingSm)
        } else {
            HStack(alignment: .top, spacing: FlareSizes.spacingSm) {
                if !isSelf { leadingAvatar }
                if isSelf { Spacer(minLength: 40) }
                bubbleColumn(colors)
                if !isSelf { Spacer(minLength: 40) }
            }
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.top, groupStart ? FlareSizes.spacingSm : 2)
            .padding(.bottom, groupEnd ? FlareSizes.spacingSm : 2)
        }
    }

    private var showAvatar: Bool { !isSelf && conversationKind != .single && groupStart }

    @ViewBuilder
    private var leadingAvatar: some View {
        if showAvatar {
            AvatarView(userId: message.senderId, displayName: message.senderName,
                       avatarURL: message.senderAvatarURL, size: 34)
        } else {
            Color.clear.frame(width: 34, height: 1)
        }
    }

    private func bubbleColumn(_ colors: FlareColors) -> some View {
        VStack(alignment: isSelf ? .trailing : .leading, spacing: 2) {
            if showAvatar {
                Text(message.senderName)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
            }
            bubble(colors)
        }
    }

    @ViewBuilder
    private func bubbleInner(_ colors: FlareColors) -> some View {
        VStack(alignment: isSelf ? .trailing : .leading, spacing: 3) {
            MessageContentView(
                content: message.content, isSelf: isSelf, senderName: message.senderName,
                mediaState: mediaState,
                onMediaAction: onMediaAction == nil ? nil : { onMediaAction?(message, $0) })
            // Inline meta: time + (self) delivery status, kept inside the bubble.
            if !message.timeLabel.isEmpty || isSelf {
                HStack(spacing: 4) {
                    if !message.timeLabel.isEmpty {
                        Text(message.timeLabel)
                            .font(.system(size: FlareSizes.fontSizeXs))
                            .foregroundColor(isSelf ? Color.white.opacity(0.8) : colors.textTertiary)
                    }
                    if isSelf {
                        MessageStatusView(status: message.status, variant: .compact,
                                          tint: message.status == .failed ? nil : Color.white.opacity(0.85))
                            .modifier(TapToResend(enabled: message.status == .failed) { onResend?(message) })
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    /// Conditionally attach a resend tap gesture (failed messages only).
    private struct TapToResend: ViewModifier {
        let enabled: Bool
        let action: () -> Void
        func body(content: Content) -> some View {
            if enabled { content.onTapGesture(perform: action) } else { content }
        }
    }

    // Flare thread grammar: received = white card + hairline border + whisper of
    // lift; self = an Aurora "light source" (dimensional violet gradient + soft
    // glow, stronger in dark). Radius 16. Bare media carries its own frame.
    @ViewBuilder
    private func bubble(_ colors: FlareColors) -> some View {
        if Self.isBareMedia(message.content) {
            MessageContentView(
                content: message.content, isSelf: isSelf, senderName: message.senderName,
                mediaState: mediaState,
                onMediaAction: onMediaAction == nil ? nil : { onMediaAction?(message, $0) })
        } else if isSelf {
            let dark = scheme == .dark
            bubbleInner(colors)
                .background(
                    ZStack {
                        colors.bubbleSelf
                        // Lit top-left → deeper bottom-right, for dimensional light.
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.clear, Color.black.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: colors.bubbleSelf.opacity(dark ? 0.55 : 0.38), radius: dark ? 12 : 9, y: 5)
                .shadow(color: colors.bubbleSelf.opacity(dark ? 0.32 : 0.20), radius: dark ? 6 : 4, y: 2)
        } else {
            bubbleInner(colors)
                .background(RoundedRectangle(cornerRadius: 16).fill(colors.bgPrimary))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(colors.borderSecondary, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        }
    }

    static func isBareMedia(_ content: FlareMessageContent) -> Bool {
        content is FlareImageContent || content is FlareVideoContent
            || content is FlareStickerContent || content is FlareEmojiContent
    }
}
