import SwiftUI

/// The payment confirmation a host shows for the engine's confirmPayment request (design 7.3; spec
/// Message/PaymentConfirmation). The amount, payee, what it is for and the order number come only from the order, so a
/// plugin cannot change the panel; the countdown runs on the server clock (``FlareServerClock``) and an expired order
/// cannot be confirmed: its amount dims and confirm reads "start again" (`onStartAgain`). The order number is folded
/// behind "订单号 ›"; under a minute left the countdown turns to the warning colour; a short balance (`shortfall`)
/// turns confirm off, says how much is missing above it and offers "top up" (`onTopUp`); the host's `error` shows in
/// a danger banner above the keys.
///
/// Verifying the viewer (payment password, Face ID or Touch ID) stays the host's existing reauthenticate flow:
/// `onConfirm` only says the viewer confirmed; the host verifies and answers the engine with its proof. A host that
/// asks for the password inside the panel passes the field as `credential` (a ``PinInputView``; keep confirm off with
/// `confirmDisabled` until all six digits are in, §12.19). Present it with
/// ``SwiftUI/View/flarePaymentConfirmation(item:title:dismissible:content:)`` — a bottom sheet on a phone, a
/// `component.paymentDialogWidth` dialog elsewhere — with `paymentConfirmationTitle` as the hidden title (the view draws
/// its own, 15/600 centred) and `dismissible: !busy`.
public struct FlarePaymentConfirmation: View {
    private let order: FlarePaymentOrder
    private let pluginName: String?
    private let busy: Bool
    private let error: String?
    private let confirmDisabled: Bool
    private let shortfall: String?
    private let credential: AnyView?
    private let onConfirm: (() -> Void)?
    private let onCancel: (() -> Void)?
    private let onExpire: (() -> Void)?
    private let onTopUp: (() -> Void)?
    private let onStartAgain: (() -> Void)?
    @State private var expiredSaid = false
    @State private var orderShown = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - shortfall: Insufficient balance: the formatted missing amount ("¥6.64"). Above zero, confirm is off, the
    ///     shortfall reads above it and a "top up" key calls `onTopUp`; "0" or "¥0.00" is no shortfall (§12.19).
    ///   - onStartAgain: An expired order's confirm key reads "start again" and calls this.
    public init(order: FlarePaymentOrder, pluginName: String? = nil, busy: Bool = false, error: String? = nil,
                confirmDisabled: Bool = false, shortfall: String? = nil, credential: AnyView? = nil,
                onConfirm: (() -> Void)? = nil, onCancel: (() -> Void)? = nil, onExpire: (() -> Void)? = nil,
                onTopUp: (() -> Void)? = nil, onStartAgain: (() -> Void)? = nil) {
        self.order = order; self.pluginName = pluginName; self.busy = busy; self.error = error
        self.confirmDisabled = confirmDisabled; self.shortfall = shortfall; self.credential = credential
        self.onConfirm = onConfirm; self.onCancel = onCancel; self.onExpire = onExpire
        self.onTopUp = onTopUp; self.onStartAgain = onStartAgain
    }

    /// Confirm takes a tap only with a readable amount, time left, enough balance and nothing running.
    static func confirmEnabled(order: FlarePaymentOrder, nowMs: Int64, busy: Bool, confirmDisabled: Bool,
                               shortfall: String? = nil) -> Bool {
        !busy && !confirmDisabled && !owing(shortfall)
            && FlarePaymentRules.amountText(order.amount, currency: order.currency) != nil
            && !FlarePaymentRules.countdown(remainingMs: order.expiresAtMs &- nowMs).expired
    }

    /// A shortfall counts only above zero (§12.19): a formatted amount with a non-zero digit and no minus sign.
    static func owing(_ shortfall: String?) -> Bool {
        guard let shortfall, !shortfall.contains("-"), !shortfall.contains("\u{2212}") else { return false }
        return shortfall.contains { $0.isASCII && $0.isNumber && $0 != "0" }
    }

