import SwiftUI

/// Where a bubble's 4pt directional tail sits (radius 16 elsewhere). Matches the
/// Android / Flutter bubble grammar: self = bottom-trailing, incoming =
/// bottom-leading, typing = top-leading.
enum FlareBubbleTail: Sendable { case none, bottomTrailing, bottomLeading, topLeading }

/// Radius-16 bubble shape with an optional 4pt tail corner.
func flareBubbleShape(_ tail: FlareBubbleTail, radius: CGFloat = 16, tailRadius: CGFloat = 4) -> UnevenRoundedRectangle {
    let r = radius, t = tailRadius
    switch tail {
    case .none:
        return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: r, bottomTrailingRadius: r, topTrailingRadius: r, style: .continuous)
    case .bottomTrailing:
        return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: r, bottomTrailingRadius: t, topTrailingRadius: r, style: .continuous)
    case .bottomLeading:
        return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: t, bottomTrailingRadius: r, topTrailingRadius: r, style: .continuous)
    case .topLeading:
        return UnevenRoundedRectangle(topLeadingRadius: t, bottomLeadingRadius: r, bottomTrailingRadius: r, topTrailingRadius: r, style: .continuous)
    }
}

/// A reply's quote stacked over the bubble content. The stack is as wide as the content, or
/// as the quote when that is wider (never wider than proposed); the quote then spans that
/// width, so a short quote does not leave a stub and a long one truncates instead of widening
/// the bubble. The content keeps the bubble's alignment.
struct FlareQuoteStack: Layout {
    let trailing: Bool
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        guard let quote = subviews.first else { return .zero }
        let content = subviews.dropFirst().map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) }
        let quoteWidth = min(quote.sizeThatFits(.unspecified).width, proposal.width ?? .infinity)
        let width = max(quoteWidth, content.map(\.width).max() ?? 0)
        let quoteHeight = quote.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        return CGSize(width: width, height: content.reduce(quoteHeight) { $0 + spacing + $1.height })
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var y = bounds.minY
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            let width = index == 0 ? bounds.width : size.width
            let x = trailing && index > 0 ? bounds.maxX - width : bounds.minX
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                          proposal: ProposedViewSize(width: width, height: size.height))
            y += size.height + spacing
        }
    }
}

