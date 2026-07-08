import SwiftUI

/// Read-only Markdown/RichDoc renderer with optional stats. Spec:
/// Media/MarkdownPreview (`MarkdownPreviewView`). Compact, dependency-free:
/// headings, bold/italic, inline code, fenced code, bullet/ordered lists, links.
public struct MarkdownPreviewView: View {
    private let content: String
    private let showStats: Bool
    @Environment(\.colorScheme) private var scheme

    public init(content: String, showStats: Bool = false) {
        self.content = content
        self.showStats = showStats
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            ForEach(Array(blocks().enumerated()), id: \.offset) { _, block in
                block.view(colors)
            }
            if showStats {
                Text(stats).font(.system(size: FlareSizes.fontSizeXs)).foregroundColor(colors.textTertiary)
            }
        }
    }

    private var stats: String {
        let chars = content.count
        let words = content.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
        return "\(words) 词 · \(chars) 字"
    }

    private enum Block {
        case heading(String, Int)
        case bullet(String)
        case ordered(Int, String)
        case code(String)
        case paragraph(String)

        @ViewBuilder
        func view(_ colors: FlareColors) -> some View {
            switch self {
            case let .heading(t, level):
                Text(inline(t))
                    .font(.system(size: level == 1 ? FlareSizes.fontSize4xl : level == 2 ? FlareSizes.fontSize3xl : FlareSizes.fontSize2xl, weight: .bold))
                    .foregroundColor(colors.textPrimary)
            case let .bullet(t):
                HStack(alignment: .top) { Text("•"); Text(inline(t)) }
                    .foregroundColor(colors.textPrimary).font(.system(size: FlareSizes.fontSizeLg))
            case let .ordered(n, t):
                HStack(alignment: .top) { Text("\(n).").frame(width: 20, alignment: .leading); Text(inline(t)) }
                    .foregroundColor(colors.textPrimary).font(.system(size: FlareSizes.fontSizeLg))
            case let .code(c):
                Text(c).font(.system(size: FlareSizes.fontSizeMd, design: .monospaced))
                    .foregroundColor(colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(FlareSizes.spacingMd)
                    .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgTertiary))
            case let .paragraph(t):
                Text(inline(t)).foregroundColor(colors.textPrimary).font(.system(size: FlareSizes.fontSizeLg))
            }
        }

        /// Inline markdown via Foundation's AttributedString parser.
        func inline(_ text: String) -> AttributedString {
            (try? AttributedString(markdown: text,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                ?? AttributedString(text)
        }
    }

    private func blocks() -> [Block] {
        let lines = content.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var out: [Block] = []
        var i = 0
        while i < lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                var buf: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    buf.append(lines[i]); i += 1
                }
                i += 1
                out.append(.code(buf.joined(separator: "\n")))
                continue
            }
            if line.trimmingCharacters(in: .whitespaces).isEmpty { i += 1; continue }
            if let m = line.range(of: #"^(#{1,3})\s+"#, options: .regularExpression) {
                let hashes = line[m].trimmingCharacters(in: .whitespaces)
                out.append(.heading(String(line[m.upperBound...]), hashes.count))
                i += 1; continue
            }
            if line.range(of: #"^\s*[-*]\s+"#, options: .regularExpression) != nil {
                while i < lines.count, let r = lines[i].range(of: #"^\s*[-*]\s+"#, options: .regularExpression) {
                    out.append(.bullet(String(lines[i][r.upperBound...]))); i += 1
                }
                continue
            }
            if line.range(of: #"^\s*\d+\.\s+"#, options: .regularExpression) != nil {
                var n = 1
                while i < lines.count, let r = lines[i].range(of: #"^\s*\d+\.\s+"#, options: .regularExpression) {
                    out.append(.ordered(n, String(lines[i][r.upperBound...]))); n += 1; i += 1
                }
                continue
            }
            out.append(.paragraph(line)); i += 1
        }
        return out
    }
}
