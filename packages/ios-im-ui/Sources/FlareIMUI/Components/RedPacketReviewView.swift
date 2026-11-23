import SwiftUI

/// The confirm step of sending a red packet (`presentation.renderer: "redPacket.review"`): the compact arch, the
/// total in large type, the kind and count ("拼手气红包 · 3 个"), the greeting and the red send key. Spec:
/// RedPacketReview (`RedPacketReviewView`), docs/plugin-experience.md §4.3 — it replaces the generic confirm page.
///
/// - `amount` is host-formatted with its currency prefix ("¥26.64"); it is drawn with tabular digits.
/// - `kindLabel` is the kind and count, formatted by the host ("拼手气红包 · 3 个"); it also names the group for
///   VoiceOver.
/// - `busy` spins the key and locks it; `error` shows in a danger banner above the key.
public struct RedPacketReviewView: View {
    private let amount: String
    private let kindLabel: String
    private let blessing: String
    private let submitLabel: String?
    private let busy: Bool
    private let error: String?
    private let onSubmit: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(amount: String, kindLabel: String, blessing: String, submitLabel: String? = nil, busy: Bool = false,
                error: String? = nil, onSubmit: (() -> Void)? = nil) {
        self.amount = amount; self.kindLabel = kindLabel; self.blessing = blessing; self.submitLabel = submitLabel
        self.busy = busy; self.error = error; self.onSubmit = onSubmit
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 0) {
            RedPacketArchView(compact: true)
            VStack(spacing: FlareSizes.spacingMd) {
                Text(amount)
                    .modifier(RedPacketAmountFont())
                    .foregroundColor(colors.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.top, FlareSizes.spacingXl)
                if !kindLabel.isEmpty {
                    Text(kindLabel)
                        .font(.system(size: FlareSizes.fontSizeLg))
                        .foregroundColor(colors.textSecondary)
                }
                if !blessing.isEmpty {
                    Text(blessing)
                        .font(.system(size: FlareSizes.fontSizeXl))
                        .foregroundColor(colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let error, !error.isEmpty {
                    StatusBannerView(text: error, tone: .danger)
                        .padding(.top, FlareSizes.spacingLg)
                }
                ButtonView(label: submitLabel ?? strings.packetSend, size: .lg, loading: busy, block: true,
                           action: onSubmit)
                    .flareRedPacketTint()
                    .padding(.top, error?.isEmpty == false ? 0 : FlareSizes.spacing2xl)
            }
            .padding(FlareSizes.spacingLg)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(kindLabel)
    }
}
