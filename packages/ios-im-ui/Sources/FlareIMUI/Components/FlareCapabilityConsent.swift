import SwiftUI

/// The consent a host shows the first time a plugin uses a host capability (design 7.4; spec
/// Message/CapabilityConsent): "〈plugin〉 wants to use 〈capability〉", the purpose, and allow once, always allow,
/// don't allow.
///
/// The kit keeps no consent record: `onDecide` hands the choice back and the host answers the engine with
/// ``FlareCapabilityConsentDecision/answer`` (revoking a "once" grant when the request is done). A one-time location
/// is confirmed every time, so it offers no "always". It is the body of a bottom panel: present it with
/// `flareBottomSheet(isPresented:title:)` titled `capabilityConsentTitle` with the plugin's name.
public struct FlareCapabilityConsent: View {
    private let pluginName: String
    private let capability: String
    private let params: [String: PluginJSONValue]?
    private let purpose: String?
    private let busy: Bool
    private let onDecide: ((FlareCapabilityConsentDecision) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(pluginName: String, capability: String, params: [String: PluginJSONValue]? = nil, purpose: String? = nil,
                busy: Bool = false, onDecide: ((FlareCapabilityConsentDecision) -> Void)? = nil) {
        self.pluginName = pluginName; self.capability = capability; self.params = params; self.purpose = purpose
        self.busy = busy; self.onDecide = onDecide
    }

    /// The panel's title: "〈plugin〉 wants to use".
    public static func title(_ strings: FlareStrings, pluginName: String) -> String {
        strings.capabilityConsentTitle.replacingOccurrences(of: "{plugin}", with: pluginName)
    }

    private static let icons = [
        "capabilityDocumentCapture": "camera", "capabilityCamera": "camera", "capabilityPaymentConfirmation": "wallet",
        "capabilityLocationCoarse": "location", "capabilityLocationFine": "location", "capabilityMicrophone": "mic",
        "capabilityRtcSession": "video",
    ]

    private func decide(_ decision: FlareCapabilityConsentDecision) { if !busy { onDecide?(decision) } }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let always = FlareCapabilityRules.allowsAlways(capability)
        let key = FlareCapabilityRules.labelKey(capability: capability, params: params)
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            Text(Self.title(strings, pluginName: pluginName))
                .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: FlareSizes.spacingMd) {
                IconView(Self.icons[key] ?? "info", color: colors.primaryText)
                    .frame(width: FlareSizes.touchTarget, height: FlareSizes.touchTarget)
                    .background(Circle().fill(colors.bgSecondary))
                Text(FlareCapabilityRules.label(strings, capability: capability, params: params))
                    .font(.system(size: FlareSizes.fontSize2xl, weight: .medium))
                    .foregroundColor(colors.textPrimary)
                    .accessibilityIdentifier("flare-consent-label")
            }
            .accessibilityElement(children: .combine)
            if let purpose, !purpose.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    Text(strings.capabilityConsentPurpose)
                        .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                    Text(purpose).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
                }
            }
            if always {
                Text(strings.capabilityConsentNote)
                    .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
            VStack(spacing: FlareSizes.spacingSm) {
                if always {
                    ButtonView(label: strings.capabilityConsentAllowAlways, size: .lg, disabled: busy, block: true) {
                        decide(.always)
                    }
                }
                ButtonView(label: strings.capabilityConsentAllowOnce, variant: always ? .secondary : .primary, size: .lg,
                           disabled: busy, block: true) { decide(.once) }
                ButtonView(label: strings.capabilityConsentDeny, variant: .quiet, size: .lg, disabled: busy, block: true) {
                    decide(.deny)
                }
            }
            .padding(.top, FlareSizes.spacingSm)
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.vertical, FlareSizes.spacingXl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
