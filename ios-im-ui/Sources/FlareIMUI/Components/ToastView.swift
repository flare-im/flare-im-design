import SwiftUI

// MARK: - Toast

/// Toast — transient pill with variant icon + optional action.
/// Spec: General/Toast (`ToastView`).
public enum ToastVariant: Sendable { case info, success, error, warning, loading }

public struct ToastView: View {
    private let message: String
    private let variant: ToastVariant
    private let actionLabel: String?
    private let onAction: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var animating = false

    public init(message: String, variant: ToastVariant = .info,
                actionLabel: String? = nil, onAction: (() -> Void)? = nil) {
        self.message = message; self.variant = variant
        self.actionLabel = actionLabel; self.onAction = onAction
    }

    private var icon: String {
        switch variant {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .loading: return "arrow.triangle.2.circlepath"
        }
    }

    private func tint(_ colors: FlareColors) -> Color {
        switch variant {
        case .info: return colors.primary
        case .success: return colors.success
        case .error: return colors.error
        case .warning: return colors.warning
        case .loading: return colors.textSecondary
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingMd) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(tint(colors))
                .rotationEffect(.degrees(variant == .loading && animating ? 360 : 0))
                .animation(variant == .loading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: animating)
            Text(message).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
            if let label = actionLabel {
                Button { onAction?() } label: {
                    Text(label).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(colors.primary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 14)
        .frame(maxWidth: 420)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.14), radius: 18, y: 6)
        .onAppear { if variant == .loading { animating = true } }
    }
}
