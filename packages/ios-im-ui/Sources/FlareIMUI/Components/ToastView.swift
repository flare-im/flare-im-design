import SwiftUI

// MARK: - Toast

/// Toast — transient pill with variant icon + optional action.
/// Spec: General/Toast (`ToastView`).
public enum ToastVariant: Sendable { case info, success, error, warning, loading }

public struct ToastView: View {
    private let message: String
    private let variant: ToastVariant
    private let tone: FlareStatusTone?
    private let actionLabel: String?
    private let onAction: (() -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var textSize: CGFloat = FlareSizes.fontSizeLg
    @State private var animating = false

    /// - Parameter onClose: Dismiss handler. The close button is only rendered
    ///   when a handler is supplied (no dead controls); the host removes the toast.
    public init(message: String, variant: ToastVariant = .info,
                tone: FlareStatusTone? = nil,
                actionLabel: String? = nil, onAction: (() -> Void)? = nil,
                onClose: (() -> Void)? = nil) {
        self.message = message; self.variant = variant
        self.tone = tone
        self.actionLabel = actionLabel; self.onAction = onAction
        self.onClose = onClose
    }

    /// Whether the close affordance is shown — mirrors Flutter/Compose `onClose`.
    static func showsClose(_ onClose: (() -> Void)?) -> Bool { onClose != nil }

    private var icon: String {
        if let tone, variant != .loading {
            switch tone {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.circle.fill"
            case .info, .neutral: return "info.circle.fill"
            }
        }
        switch variant {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .loading: return "arrow.triangle.2.circlepath"
        }
    }

    private func tint(_ colors: FlareColors) -> Color {
        if let tone, variant != .loading {
            return toneTint(colors, tone)
        }
        switch variant {
        case .info: return colors.primary
        case .success: return colors.success
        case .error: return colors.error
        case .warning: return colors.warning
        case .loading: return colors.textSecondary
        }
    }

    private func toneTint(_ colors: FlareColors, _ tone: FlareStatusTone) -> Color {
        switch tone {
        case .info: return colors.primary
        case .success: return colors.success
        case .warning: return colors.warning
        case .danger: return colors.error
        case .neutral: return colors.textSecondary
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacingSm) {
            Image(systemName: icon).font(.system(size: FlareSizes.fontSize3xl)).foregroundColor(tint(colors))
                .rotationEffect(.degrees(variant == .loading && !reduceMotion && animating ? 360 : 0))
                .animation(variant == .loading && !reduceMotion ? .linear(duration: 0.9).repeatForever(autoreverses: false) : nil, value: animating)
                .accessibilityHidden(true)
            Text(message).font(.system(size: textSize)).foregroundColor(colors.textPrimary)
            if let label = actionLabel, let onAction {
                Button(action: onAction) {
                    Text(label).font(.system(size: textSize, weight: .semibold)).foregroundColor(colors.primaryText)
                        .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                }.buttonStyle(.plain)
            }
            if let onClose, Self.showsClose(onClose) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                        .foregroundColor(colors.textTertiary)
                        .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.close)
            }
        }
        .padding(.vertical, 11).padding(.horizontal, FlareSizes.spacing2md)
        .frame(maxWidth: 420)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.14), radius: 18, y: 6)
        .onAppear { animating = variant == .loading && !reduceMotion }
        .onChange(of: reduceMotion) { animating = variant == .loading && !$0 }
        .onChange(of: variant) { animating = $0 == .loading && !reduceMotion }
    }
}
