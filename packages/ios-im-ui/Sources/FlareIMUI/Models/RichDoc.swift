import Foundation

// A rich-text message as it is drawn: the RichDoc v2 document the core stores (`docJson`, flare-proto
// `RichTextContent.doc_json`) read into blocks and runs. The rule is shared with the other three kits and
// written down in `spec/rich-doc-vectors.json`; Vue implements it in `utils/richDoc.ts`.

/// The marks a run can carry, in the order a run lists them.
public enum FlareRichMark: String, CaseIterable, Sendable {
    case bold, italic, underline, strike, spoiler
}

/// One run of a paragraph or heading.
public struct FlareRichRun: Equatable, Sendable {
    public let text: String
    /// The known marks, once each, in ``FlareRichMark`` order.
    public let marks: [FlareRichMark]
    /// Inline code.
    public let code: Bool
    /// The href of the innermost link around the run that ``safeExternalURL(_:)`` accepts, as written.
    public let link: String?
    /// A mention: the user id it names, possibly empty.
    public let mention: String?
    /// An emoji: its pack key, possibly empty.
    public let emoji: String?

    public init(_ text: String, marks: [FlareRichMark] = [], code: Bool = false, link: String? = nil,
                mention: String? = nil, emoji: String? = nil) {
        self.text = text; self.marks = marks; self.code = code; self.link = link
        self.mention = mention; self.emoji = emoji
    }

    public func has(_ mark: FlareRichMark) -> Bool { marks.contains(mark) }

    fileprivate func linked(_ href: String?) -> FlareRichRun {
        guard let href else { return self }
        return FlareRichRun(text, marks: marks, code: code, link: href, mention: mention, emoji: emoji)
    }
}

/// A block of a rich-text body.
public indirect enum FlareRichBlock: Equatable, Sendable {
    case paragraph([FlareRichRun])
    /// `level` is 1…6.
    case heading(level: Int, runs: [FlareRichRun])
    case quote([FlareRichBlock])
    case code(text: String, language: String?)
    /// Each item's blocks; never empty.
    case list(ordered: Bool, items: [[FlareRichBlock]])
    case divider
}

/// What a covered spoiler run draws in place of `text`: every code point that is not whitespace becomes
/// U+3000 IDEOGRAPHIC SPACE, so the words are in neither the rendered text nor a copy until revealed.
public func flareRichSpoilerCover(_ text: String) -> String {
    var out = String.UnicodeScalarView()
    for scalar in text.unicodeScalars {
        out.append(scalar.properties.isWhitespace ? scalar : "\u{3000}")
    }
    return String(out)
}

/// The core's own limits (`rich_doc_v2/validate.rs`).
public let flareRichDocMaxDepth = 64
public let flareRichDocMaxNodes = 10_000

/// The blocks a rich-text body draws for `input` — the document's JSON text or its decoded dictionary —
/// or nil when it is not a drawable RichDoc v2 document, and the body shows the message's plain text.
public func flareParseRichDoc(_ input: Any?) -> [FlareRichBlock]? {
    var value = input
    if let text = input as? String {
        guard let data = text.data(using: .utf8),
              let decoded = try? JSONSerialization.jsonObject(with: data) else { return nil }
        value = decoded
    }
    guard let root = value as? [String: Any], root["type"] as? String == "doc",
          let version = RichDocReader.number(root["version"]), version == 2,
          let children = root["children"] as? [Any] else { return nil }
    guard RichDocReader.withinLimits(children) else { return nil }
    var out: [FlareRichBlock] = []
    RichDocReader.blocks(children, into: &out)
    return out
}

