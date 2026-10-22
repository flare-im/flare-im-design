import Foundation

// The receipt the core SDK projects for a message (MessageReceiptView {status, readSummary?}) and the row's
// accessible name (docs/design/message-surface-and-meta.md C3 / §6). Pure rules, run against
// spec/message-receipt-vectors.json by all four kits; the views only draw what these return.

/// The SDK's group read summary of the viewer's own message (`MessageReceiptView.readSummary`). There is none in
/// single chats, for incoming messages, above the large-group threshold and while the SDK has no data.
public struct FlareMessageReadSummary: Equatable, Hashable, Sendable {
    public let readCount: Int
    public let unreadCount: Int
    public let total: Int
    public init(readCount: Int, unreadCount: Int, total: Int) {
        self.readCount = readCount; self.unreadCount = unreadCount; self.total = total
    }
}

/// The status glyph a receipt draws.
public enum FlareMessageReceiptGlyph: String, Sendable {
    case clock, spinner, check, doubleCheck, alert
}

/// The read summary line that replaces the check of the viewer's own group message.
public struct FlareMessageReadSummaryLine: Equatable, Sendable {
    /// Everyone it was sent to has read it ("全部已读").
    public let allRead: Bool
    /// The unread count ("N 人未读"); nil when all have read it.
    public let count: Int?

    /// The line's words: `messageReadSummaryUnread` with the count, or `messageReadSummaryAllRead`.
    public func text(_ strings: FlareStrings) -> String {
        guard let count, !allRead else { return strings.messageReadSummaryAllRead }
        return strings.messageReadSummaryUnread.replacingOccurrences(of: "{count}", with: String(count))
    }
}

/// What a receipt draws: the glyph, or the read summary in its place (never both).
public struct FlareMessageReceiptPresentation: Equatable, Sendable {
    public let glyph: FlareMessageReceiptGlyph?
    public let summary: FlareMessageReadSummaryLine?
}

/// The glyph of each status: pending clock, sending spinner, sent single check, read double check, failed alert.
public func flareMessageReceiptGlyph(_ status: FlareMessageDeliveryStatus) -> FlareMessageReceiptGlyph {
    switch status {
    case .pending: return .clock
    case .sending: return .spinner
    case .sent: return .check
    case .read: return .doubleCheck
    case .failed: return .alert
    }
}

/// The receipt of a message (spec rules): incoming messages show nothing; the viewer's own group message with a
/// read summary and status sent or read shows the summary in place of the check; every other own message shows
/// its glyph. A single chat never shows a summary, and without the SDK's numbers there is none.
public func flareMessageReceiptPresentation(conversationKind: FlareConversationKind, isSelf: Bool,
                                            status: FlareMessageDeliveryStatus,
                                            readSummary: FlareMessageReadSummary?) -> FlareMessageReceiptPresentation {
    guard isSelf else { return FlareMessageReceiptPresentation(glyph: nil, summary: nil) }
    if conversationKind == .group, let readSummary, status == .sent || status == .read {
        let unread = max(0, readSummary.unreadCount)
        return FlareMessageReceiptPresentation(
            glyph: nil,
            summary: unread > 0 ? FlareMessageReadSummaryLine(allRead: false, count: unread)
                : FlareMessageReadSummaryLine(allRead: true, count: nil))
    }
    return FlareMessageReceiptPresentation(glyph: flareMessageReceiptGlyph(status), summary: nil)
}

/// The glyph's accessible name: messagePending / messageSending / messageSent / messageRead / messageFailed.
public func flareMessageStatusText(_ status: FlareMessageDeliveryStatus, strings: FlareStrings) -> String {
    switch status {
    case .pending: return strings.messagePending
    case .sending: return strings.messageSending
    case .sent: return strings.messageSent
    case .read: return strings.messageRead
    case .failed: return strings.messageFailed
    }
}

/// The list separator of `locale`: "，" in Chinese, ", " elsewhere.
public func flareListSeparator(_ locale: Locale) -> String {
    locale.identifier.lowercased().hasPrefix("zh") ? "，" : ", "
}

/// One reading unit per message row (spec rules.accessibilityLabel): sender, content summary, time, then for the
/// viewer's own messages the status text (``FlareStrings/messageSendFailedRetry`` while failed) or the read summary
/// that replaced the glyph. Empty parts are skipped; parts are joined with the locale's list separator.
public func flareMessageAccessibilityLabel(sender: String, preview: String, time: String, isSelf: Bool,
                                           status: FlareMessageDeliveryStatus,
                                           conversationKind: FlareConversationKind = .single,
                                           readSummary: FlareMessageReadSummary? = nil,
                                           strings: FlareStrings, locale: Locale) -> String {
    var parts = [sender, preview, time]
    if isSelf {
        let receipt = flareMessageReceiptPresentation(conversationKind: conversationKind, isSelf: true,
                                                      status: status, readSummary: readSummary)
        if let summary = receipt.summary {
            parts.append(summary.text(strings))
        } else {
            parts.append(status == .failed ? strings.messageSendFailedRetry : flareMessageStatusText(status, strings: strings))
        }
    }
    return parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        .joined(separator: flareListSeparator(locale))
}
