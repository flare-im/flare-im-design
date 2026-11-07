import SwiftUI

/// A wrapping row: subviews keep their ideal size and move to the next line when the line is full. Lines are aligned
/// to the leading edge, center, or trailing edge. Each subview is centred in its line's height.
struct FlareFlowLayout: Layout {
    enum Alignment { case leading, center, trailing }

    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 2
    var alignment: Alignment = .leading
    var trailingLast = false
    var constrainSubviews = false
    /// When set, the first subview is the message surface above the flow.
    var surfaceSpacing: CGFloat?
    var topAligned = false

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
        let maxWidth = proposal.width ?? .infinity
        let hasSurface = surfaceSpacing != nil && !subviews.isEmpty
        let items = subviews.dropFirst(hasSurface ? 1 : 0)
        let sizes = itemSizes(items, maxWidth: proposal.width)
        let surfaceSize = hasSurface
            ? subviews[0].sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
            : .zero
        let widths = sizes.map(\.width)
        let lastItems = widths.suffix(trailingLast ? 3 : 2)
        let sharedFooterWidth = lastItems.reduce(0, +) + spacing * CGFloat(max(lastItems.count - 1, 0))
        // A short message can show up to two reactions beside the metadata
        // before the footer needs more lines.
        let lineLimit = hasSurface
            ? min(maxWidth, max(surfaceSize.width, widths.max() ?? 0, sharedFooterWidth))
            : maxWidth
        let lines = Self.lines(widths, maxWidth: lineLimit, spacing: spacing)
        var width = surfaceSize.width
        var height = surfaceSize.height + (hasSurface && !items.isEmpty ? surfaceSpacing ?? 0 : 0)
        for (number, line) in lines.enumerated() {
            width = max(width, line.map { sizes[$0].width }.reduce(0, +) + spacing * CGFloat(line.count - 1))
            height += line.map { sizes[$0].height }.max() ?? 0
            if number > 0 { height += lineSpacing }
        }
        let fillsWidth = trailingLast && !hasSurface && maxWidth.isFinite
        return CGSize(width: fillsWidth ? maxWidth : min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let hasSurface = surfaceSpacing != nil && !subviews.isEmpty
        let items = Array(subviews.dropFirst(hasSurface ? 1 : 0))
        let sizes = itemSizes(items, maxWidth: bounds.width)
        var y = bounds.minY
        if hasSurface {
            let surface = subviews[0]
            let size = surface.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            let x = alignment == .trailing ? bounds.maxX - size.width : bounds.minX
            surface.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            y += size.height + (surfaceSpacing ?? 0)
        }
        for line in Self.lines(sizes.map(\.width), maxWidth: bounds.width, spacing: spacing) {
            let lineWidth = line.map { sizes[$0].width }.reduce(0, +) + spacing * CGFloat(line.count - 1)
            let lineHeight = line.map { sizes[$0].height }.max() ?? 0
            var x = switch alignment {
            case .leading: bounds.minX
            case .center: bounds.midX - lineWidth / 2
            case .trailing: bounds.maxX - lineWidth
            }
            for index in line {
                let size = sizes[index]
                if trailingLast && index == items.count - 1 { x = max(x, bounds.maxX - size.width) }
                let yOffset = topAligned ? 0 : (lineHeight - size.height) / 2
                items[index].place(at: CGPoint(x: x, y: y + yOffset),
                                      anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += lineHeight + lineSpacing
        }
    }

    private func itemSizes(_ items: some Sequence<LayoutSubview>, maxWidth: CGFloat?) -> [CGSize] {
        let proposal = constrainSubviews ? ProposedViewSize(width: maxWidth, height: nil) : .unspecified
        return items.map { $0.sizeThatFits(proposal) }
    }
}