/// One message in a thread — content, sender, grouping, delivery status.
/// Spec: Message/MessageBubble (`MessageBubbleView`). Status comes from host lifecycle state
/// view (optimistic), never a network wait.
public struct MessageBubbleView: View {
    private let message: FlareMessageData
    private let currentUserId: String
    private let conversationKind: FlareConversationKind
    private let groupPosition: MessageGroupPosition
    private let rowPresentation: MessageRowPresentation
    private let mediaState: FlareMediaDownloadState?
    private let onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onOpenFile: ((FlareMessageData, FlareFileContent) -> Void)?
    private let onOpenLink: ((FlareMessageData, String) -> Void)?
    private let onResend: ((FlareMessageData) -> Void)?
    private let multiSelectMode: Bool
    private let selected: Bool
    private let onToggleSelect: ((String) -> Void)?
    private let onReact: ((FlareMessageData, String) -> Void)?
    private let onLocateMessage: ((String) -> Void)?
    private let onVote: ((FlareMessageData, Int) -> Void)?
    private let onTaskToggle: ((FlareMessageData, Bool) -> Void)?
    /// The list's media defaults; nil outside a list, where a media body owns its own.
    private var mediaSession: FlareMediaSession?
    /// The list's gallery; nil outside a list, where a picture opens alone.
    private var gallery: FlareImageGallerySource?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareLocateMark) private var locateMark
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .footnote) private var quoteTextSize: CGFloat = FlareSizes.fontSizeSm

    /// - Parameters:
    ///   - multiSelectMode: Batch-selection mode (same name as Flutter/Compose).
    ///     A check control leads the row and tapping the whole row toggles it.
    ///   - selected: Whether this message is in the host's selection.
    ///   - onToggleSelect: Called with the message id when the row is tapped in
    ///     multi-select mode. Stable ID first; the host owns the selection set.
    ///   - onReact: Tapping a reaction pill toggles the current user's reaction
    ///     (message, emoji); without it the pills are display-only.
    ///   - onLocateMessage: Tapping the reply quote asks for the quoted message
    ///     (`replyTo.messageId`); without it, or without that id, the quote is plain text.
    ///   - onMediaAction: Takes every media tap. Without it the kit opens images and videos in its
    ///     full-screen viewer and plays voice messages in the bubble (see ``MessageContentView``).
    ///   - onMediaDownload: Offered as the download key of the kit's image preview; without it the
    ///     preview has no download key.
    ///   - onOpenFile: A file tap when there is no `onMediaAction`: the host opens the file (the kit
    ///     never leaves the app), and images, videos and voice keep the kit defaults.
    ///   - onOpenLink: A tapped link, in the text body or on a link card, with its raw URL. Without it
    ///     the body opens a web address itself after ``safeExternalURL(_:)`` and opens nothing else.
    ///   - onVote: A tapped poll option (message, option index); without it, or in multi-select mode, the
    ///     poll is read-only.
    ///   - onTaskToggle: A tapped task checkbox (message, the done state asked for); without it, or in
    ///     multi-select mode, the task is read-only.
    public init(
        message: FlareMessageData,
        currentUserId: String,
        conversationKind: FlareConversationKind = .single,
        groupPosition: MessageGroupPosition = .single,
        rowPresentation: MessageRowPresentation = MessageRowPresentation(),
        mediaState: FlareMediaDownloadState? = nil,
        onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onOpenFile: ((FlareMessageData, FlareFileContent) -> Void)? = nil,
        onOpenLink: ((FlareMessageData, String) -> Void)? = nil,
        onResend: ((FlareMessageData) -> Void)? = nil,
        multiSelectMode: Bool = false,
        selected: Bool = false,
        onToggleSelect: ((String) -> Void)? = nil,
        onReact: ((FlareMessageData, String) -> Void)? = nil,
        onLocateMessage: ((String) -> Void)? = nil,
        onVote: ((FlareMessageData, Int) -> Void)? = nil,
        onTaskToggle: ((FlareMessageData, Bool) -> Void)? = nil
    ) {
        self.message = message
        self.currentUserId = currentUserId
        self.conversationKind = conversationKind
        self.groupPosition = groupPosition
        self.rowPresentation = rowPresentation
        self.mediaState = mediaState
        self.onMediaAction = onMediaAction
        self.onMediaDownload = onMediaDownload
        self.onOpenFile = onOpenFile
        self.onOpenLink = onOpenLink
        self.onResend = onResend
        self.multiSelectMode = multiSelectMode
        self.selected = selected
        self.onToggleSelect = onToggleSelect
        self.onReact = onReact
        self.onVote = onVote
        self.onTaskToggle = onTaskToggle
        self.onLocateMessage = onLocateMessage
    }

    /// This bubble inside a timeline whose media defaults are `session` and whose pictures are `gallery`.
    func mediaDefaults(_ session: FlareMediaSession?, gallery: FlareImageGallerySource? = nil) -> MessageBubbleView {
        var copy = self
        copy.mediaSession = session
        copy.gallery = gallery
        return copy
    }

    /// The message body, with this message's media handlers and the timeline's media defaults.
    private var content: MessageContentView {
        MessageContentView(
            content: message.content, isSelf: isSelf, senderName: message.senderName,
            mediaState: mediaState,
            onMediaAction: onMediaAction == nil ? nil : { onMediaAction?(message, $0) },
            onMediaDownload: onMediaDownload == nil ? nil : { onMediaDownload?(message, $0) },
            onOpenFile: onOpenFile == nil ? nil : { onOpenFile?(message, $0) },
            onOpenLink: onOpenLink == nil ? nil : { onOpenLink?(message, $0) },
            // Multi-select taps select the row: a poll or a task is not a control then.
            onVote: onVote == nil || multiSelectMode ? nil : { onVote?(message, $0) },
            onTaskToggle: onTaskToggle == nil || multiSelectMode ? nil : { onTaskToggle?(message, $0) })
        .mediaDefaults(mediaSession, messageId: message.id, gallery: gallery)
    }

    /// Check-control glyph: filled when selected, hollow ring otherwise, so the
    /// state is legible without colour (Flutter check_circle / radio_button_unchecked).
    static func selectionSymbol(selected: Bool) -> String {
        selected ? "checkmark.circle.fill" : "circle"
    }

    /// Row tap in multi-select mode toggles selection; outside it the row has no
    /// tap of its own (media/resend keep their inner gestures).
    static func rowTap(multiSelectMode: Bool, id: String,
                       onToggleSelect: ((String) -> Void)?) -> (() -> Void)? {
        guard multiSelectMode, let onToggleSelect else { return nil }
        return { onToggleSelect(id) }
    }

    /// Recalled-notice copy: your own message, a named member in a group, or the
    /// peer otherwise (same rule as Compose `MessageBubble`).
    static func recalledNotice(isSelf: Bool, conversationKind: FlareConversationKind,
                               senderName: String, strings: FlareStrings) -> String {
        if isSelf { return strings.messageRecalledSelf }
        if conversationKind == .group { return strings.messageRecalledGroupOther(senderName) }
        return strings.messageRecalledPeer
    }

    /// Reaction pill tap: toggles via `onReact` with this message; nil (display-only
    /// pills) when the host supplied no handler.
    static func reactionToggle(_ message: FlareMessageData,
                               onReact: ((FlareMessageData, String) -> Void)?) -> ((String) -> Void)? {
        guard let onReact else { return nil }
        return { onReact(message, $0) }
    }

    /// The quote a bubble shows: the reply target, except on notices (system lines and
    /// recalled messages quote nothing).
    static func quote(_ message: FlareMessageData) -> FlareReplyTarget? {
        message.isSystem || message.isRecalled ? nil : message.replyTo
    }

    /// Quote tap: asks `onLocateMessage` for the quoted message. Nil — a plain, unannounced
    /// quote — without a handler, without a quoted message id, or in multi-select mode.
    static func quoteLocate(_ message: FlareMessageData, multiSelectMode: Bool,
                            onLocateMessage: ((String) -> Void)?) -> (() -> Void)? {
        guard !multiSelectMode, let onLocateMessage,
              let id = quote(message)?.messageId, !id.isEmpty else { return nil }
        return { onLocateMessage(id) }
    }

    /// Bare media draws without bubble chrome — unless it carries a quote, which always
    /// sits inside the bubble.
    static func isChromeless(_ message: FlareMessageData) -> Bool {
        isBareMedia(message.content) && quote(message) == nil
    }

    private var isSelf: Bool { message.senderId == currentUserId }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)

        if message.isSystem, let n = message.content as? FlareNotificationContent {
            noticeLine(n.text, colors)
        } else if message.isRecalled {
            // Notice only: no content, status, avatar or selection.
            noticeLine(Self.recalledNotice(isSelf: isSelf, conversationKind: conversationKind,
                                           senderName: message.senderName, strings: strings), colors)
        } else {
            HStack(alignment: .top, spacing: FlareSizes.spacingSm) {
                if multiSelectMode { selectionControl(colors) }
                if !isSelf && rowPresentation.reserveAvatarSpace { leadingAvatar }
                if isSelf { Spacer(minLength: 40) }
                bubbleColumn(colors)
                if !isSelf { Spacer(minLength: 40) }
                if isSelf && rowPresentation.reserveAvatarSpace { trailingAvatar }
            }
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.top, groupStart ? FlareSizes.spacingSm : 2)
            .padding(.bottom, groupEnd ? FlareSizes.spacingSm : 2)
            .background(selected ? colors.messageSelectedBackground : Color.clear)
            .modifier(RowTap(action: Self.rowTap(multiSelectMode: multiSelectMode, id: message.id,
                                                onToggleSelect: onToggleSelect)))
        }
    }

    /// Centred notice pill for system lines and recalled messages.
    private func noticeLine(_ text: String, _ colors: FlareColors) -> some View {
        Text(text)
            .font(.system(size: FlareSizes.fontSizeSm))
            .foregroundColor(colors.textTertiary)
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.vertical, FlareSizes.spacingXs)
            .background(Capsule().fill(colors.bgTertiary))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, FlareSizes.spacingSm)
    }

    private func selectionControl(_ colors: FlareColors) -> some View {
        Image(systemName: Self.selectionSymbol(selected: selected))
            .font(.system(size: 22))
            .foregroundColor(selected ? colors.primaryText : colors.textTertiary)
            .frame(width: 24, height: 24)
            .padding(.top, showAvatar ? 5 : 0)
            .accessibilityLabel(strings.select)
            .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    /// Conditionally attach the whole-row tap (multi-select mode only).
    private struct RowTap: ViewModifier {
        let action: (() -> Void)?
        func body(content: Content) -> some View {
            if let action { content.contentShape(Rectangle()).onTapGesture(perform: action) } else { content }
        }
    }

    private var groupStart: Bool { groupPosition == .single || groupPosition == .first }
    private var groupEnd: Bool { groupPosition == .single || groupPosition == .last }
    private var showAvatar: Bool { rowPresentation.showAvatar }

    @ViewBuilder
    private var leadingAvatar: some View {
        if showAvatar {
            AvatarView(userId: message.senderId, displayName: message.senderName,
                       avatarURL: message.senderAvatarURL, size: 34)
        } else {
            Color.clear.frame(width: 34, height: 1)
        }
    }

    @ViewBuilder
    private var trailingAvatar: some View {
        if showAvatar {
            AvatarView(userId: message.senderId, displayName: message.senderName,
                       avatarURL: message.senderAvatarURL, size: 34)
        } else {
            Color.clear.frame(width: 34, height: 1)
        }
    }

    private func bubbleColumn(_ colors: FlareColors) -> some View {
        VStack(alignment: isSelf ? .trailing : .leading, spacing: 2) {
            if rowPresentation.showSenderName {
                Text(message.senderName)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
            }
            bubble(colors)
            if !message.reactions.isEmpty {
                // Multi-select taps select the row; pills toggle only outside it.
                ReactionSummaryView(reactions: message.reactions, hideAdd: true,
                                    onToggle: Self.reactionToggle(message, onReact: multiSelectMode ? nil : onReact))
                    .padding(.top, FlareSizes.spacingXs)
            }
        }
    }

    @ViewBuilder
    private func bubbleInner(_ colors: FlareColors) -> some View {
        Group {
            if let quote = Self.quote(message) {
                FlareQuoteStack(trailing: isSelf, spacing: FlareSizes.spacingSm) {
                    quoteStrip(quote, colors)
                    bubbleContent(colors)
                }
            } else {
                bubbleContent(colors)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private func bubbleContent(_ colors: FlareColors) -> some View {
        VStack(alignment: isSelf ? .trailing : .leading, spacing: 3) {
            content
            // Inline meta: time + (self) delivery status, kept inside the bubble.
            if !message.timeLabel.isEmpty || message.edited || message.lifecycle != nil || isSelf {
                MessageMetaView(
                    timestamp: message.timeLabel,
                    edited: message.edited,
                    status: isSelf ? message.status : nil,
                    lifecycle: isSelf ? message.lifecycle : nil,
                    ephemeral: message.lifecycle?.ephemeral ?? .none,
                    tint: isSelf
                        ? (message.status == .read ? colors.messageStatusReadOnOutgoing : colors.messageStatusOnOutgoing)
                        : nil,
                    onResend: onResend == nil ? nil : { onResend?(message) }
                )
            }
        }
    }

    /// The reply's quote: accent bar, quoted sender (omitted when empty) and a one-line summary.
    /// A button only when it can locate the quoted message; otherwise one plain text element.
    @ViewBuilder
    private func quoteStrip(_ quote: FlareReplyTarget, _ colors: FlareColors) -> some View {
        if let locate = Self.quoteLocate(message, multiSelectMode: multiSelectMode, onLocateMessage: onLocateMessage) {
            Button(action: locate) { quoteLabel(quote, colors, minHeight: FlareSizes.touchTargetMin) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(strings.messageQuoteLabel(quote.senderName, quote.summary))
                .accessibilityAddTraits(.isButton)
        } else {
            quoteLabel(quote, colors, minHeight: nil).accessibilityElement(children: .combine)
        }
    }

    private func quoteLabel(_ quote: FlareReplyTarget, _ colors: FlareColors, minHeight: CGFloat?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if !quote.senderName.isEmpty {
                Text(quote.senderName)
                    .font(.system(size: quoteTextSize, weight: .medium))
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }
            Text(quote.summary)
                .font(.system(size: quoteTextSize))
                .foregroundColor(colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, FlareSizes.spacingSm)
        .padding(.vertical, FlareSizes.spacing2xs)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .background(colors.messageReplyBackground)
        // The 3pt start accent bar of the reply contract.
        .overlay(alignment: .leading) { Rectangle().fill(colors.messageReplyBorder).frame(width: 3) }
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusSm))
        .contentShape(Rectangle())
    }

    // Quiet, directional message surfaces; bare media retains its own frame.
    @ViewBuilder
    private func bubble(_ colors: FlareColors) -> some View {
        if Self.isChromeless(message) {
            VStack(alignment: isSelf ? .trailing : .leading, spacing: FlareSizes.spacingXs) {
                content
                if !message.timeLabel.isEmpty || message.edited || message.lifecycle != nil || isSelf {
                    MessageMetaView(
                        timestamp: message.timeLabel,
                        edited: message.edited,
                        status: isSelf ? message.status : nil,
                        lifecycle: isSelf ? message.lifecycle : nil,
                        ephemeral: message.lifecycle?.ephemeral ?? .none,
                        tint: nil,
                        onResend: onResend == nil ? nil : { onResend?(message) }
                    )
                }
            }
        } else if isSelf {
            bubbleInner(colors)
                .background(colors.messageOutgoingBackground)
                .clipShape(flareBubbleShape(groupEnd ? .bottomTrailing : .none))
                .background { locateRing(colors, shape: flareBubbleShape(groupEnd ? .bottomTrailing : .none)) }
        } else {
            bubbleInner(colors)
                .background(flareBubbleShape(groupEnd ? .bottomLeading : .none).fill(colors.messageIncomingBackground))
                .overlay(flareBubbleShape(groupEnd ? .bottomLeading : .none).strokeBorder(colors.messageIncomingBorder, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                .background { locateRing(colors, shape: flareBubbleShape(groupEnd ? .bottomLeading : .none)) }
        }
    }

    /// The ring a row wears after a jump landed on it (`spec/locate-highlight-vectors.json`). Only the marked
    /// row draws it, and it is drawn behind the bubble, so it neither moves the layout nor covers the message.
    @ViewBuilder
    private func locateRing(_ colors: FlareColors, shape: UnevenRoundedRectangle) -> some View {
        if locateMark.messageId == message.id {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(locateMark.startedAt) * 1000
                let mark = FlareLocateHighlight.resolve(elapsedMs: elapsed, reduceMotion: reduceMotion)
                shape
                    .fill(colors.primary.opacity(mark.marked ? mark.alpha : 0))
                    .padding(-mark.spread)
            }
            .accessibilityHidden(true)
        }
    }

    static func isBareMedia(_ content: FlareMessageContent) -> Bool {
        content is FlareImageContent || content is FlareVideoContent
            || content is FlareStickerContent || content is FlareEmojiContent
    }
}
