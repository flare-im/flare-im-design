import SwiftUI

public extension FlareTextRole {
    /// Keeps the semantic role's typeface and weight while applying a host's
    /// Dynamic Type scale. Pass an `@ScaledMetric` ratio, not viewport width.
    /// Invalid or nonpositive scales keep the unscaled role.
    func font(scaledBy scale: CGFloat) -> Font {
        let factor = scale.isFinite && scale > 0 ? scale : 1
        let fontWeight: Font.Weight = weight >= 700 ? .bold : weight >= 600 ? .semibold : weight >= 500 ? .medium : .regular
        return .system(size: fontSize * factor, weight: fontWeight)
    }
}
