import SwiftUI

/// A width-driven grid with one stable set of children. Unlike probing several
/// candidate grids with ViewThatFits, reflow does not mount competing copies of
/// asynchronous content such as image decoders or media players.
public struct FlareAdaptiveGrid: Layout {
    public var spacing: CGFloat
    public var singleColumn: Bool
    public var layoutDirection: LayoutDirection

    public init(spacing: CGFloat = FlareSizes.spacingMd, singleColumn: Bool = false,
                layoutDirection: LayoutDirection = .leftToRight) {
        self.spacing = max(0, spacing)
        self.singleColumn = singleColumn
        self.layoutDirection = layoutDirection
    }

    /// These are content-width breakpoints, independent of children's intrinsic
    /// size. Loading and loaded content therefore select the same layout.
    public static func columnCount(width: CGFloat, singleColumn: Bool = false) -> Int {
        if singleColumn || width < 320 { return 1 }
        return width < 600 ? 2 : 3
    }

    private struct Metrics {
        let width: CGFloat
        let columns: Int
        let cellWidth: CGFloat
        let rowHeights: [CGFloat]
    }

    private func metrics(width proposedWidth: CGFloat?, subviews: Subviews) -> Metrics {
        let width = proposedWidth.flatMap { $0.isFinite ? max(0, $0) : nil } ?? 600
        let columns = Self.columnCount(width: width, singleColumn: singleColumn)
        let cellWidth = max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        let proposal = ProposedViewSize(width: cellWidth, height: nil)
        var heights: [CGFloat] = []
        for (index, view) in subviews.enumerated() {
            let row = index / columns
            if row == heights.count { heights.append(0) }
            heights[row] = max(heights[row], view.sizeThatFits(proposal).height)
        }
        return Metrics(width: width, columns: columns, cellWidth: cellWidth, rowHeights: heights)
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let grid = metrics(width: proposal.width, subviews: subviews)
        return CGSize(width: grid.width, height: grid.rowHeights.reduce(0, +)
            + spacing * CGFloat(max(0, grid.rowHeights.count - 1)))
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let grid = metrics(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for (index, view) in subviews.enumerated() {
            let column = index % grid.columns
            let visualColumn = layoutDirection == .rightToLeft ? grid.columns - 1 - column : column
            let x = bounds.minX + CGFloat(visualColumn) * (grid.cellWidth + spacing)
            view.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                       proposal: ProposedViewSize(width: grid.cellWidth, height: nil))
            if column == grid.columns - 1 { y += grid.rowHeights[index / grid.columns] + spacing }
        }
    }
}
