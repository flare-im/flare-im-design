import SwiftUI

/// Semantic tone for a status banner.
public enum FlareStatusTone: String, Sendable {
    case info, success, warning, danger, neutral
}

/// Compact status strip (connection / sync / runtime state). Spec: General/StatusBanner (`StatusBannerView`).
/// A tone-tinted strip with an optional (optionally pulsing) dot and an optional inline underlined action.
///
/// `floating` is for a banner that a host lifts out of the page flow and hangs over the content
/// (a global connection notice, say). The inline form's fill is the tone at 10% — right on the
/// page's own surface, but as an overlay the content underneath shows straight through it and the
/// two sets of words collide. The floating form puts the tint on an opaque surface and adds the
/// elevation that says it is above the page.
public struct StatusBannerView: View {
    private let text: String
    private let tone: FlareStatusTone
    private let dot: Bool
    private let pulse: Bool
    private let actionText: String?
    private let onAction: (() -> Void)?
    private let floating: Bool
    @ScaledMetric private var textSize: CGFloat = FlareSizes.fontSizeMd
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    public init(text: String, tone: FlareStatusTone = .info, dot: Bool = true, pulse: Bool = false,
                actionText: String? = nil, onAction: (() -> Void)? = nil, floating: Bool = false) {
        self.text = text; self.tone = tone; self.dot = dot; self.pulse = pulse
        self.actionText = actionText; self.onAction = onAction; self.floating = floating
    }

    private func toneColor(_ colors: FlareColors) -> Color {
        switch tone {
        case .info: return colors.info
        case .success: return colors.success
        case .warning: return colors.warning
        case .danger: return colors.error
        case .neutral: return colors.textSecondary
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let tint = toneColor(colors)
        HStack(spacing: FlareSizes.spacingSm) {
            if dot {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                    .opacity(pulse && !reduceMotion && pulsing ? 0.35 : 1)
                    .animation(pulse && !reduceMotion
                        ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                        : .default, value: pulsing)
                    .onAppear { if pulse && !reduceMotion { pulsing = true } }
            }
            Text(text)
                .font(.system(size: textSize))
                .foregroundColor(colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionText, !actionText.isEmpty, onAction != nil {
                Button { onAction?() } label: {
                    Text(actionText)
                        .font(.system(size: textSize, weight: .semibold))
                        .underline()
                        .foregroundColor(colors.textPrimary)
                        .frame(minWidth: 48, minHeight: 48)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FlareSizes.spacing2md)
        .padding(.vertical, FlareSizes.spacingSm)
        .background(
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                // Over content the tint alone is see-through; it needs a surface under it.
                .fill(floating ? AnyShapeStyle(colors.bgElevated) : AnyShapeStyle(Color.clear))
                .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(tint.opacity(0.10)))
                .shadow(color: .black.opacity(floating ? 0.12 : 0), radius: floating ? 10 : 0, y: floating ? 4 : 0)
        )
        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(tint.opacity(0.24), lineWidth: 1))
    }
}
