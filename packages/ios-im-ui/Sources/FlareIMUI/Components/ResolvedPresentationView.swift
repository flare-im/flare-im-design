import SwiftUI

func flareHasResolvedPresentation(_ view: PluginViewModel) -> Bool {
    guard view.available, let p = view.presentation,
          ["redPacket.card", "redPacket.composer", "redPacket.detail", "redPacket.pay", "payment.confirm"].contains(p.renderer) else { return false }
    return p.renderer != "redPacket.detail" || p.props["details"]?.objectValue != nil
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

/// The envelope belongs to the presentation, while its action belongs to the host.
/// Keep it visible until that host reports the result; a tap is not a successful claim.
struct ResolvedRedPacketOpenState {
    var presented = false
    private(set) var pendingActionId: String?
    private var host = PluginHostSignal()

    var pending: Bool { pendingActionId != nil }

    mutating func show(busy: Bool, unknown: Bool) {
        guard !busy, !unknown, !pending else { return }
        presented = true
    }

    mutating func begin(actionId: String, unknown: Bool, host: PluginHostSignal) -> Bool {
        guard presented, !pending, !host.busy, host.busyActionId == nil, !unknown else { return false }
        pendingActionId = actionId
        self.host = host
        return true
    }

    mutating func hostChanged(to next: PluginHostSignal, unknown: Bool = false) {
        guard let actionId = pendingActionId else { return }
        let result = PluginSettleRules.form(from: host, to: next, actionId: actionId)
        host = next
        switch result {
        case .wait: break
        case .keep: pendingActionId = nil
        case .close:
            pendingActionId = nil
            if !unknown { presented = false }
        }
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
    init(view: PluginViewModel, busy: Bool, error: String?, formErrors: [PluginFormError], members: [PluginMember],
         membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
         onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil,
         settleToken: Int, resolveUser: ((String) async -> PluginUser?)?,
         onAction: ((String, PluginActionPayload) -> Void)?, onRequest: @escaping (String) -> Void) {
        self.view = view; self.busy = busy; self.error = error; self.formErrors = formErrors; self.members = members
        self.membersLoading = membersLoading; self.membersRevision = membersRevision; self.membersError = membersError
        self.onMemberSearch = onMemberSearch; self.onMembersRetry = onMembersRetry
        self.settleToken = settleToken; self.resolveUser = resolveUser; self.onAction = onAction; self.onRequest = onRequest
    }
    @State private var recipient: PluginMember?
    @State private var recipientRequired = false
    @State private var pickingRecipient = false
    @State private var payment = ResolvedPaymentState()
    @State private var kind: FlareRedPacketKind = .normal
    @State private var amount = ""
    @State private var count = 1
    @State private var greeting = ""
    @State private var opening = ResolvedRedPacketOpenState()
    @State private var people: [String: PluginUser] = [:]
    @Environment(\.flareStrings) private var strings
    private var p: [String: PluginJSONValue] { view.presentation?.props ?? [:] }
    private var renderer: String { view.presentation?.renderer ?? "" }
    private var unknown: Bool { p["journal"]?["known"]?.boolValue == false }
    private var passwordInput: PluginInput? { view.inputs.first { $0.kind == .password && (bound("confirm")?.form?.contains($0.id) ?? false) } }
    private var passwordValid: Bool { passwordInput == nil || (payment.password.count == 6 && payment.password.utf8.allSatisfy { (48...57).contains($0) }) }
    private var paymentBlocked: Bool { unknown || (error?.isEmpty == false && passwordInput == nil) }
    private var isPayment: Bool { ["redPacket.pay", "payment.confirm"].contains(renderer) }
    private var hostSignal: PluginHostSignal {
        PluginHostSignal(busy: busy, error: error, formErrors: formErrors, settleToken: settleToken)
    }
    private var openState: FlareRedPacketOpenState {
        if busy || opening.pending { return .opening }
        return hostSignal.failed || unknown ? .error : .ready
    }
    private var openFailure: String? {
        error.flatMap { $0.isEmpty ? nil : $0 } ?? (formErrors.isEmpty ? nil : strings.pluginFormInvalid)
    }
    private var paymentPresented: Binding<Bool> {
        Binding(get: { payment.presented && isPayment && bound("confirm") != nil && !paymentBlocked },
                set: { if !$0 { payment.close(busy: busy) } })
    }
    private func text(_ key: String) -> String { p[key]?.stringValue ?? "" }
    private func bound(_ name: String) -> PluginViewAction? { view.actions.first { $0.id == (view.presentation?.actions[name] ?? (name == "confirm" ? view.presentation?.actions["authorize"] : nil)) } }
    private func request(_ name: String) { if !busy, !unknown, !(name == "confirm" && paymentBlocked), let a = bound(name) { onRequest(a.id) } }
    private func person(_ id: String) -> PluginUser { people[id] ?? PluginUser(name: String(id.suffix(4))) }
    private var sender: PluginUser { person(text("senderId")) }
    private var details: FlareRedPacketDetailsView? {
        guard let raw = p["details"], let data = try? JSONEncoder().encode(raw) else { return nil }
        return try? JSONDecoder().decode(FlareRedPacketDetailsView.self, from: data)
    }
    private var claimValues: [PluginJSONValue] { p["claims"]?.arrayValue ?? [] }
    private var claims: [FlareRedPacketClaim] { claimValues.map { c in
        let id = c["id"]?.stringValue ?? "", user = person(id)
        return FlareRedPacketClaim(id: id, name: user.name, avatar: user.avatarUrl,
                                  amountMinor: c["amountMinor"]?.stringValue ?? "",
                                  claimedAtMs: Int64(c["claimedAtMs"]?.numberValue ?? 0), best: c["best"]?.boolValue == true)
    } }
    private var remainder: PluginViewModel {
        let handled = Set(view.presentation?.actions.values.map { $0 } ?? [])
        return PluginViewModel(available: view.available, title: "", fields: ["redPacket.pay", "payment.confirm"].contains(renderer) ? view.fields : [],
            actions: view.actions.filter { !handled.contains($0.id) }, blocks: renderer == "redPacket.card" ? [] : view.blocks,
            inputs: view.inputs, menuActions: view.menuActions, unavailableReason: view.unavailableReason)
    }
    private var composerKinds: [FlareRedPacketKind] {
        switch text("conversationType") {
        case "single": return [.normal]
        case "group": return [.normal, .lucky, .exclusive]
        default: return []
        }
    }
    private var composerKind: FlareRedPacketKind { composerKinds.contains(kind) ? kind : (composerKinds.first ?? .normal) }
    private var recipientInput: PluginInput? { view.inputs.first { $0.id == "designatedUserIds" && $0.kind == .members } }
    private var composerRecipient: some View {
        VStack(alignment: .trailing, spacing: FlareSizes.spacingXs) {
            if let recipient { Text(recipient.name).lineLimit(1).accessibilityIdentifier("flare-red-packet-recipient-name") }
            HStack(spacing: FlareSizes.spacingXs) {
                ButtonView(label: strings.select, variant: .secondary, size: .sm,
                           disabled: busy || unknown || recipientInput == nil) {
                    onMemberSearch?("")
                    pickingRecipient = true
                }.accessibilityIdentifier("flare-red-packet-recipient-choose")
                if recipient != nil {
                    ButtonView(label: strings.clear, variant: .text, size: .sm, disabled: busy || unknown) {
                        recipient = nil
                        recipientRequired = true
                    }.accessibilityIdentifier("flare-red-packet-recipient-clear")
                }
            }
            if recipientRequired, recipient == nil {
                FormFieldView(error: strings.pluginFormRequired) { EmptyView() }
                    .accessibilityIdentifier("flare-red-packet-recipient-required")
            }
        }
    }
    private var asset: PluginJSONValue? { p["funding"] }
    private var exponent: Int { Int(asset?["currencyExponent"]?.numberValue ?? 2) }
    private var total: String {
        guard let minor = flareRedPacketAmountMinor(amount, exponent: exponent), minor.count <= 64 else { return "" }
        let factor = composerKind == .normal && text("conversationType") == "group" ? max(0, min(999, count)) : 1
        var carry = 0, digits = ""
        for ch in minor.reversed() { let n = (ch.wholeNumberValue ?? 0) * factor + carry; digits.append(String(n % 10)); carry = n / 10 }
        while carry > 0 { digits.append(String(carry % 10)); carry /= 10 }
        let formatted = FlareRedPacketMoney.text(minor: String(digits.reversed()), exponent: exponent) ?? ""
        return "\(asset?["currency"]?.stringValue ?? "") \(formatted)"
    }
    private func submit() {
        guard !busy, !unknown, !composerKinds.isEmpty, let a = bound("submit") else { return }
        if composerKind == .exclusive, recipient == nil || recipientInput == nil {
            recipientRequired = true
            return
        }
        var values: [String: PluginJSONValue] = ["designatedUserIds": .array(composerKind == .exclusive ? recipient.map { [.string($0.userId)] } ?? [] : [])]
        values["kind"] = .string(composerKind.rawValue); values["decimalAmount"] = .string(amount)
        values["shareCount"] = .number(Double(composerKind == .exclusive || text("conversationType") == "single" ? 1 : count)); values["greeting"] = .string(greeting)
        onAction?(a.id, PluginActionPayload(formValues: values))
    }
    @ViewBuilder private var composer: some View {
        RedPacketComposerView(kinds: composerKinds, kind: composerKind, amount: amount, currencyExponent: exponent,
            count: count, greeting: greeting, total: total, error: formErrors.isEmpty ? nil : strings.pluginFormInvalid,
            busy: busy, locked: unknown || composerKinds.isEmpty || bound("submit") == nil, submitLabel: bound("submit")?.label,
            onKindChange: { if composerKinds.contains($0) { kind = $0; recipientRequired = false } }, onAmountChange: { amount = $0 }, onCountChange: { count = $0 },
            onGreetingChange: { greeting = $0 }, onSubmit: submit) {
                AnyView(composerRecipient)
            }
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
    private func openPacket() {
        guard let action = bound("open"),
              opening.begin(actionId: action.id, unknown: unknown, host: hostSignal) else { return }
        onRequest(action.id)
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
            } else if renderer == "redPacket.composer" { composer }
            else if renderer == "redPacket.detail", let details {
                RedPacketDetailView(senderName: sender.name, senderAvatar: sender.avatarUrl, details: details, claims: claims)
                if let a = bound("open") {
                    RedPacketActionButton(label: a.label, loading: busy || opening.pending, disabled: unknown) {
                        opening.show(busy: busy, unknown: unknown)
                    }
                    .padding(.top, FlareSizes.spacingSm)
                }
            } else if isPayment, let action = bound("confirm") {
                ButtonView(label: action.label, disabled: busy || paymentBlocked || payment.pending != nil) {
                    payment.reopen(busy: busy, blocked: paymentBlocked)
                }
            }
            if renderer != "redPacket.card" {
                AnyView(PluginView(view: remainder, busy: busy, error: error, embedded: true, resolveUser: resolveUser,
                    members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry,  formErrors: formErrors, settleToken: settleToken, onAction: onAction))
            }
        }
        .onDisappear { payment.refreshed() }
        .onChange(of: view) { _ in payment.refreshed() }
        .onChange(of: text("conversationType")) { _ in
            kind = .normal; recipient = nil; recipientRequired = false; pickingRecipient = false
        }
        .onChange(of: membersRevision) { _ in
            recipient = nil; recipientRequired = true; pickingRecipient = false
        }
        .onChange(of: members) { next in
            if onMemberSearch == nil, let recipient, !next.contains(where: { $0.userId == recipient.userId }) {
                self.recipient = nil
            }
        }
        .flareBottomSheet(isPresented: $pickingRecipient, title: recipientInput?.label ?? strings.packetFieldRecipient,
                          titleHidden: true, fill: true) {
            ContactPickerView(groups: [FlareContactPickerGroup(id: FlareContactPickerGroup.groupMembers,
                entries: members.map { FlareContactPickerEntry(userId: $0.userId, name: $0.name, avatarUrl: $0.avatarUrl) })],
                multiple: false, title: recipientInput?.label ?? strings.packetFieldRecipient,
                loading: membersLoading, error: membersError, onSearch: onMemberSearch, onRetry: onMembersRetry,
                onSelect: { entries in
                    guard pickingRecipient, !busy, !unknown, composerKind == .exclusive, !membersLoading, membersError?.isEmpty != false,
                          entries.count == 1, let member = members.first(where: { $0.userId == entries[0].userId }) else { return }
                    recipient = member; recipientRequired = false; pickingRecipient = false
                }, onCancel: { pickingRecipient = false })
        }
        .onChange(of: hostSignal) { opening.hostChanged(to: $0, unknown: unknown) }
        .flareBottomSheet(isPresented: paymentPresented, title: strings.packetPayTitle, titleHidden: true,
            presentation: .auto, dismissible: !busy, onDismiss: paymentDismissed) {
                paymentConfirmation
            }
        .task(id: [text("senderId")] + claimValues.compactMap { $0["id"]?.stringValue }) {
            if greeting.isEmpty { greeting = view.inputs.first { $0.id == "greeting" }?.defaultValue?.stringValue ?? "" }
            guard let resolveUser else { return }
            let ids = Set([text("senderId")] + claimValues.compactMap { $0["id"]?.stringValue })
            for id in ids where !id.isEmpty { if Task.isCancelled { return }; if let user = await resolveUser(id), !Task.isCancelled { people[id] = user } }
        }
        .flareRedPacketOpenSheet(isPresented: $opening.presented) {
            RedPacketOpenSheet(senderName: sender.name, senderAvatar: sender.avatarUrl,
                blessing: details?.greeting ?? "", state: openState, message: openFailure,
                onOpen: unknown || bound("open") == nil ? nil : openPacket,
                onViewDetails: { opening.presented = false }, onClose: { opening.presented = false })
        }
    }
}
