import SwiftUI

// MARK: - DatePill

/// Date pill — centered day separator chip on the secondary surface; the `floating` one (over scrolled messages) is
/// the primary surface with a hairline and a shadow. Its words follow Dynamic Type.
/// Spec: Message/DatePill (`DatePillView`).
public struct DatePillView: View {
    private let label: String
    private let floating: Bool
    /// The pill's words follow Dynamic Type.
    @ScaledMetric(relativeTo: .caption) private var textSize: CGFloat = 12
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(label: String, floating: Bool = false) {
        self.label = label; self.floating = floating
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack {
            Spacer()
            // Vue `FlareDatePill`: a quiet chip in the timeline; only the floating one, over scrolled messages,
            // gets a surface, hairline and shadow of its own.
            Text(label)
                .font(.system(size: textSize, weight: .medium))
                .foregroundColor(colors.textSecondary)
                .padding(.vertical, FlareSizes.spacing3xs).padding(.horizontal, FlareSizes.spacing2sm)
                .background(Capsule().fill(floating ? colors.bgPrimary.opacity(0.78) : colors.bgSecondary)
                    .overlay(Capsule().stroke(floating ? colors.borderPrimary : .clear, lineWidth: 1)))
                .shadow(color: Color.black.opacity(floating ? 0.08 : 0), radius: 6, y: 2)
            Spacer()
        }
    }
}
