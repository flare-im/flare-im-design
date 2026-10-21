import SwiftUI

/// The payment confirmation for a red packet: the title, the amount in large type, the payment method row,
/// and confirm / cancel. Spec: RedPacketPayConfirm (`RedPacketPayConfirmView`).
///
/// It is the body of a bottom panel: present it with
/// ``SwiftUI/View/flareBottomSheet(isPresented:title:titleHidden:presentation:dismissible:size:maxHeight:onDismiss:content:)``,
/// passing ``FlareStrings/packetPayTitle`` as a hidden title (the view draws its own) and `dismissible: !busy`.
/// `amount` and `methodLabel` (for example the wallet and its balance) are host-formatted.
///
/// - Confirm is the family's red action; cancel is the kit's quiet button.
/// - `insufficient` disables confirm and says the balance is too low.
/// - `busy` shows progress on confirm and disables both buttons.
public struct RedPacketPayConfirmView: View {
    private let amount: String
    private let methodLabel: String
    private let insufficient: Bool
    private let busy: Bool
    private let onConfirm: (() -> Void)?
    private let onCancel: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(amount: String, methodLabel: String, insufficient: Bool = false, busy: Bool = false,
                onConfirm: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.amount = amount; self.methodLabel = methodLabel; self.insufficient = insufficient; self.busy = busy
        self.onConfirm = onConfirm; self.onCancel = onCancel
    }

    /// Confirm takes a tap only with enough balance and nothing running.
    static func confirmEnabled(insufficient: Bool, busy: Bool, handled: Bool) -> Bool {
        handled && !insufficient && !busy
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: FlareSizes.spacingLg) {
            Text(strings.packetPayTitle)
                .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(amount)
                .font(.system(size: FlareSizes.componentRedPacketAmountFontSize, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            VStack(spacing: 0) {
                Rectangle().fill(colors.borderSecondary).frame(height: RedPacketMetrics.hairline)
                HStack(spacing: FlareSizes.spacingMd) {
                    Text(strings.packetPayMethod)
                        .foregroundColor(colors.textSecondary)
                        .fixedSize()
                    Spacer(minLength: FlareSizes.spacingSm)
                    Text(methodLabel)
                        .foregroundColor(insufficient ? colors.errorText : colors.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
                .font(.system(size: FlareSizes.fontSizeLg))
                .frame(minHeight: FlareSizes.touchTarget)
                .accessibilityElement(children: .combine)
                Rectangle().fill(colors.borderSecondary).frame(height: RedPacketMetrics.hairline)
            }
            if insufficient {
                Text(strings.packetInsufficient)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.errorText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: FlareSizes.spacingSm) {
                // `loading` already holds the button while busy; `disabled` would also dim the progress.
                RedPacketActionButton(label: strings.packetPayConfirm, loading: busy, disabled: insufficient,
                                      action: onConfirm)
                    .accessibilityHint(insufficient ? strings.packetInsufficient : "")
                ButtonView(label: strings.cancel, variant: .quiet, size: .lg, disabled: busy, block: true,
                           action: onCancel)
            }
            .padding(.top, FlareSizes.spacingSm)
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.vertical, FlareSizes.spacingXl)
        .frame(maxWidth: .infinity)
    }
}
