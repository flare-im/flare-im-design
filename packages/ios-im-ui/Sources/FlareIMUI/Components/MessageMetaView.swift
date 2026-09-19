import SwiftUI

public enum FlareMessageMetaDensity: Sendable { case compact, normal }

/// Stable metadata row for time, mutation, ephemeral state, and outgoing receipt.
public struct MessageMetaView: View {
    @ScaledMetric(relativeTo: .caption) private var metaTextSize: CGFloat = FlareSizes.fontSizeXs
    private let timestamp: String
    private let edited: Bool
    private let status: FlareMessageDeliveryStatus?
    private let lifecycle: FlareMessageLifecycle?
    private let ephemeral: FlareMessageEphemeralState
    private let density: FlareMessageMetaDensity
    private let tint: Color?
    private let onResend: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(
        timestamp: String = "",
        edited: Bool = false,
        status: FlareMessageDeliveryStatus? = nil,
        lifecycle: FlareMessageLifecycle? = nil,
        ephemeral: FlareMessageEphemeralState = .none,
        density: FlareMessageMetaDensity = .compact,
        tint: Color? = nil,
        onResend: (() -> Void)? = nil
    ) {
        self.timestamp = timestamp
        self.edited = edited
        self.status = status
        self.lifecycle = lifecycle
        self.ephemeral = ephemeral
        self.density = density
        self.tint = tint
        self.onResend = onResend
    }

    private var ephemeralLabel: String {
        switch lifecycle?.ephemeral ?? ephemeral {
        case .none: ""
        case .readOnce: strings.messageReadOnce
        case .burnAfterRead: strings.messageBurnAfterRead
        case .expired: strings.messageExpired
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let labels = [
            timestamp.isEmpty ? nil : timestamp,
            (edited || lifecycle?.mutation == .edited) ? strings.messageEdited : nil,
            ephemeralLabel.isEmpty ? nil : ephemeralLabel,
        ].compactMap { $0 }
        HStack(spacing: density == .compact ? FlareSizes.spacingXs : FlareSizes.spacing2xs) {
            if !labels.isEmpty {
                Text(labels.joined(separator: " · "))
                    .font(.system(size: metaTextSize))
                    .foregroundStyle(tint ?? colors.textTertiary)
                    .lineLimit(1)
            }
            if status != nil || lifecycle != nil {
                MessageStatusView(
                    status: status ?? .sent,
                    lifecycle: lifecycle,
                    variant: .compact,
                    tint: tint,
                    onResend: onResend
                )
            }
        }
        .frame(minHeight: FlareSizes.iconSizeSm)
    }
}
