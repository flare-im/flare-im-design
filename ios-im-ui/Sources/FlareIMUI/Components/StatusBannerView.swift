import SwiftUI

/// Semantic tone for a status banner.
public enum FlareStatusTone: String, Sendable {
    case info, success, warning, danger, neutral
}

/// Compact status strip (connection / sync / runtime state). Spec: General/StatusBanner (`StatusBannerView`).
/// A tone-tinted strip with an optional (optionally pulsing) dot and an optional inline underlined action.
public struct StatusBannerView: View {
    private let text: String
    private let tone: FlareStatusTone
    private let dot: Bool
    private let pulse: Bool
    private let actionText: String?
    private let onAction: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    public init(text: String, tone: FlareStatusTone = .info, dot: Bool = true, pulse: Bool = false,
                actionText: String? = nil, onAction: (() -> Void)? = nil) {
        self.text = text; self.tone = tone; self.dot = dot; self.pulse = pulse
        self.actionText = actionText; self.onAction = onAction
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
        let colors = FlareColors.of(scheme)
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
                .font(.system(size: FlareSizes.fontSizeMd))
                .foregroundColor(tint)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionText {
                Button { onAction?() } label: {
                    Text(actionText)
                        .font(.system(size: FlareSizes.fontSizeMd, weight: .semibold))
                        .underline()
                        .foregroundColor(tint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingSm)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(tint.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(tint.opacity(0.24), lineWidth: 1))
    }
}
