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

/// A message body over its meta row (time, edits, delivery). The stack is as wide as the wider of the two; the body
/// keeps its side of the bubble (`bodyTrailing`: an outgoing one), and the meta row sits at the trailing edge for every
/// message — under an incoming picture at the picture's right edge, in an incoming bubble at its bottom right — as on
/// the other kits. Only the meta row moves: an incoming text stays where it starts.
struct FlareMessageMetaStack: Layout {
    let bodyTrailing: Bool
    /// The last subview is the meta row.
    let hasMeta: Bool
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) }
        let height = sizes.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(sizes.count - 1, 0))
        return CGSize(width: sizes.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var y = bounds.minY
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            let trailing = bodyTrailing || (hasMeta && index == subviews.count - 1)
            subview.place(at: CGPoint(x: trailing ? bounds.maxX - size.width : bounds.minX, y: y), anchor: .topLeading,
                          proposal: ProposedViewSize(width: size.width, height: size.height))
            y += size.height + spacing
        }
    }
}

/// One message in a thread — content, sender, grouping, delivery status.
/// Spec: Message/MessageBubble (`MessageBubbleView`). Status comes from host lifecycle state
/// view (optimistic), never a network wait.
///
/// The row draws its content on one surface (`spec/message-surface-vectors.json`, ``FlareMessageSurface``):
/// a text, rich text, voice, file, album or quoting message in the coloured bubble; a picture, sticker or lone
/// emoji bare; a card (plugin cards, red packets, locations, contact and link cards, polls, tasks …) as its own
/// shell with nothing drawn around it — a quote then sits inside the shell at its top; a system line, recall or
/// deletion as a centred notice. The time and receipt sit where `spec/message-meta-placement-vectors.json` puts
/// them: after a text's last line, in the footer of other bubbles, under bare media and cards (spacing xs, trailing,
/// default palette). A failed outgoing bubble takes the failure surface with its glyph as the retry key; under a
/// failed picture or card the text key "发送失败，重试" retries. Both targets are 44pt.
///
/// The viewer's own group message shows the SDK's read summary ("N 人未读" / "全部已读") in place of the check;
/// with `onReadReceiptOpen` it opens the host's read receipt list.
///
/// In multi-select every control of the content is inert and a tap anywhere on the row toggles its selection.
/// The row is one VoiceOver element: sender, content summary, time and status (`spec/message-receipt-vectors.json`
/// accessibility); a card row keeps its controls reachable inside it.
public struct MessageBubbleView: View {
    private let message: FlareMessageData
    private let currentUserId: String
    private let conversationKind: FlareConversationKind
    private let groupPosition: MessageGroupPosition
    private let rowPresentation: MessageRowPresentation
    private let surfaceOverride: FlareMessageSurface?
    private let mediaState: FlareMediaDownloadState?
    private let onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onMediaReveal: ((FlareMessageData, FlareMessageContent) -> Void)?
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
    private let onCardOpen: ((FlareMessageData, String) -> Void)?
    private let onLocationOpen: ((FlareMessageData, FlareLocationContent) -> Void)?
    private let onReadReceiptOpen: ((FlareMessageData) -> Void)?
    /// The list's media defaults; nil outside a list, where a media body owns its own.
    private var mediaSession: FlareMediaSession?
    /// The list's gallery; nil outside a list, where a picture opens alone.
    private var gallery: FlareImageGallerySource?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBubbleMaxWidth) private var bubbleMaxWidth
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareLocateMark) private var locateMark
    @Environment(\.flareContentSurfaces) private var contentSurfaces
    @Environment(\.flareMessageConversationId) private var conversationId
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .footnote) private var quoteTextSize: CGFloat = FlareSizes.fontSizeSm
    /// Notices and the sender's name follow Dynamic Type.
    @ScaledMetric(relativeTo: .footnote) private var smallTextSize: CGFloat = FlareSizes.fontSizeSm
    @ScaledMetric(relativeTo: .caption) private var metaTextSize: CGFloat = FlareSizes.fontSizeXs

    /// - Parameters:
    ///   - surface: The surface to draw on; nil derives it from the content, the quote, the recall / delete state
    ///     and the host's registrations (``flareContentRenderers(_:surfaces:)``). ``MessageListView`` passes the
    ///     one it grouped by.
    ///   - multiSelectMode: Batch-selection mode (same name as Flutter/Compose).
    ///     A check control leads the row, the content is inert and tapping the whole row toggles it.
    ///   - selected: Whether this message is in the host's selection.
    ///   - onToggleSelect: Called with the message id when the row is tapped in
    ///     multi-select mode. Stable ID first; the host owns the selection set.
    ///   - onReact: Tapping a reaction pill toggles the current user's reaction
    ///     (message, emoji); without it the pills are display-only.
    ///   - onLocateMessage: Tapping the reply quote asks for the quoted message
    ///     (`replyTo.messageId`); without it, or without that id, the quote is plain text.
    ///   - onMediaAction: Takes every media tap. Without it the kit opens images and videos in its
    ///     full-screen viewer and plays voice messages in the bubble (see ``MessageContentView``).
    ///   - onMediaDownload: Offered as the download key of the kit's image preview and video player,
    ///     called with the picture or the video on screen, and as the key at the trailing edge of a file
    ///     card; without it none of them has a key.
    ///   - mediaState: The media on this device, as the host knows it — the keys show a download, the
    ///     save's progress, or once it is saved a folder.
    ///   - onMediaReveal: The folder key of a saved file, picture or video (message, the content): the host
    ///     shows it where it was saved, or finds it gone and passes `idle` again.
    ///   - onOpenFile: A file tap when there is no `onMediaAction`: the host opens the file (the kit
    ///     never leaves the app), and images, videos and voice keep the kit defaults.
    ///   - onOpenLink: A tapped link, in the text body or on a link card, with its raw URL. Without it
    ///     the body opens a web address itself after ``safeExternalURL(_:)`` and opens nothing else.
    ///   - onVote: A tapped poll option (message, option index); without it, or in multi-select mode, the
    ///     poll is read-only.
    ///   - onTaskToggle: A tapped task checkbox (message, the done state asked for); without it, or in
    ///     multi-select mode, the task is read-only.
    ///   - onCardOpen: A tapped contact card (message, the user id it shares), for the host to open the profile;
    ///     before `onMediaAction`.
    ///   - onLocationOpen: A tapped location (message, the location); before `onMediaAction`. Without either the
    ///     card opens Apple Maps at the point.
    ///   - onReadReceiptOpen: A tap on the read summary of the viewer's own group message; the host shows who has
    ///     read it. Without it the summary is plain text.
    public init(
        message: FlareMessageData,
        currentUserId: String,
        conversationKind: FlareConversationKind = .single,
        groupPosition: MessageGroupPosition = .single,
        rowPresentation: MessageRowPresentation = MessageRowPresentation(),
        surface: FlareMessageSurface? = nil,
        mediaState: FlareMediaDownloadState? = nil,
        onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onMediaReveal: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onOpenFile: ((FlareMessageData, FlareFileContent) -> Void)? = nil,
        onOpenLink: ((FlareMessageData, String) -> Void)? = nil,
        onResend: ((FlareMessageData) -> Void)? = nil,
        multiSelectMode: Bool = false,
        selected: Bool = false,
        onToggleSelect: ((String) -> Void)? = nil,
        onReact: ((FlareMessageData, String) -> Void)? = nil,
        onLocateMessage: ((String) -> Void)? = nil,
        onVote: ((FlareMessageData, Int) -> Void)? = nil,
        onTaskToggle: ((FlareMessageData, Bool) -> Void)? = nil,
        onCardOpen: ((FlareMessageData, String) -> Void)? = nil,
        onLocationOpen: ((FlareMessageData, FlareLocationContent) -> Void)? = nil,
        onReadReceiptOpen: ((FlareMessageData) -> Void)? = nil
    ) {
        self.message = message
        self.currentUserId = currentUserId
        self.conversationKind = conversationKind
        self.groupPosition = groupPosition
        self.rowPresentation = rowPresentation
        self.surfaceOverride = surface
        self.mediaState = mediaState
        self.onMediaAction = onMediaAction
        self.onMediaDownload = onMediaDownload
        self.onMediaReveal = onMediaReveal
        self.onOpenFile = onOpenFile
        self.onOpenLink = onOpenLink
        self.onResend = onResend
        self.multiSelectMode = multiSelectMode
        self.selected = selected
        self.onToggleSelect = onToggleSelect
        self.onReact = onReact
        self.onVote = onVote
        self.onTaskToggle = onTaskToggle
        self.onCardOpen = onCardOpen
        self.onLocationOpen = onLocationOpen
        self.onLocateMessage = onLocateMessage
        self.onReadReceiptOpen = onReadReceiptOpen
    }

    /// This bubble inside a timeline whose media defaults are `session` and whose pictures are `gallery`.
    func mediaDefaults(_ session: FlareMediaSession?, gallery: FlareImageGallerySource? = nil) -> MessageBubbleView {
        var copy = self
        copy.mediaSession = session
        copy.gallery = gallery
        return copy
    }

    /// The surface this row draws on.
    var surface: FlareMessageSurface { surfaceOverride ?? message.surface(registry: contentSurfaces) }

    /// Where the meta sits on this row.
    var metaPlacement: FlareMessageMetaPlacement {
        flareMessageMetaPlacement(surface: surface, contentType: message.content.specContentType)
    }

    /// The message body, with this message's media handlers and the timeline's media defaults.
    private var content: MessageContentView {
        MessageContentView(
            content: message.content, isSelf: isSelf, senderName: message.senderName, senderId: message.senderId,
            mediaState: mediaState,
            onMediaAction: onMediaAction == nil ? nil : { onMediaAction?(message, $0) },
            onMediaDownload: onMediaDownload == nil ? nil : { onMediaDownload?(message, $0) },
            onMediaReveal: onMediaReveal == nil ? nil : { onMediaReveal?(message, $0) },
            onOpenFile: onOpenFile == nil ? nil : { onOpenFile?(message, $0) },
            onOpenLink: onOpenLink == nil ? nil : { onOpenLink?(message, $0) },
            onVote: onVote == nil ? nil : { onVote?(message, $0) },
            onTaskToggle: onTaskToggle == nil ? nil : { onTaskToggle?(message, $0) },
            onCardOpen: onCardOpen == nil ? nil : { onCardOpen?(message, $0) },
            onLocationOpen: onLocationOpen == nil ? nil : { onLocationOpen?(message, $0) },
            // Multi-select taps select the row: nothing in the body is a control then.
            selectionMode: multiSelectMode)
        .mediaDefaults(mediaSession, messageId: message.id, gallery: gallery)
        // The core's id: the server's once it has one, else the client id the message was sent with.
        .messageIdentity(messageId: message.serverId ?? message.id, conversationId: conversationId)
        .onSurface(surface, failed: failed)
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

    /// The text of a centred row: the system line, the recall notice, or "消息已删除".
    static func noticeText(_ message: FlareMessageData, isSelf: Bool, conversationKind: FlareConversationKind,
                           strings: FlareStrings) -> String {
        if message.isRecalled {
            return recalledNotice(isSelf: isSelf, conversationKind: conversationKind, senderName: message.senderName,
                                  strings: strings)
        }
        if message.isDeleted { return strings.messageDeleted }
        if let notice = message.content as? FlareNotificationContent { return notice.text }
        return flareMessagePreviewText(message.content, strings: strings)
    }

    /// Reaction pill tap: toggles via `onReact` with this message; nil (display-only
    /// pills) when the host supplied no handler.
    static func reactionToggle(_ message: FlareMessageData,
                               onReact: ((FlareMessageData, String) -> Void)?) -> ((String) -> Void)? {
        guard let onReact else { return nil }
        return { onReact(message, $0) }
    }

    /// The quote a bubble shows: the reply target, except on notices (system lines, recalled and deleted
    /// messages quote nothing).
    static func quote(_ message: FlareMessageData) -> FlareReplyTarget? {
        message.isSystem || message.isRecalled || message.isDeleted ? nil : message.replyTo
    }

    /// Quote tap: asks `onLocateMessage` for the quoted message. Nil — a plain, unannounced
    /// quote — without a handler, without a quoted message id, or in multi-select mode.
    static func quoteLocate(_ message: FlareMessageData, multiSelectMode: Bool,
                            onLocateMessage: ((String) -> Void)?) -> (() -> Void)? {
        guard !multiSelectMode, let onLocateMessage,
              let id = quote(message)?.messageId, !id.isEmpty else { return nil }
        return { onLocateMessage(id) }
    }

    /// The row's reading unit (`spec/message-receipt-vectors.json` accessibility): sender, content summary, time,
    /// and the status or read summary of the viewer's own message.
    static func accessibilityLabel(_ message: FlareMessageData, isSelf: Bool, conversationKind: FlareConversationKind,
                                   strings: FlareStrings, locale: Locale) -> String {
        flareMessageAccessibilityLabel(
            sender: message.senderName, preview: flareMessagePreviewText(message.content, strings: strings),
            time: message.timeLabel, isSelf: isSelf, status: message.receiptStatus,
            conversationKind: conversationKind, readSummary: message.readSummary, strings: strings, locale: locale)
    }

    private var isSelf: Bool { message.senderId == currentUserId }
    /// The bubble's tone (spec/message-surface-vectors.json `palette`).
    private var tone: FlareMessageBubbleTone { flareMessageBubbleTone(isSelf: isSelf, status: message.receiptStatus) }
    private var failed: Bool { tone == .failed }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if surface == .centered {
            // Notice only: no content, status, avatar, menu or selection.
            noticeLine(Self.noticeText(message, isSelf: isSelf, conversationKind: conversationKind, strings: strings),
                       colors)
        } else {
            let card = surface == .card
            HStack(alignment: .top, spacing: FlareSizes.spacingSm) {
                if multiSelectMode { selectionControl(colors) }
                if !isSelf && rowPresentation.reserveAvatarSpace { avatar }
                if isSelf { Spacer(minLength: 40) }
                bubbleColumn(colors)
                if !isSelf { Spacer(minLength: 40) }
                if isSelf && rowPresentation.reserveAvatarSpace { avatar }
            }
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.top, groupStart ? FlareSizes.spacingSm : 2)
            .padding(.bottom, groupEnd ? FlareSizes.spacingSm : 2)
            .background(selected ? colors.messageSelectedBackground : Color.clear)
            .modifier(RowTap(action: Self.rowTap(multiSelectMode: multiSelectMode, id: message.id,
                                                onToggleSelect: onToggleSelect)))
            // One reading unit per message. A card keeps its own controls reachable inside it.
            .accessibilityElement(children: card && !multiSelectMode ? .contain : .combine)
            .accessibilityLabel(Self.accessibilityLabel(message, isSelf: isSelf, conversationKind: conversationKind,
                                                        strings: strings, locale: locale))
            .accessibilityAddTraits(multiSelectMode && selected ? .isSelected : [])
        }
    }

    /// Centred notice pill for system lines, recalled and deleted messages.
    private func noticeLine(_ text: String, _ colors: FlareColors) -> some View {
        Text(text)
            .font(.system(size: smallTextSize))
            .foregroundColor(colors.textTertiary)
            .multilineTextAlignment(.center)
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
    /// Only a bubble ending its run draws the tail; bare media and cards never do.
    private var tail: Bool { surface == .bubble && rowPresentation.tail && groupEnd }

    @ViewBuilder
    private var avatar: some View {
        if showAvatar {
            AvatarView(userId: message.senderId, displayName: message.senderName,
                       avatarURL: message.senderAvatarURL, size: FlareSizes.componentMessageAvatarSize)
        } else {
            Color.clear.frame(width: FlareSizes.componentMessageAvatarSize, height: 1)
        }
    }

    private func bubbleColumn(_ colors: FlareColors) -> some View {
        // 最大宽由时间线量一次后经环境下发(见 EnvironmentValues.flareBubbleMaxWidth)。
        VStack(alignment: isSelf ? .trailing : .leading, spacing: 2) {
            if rowPresentation.showSenderName {
                Text(message.senderName)
                    .font(.system(size: smallTextSize))
                    .foregroundColor(colors.textTertiary)
            }
            surfaceBody(colors)
            if !message.reactions.isEmpty {
                // Multi-select taps select the row; pills toggle only outside it.
                ReactionSummaryView(reactions: message.reactions, hideAdd: true,
                                    onToggle: Self.reactionToggle(message, onReact: multiSelectMode ? nil : onReact))
                    .padding(.top, FlareSizes.spacingXs)
            }
        }
        .frame(maxWidth: bubbleMaxWidth, alignment: isSelf ? .trailing : .leading)
    }

    /// Whether the message has a meta row: a time, an edit or a lifecycle to say, or my delivery status.
    private var showsMeta: Bool {
        !message.timeLabel.isEmpty || message.edited || message.lifecycle != nil || isSelf
    }

    private func meta(_ placement: FlareMessageMetaPlacement) -> MessageMetaView {
        MessageMetaView(
            timestamp: message.timeLabel,
            edited: message.edited,
            status: isSelf ? message.status : nil,
            lifecycle: isSelf ? message.lifecycle : nil,
            ephemeral: message.lifecycle?.ephemeral ?? .none,
            placement: placement,
            tone: flareMessageMetaTone(placement: placement, isSelf: isSelf, status: message.receiptStatus),
            readSummary: isSelf ? message.readSummary : nil,
            conversationKind: conversationKind,
            // In multi-select the meta's keys are inert too: the row's tap selects it.
            onResend: onResend == nil || multiSelectMode ? nil : { onResend?(message) },
            onReadReceiptOpen: onReadReceiptOpen == nil || multiSelectMode ? nil : { onReadReceiptOpen?(message) }
        )
    }

    /// The room the inline meta keeps after a text's last line.
    private var inlineReservation: FlareTextTrailingReservation {
        let labels = MessageMetaView.labels(
            timestamp: message.timeLabel, edited: message.edited || message.lifecycle?.mutation == .edited,
            ephemeral: MessageMetaView.ephemeralLabel(message.lifecycle?.ephemeral ?? .none, strings: strings),
            strings: strings)
        let receipt = flareMessageReceiptPresentation(conversationKind: conversationKind, isSelf: isSelf,
                                                      status: message.receiptStatus, readSummary: message.readSummary)
        return FlareTextTrailingReservation(
            text: MessageMetaView.reservation(labels: labels, receipt: receipt, strings: strings), size: metaTextSize)
    }

    @ViewBuilder
    private func bubbleInner(_ colors: FlareColors) -> some View {
        let placement = metaPlacement
        Group {
            if placement == .inline && showsMeta {
                // The meta sits at the end of the text's last line: the text keeps its room there (drawn clear),
                // and wraps it onto a line of its own when the last line is full.
                quoted {
                    content
                        .environment(\.flareTextTrailingReservation, inlineReservation)
                        .overlay(alignment: .bottomTrailing) { meta(.inline) }
                }
            } else {
                FlareMessageMetaStack(bodyTrailing: isSelf, hasMeta: showsMeta, spacing: 3) {
                    quoted { content }
                    if showsMeta { meta(.bubbleFooter) }
                }
            }
        }
        .padding(.horizontal, FlareSizes.componentBubblePaddingX)
        .padding(.vertical, FlareSizes.componentBubblePaddingY)
    }

    /// The content under the reply's quote, when it has one.
    @ViewBuilder
    private func quoted<Body: View>(@ViewBuilder _ body: () -> Body) -> some View {
        if let quote = Self.quote(message) {
            FlareQuoteStack(trailing: isSelf, spacing: FlareSizes.spacingSm) {
                quoteStrip(quote, FlareColors.of(scheme, brand: flareBrandTheme))
                body()
            }
        } else {
            body()
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

    /// The row's surface: the coloured bubble, a bare picture, or a card's own shell with nothing around it.
    @ViewBuilder
    private func surfaceBody(_ colors: FlareColors) -> some View {
        switch surface {
        case .bareMedia, .card:
            let shape = AnyShape(RoundedRectangle(cornerRadius: surface == .card ? FlareSizes.radiusLg
                                                  : FlareSizes.radiusCard, style: .continuous))
            // The meta row under bare media and cards ends at the surface's trailing edge, whoever sent it.
            FlareMessageMetaStack(bodyTrailing: isSelf, hasMeta: showsMeta, spacing: FlareSizes.spacingXs) {
                content
                    // A quoting card draws its quote inside its own shell, at the top.
                    .environment(\.flareMessageCardQuote, surface == .card ? Self.quote(message).map {
                        AnyView(quoteStrip($0, colors))
                    } : nil)
                    .background { locateRing(colors, shape: shape) }
                if showsMeta { meta(.below) }
            }
        case .bubble, .centered:
            let shape = flareBubbleShape(tail ? (isSelf ? .bottomTrailing : .bottomLeading) : .none)
            let palette = flareMessageBubblePalette(tone, colors: colors)
            if let edge = palette.edge {
                // A failed message keeps its red edge on the failure surface, where the failure glyph (the retry)
                // keeps its contrast; it was about 1.5:1 on the outgoing fill.
                bubbleInner(colors)
                    .background(shape.fill(palette.background))
                    .overlay(shape.stroke(edge, lineWidth: 1).allowsHitTesting(false))
                    .background { locateRing(colors, shape: AnyShape(shape)) }
            } else if isSelf {
                bubbleInner(colors)
                    .background(shape.fill(palette.background))
                    .background { locateRing(colors, shape: AnyShape(shape)) }
            } else {
                // Drawn by fill, not by outline: the incoming surface is a tertiary tone the chat canvas
                // never uses, so the bubble has an edge without a hairline to keep in sync with it.
                bubbleInner(colors)
                    .background(shape.fill(palette.background))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                    .background { locateRing(colors, shape: AnyShape(shape)) }
            }
        }
    }

    /// The ring a row wears after a jump landed on it (`spec/locate-highlight-vectors.json`). Only the marked
    /// row draws it, and it is drawn behind the surface, so it neither moves the layout nor covers the message.
    @ViewBuilder
    private func locateRing(_ colors: FlareColors, shape: AnyShape) -> some View {
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
}
