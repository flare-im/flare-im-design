import SwiftUI

/// Final visual projection of the orthogonal message lifecycle.
public enum FlareMessageDeliveryStatus: Sendable {
    case pending, sending, sent, delivered, read, failed, retrying
}

public enum FlareMessageStatusVariant: Sendable {
    case tick, compact
}

/// One compact double-check silhouette shared by delivered and read receipts.
public struct MessageDoubleCheckShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 16
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
        }
        var path = Path()
        path.move(to: point(1.75, 8.5))
        path.addLine(to: point(4.5, 11.25))
        path.addLine(to: point(9.25, 5.75))
        path.move(to: point(6, 8.5))
        path.addLine(to: point(8.75, 11.25))
        path.addLine(to: point(14.25, 4.75))
        return path
    }
}

private struct MessageSingleCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 16
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
        }
        var path = Path()
        path.move(to: point(3.5, 8))
        path.addLine(to: point(6.5, 11))
        path.addLine(to: point(12.5, 4.75))
        return path
    }
}

public struct MessageStatusView: View {
    private let status: FlareMessageDeliveryStatus
    private let lifecycle: FlareMessageLifecycle?
    private let variant: FlareMessageStatusVariant
    private let tint: Color?
    private let onResend: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        status: FlareMessageDeliveryStatus,
        lifecycle: FlareMessageLifecycle? = nil,
        variant: FlareMessageStatusVariant = .tick,
        tint: Color? = nil,
        onResend: (() -> Void)? = nil
    ) {
        self.status = status
        self.lifecycle = lifecycle
        self.variant = variant
        self.tint = tint
        self.onResend = onResend
    }

    static func resendEnabled(_ status: FlareMessageDeliveryStatus, _ onResend: (() -> Void)?) -> Bool {
        status == .failed && onResend != nil
    }

    private func label(_ state: FlareMessageDeliveryStatus) -> String {
        switch state {
        case .pending: strings.messagePending
        case .sending: strings.messageSending
        case .sent: strings.messageSent
        case .delivered: strings.messageDelivered
        case .read: strings.messageRead
        case .failed: strings.messageFailed
        case .retrying: strings.messageRetrying
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let dim: CGFloat = variant == .compact ? 12 : 16
        let effectiveStatus = lifecycle?.visualStatus ?? status
        glyph(colors, dim, effectiveStatus)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.resendEnabled(effectiveStatus, onResend)
                ? "\(label(effectiveStatus)), \(strings.retry)"
                : label(effectiveStatus))
            .modifier(TapToResend(
                enabled: Self.resendEnabled(effectiveStatus, onResend),
                label: strings.retry
            ) { onResend?() })
    }

    private struct TapToResend: ViewModifier {
        let enabled: Bool
        let label: String
        let action: () -> Void
        func body(content: Content) -> some View {
            if enabled {
                content.contentShape(Rectangle()).onTapGesture(perform: action)
                    .accessibilityAddTraits(.isButton)
            } else { content }
        }
    }

    @ViewBuilder
    private func glyph(_ colors: FlareColors, _ dim: CGFloat, _ state: FlareMessageDeliveryStatus) -> some View {
        switch state {
        case .pending:
            Image(systemName: "clock")
                .font(.system(size: dim, weight: .regular))
                .frame(width: dim, height: dim)
                .foregroundStyle(tint ?? colors.messageStatusPending)
        case .sending, .retrying:
            if reduceMotion {
                Image(systemName: "clock")
                    .font(.system(size: dim, weight: .regular))
                    .frame(width: dim, height: dim)
                    .foregroundStyle(tint ?? colors.messageStatusPending)
            } else {
                ProgressView().controlSize(.mini).frame(width: dim, height: dim)
                    .tint(tint ?? colors.messageStatusPending)
            }
        case .sent:
            MessageSingleCheckShape()
                .stroke(tint ?? colors.messageStatusSent,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: dim, height: dim)
        case .delivered:
            MessageDoubleCheckShape()
                .stroke(tint ?? colors.messageStatusDelivered,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: dim, height: dim)
        case .read:
            MessageDoubleCheckShape()
                .stroke(tint ?? colors.messageStatusRead,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: dim, height: dim)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: dim)).frame(width: dim, height: dim)
                .foregroundStyle(colors.messageStatusFailed)
        }
    }
}
