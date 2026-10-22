import SwiftUI

public enum FlareMessageMetaDensity: Sendable { case compact, normal }

/// Stable metadata row for time, mutation, ephemeral state, and the outgoing receipt. Spec: Message/MessageMeta
/// (`MessageMetaView`); placement and palette follow `spec/message-meta-placement-vectors.json`, the receipt
/// `spec/message-receipt-vectors.json`.
///
/// - `placement`: inline and bubbleFooter sit inside a bubble (the bubble lays them out); below sits under a bare
///   picture or a card in the default palette; none draws nothing.
/// - `tone`: ``FlareMessageMetaTone/onOutgoing`` inside an outgoing bubble that has not failed, else default
///   (``FlareColors/messageMetaForeground`` and the default receipt palette).
/// - The viewer's own group message with the SDK's `readSummary` and status sent or read shows "N 人未读" /
///   "全部已读" in place of the check; with `onReadReceiptOpen` it is a text key (44pt target) that asks for the
///   read receipt list. Incoming messages pass no status and show no receipt.
/// - Failed with `onResend`: inside a bubble the failed glyph is the retry key; below a surface the text key
///   "发送失败，重试" in the failure colour replaces the glyph, before the time. Both targets are 44pt.
public struct MessageMetaView: View {
    @ScaledMetric(relativeTo: .caption) private var metaTextSize: CGFloat = FlareSizes.fontSizeXs
    private let timestamp: String
    private let edited: Bool
    private let status: FlareMessageDeliveryStatus?
    private let lifecycle: FlareMessageLifecycle?
    private let ephemeral: FlareMessageEphemeralState
    private let density: FlareMessageMetaDensity
    let placement: FlareMessageMetaPlacement
    private let tone: FlareMessageMetaTone
    private let readSummary: FlareMessageReadSummary?
    private let conversationKind: FlareConversationKind?
    private let onResend: (() -> Void)?
    private let onReadReceiptOpen: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameter conversationKind: The read summary shows only in a group; nil takes a summary as given (the SDK
    ///   gives one only for groups).
    public init(
        timestamp: String = "",
        edited: Bool = false,
        status: FlareMessageDeliveryStatus? = nil,
        lifecycle: FlareMessageLifecycle? = nil,
        ephemeral: FlareMessageEphemeralState = .none,
        density: FlareMessageMetaDensity = .compact,
        placement: FlareMessageMetaPlacement = .bubbleFooter,
        tone: FlareMessageMetaTone = .default,
        readSummary: FlareMessageReadSummary? = nil,
        conversationKind: FlareConversationKind? = nil,
        onResend: (() -> Void)? = nil,
        onReadReceiptOpen: (() -> Void)? = nil
    ) {
        self.timestamp = timestamp
        self.edited = edited
        self.status = status
        self.lifecycle = lifecycle
        self.ephemeral = ephemeral
        self.density = density
        self.placement = placement
        self.tone = tone
        self.readSummary = readSummary
        self.conversationKind = conversationKind
        self.onResend = onResend
        self.onReadReceiptOpen = onReadReceiptOpen
    }

    private var ephemeralLabel: String { Self.ephemeralLabel(lifecycle?.ephemeral ?? ephemeral, strings: strings) }

    static func ephemeralLabel(_ state: FlareMessageEphemeralState, strings: FlareStrings) -> String {
        switch state {
        case .none: return ""
        case .readOnce: return strings.messageReadOnce
        case .burnAfterRead: return strings.messageBurnAfterRead
        case .expired: return strings.messageExpired
        }
    }

    /// The time and the edited / ephemeral labels, joined.
    static func labels(timestamp: String, edited: Bool, ephemeral: String, strings: FlareStrings) -> String {
        [timestamp.isEmpty ? nil : timestamp, edited ? strings.messageEdited : nil, ephemeral.isEmpty ? nil : ephemeral]
            .compactMap { $0 }.joined(separator: " · ")
    }

    /// The status the row shows: the lifecycle's projection, else `status`; nil for incoming messages.
    private var shownStatus: FlareMessageDeliveryStatus? {
        guard status != nil || lifecycle != nil else { return nil }
        return lifecycle?.visualStatus ?? status ?? .sent
    }

    /// The receipt this row draws.
    var receipt: FlareMessageReceiptPresentation {
        guard let shown = shownStatus else { return FlareMessageReceiptPresentation(glyph: nil, summary: nil) }
        return flareMessageReceiptPresentation(conversationKind: conversationKind ?? .group, isSelf: true,
                                               status: shown, readSummary: readSummary)
    }

    /// The text that holds the meta's room at the end of a text's last line (inline placement): its labels and the
    /// receipt, with a little air before them.
    static func reservation(labels: String, receipt: FlareMessageReceiptPresentation, strings: FlareStrings) -> String {
        var text = "\u{00A0}\u{00A0}\u{00A0}" + labels
        if let summary = receipt.summary { text += "\u{00A0}\u{00A0}" + summary.text(strings) }
        else if receipt.glyph != nil { text += "\u{00A0}\u{2003}\u{2002}" }
        return text
    }

    public var body: some View {
        if placement != .none { row }
    }

    private var row: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let labels = Self.labels(timestamp: timestamp, edited: edited || lifecycle?.mutation == .edited,
                                 ephemeral: ephemeralLabel, strings: strings)
        let onBubble = tone == .onOutgoing
        let textColor = onBubble ? colors.messageStatusOnOutgoing : colors.messageMetaForeground
        // Below a surface the failure is a text key; without a resend listener the glyph stays and nothing taps.
        let failedBelow = placement == .below && shownStatus == .failed && onResend != nil
        let receipt = self.receipt
        return HStack(spacing: density == .compact ? FlareSizes.spacingXs : FlareSizes.spacing2xs) {
            if failedBelow { retryKey(colors) }
            if !labels.isEmpty {
                Text(labels)
                    .font(.system(size: metaTextSize))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
            }
            if let summary = receipt.summary {
                summaryKey(summary, onBubble: onBubble, colors: colors)
            } else if let shown = shownStatus, !failedBelow {
                MessageStatusView(status: shown, variant: .compact,
                                  tint: onBubble ? colors.messageStatusOnOutgoing : nil, onResend: onResend)
            }
        }
        .frame(minHeight: FlareSizes.iconSizeSm)
    }

