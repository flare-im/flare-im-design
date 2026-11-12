import SwiftUI

/// The compiled-in renderers this kit still draws (its vocabulary's `renderers`): the red packet card and the payment
/// confirmation. The composer, the detail, the account page and the QR renderer moved to blocks and draw as plain views.
func flareHasResolvedPresentation(_ view: PluginViewModel) -> Bool {
    guard view.available, let p = view.presentation else { return false }
    return ["redPacket.card", "redPacket.pay", "payment.confirm"].contains(p.renderer)
}

/// Local presentation state only. Closing never carries a credential into a
/// reopened confirmation, and a busy host keeps control of the current layer.
struct ResolvedPaymentState {
    struct Submission {
        let source: PluginViewModel
        let actionId: String
        let payload: PluginActionPayload?
    }
    var presented = true
    var password = ""
    private(set) var pending: Submission?

    @discardableResult mutating func close(busy: Bool) -> Bool {
        guard !busy else { return false }
        let wasPresented = presented
        password = ""
        presented = false
        if wasPresented { pending = nil }
        return wasPresented
    }

    mutating func refreshed() {
        password = ""
        pending = nil
    }

    mutating func confirm(source: PluginViewModel, actionId: String, passwordInput: String?) -> Bool {
        guard presented, pending == nil else { return false }
        let payload = passwordInput.map { PluginActionPayload(formValues: [$0: .string(password)]) }
        guard close(busy: false) else { return false }
        pending = Submission(source: source, actionId: actionId, payload: payload)
        return true
    }

    mutating func dismissed(source: PluginViewModel, busy: Bool, blocked: Bool) -> Submission? {
        password = ""
        let result = pending
        pending = nil
        guard !busy, !blocked, result?.source == source else { return nil }
        return result
    }

    mutating func reopen(busy: Bool, blocked: Bool) {
        guard !busy, !blocked, pending == nil else { return }
        password = ""
        presented = true
    }
}

