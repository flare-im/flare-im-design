import SwiftUI

/// A linear progress bar: a value from 0 to 1, or a sliding fill while the length of the work is not known.
/// Spec: Feedback/ProgressBar (`ProgressBarView`).
///
/// A value that is missing or not finite reads as indeterminate (`spec/update-prompt-vectors.json`, the same in every
/// kit). VoiceOver reads `label` and the number. Under reduced motion the indeterminate fill stands still and muted.
public struct ProgressBarView: View {
    private let value: Double?
    private let indeterminate: Bool
    private let tone: FlareProgressBarTone
    private let label: String?
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - value: how far along, 0 to 1.
    ///   - indeterminate: the length of the work is not known, so the fill slides instead.
    ///   - tone: what the colour says.
    ///   - label: what is progressing, for VoiceOver.
    public init(value: Double? = nil, indeterminate: Bool = false, tone: FlareProgressBarTone = .primary,
                label: String? = nil) {
        self.value = value; self.indeterminate = indeterminate; self.tone = tone; self.label = label
    }

    private func fill(_ colors: FlareColors) -> Color {
        switch tone {
        case .primary: return colors.primaryText
        case .success: return colors.successText
        case .warning: return colors.warningText
        case .danger: return colors.errorText
        case .neutral: return colors.textSecondary
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shown = flareProgressBarValue(value, indeterminate: indeterminate)
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(colors.bgTertiary)
                if let fraction = shown.value {
                    Capsule().fill(fill(colors)).frame(width: proxy.size.width * fraction)
                } else if reduceMotion {
                    Capsule().fill(fill(colors)).opacity(FlareOpacity.muted)
                } else {
                    ProgressBarSlide(color: fill(colors), width: proxy.size.width)
                }
            }
        }
        .frame(height: FlareSizes.spacingXs)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? strings.progressBarLabel)
        .accessibilityValue(shown.percent.map { "\($0)%" } ?? strings.progressBarLoading)
    }
}

/// The indeterminate fill: a share of the track sliding across it, again and again.
private struct ProgressBarSlide: View {
    /// The fill's share of the track.
    private static let share: CGFloat = 0.4
    /// One pass, the kit's looping pace.
    private static let duration: Double = 1.4

    let color: Color
    let width: CGFloat
    @State private var moved = false
    @Environment(\.layoutDirection) private var direction

    var body: some View {
        // An offset does not mirror, and the fill starts at the leading edge either way.
        let forward: CGFloat = direction == .rightToLeft ? -1 : 1
        Capsule().fill(color)
            .frame(width: width * Self.share)
            .offset(x: forward * (moved ? width : -width * Self.share))
            .onAppear {
                withAnimation(.linear(duration: Self.duration).repeatForever(autoreverses: false)) { moved = true }
            }
    }
}