    /// The row's height for a key inside it: the line, never under the glyph's.
    private var lineHeight: CGFloat { max(FlareSizes.iconSizeSm, (metaTextSize * 1.25).rounded(.up)) }

    /// "发送失败，重试" under a failed picture or card: the retry key, its target 44pt.
    private func retryKey(_ colors: FlareColors) -> some View {
        Button { onResend?() } label: {
            Text(strings.messageSendFailedRetry)
                .font(.system(size: metaTextSize, weight: .medium))
                .foregroundStyle(colors.messageStatusFailed)
                .lineLimit(1)
                .fixedSize()
                .flareTouchTarget()
        }
        .buttonStyle(.plain)
        .flareCompactLayout(height: lineHeight)
        .accessibilityLabel(strings.messageSendFailedRetry)
    }

    /// "N 人未读" / "全部已读": a key with `onReadReceiptOpen`, plain text without.
    @ViewBuilder
    private func summaryKey(_ summary: FlareMessageReadSummaryLine, onBubble: Bool, colors: FlareColors) -> some View {
        let color: Color = summary.allRead
            ? (onBubble ? colors.messageStatusReadOnOutgoing : colors.messageStatusRead)
            : (onBubble ? colors.messageStatusOnOutgoing : colors.messageMetaForeground)
        let text = summary.text(strings)
        let label = Text(text)
            .font(.system(size: metaTextSize, weight: summary.allRead ? .regular : .medium))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
        if let onReadReceiptOpen {
            Button(action: onReadReceiptOpen) { label.flareTouchTarget() }
                .buttonStyle(.plain)
                .flareCompactLayout(height: lineHeight)
                .accessibilityLabel(text)
        } else {
            label.accessibilityLabel(text)
        }
    }
}