private enum RichDocReader {
    /// A JSON number, never a JSON boolean (which Foundation also hands over as an NSNumber).
    static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return number.doubleValue
    }

    static func string(_ value: Any?) -> String { value as? String ?? "" }

    static func children(_ node: Any?) -> [Any] { (node as? [String: Any])?["children"] as? [Any] ?? [] }

    static func withinLimits(_ top: [Any]) -> Bool {
        var nodes = 1
        var stack: [(Any, Int)] = top.map { ($0, 1) }
        while let (node, depth) = stack.popLast() {
            if depth > flareRichDocMaxDepth { return false }
            nodes += 1
            if nodes > flareRichDocMaxNodes { return false }
            for child in children(node) { stack.append((child, depth + 1)) }
        }
        return true
    }

    static func runs(_ inlines: [Any], link: String?, into out: inout [FlareRichRun]) {
        func push(_ run: FlareRichRun) { out.append(run.linked(link)) }
        for value in inlines {
            guard let node = value as? [String: Any] else { continue }
            switch node["type"] as? String {
            case "text":
                let text = string(node["text"])
                guard !text.isEmpty else { break }
                let named = Set(((node["marks"] as? [Any]) ?? []).compactMap { ($0 as? [String: Any])?["type"] as? String })
                push(FlareRichRun(text, marks: FlareRichMark.allCases.filter { named.contains($0.rawValue) }))
            case "inline_code":
                let text = string(node["text"])
                if !text.isEmpty { push(FlareRichRun(text, code: true)) }
            case "hard_break":
                push(FlareRichRun("\n"))
            case "mention":
                let userId = string(node["user_id"]), text = string(node["text"])
                if !userId.isEmpty || !text.isEmpty { push(FlareRichRun(text.isEmpty ? "@\(userId)" : text, mention: userId)) }
            case "emoji":
                let key = string(node["key"]), text = string(node["text"])
                if !key.isEmpty || !text.isEmpty { push(FlareRichRun(text.isEmpty ? ":\(key):" : text, emoji: key)) }
            case "link":
                let href = string(node["href"])
                let accepted = !href.isEmpty && safeExternalURL(href) != nil
                runs(children(node), link: accepted ? href : link, into: &out)
            case "custom_inline":
                break
            default:
                let text = string(node["text"])
                if !text.isEmpty { push(FlareRichRun(text)) }
            }
        }
    }

    static func blocks(_ values: [Any], into out: inout [FlareRichBlock]) {
        for value in values {
            guard let node = value as? [String: Any] else { continue }
            switch node["type"] as? String {
            case "paragraph":
                var inline: [FlareRichRun] = []
                runs(children(node), link: nil, into: &inline)
                if !inline.isEmpty { out.append(.paragraph(inline)) }
            case "heading":
                var inline: [FlareRichRun] = []
                runs(children(node), link: nil, into: &inline)
                guard !inline.isEmpty else { break }
                let raw = number(node["level"]).flatMap { $0.isFinite ? Int($0.rounded(.towardZero)) : nil } ?? 1
                out.append(.heading(level: min(6, max(1, raw)), runs: inline))
            case "quote":
                var inner: [FlareRichBlock] = []
                blocks(children(node), into: &inner)
                if !inner.isEmpty { out.append(.quote(inner)) }
            case "code_block":
                let text = children(node).map { child -> String in
                    guard let inline = child as? [String: Any] else { return "" }
                    switch inline["type"] as? String {
                    case "text": return string(inline["text"])
                    case "hard_break": return "\n"
                    default: return ""
                    }
                }.joined()
                guard !text.isEmpty else { break }
                let language = string(node["language"])
                out.append(.code(text: text, language: language.isEmpty ? nil : language))
            case "bullet_list", "ordered_list":
                let items = children(node).compactMap { child -> [FlareRichBlock]? in
                    guard let item = child as? [String: Any], item["type"] as? String == "list_item" else { return nil }
                    var inner: [FlareRichBlock] = []
                    blocks(children(item), into: &inner)
                    return inner.isEmpty ? nil : inner
                }
                if !items.isEmpty { out.append(.list(ordered: node["type"] as? String == "ordered_list", items: items)) }
            case "divider":
                out.append(.divider)
            case "custom_block":
                blocks(children(node), into: &out)
            default:
                break
            }
        }
    }
}
