import SwiftUI

func flareHasResolvedPresentation(_ view: PluginViewModel) -> Bool {
    guard view.available, let p = view.presentation,
          ["redPacket.card", "redPacket.composer", "redPacket.detail", "redPacket.pay", "payment.confirm"].contains(p.renderer) else { return false }
    return p.renderer != "redPacket.detail" || p.props["details"]?.objectValue != nil
}

/// Compiled-in Kit composition. Values are resolved, actions are opaque IDs; no SDK or target interpretation.
struct ResolvedPresentationView: View {
    let view: PluginViewModel
    let busy: Bool
    let error: String?
    let formErrors: [PluginFormError]
    let members: [PluginMember]
    let settleToken: Int
    let resolveUser: ((String) async -> PluginUser?)?
    let onAction: ((String, PluginActionPayload) -> Void)?
    let onRequest: (String) -> Void
    @State private var recipient = ""
    @State private var kind: FlareRedPacketKind = .normal
    @State private var amount = ""
    @State private var count = 1
    @State private var greeting = ""
    @State private var envelope = false
    @State private var people: [String: PluginUser] = [:]
    @Environment(\.flareStrings) private var strings
    private var p: [String: PluginJSONValue] { view.presentation?.props ?? [:] }
    private var renderer: String { view.presentation?.renderer ?? "" }
    private var unknown: Bool { p["journal"]?["known"]?.boolValue == false }
    private var paymentBlocked: Bool { unknown || error?.isEmpty == false }
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
    private var asset: PluginJSONValue? { p["funding"] }
    private var exponent: Int { Int(asset?["currencyExponent"]?.numberValue ?? 2) }
    private var total: String {
        guard let minor = flareRedPacketAmountMinor(amount, exponent: exponent), minor.count <= 64 else { return "" }
        let factor = kind == .normal ? max(0, min(999, count)) : 1
        var carry = 0, digits = ""
        for ch in minor.reversed() { let n = (ch.wholeNumberValue ?? 0) * factor + carry; digits.append(String(n % 10)); carry = n / 10 }
        while carry > 0 { digits.append(String(carry % 10)); carry /= 10 }
        let formatted = FlareRedPacketMoney.text(minor: String(digits.reversed()), exponent: exponent) ?? ""
        return "\(asset?["currency"]?.stringValue ?? "") \(formatted)"
    }
    private func submit() {
        guard !busy, !unknown, let a = bound("submit") else { return }
        var values: [String: PluginJSONValue] = ["designatedUserId": .string(kind == .exclusive ? recipient : "")]
        values["kind"] = .string(kind.rawValue); values["decimalAmount"] = .string(amount)
        values["shareCount"] = .number(Double(kind == .exclusive ? 1 : count)); values["greeting"] = .string(greeting)
        onAction?(a.id, PluginActionPayload(formValues: values))
    }
    @ViewBuilder private var composer: some View {
        RedPacketComposerView(kinds: [.normal, .lucky, .exclusive], kind: kind, amount: amount, currencyExponent: exponent,
            count: count, greeting: greeting, total: total, error: formErrors.isEmpty ? nil : strings.pluginFormInvalid,
            busy: busy, locked: unknown || bound("submit") == nil, submitLabel: bound("submit")?.label,
            onKindChange: { kind = $0 }, onAmountChange: { amount = $0 }, onCountChange: { count = $0 },
            onGreetingChange: { greeting = $0 }, onSubmit: submit) {
                InputView(text: $recipient, placeholder: view.inputs.first { $0.id == "designatedUserId" }?.label ?? "", disabled: busy || unknown)
            }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            if renderer == "redPacket.card" {
                RedPacketCardView(blessing: text("blessing"), kind: FlareRedPacketKind(rawValue: text("kind")),
                    state: flareRedPacketCardState(status: FlareRedPacketStatus(rawValue: text("status")) ?? .open,
                        claimedByMe: p["claimedByMe"]?.boolValue == true, tapAction: p["canClaim"]?.boolValue == false ? .details : .open),
                    disabled: bound("open") == nil, busy: busy, onOpen: { request("open") })
            } else if renderer == "redPacket.composer" { composer }
            else if renderer == "redPacket.detail", let details {
                RedPacketDetailView(senderName: sender.name, senderAvatar: sender.avatarUrl, details: details, claims: claims)
                if let a = bound("open") { ButtonView(label: a.label, disabled: busy || unknown) { envelope = true } }
            } else if ["redPacket.pay", "payment.confirm"].contains(renderer), bound("confirm") != nil, !paymentBlocked {
                RedPacketPayConfirmView(amount: text("amount"), methodLabel: text("methodLabel"), busy: busy,
                                        onConfirm: { request("confirm") }, confirmLabel: bound("confirm")?.label)
            }
            if renderer != "redPacket.card" {
                AnyView(PluginView(view: remainder, busy: busy, error: error, embedded: true, resolveUser: resolveUser,
                    members: members, formErrors: formErrors, settleToken: settleToken, onAction: onAction))
            }
        }
        .task(id: [text("senderId")] + claimValues.compactMap { $0["id"]?.stringValue }) {
            if greeting.isEmpty { greeting = view.inputs.first { $0.id == "greeting" }?.defaultValue?.stringValue ?? "" }
            guard let resolveUser else { return }
            let ids = Set([text("senderId")] + claimValues.compactMap { $0["id"]?.stringValue })
            for id in ids where !id.isEmpty { if Task.isCancelled { return }; if let user = await resolveUser(id), !Task.isCancelled { people[id] = user } }
        }
        .flareRedPacketOpenSheet(isPresented: $envelope) {
            RedPacketOpenSheet(senderName: sender.name, senderAvatar: sender.avatarUrl,
                blessing: details?.greeting ?? "", onOpen: { envelope = false; request("open") },
                onViewDetails: { envelope = false }, onClose: { envelope = false })
        }
    }
}
