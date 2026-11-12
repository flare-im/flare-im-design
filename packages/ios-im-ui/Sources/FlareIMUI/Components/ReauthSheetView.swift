import SwiftUI

/// Opaque SDK id and already masked display copy, without credentials or proofs.
public struct FlareReauthDestination: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let detail: String?
    public init(id: String, label: String, detail: String? = nil) { self.id = id; self.label = label; self.detail = detail }
}
/// Pure OTP form body. The host owns presentation, network effects and countdown state.
public struct ReauthSheetView: View {
    private let destinations: [FlareReauthDestination]
    @Binding private var selectedId: String
    @Binding private var code: String
    private let title: String?, subtitle: String?, error: String?, notice: String?
    private let codeLength: Int, resendInSeconds: Int
    private let sending: Bool, submitting: Bool, canSend: Bool, canSubmit: Bool
    private let onSend: () -> Void, onSubmit: () -> Void, onCancel: () -> Void
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    public init(destinations: [FlareReauthDestination], selectedId: Binding<String>, code: Binding<String>, title: String? = nil, subtitle: String? = nil, codeLength: Int = 6, sending: Bool = false, submitting: Bool = false, canSend: Bool, canSubmit: Bool, resendInSeconds: Int = 0, error: String? = nil, notice: String? = nil, onSend: @escaping () -> Void, onSubmit: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.destinations = destinations; self._selectedId = selectedId; self._code = code; self.title = title; self.subtitle = subtitle; self.codeLength = codeLength; self.sending = sending; self.submitting = submitting; self.canSend = canSend; self.canSubmit = canSubmit; self.resendInSeconds = resendInSeconds; self.error = error; self.notice = notice; self.onSend = onSend; self.onSubmit = onSubmit; self.onCancel = onCancel
    }
    private var busy: Bool { sending || submitting }
    private var selected: FlareReauthDestination? { destinations.first { $0.id == selectedId } }
    private var maySend: Bool { canSend && selected != nil && !busy && resendInSeconds <= 0 }
    private var maySubmit: Bool { canSubmit && selected != nil && !busy }
    private var codeField: some View { InputView(text: $code, placeholder: strings.reauthCode, maxLength: codeLength, disabled: busy, monospace: true, onSubmit: { if maySubmit { onSubmit() } }).accessibilityLabel(strings.reauthCode) }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: brand)
        ScrollView {
            VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                Text(title ?? strings.reauthTitle).font(.headline)
                if let subtitle { Text(subtitle).foregroundColor(colors.textSecondary) }
                if let notice { StatusBannerView(text: notice, tone: .info) }
                if let error { StatusBannerView(text: error, tone: .danger) }
                if destinations.isEmpty { StatusBannerView(text: strings.reauthUnavailable, tone: .warning) }
                FormFieldView(label: strings.reauthDestination, hint: selected?.detail) {
                    SelectView(options: destinations.map { FlareSelectOption(value: $0.id, label: $0.label) }, selection: $selectedId, disabled: busy || destinations.isEmpty)
                }
                FormFieldView(label: strings.reauthCode) {
                    #if os(iOS)
                    codeField.keyboardType(.numberPad).textContentType(.oneTimeCode)
                    #else
                    codeField
                    #endif
                }
                ButtonView(label: resendInSeconds > 0 ? strings.reauthResendIn.replacingOccurrences(of: "{seconds}", with: String(resendInSeconds)) : strings.reauthSendCode, variant: .secondary, loading: sending, disabled: !maySend, block: true) { if maySend { onSend() } }
                ButtonView(label: strings.confirm, loading: submitting, disabled: !maySubmit, block: true) { if maySubmit { onSubmit() } }
                ButtonView(label: strings.cancel, variant: .quiet, block: true, action: onCancel)
            }.padding(FlareSizes.spacingLg).foregroundColor(colors.textPrimary)
        }
    }
}
