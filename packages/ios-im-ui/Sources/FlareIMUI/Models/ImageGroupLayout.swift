import Foundation

/// How an image-group (album) body lays out its images: square tiles in `columns` columns, `visible` of them
/// drawn, and the last drawn tile reading `+more` when there are more images than tiles. The rule is shared
/// with the other three kits (`spec/image-group-layout-vectors.json`).
public struct FlareImageGroupLayout: Equatable, Sendable {
    public let columns: Int
    public let visible: Int
    public let more: Int

    public init(columns: Int, visible: Int, more: Int) {
        self.columns = columns; self.visible = visible; self.more = more
    }

    /// Whether the tile at `index` is the covered last one.
    public func covers(_ index: Int) -> Bool { more > 0 && index == visible - 1 }

    /// At most this many tiles are drawn.
    public static let maxVisible = 9

    public static func forCount(_ count: Int) -> FlareImageGroupLayout {
        guard count > 0 else { return FlareImageGroupLayout(columns: 0, visible: 0, more: 0) }
        return FlareImageGroupLayout(columns: count == 4 ? 2 : min(count, 3),
                                     visible: min(count, maxVisible),
                                     more: count > maxVisible ? count - maxVisible + 1 : 0)
    }
}