    /// The insufficient-balance line above confirm ("余额不足，还差 ¥6.64"); nil while the balance is enough.
    static func insufficientText(_ shortfall: String?, strings: FlareStrings) -> String? {
        guard let shortfall, owing(shortfall) else { return nil }
        return strings.paymentConfirmationInsufficient.replacingOccurrences(of: "{amount}", with: shortfall)
    }

    /// The countdown turns to the warning colour in its last minute.
    static func countdownUrgent(remainingMs: Int64) -> Bool { remainingMs > 0 && remainingMs < 60_000 }

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

    /// The order number, folded behind "订单号 ›"; a tap shows it, selectable for copying.
    @ViewBuilder private func orderRow(_ colors: FlareColors) -> some View {
        Button { orderShown.toggle() } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                Text(strings.paymentConfirmationOrder).foregroundColor(colors.textSecondary)
                Spacer(minLength: FlareSizes.spacingSm)
                IconView(orderShown ? "chevron-down" : "chevron-right", size: FlareSizes.fontSizeSm,
                         color: colors.textTertiary)
            }
            .font(.system(size: FlareSizes.fontSizeLg))
            .frame(minHeight: FlareSizes.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(orderShown ? order.orderId : "")
        if orderShown {
            Text(order.orderId)
                .font(.system(size: FlareSizes.fontSizeMd).monospacedDigit())
                .foregroundColor(colors.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, FlareSizes.spacingSm)
                .accessibilityIdentifier("flare-payment-order")
        }
    }

    private func content(nowMs: Int64) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let amount = FlarePaymentRules.amountText(order.amount, currency: order.currency)
        let remainingMs = order.expiresAtMs &- nowMs
        let countdown = FlarePaymentRules.countdown(remainingMs: remainingMs)
        let enabled = Self.confirmEnabled(order: order, nowMs: nowMs, busy: busy, confirmDisabled: confirmDisabled,
                                          shortfall: shortfall)
        let insufficient = Self.insufficientText(shortfall, strings: strings)
        return VStack(spacing: FlareSizes.spacingMd) {
            Text(strings.paymentConfirmationTitle)
                .font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let pluginName {
                Text(strings.paymentConfirmationRequestedBy.replacingOccurrences(of: "{plugin}", with: pluginName))
                    .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
            Text(amount ?? "—")
                .font(.system(size: FlareSizes.componentAmountHeroFontSize, weight: .semibold).monospacedDigit())
                .foregroundColor(countdown.expired ? colors.textTertiary : colors.textPrimary)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .accessibilityIdentifier("flare-payment-amount")
            VStack(spacing: 0) {
                Rectangle().fill(colors.borderSecondary).frame(height: 1)
                row(strings.paymentConfirmationPayee, order.payee, colors)
                if !order.title.isEmpty { row(strings.paymentConfirmationItem, order.title, colors) }
                orderRow(colors)
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
                        .foregroundColor(Self.countdownUrgent(remainingMs: remainingMs) ? colors.warningText
                                         : colors.textSecondary)
                        .monospacedDigit()
                }
            }
            .font(.system(size: FlareSizes.fontSizeSm))
            if let credential { credential }
            if let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
            VStack(spacing: FlareSizes.spacingSm) {
                if let insufficient {
                    Text(insufficient)
                        .font(.system(size: FlareSizes.fontSizeSm).monospacedDigit())
                        .foregroundColor(colors.errorText)
                        .accessibilityIdentifier("flare-payment-insufficient")
                }
                if countdown.expired, amount != nil {
                    ButtonView(label: strings.paymentConfirmationStartAgain, size: .lg, disabled: busy, block: true,
                               action: onStartAgain)
                } else {
                    ButtonView(label: busy ? strings.paymentConfirmationVerifying : strings.paymentConfirmationConfirm,
                               size: .lg, loading: busy, disabled: !enabled && !busy, block: true) {
                        if enabled { onConfirm?() }
                    }
                }
                if insufficient != nil {
                    ButtonView(label: strings.paymentConfirmationTopUp, variant: .secondary, size: .lg, disabled: busy,
                               block: true, action: onTopUp)
                }
                ButtonView(label: strings.cancel, variant: .secondary, size: .lg, disabled: busy, block: true) {
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
