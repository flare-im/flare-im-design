import SwiftUI

/// A wrapping row: subviews keep their ideal size and move to the next line when the line is full. Lines are aligned
/// to the leading or the trailing edge, and each subview is centred in its line's height.
struct FlareFlowLayout: Layout {
    enum Alignment { case leading, trailing }

    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 2
    var alignment: Alignment = .leading

    /// The subview indices on each line, for subviews of `widths` in a line at most `maxWidth` wide.
    static func lines(_ widths: [CGFloat], maxWidth: CGFloat, spacing: CGFloat) -> [[Int]] {
        var lines: [[Int]] = []
        var current: [Int] = []
        var x: CGFloat = 0
        for (index, width) in widths.enumerated() {
            if !current.isEmpty && x + spacing + width > maxWidth {
                lines.append(current)
                current = []
                x = 0
            }
            x += (current.isEmpty ? 0 : spacing) + width
            current.append(index)
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxWidth = proposal.width ?? .infinity
        let lines = Self.lines(sizes.map(\.width), maxWidth: maxWidth, spacing: spacing)
        var width: CGFloat = 0
        var height: CGFloat = 0
        for (number, line) in lines.enumerated() {
            width = max(width, line.map { sizes[$0].width }.reduce(0, +) + spacing * CGFloat(line.count - 1))
            height += line.map { sizes[$0].height }.max() ?? 0
            if number > 0 { height += lineSpacing }
        }
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var y = bounds.minY
        for line in Self.lines(sizes.map(\.width), maxWidth: bounds.width, spacing: spacing) {
            let lineWidth = line.map { sizes[$0].width }.reduce(0, +) + spacing * CGFloat(line.count - 1)
            let lineHeight = line.map { sizes[$0].height }.max() ?? 0
            var x = alignment == .trailing ? bounds.maxX - lineWidth : bounds.minX
            for index in line {
                let size = sizes[index]
                subviews[index].place(at: CGPoint(x: x, y: y + (lineHeight - size.height) / 2),
                                      anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += lineHeight + lineSpacing
        }
    }
}
