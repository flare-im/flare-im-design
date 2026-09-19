import Foundation

/// One markdown message read as one plain line — what a conversation row, a reply strip or a quote shows.
///
/// Marks are stripped, never interpreted: a link keeps its words and loses its target, an image becomes the
/// `preview.image` term with its alt text when it has one, and a fenced block keeps the code inside it. The
/// rule is shared with the Vue, Flutter and Compose kits and tested against
/// `spec/markdown-preview-vectors.json`; Vue has applied it to every preview since before this kit existed,
/// which is why the same string used to arrive here with its asterisks (FR-120).
///
/// The word classes are written out as ASCII on purpose: ICU counts 中文 as word characters and JavaScript
/// does not, so `__周报__已发出` would otherwise read differently here than everywhere else.
public func flareMarkdownToPlainText(_ content: String, strings s: FlareStrings) -> String {
    let word = "A-Za-z0-9_"
    var text = content.replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")

    // A fenced block keeps what is inside it; the fence and its language are not words.
    text = replacing(text, "```(?:[^\n`]*)\n?([\\s\\S]*?)```") { $0[1] }
    text = replacing(text, "!\\[([^\\]\n]*)\\]\\([^)]+\\)") { groups in
        let label = groups[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? s.previewImage : s.previewImageNamed(label)
    }
    text = replacing(text, "\\[([^\\]\n]+)\\]\\([^)]+\\)") { $0[1] }
    text = replacing(text, "^#{1,6}\\s+", lines: true) { _ in "" }
    text = replacing(text, "^\\s{0,3}>\\s?", lines: true) { _ in "" }
    text = replacing(text, "^\\s{0,3}(?:[-*+]|\\d+\\.)\\s+", lines: true) { _ in "" }
    text = replacing(text, "^\\s{0,3}---+\\s*$", lines: true) { _ in " " }
    text = replacing(text, "<u>([\\s\\S]+?)</u>", caseless: true) { $0[1] }
    text = replacing(text, "\\*\\*\\*([\\s\\S]+?)\\*\\*\\*") { $0[1] }
    text = replacing(text, "___([\\s\\S]+?)___") { $0[1] }
    text = replacing(text, "\\*\\*([\\s\\S]+?)\\*\\*") { $0[1] }
    text = replacing(text, "(^|[^\(word)])__([^_\n]+?)__(?=$|[^\(word)])") { $0[1] + $0[2] }
    text = replacing(text, "~~([\\s\\S]+?)~~") { $0[1] }
    text = replacing(text, "`([^`\n]+?)`") { $0[1] }
    text = replacing(text, "\\*([^*\n]+?)\\*") { $0[1] }
    text = replacing(text, "(^|[^\(word)])_([^_\n]+?)_(?=$|[^\(word)])") { $0[1] + $0[2] }
    text = replacing(text, "[ \t]+\n") { _ in "\n" }
    text = replacing(text, "\n{3,}") { _ in "\n\n" }
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// One pass of the rule above. `lines` makes `^` and `$` match around each line, the way a JavaScript `m`
/// flag does; without it they mean the ends of the whole string, which is what the word-boundary passes want.
private func replacing(
    _ text: String, _ pattern: String, lines: Bool = false, caseless: Bool = false,
    with replacement: ([String]) -> String
) -> String {
    var options: NSRegularExpression.Options = []
    if lines { options.insert(.anchorsMatchLines) }
    if caseless { options.insert(.caseInsensitive) }
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return text }
    let ns = text as NSString
    var out = ""
    var last = 0
    for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
        out += ns.substring(with: NSRange(location: last, length: match.range.location - last))
        var groups: [String] = []
        for index in 0..<match.numberOfRanges {
            let range = match.range(at: index)
            groups.append(range.location == NSNotFound ? "" : ns.substring(with: range))
        }
        out += replacement(groups)
        last = match.range.location + match.range.length
    }
    out += ns.substring(from: last)
    return out
}
