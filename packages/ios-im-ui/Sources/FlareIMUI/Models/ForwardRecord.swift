import Foundation

/// How a forward was sent: the core's `mode` (0 unspecified, 1 single, 2 merged).
public enum FlareForwardMode: Int, Sendable, CaseIterable {
    case unspecified = 0, single = 1, merged = 2

    /// The wire value; anything the kit does not know reads as unspecified.
    public init(wire: Int) { self = FlareForwardMode(rawValue: wire) ?? .unspecified }
}

/// One forwarded message of a record: the core's `sourceSenderName`, `sourceMessageTimeMs`, `plainText` and the
/// message's content (mapped with the host's own content mapping; nil when the record carries only text).
public struct FlareForwardItem {
    public let senderName: String
    public let sentAtMs: Int64
    public let plainText: String
    public let content: FlareMessageContent?

    public init(senderName: String = "", sentAtMs: Int64 = 0, plainText: String = "", content: FlareMessageContent? = nil) {
        self.senderName = senderName; self.sentAtMs = sentAtMs; self.plainText = plainText; self.content = content
    }
}

/// A forward record (the chat history card). Hosts map the core's `contentType: "forward"` (or `merged_forward`) to
/// it: `title`, `mode` and `items[]` from `sourceSenderName / sourceMessageTimeMs / plainText / content`. Its surface
/// is `card` (spec/message-surface-vectors.json). Drawn by ``MessageContentView`` (``FlareForwardMessageView``).
public struct FlareForwardContent: FlareMessageContent {
    public let title: String
    public let mode: FlareForwardMode
    public let items: [FlareForwardItem]

    public init(title: String = "", mode: FlareForwardMode = .unspecified, items: [FlareForwardItem] = []) {
        self.title = title; self.mode = mode; self.items = items
    }

    public var type: String { "forward" }
}

/// What a forward record draws (spec/message-forward-vectors.json), the same facts on every kit.
public struct FlareForwardRecordView: Equatable, Sendable {
    public enum Layout: String, Sendable {
        /// No items: one line, `forwardRecordEmpty`.
        case empty
        /// Exactly one item and the mode is not merged: that item's content drawn as it is.
        case single
        /// The record card.
        case card
    }

    /// One preview line of the card: the sender and the summary.
    public struct Preview: Equatable, Sendable {
        public let sender: String
        public let text: String
    }

    public let layout: Layout
    /// The card's title: the record's title trimmed, else `forwardRecordTitle`.
    public let title: String
    /// "共 N 条消息" when there is more than one item.
    public let subtitle: String?
    /// The first three items.
    public let previews: [Preview]
    /// "还有 N 条消息…" past three items.
    public let more: String?
    public let hint: String
    /// The card's accessible name: "{title}，{subtitle}", or the title alone.
    public let label: String
    /// The drawer's title: "{title}（N 条）".
    public let drawerTitle: String
}

/// The sender of a forwarded item as the record writes it: the name trimmed, else `forwardRecordUnknownSender`.
public func flareForwardSender(_ item: FlareForwardItem, strings: FlareStrings) -> String {
    let name = item.senderName.trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty ? strings.forwardRecordUnknownSender : name
}

/// The drawer avatar's initial for a forwarded item: the first character of the sender's name (trimmed), upper-cased;
/// "?" without a name — never the first character of `forwardRecordUnknownSender`.
public func flareForwardSenderInitial(_ item: FlareForwardItem) -> String {
    let name = item.senderName.trimmingCharacters(in: .whitespacesAndNewlines)
    return name.first.map { String($0).uppercased() } ?? "?"
}

/// The one-line summary of a forwarded item: its plain text read as a text body's summary is (trimmed, Markdown to
/// plain text, emoji-pack keys in the reader's language), else the kit's summary of its content
/// (``flareMessagePreviewText(_:strings:locale:)``), else `previewForward`. Line breaks become spaces. The kit never
/// decodes the plain text further: the core wrote it with the conversation list's rules.
public func flareForwardSummary(_ item: FlareForwardItem, strings: FlareStrings, locale: Locale = .current) -> String {
    let oneLine: (String) -> String = {
        $0.components(separatedBy: .newlines).joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
    let plain = oneLine(flareMessagePreviewText(FlareTextContent(item.plainText), strings: strings,
                                                locale: locale.identifier))
    if !plain.isEmpty { return plain }
    let summary = oneLine(flareMessagePreviewText(item.content, strings: strings, locale: locale.identifier))
    return summary.isEmpty ? strings.previewForward : summary
}

/// The record's layout and copy (spec/message-forward-vectors.json rules). The plural forms follow `locale`.
public func flareForwardRecordView(_ content: FlareForwardContent, strings: FlareStrings,
                                   locale: Locale = .current) -> FlareForwardRecordView {
    let count = content.items.count
    let layout: FlareForwardRecordView.Layout = count == 0 ? .empty
        : count == 1 && content.mode != .merged ? .single
        : .card
    let trimmed = content.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let title = trimmed.isEmpty ? strings.forwardRecordTitle : trimmed
    let subtitle = count > 1 ? strings.forwardRecordTotalText(count, locale: locale) : nil
    let previews = content.items.prefix(3).map {
        FlareForwardRecordView.Preview(sender: flareForwardSender($0, strings: strings),
                                       text: flareForwardSummary($0, strings: strings, locale: locale))
    }
    let more = count > 3 ? strings.forwardRecordMoreText(count - 3, locale: locale) : nil
    let label = subtitle.map {
        strings.forwardRecordCardLabel.replacingOccurrences(of: "{title}", with: title)
            .replacingOccurrences(of: "{subtitle}", with: $0)
    } ?? title
    let drawerTitle = title + strings.forwardRecordCountSuffix.replacingOccurrences(of: "{count}", with: String(count))
    return FlareForwardRecordView(layout: layout, title: title, subtitle: subtitle, previews: Array(previews),
                                  more: more, hint: strings.forwardRecordViewDetails, label: label,
                                  drawerTitle: drawerTitle)
}