/// Compiled-in Kit composition. Values are resolved, actions are opaque IDs; no SDK or target interpretation.
struct ResolvedPresentationView: View {
    let view: PluginViewModel
    let busy: Bool
    let error: String?
    let formErrors: [PluginFormError]
    let members: [PluginMember]
    private let membersLoading: Bool
    private let membersRevision: Int
    private let membersError: String?
    private let onMemberSearch: ((String) -> Void)?
    private let onMembersRetry: (() -> Void)?
    let settleToken: Int
    let resolveUser: ((String) async -> PluginUser?)?
    let onAction: ((String, PluginActionPayload) -> Void)?
    let onRequest: (String) -> Void
    /// The blocks under a pay sheet draw images and refresh QR codes as any view does.
    private let resolveImage: (@Sendable (PluginImageSource) async -> URL?)?
    private let onQrRefresh: ((PluginQrRefresh) -> Void)?
    init(view: PluginViewModel, busy: Bool, error: String?, formErrors: [PluginFormError], members: [PluginMember],
         membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
         onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil,
         settleToken: Int, resolveUser: ((String) async -> PluginUser?)?,
         onAction: ((String, PluginActionPayload) -> Void)?, onRequest: @escaping (String) -> Void,
         resolveImage: (@Sendable (PluginImageSource) async -> URL?)? = nil,
         onQrRefresh: ((PluginQrRefresh) -> Void)? = nil) {
        self.resolveImage = resolveImage; self.onQrRefresh = onQrRefresh
        self.view = view; self.busy = busy; self.error = error; self.formErrors = formErrors; self.members = members
        self.membersLoading = membersLoading; self.membersRevision = membersRevision; self.membersError = membersError
        self.onMemberSearch = onMemberSearch; self.onMembersRetry = onMembersRetry
        self.settleToken = settleToken; self.resolveUser = resolveUser; self.onAction = onAction; self.onRequest = onRequest
    }
    @State private var payment = ResolvedPaymentState()
    @Environment(\.flareStrings) private var strings
    private var p: [String: PluginJSONValue] { view.presentation?.props ?? [:] }
    private var renderer: String { view.presentation?.renderer ?? "" }
    private var unknown: Bool { p["journal"]?["known"]?.boolValue == false }
    private var passwordInput: PluginInput? { view.inputs.first { $0.kind == .password && (bound("confirm")?.form?.contains($0.id) ?? false) } }
    private var passwordValid: Bool { passwordInput == nil || (payment.password.count == 6 && payment.password.utf8.allSatisfy { (48...57).contains($0) }) }
    private var paymentBlocked: Bool { unknown || (error?.isEmpty == false && passwordInput == nil) }
    private var isPayment: Bool { ["redPacket.pay", "payment.confirm"].contains(renderer) }
    private var paymentPresented: Binding<Bool> {
        Binding(get: { payment.presented && isPayment && bound("confirm") != nil && !paymentBlocked },
                set: { if !$0 { payment.close(busy: busy) } })
    }
    private func text(_ key: String) -> String { p[key]?.stringValue ?? "" }
    private func bound(_ name: String) -> PluginViewAction? { view.actions.first { $0.id == (view.presentation?.actions[name] ?? (name == "confirm" ? view.presentation?.actions["authorize"] : nil)) } }
    private func request(_ name: String) { if !busy, !unknown, !(name == "confirm" && paymentBlocked), let a = bound(name) { onRequest(a.id) } }
    private var remainder: PluginViewModel {
        let handled = Set(view.presentation?.actions.values.map { $0 } ?? [])
        return PluginViewModel(available: view.available, title: "", fields: isPayment ? view.fields : [],
            actions: view.actions.filter { !handled.contains($0.id) }, blocks: renderer == "redPacket.card" ? [] : view.blocks,
            inputs: view.inputs, menuActions: view.menuActions, unavailableReason: view.unavailableReason)
    }
    private func confirmPayment() {
        guard passwordValid, !busy, !paymentBlocked, let action = bound("confirm") else { return }
        payment.confirm(source: view, actionId: action.id, passwordInput: passwordInput?.id)
    }
    private func paymentDismissed() {
        guard let pending = payment.dismissed(source: view, busy: busy, blocked: paymentBlocked || !isPayment),
              bound("confirm")?.id == pending.actionId else { return }
        // The system sheet is gone before a fast success changes the root navigation.
        if let payload = pending.payload { onAction?(pending.actionId, payload) }
        else { request("confirm") }
    }
    private func cancelPayment() {
        guard !busy else { return }
        payment.refreshed()
        payment.close(busy: false)
    }
    @ViewBuilder private var paymentConfirmation: some View {
        if bound("confirm") != nil, !paymentBlocked {
            RedPacketPayConfirmView(amount: text("amount"), methodLabel: text("methodLabel"), busy: busy,
                onConfirm: confirmPayment, onCancel: cancelPayment, confirmLabel: bound("confirm")?.label,
                credential: passwordInput.map { input in AnyView(InputView(text: $payment.password,
                    placeholder: input.placeholder ?? input.label, maxLength: 6, disabled: busy, secure: true)
                    .accessibilityLabel(input.label)) }, confirmDisabled: !passwordValid)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            if renderer == "redPacket.card" {
                RedPacketCardView(blessing: text("blessing"), kind: FlareRedPacketKind(rawValue: text("kind")),
                    state: flareRedPacketCardState(status: FlareRedPacketStatus(rawValue: text("status")) ?? .open,
                        claimedByMe: p["claimedByMe"]?.boolValue == true, tapAction: p["canClaim"]?.boolValue == false ? .details : .open),
                    disabled: bound("open") == nil, busy: busy, brandName: text("brandName"), onOpen: { request("open") })
            } else if isPayment, let action = bound("confirm") {
                ButtonView(label: action.label, disabled: busy || paymentBlocked || payment.pending != nil) {
                    payment.reopen(busy: busy, blocked: paymentBlocked)
                }
            }
            if renderer != "redPacket.card" {
                AnyView(PluginView(view: remainder, busy: busy, error: error, embedded: true, resolveUser: resolveUser,
                    members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry,  formErrors: formErrors, settleToken: settleToken, onAction: onAction,
                    resolveImage: resolveImage, onQrRefresh: onQrRefresh))
            }
        }
        .onDisappear { payment.refreshed() }
        .onChange(of: view) { _ in payment.refreshed() }
        .flareBottomSheet(isPresented: paymentPresented, title: strings.packetPayTitle, titleHidden: true,
            presentation: .auto, dismissible: !busy, onDismiss: paymentDismissed) {
                paymentConfirmation
            }
    }
}
