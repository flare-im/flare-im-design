import SwiftUI

/// The receipt status the SDK projects for a message (`MessageReceiptView.status`), and the final visual
/// projection of the orthogonal message lifecycle. Five states: there is no delivered one — a single check means
/// the server has the message, a double check that it was read (`spec/message-receipt-vectors.json`).
public enum FlareMessageDeliveryStatus: String, Sendable, CaseIterable {
    case pending, sending, sent, read, failed
}

public enum FlareMessageStatusVariant: Sendable {
    case tick, compact
}

/// The read receipt's double check (never the sent check's shape: read is not told apart by colour alone).
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

    /// - Parameters:
    ///   - tint: The glyph colour inside an outgoing bubble (``FlareColors/messageStatusOnOutgoing``); nil is the
    ///     default palette. A read glyph always takes the read colour of that palette, a failure always the
    ///     failure colour.
    ///   - onResend: A failed glyph with it is the retry key: its target is the 44pt minimum around the drawn
    ///     glyph, which keeps its size in the row.
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

    /// The glyph's drawn side: 12pt in a meta row, 16pt on its own.
    static func side(_ variant: FlareMessageStatusVariant) -> CGFloat { variant == .compact ? 12 : 16 }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let dim = Self.side(variant)
        let effectiveStatus = lifecycle?.visualStatus ?? status
        if Self.resendEnabled(effectiveStatus, onResend) {
            Button { onResend?() } label: {
                glyph(colors, dim, effectiveStatus).flareTouchTarget()
            }
            .buttonStyle(.plain)
            // The row keeps the glyph's size; the 44pt around it still takes the tap.
            .flareCompactLayout(width: dim, height: dim)
            .accessibilityLabel(strings.messageSendFailedRetry)
        } else {
            glyph(colors, dim, effectiveStatus)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(flareMessageStatusText(effectiveStatus, strings: strings))
        }
    }

    @ViewBuilder
    private func glyph(_ colors: FlareColors, _ dim: CGFloat, _ state: FlareMessageDeliveryStatus) -> some View {
        switch flareMessageReceiptGlyph(state) {
        case .clock:
            Image(systemName: "clock")
                .font(.system(size: dim, weight: .regular))
                .frame(width: dim, height: dim)
                .foregroundStyle(tint ?? colors.messageStatusPending)
        case .spinner:
            if reduceMotion {
                Image(systemName: "clock")
                    .font(.system(size: dim, weight: .regular))
                    .frame(width: dim, height: dim)
                    .foregroundStyle(tint ?? colors.messageStatusPending)
            } else {
                ProgressView().controlSize(.mini).frame(width: dim, height: dim)
                    .tint(tint ?? colors.messageStatusPending)
            }
        case .check:
            MessageSingleCheckShape()
                .stroke(tint ?? colors.messageStatusSent,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: dim, height: dim)
        case .doubleCheck:
            MessageDoubleCheckShape()
                .stroke(tint == nil ? colors.messageStatusRead : colors.messageStatusReadOnOutgoing,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: dim, height: dim)
        case .alert:
            // Never drawn on the outgoing fill: a failed bubble takes the failure surface, so the glyph keeps
            // its contrast (it was about 1.5:1 on the outgoing fill).
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: dim)).frame(width: dim, height: dim)
                .foregroundStyle(colors.messageStatusFailed)
        }
    }
}
