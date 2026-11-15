import SwiftUI

/// The payment confirmation a host shows for the engine's confirmPayment request (design 7.3; spec
/// Message/PaymentConfirmation). The amount, payee, what it is for and the order number come only from the order, so a
/// plugin cannot change the panel; the countdown runs on the server clock (``FlareServerClock``) and an expired order
/// cannot be confirmed.
///
/// Verifying the viewer (payment password, Face ID or Touch ID) stays the host's existing reauthenticate flow:
/// `onConfirm` only says the viewer confirmed; the host verifies and answers the engine with its proof. A host that
/// asks for the password inside the panel passes the field as `credential`. Present it with
/// `flareBottomSheet(isPresented:title:titleHidden:dismissible:)` with `paymentConfirmationTitle` as a hidden title
/// (the view draws its own) and `dismissible: !busy`.
public struct FlarePaymentConfirmation: View {
    private let order: FlarePaymentOrder
    private let pluginName: String?
    private let busy: Bool
    private let error: String?
    private let confirmDisabled: Bool
    private let credential: AnyView?
    private let onConfirm: (() -> Void)?
    private let onCancel: (() -> Void)?
    private let onExpire: (() -> Void)?
    @State private var expiredSaid = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(order: FlarePaymentOrder, pluginName: String? = nil, busy: Bool = false, error: String? = nil,
                confirmDisabled: Bool = false, credential: AnyView? = nil, onConfirm: (() -> Void)? = nil,
                onCancel: (() -> Void)? = nil, onExpire: (() -> Void)? = nil) {
        self.order = order; self.pluginName = pluginName; self.busy = busy; self.error = error
        self.confirmDisabled = confirmDisabled; self.credential = credential
        self.onConfirm = onConfirm; self.onCancel = onCancel; self.onExpire = onExpire
    }

    /// Confirm takes a tap only with a readable amount, time left and nothing running.
    static func confirmEnabled(order: FlarePaymentOrder, nowMs: Int64, busy: Bool, confirmDisabled: Bool) -> Bool {
        !busy && !confirmDisabled && FlarePaymentRules.amountText(order.amount, currency: order.currency) != nil
            && !FlarePaymentRules.countdown(remainingMs: order.expiresAtMs &- nowMs).expired
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            content(nowMs: FlareServerClock.nowMs())
        }
    }

    @ViewBuilder private func row(_ label: String, _ value: String, _ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            Text(label).foregroundColor(colors.textSecondary).fixedSize()
            Spacer(minLength: FlareSizes.spacingSm)
            Text(value).foregroundColor(colors.textPrimary).multilineTextAlignment(.trailing)
        }
        .font(.system(size: FlareSizes.fontSizeLg))
        .frame(minHeight: FlareSizes.touchTarget)
        .accessibilityElement(children: .combine)
    }

    private func content(nowMs: Int64) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let amount = FlarePaymentRules.amountText(order.amount, currency: order.currency)
        let countdown = FlarePaymentRules.countdown(remainingMs: order.expiresAtMs &- nowMs)
        let enabled = Self.confirmEnabled(order: order, nowMs: nowMs, busy: busy, confirmDisabled: confirmDisabled)
        return VStack(spacing: FlareSizes.spacingMd) {
            Text(strings.paymentConfirmationTitle)
                .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(amount ?? "—")
                .font(.system(size: FlareSizes.componentRedPacketAmountFontSize, weight: .semibold).monospacedDigit())
                .foregroundColor(colors.textPrimary)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .accessibilityIdentifier("flare-payment-amount")
            VStack(spacing: 0) {
                Rectangle().fill(colors.borderSecondary).frame(height: 1)
                row(strings.paymentConfirmationPayee, order.payee, colors)
                if !order.title.isEmpty { row(strings.paymentConfirmationItem, order.title, colors) }
                row(strings.paymentConfirmationOrder, order.orderId, colors)
                Rectangle().fill(colors.borderSecondary).frame(height: 1)
            }
            Group {
                if amount == nil {
                    Text(strings.paymentConfirmationInvalid).foregroundColor(colors.errorText)
                } else if countdown.expired {
                    Text(strings.paymentConfirmationExpired).foregroundColor(colors.errorText)
                        .accessibilityIdentifier("flare-payment-expired")
                } else {
                    Text(strings.paymentConfirmationExpiresIn.replacingOccurrences(of: "{time}", with: countdown.text))
                        .foregroundColor(colors.textSecondary)
                        .monospacedDigit()
                }
            }
            .font(.system(size: FlareSizes.fontSizeSm))
            if let pluginName {
                Text(strings.paymentConfirmationRequestedBy.replacingOccurrences(of: "{plugin}", with: pluginName))
                    .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
            if let credential { credential }
            if let error {
                Text(error).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.errorText)
            }
            VStack(spacing: FlareSizes.spacingSm) {
                ButtonView(label: busy ? strings.paymentConfirmationVerifying : strings.paymentConfirmationConfirm,
                           size: .lg, loading: busy, disabled: !enabled && !busy, block: true) {
                    if enabled { onConfirm?() }
                }
                ButtonView(label: strings.cancel, variant: .quiet, size: .lg, disabled: busy, block: true) {
                    if !busy { onCancel?() }
                }
            }
            .padding(.top, FlareSizes.spacingSm)
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.vertical, FlareSizes.spacingXl)
        .frame(maxWidth: .infinity)
        .onChange(of: countdown.expired) { expired in
            if expired, !expiredSaid { expiredSaid = true; onExpire?() }
        }
    }
}
