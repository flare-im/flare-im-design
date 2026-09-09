import SwiftUI

/// Delivery state of an outgoing message. Neutral spec union
/// `'pending' | 'sent' | 'read' | 'failed'`.
public enum FlareMessageDeliveryStatus: Sendable {
    case pending, sent, read, failed
}

/// Visual density of ``MessageStatusView``. Neutral union `'tick' | 'compact'`.
public enum FlareMessageStatusVariant: Sendable {
    case tick, compact
}

/// Small delivery-status indicator for outgoing message bubbles.
/// Spec: General/MessageStatus (`MessageStatusView`).
public struct MessageStatusView: View {
    private let status: FlareMessageDeliveryStatus
    private let variant: FlareMessageStatusVariant
    private let tint: Color?
    @Environment(\.colorScheme) private var scheme

    public init(
        status: FlareMessageDeliveryStatus,
        variant: FlareMessageStatusVariant = .tick,
        tint: Color? = nil
    ) {
        self.status = status
        self.variant = variant
        self.tint = tint
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let dim: CGFloat = variant == .compact ? 12 : 14

        switch status {
        case .pending:
            ProgressView()
                .controlSize(.mini)
                .frame(width: dim, height: dim)
                .tint(tint ?? colors.textTertiary)
        // Glyphs fill the full `dim` box; read = double tick (Android DoneAll /
        // Flutter done_all parity), not a filled circle.
        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: dim, weight: .medium))
                .frame(width: dim, height: dim)
                .foregroundColor(tint ?? colors.textTertiary)
        case .read:
            // No double-tick SF Symbol: two checkmarks offset like Lucide `check-check`.
            ZStack {
                Image(systemName: "checkmark")
                    .font(.system(size: dim * 0.8, weight: .medium))
                    .offset(x: -dim * 0.22)
                Image(systemName: "checkmark")
                    .font(.system(size: dim * 0.8, weight: .medium))
                    .offset(x: dim * 0.22)
            }
            .frame(width: dim, height: dim)
            .foregroundColor(tint ?? colors.primary)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: dim))
                .frame(width: dim, height: dim)
                .foregroundColor(colors.error)
        }
    }
}
