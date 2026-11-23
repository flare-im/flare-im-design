import Foundation

// The red packet page renderers (docs/plugin-experience.md §4, §11 "从 + 到详情都是红包版式"): a plugin page whose
// manifest declares `presentation.renderer` `redPacket.compose`, `redPacket.review` or `redPacket.detail` is drawn by the kit's red packet
// components (``RedPacketPageView``), chosen by the renderer name, never by a plugin id. These read the resolved view
// alone — its inputs, actions and the presentation's props and bound actions — and say nil whenever something is
// missing or unknown: the page then draws the plugin's generic document, as a kit without the renderer does.

/// What the send page (`redPacket.compose`) draws: the bound submit action, its form inputs in form order, the money
/// input and the kinds the conversation offers.
public struct FlareRedPacketComposePlan: Equatable, Sendable {
    /// `presentation.actions.submit` (a group) or `submitDirect` (a direct chat): whichever the view still shows.
    public let action: PluginViewAction
    public let inputs: [PluginInput]
    /// The `amount` input (money, with a currency).
    public let money: PluginInput
    /// The `kind` input's choices, or `[.normal]` when the form has none.
    public let kinds: [FlareRedPacketKind]
    public let scale: Int
    public let currency: String
    /// The plugin's live limit on shares (`props.maxRecipients`), when it is a positive whole number.
    public let maxRecipients: Int?
}

/// One claim row as the server wrote it; the host's directory names it.
public struct FlareRedPacketClaimLine: Equatable, Sendable {
    public let id: String
    public let amountMinor: String
    public let claimedAtMs: Int64
    public let best: Bool
}

/// What the details page (`redPacket.detail`) draws, and the open sheet over it while the packet can be claimed.
public struct FlareRedPacketDetailPlan: Equatable, Sendable {
    public let details: FlareRedPacketDetailsView
    public let claims: [FlareRedPacketClaimLine]
    public let senderId: String
    public let designatedUserIds: [String]
    /// `presentation.actions.claim`: drawn by the open sheet's 開.
    public let claimAction: PluginViewAction?
    /// `presentation.actions.wallet`: the "已存入钱包 ›" line.
    public let walletAction: PluginViewAction?
    /// The viewer's share is paid but the original claim command is still unconfirmed.
    public let paidClaimPending: Bool
}

/// What the confirm page (`redPacket.review`, §4.3) draws: the bound send action and the packet as the server wrote it.
public struct FlareRedPacketReviewPlan: Equatable, Sendable {
    /// `presentation.actions.submit`.
    public let action: PluginViewAction
    /// `props.amount` as written (a plain decimal, or already formatted).
    public let amount: String
    public let currency: String?
    public let kind: FlareRedPacketKind?
    /// A positive whole share count.
    public let shareCount: Int?
    public let blessing: String?
    /// `props.kindLabel`, when the plugin wrote the line itself.
    public let kindLabel: String?
}

public enum FlareRedPacketPagePlan: Equatable, Sendable {
    case compose(FlareRedPacketComposePlan)
    case review(FlareRedPacketReviewPlan)
    case detail(FlareRedPacketDetailPlan)

    public static let composeRenderer = "redPacket.compose"
    public static let reviewRenderer = "redPacket.review"
    public static let detailRenderer = "redPacket.detail"

    /// The red packet page `view` is, or nil for the generic document.
    public static func of(_ view: PluginViewModel) -> FlareRedPacketPagePlan? {
        if let plan = compose(view) { return .compose(plan) }
        if let plan = review(view) { return .review(plan) }
        return detail(view).map(FlareRedPacketPagePlan.detail)
    }

    /// The actions the red packet page runs itself; the page lists the rest (cancel, recovery) under it.
    public var ownedActionIds: [String] {
        switch self {
        case .compose(let plan): return [plan.action.id]
        case .review(let plan): return [plan.action.id]
        case .detail(let plan): return [plan.claimAction?.id, plan.walletAction?.id].compactMap { $0 }
        }
    }

    // MARK: compose

    private static let composeKinds: Set<PluginInputKind> = [.money, .text, .select, .number, .members]

    public static func compose(_ view: PluginViewModel) -> FlareRedPacketComposePlan? {
        guard view.available, view.unavailableReason != .unboundCopy,
              let presentation = view.presentation, presentation.renderer == composeRenderer else { return nil }
        // A command whose outcome is still unknown stays on the generic page, where its recovery action is.
        let journal = presentation.props["journal"]
        if journal?["commandId"]?.stringValue != nil, journal?["known"]?.boolValue == false { return nil }
        let bound = presentation.actions["submit"].flatMap { id in view.actions.first { $0.id == id } }
            ?? presentation.actions["submitDirect"].flatMap { id in view.actions.first { $0.id == id } }
        guard let action = bound, ownable(action), let form = action.form, !form.isEmpty else { return nil }
        let inputs = form.compactMap { id in view.inputs.first { $0.id == id } }
        guard inputs.count == form.count, inputs.allSatisfy({ composeKinds.contains($0.kind) }),
              let money = inputs.first(where: { $0.id == "amount" && $0.kind == .money }),
              let currency = money.money?.currency, !currency.isEmpty,
              inputs.contains(where: { $0.id == "greeting" && $0.kind == .text }) else { return nil }
        let kinds: [FlareRedPacketKind]
        if let kind = inputs.first(where: { $0.id == "kind" }) {
            let choices = kind.choices ?? []
            kinds = choices.compactMap { FlareRedPacketKind(rawValue: $0.value) }
            guard !kinds.isEmpty, kinds.count == choices.count else { return nil }
        } else {
            kinds = [.normal]
        }
        let limit = whole(presentation.props["maxRecipients"]).flatMap { $0 > 0 ? Int(exactly: $0) : nil }
        return FlareRedPacketComposePlan(action: action, inputs: inputs, money: money, kinds: kinds,
                                         scale: money.money?.scale ?? 2, currency: currency, maxRecipients: limit)
    }

    // MARK: review

    /// The confirm page's plan, or nil for the generic document (another renderer, an unavailable or read-only view,
    /// an original command still unconfirmed, no bound send action the page may run).
    public static func review(_ view: PluginViewModel) -> FlareRedPacketReviewPlan? {
        guard view.available, view.unavailableReason != .unboundCopy,
              let presentation = view.presentation, presentation.renderer == reviewRenderer else { return nil }
        let props = presentation.props
        let journal = props["journal"]
        if journal?["commandId"]?.stringValue != nil, journal?["known"]?.boolValue == false { return nil }
        guard let action = presentation.actions["submit"].flatMap({ id in view.actions.first { $0.id == id } }),
              ownable(action), (action.form ?? []).isEmpty else { return nil }
        let text = { (key: String) in props[key]?.stringValue.flatMap { $0.isEmpty ? nil : $0 } }
        return FlareRedPacketReviewPlan(
            action: action, amount: text("amount") ?? "", currency: text("currency"),
            kind: text("kind").flatMap(FlareRedPacketKind.init(rawValue:)),
            shareCount: whole(props["shareCount"]).flatMap { $0 > 0 ? Int(exactly: $0) : nil },
            blessing: text("blessing"), kindLabel: text("kindLabel"))
    }

    // MARK: detail

    public static func detail(_ view: PluginViewModel) -> FlareRedPacketDetailPlan? {
        guard view.available, let presentation = view.presentation, presentation.renderer == detailRenderer,
              let details = Self.details(presentation.props["details"]) else { return nil }
        let props = presentation.props
        let bound = { (name: String) in presentation.actions[name].flatMap { id in view.actions.first { $0.id == id } } }
        let claimAction = bound("claim").flatMap { ownable($0) && ($0.form ?? []).isEmpty ? $0 : nil }
        let walletAction = bound("wallet").flatMap { ownable($0) && ($0.form ?? []).isEmpty ? $0 : nil }
        let claims: [FlareRedPacketClaimLine] = (props["claims"]?.arrayValue ?? []).compactMap { row in
            guard let id = row["id"]?.stringValue, let minor = row["amountMinor"]?.stringValue, digits(minor),
                  let at = row["claimedAtMs"]?.numberValue, at.rounded() == at, abs(at) <= maxSafe else { return nil }
            return FlareRedPacketClaimLine(id: id, amountMinor: minor, claimedAtMs: Int64(at),
                                           best: row["best"]?.boolValue == true)
        }
        let designated = (props["details"]?["designatedUserIds"]?.arrayValue ?? []).compactMap(\.stringValue)
        let journal = props["journal"]
        let pending = journal?["known"]?.boolValue == false
            && ["flare.redpacket.ui.claim", "flare.redpacket.claim"].contains(journal?["capabilityId"]?.stringValue ?? "")
            && details.viewerRole == .claimer && details.myAmountMinor != nil
        return FlareRedPacketDetailPlan(details: details, claims: claims, senderId: props["senderId"]?.stringValue ?? "",
                                        designatedUserIds: designated, claimAction: claimAction,
                                        walletAction: walletAction, paidClaimPending: pending)
    }

    /// The details the server wrote for this viewer, checked field by field; one wrong field and the page is generic.
    static func details(_ raw: PluginJSONValue?) -> FlareRedPacketDetailsView? {
        guard let raw, let role = raw["viewerRole"]?.stringValue.flatMap(FlareRedPacketViewerRole.init(rawValue:)),
              let status = raw["status"]?.stringValue.flatMap(FlareRedPacketStatus.init(rawValue:)),
              let kind = raw["kind"]?.stringValue.flatMap(FlareRedPacketKind.init(rawValue:)),
              let greeting = raw["greeting"]?.stringValue,
              let currency = raw["currency"]?.stringValue, !currency.isEmpty,
              let exponent = whole(raw["currencyExponent"]), exponent >= 0, exponent <= 12,
              let claimed = whole(raw["claimedCount"]), claimed >= 0,
              let shares = whole(raw["shareCount"]), shares >= 0,
              let created = whole(raw["createdAtMs"]), created >= 0,
              let expires = whole(raw["expiresAtMs"]), expires >= 0,
              let listed = raw["claimsListed"]?.boolValue else { return nil }
        var minors: [String: String] = [:]
        for key in ["totalMinor", "claimedMinor", "refundedMinor", "myAmountMinor"] {
            guard let value = raw[key], !value.isNull else { continue }
            guard let text = value.stringValue, digits(text) else { return nil }
            minors[key] = text
        }
        let completedIn = whole(raw["completedInMs"]).flatMap { $0 >= 0 ? $0 : nil }
        let completed = completedIn.flatMap { created + $0 <= Int64(maxSafe) ? created + $0 : nil }
        let refundedAt = whole(raw["refundedAtMs"]).flatMap { $0 >= 0 ? $0 : nil }
        return FlareRedPacketDetailsView(
            viewerRole: role, status: status, kind: kind, greeting: greeting, currency: currency,
            currencyExponent: Int(exponent), totalMinor: minors["totalMinor"], claimedMinor: minors["claimedMinor"],
            refundedMinor: minors["refundedMinor"], myAmountMinor: minors["myAmountMinor"], claimedCount: Int(claimed),
            shareCount: Int(shares), createdAtMs: created, completedAtMs: completed, expiresAtMs: expires,
            refundedAtMs: refundedAt, claimsListed: listed)
    }

    // MARK: helpers

    /// What the page may run itself: no confirmation, no host capability, no secret input (those stay generic).
    static func ownable(_ action: PluginViewAction) -> Bool {
        action.confirm == nil && action.target?.kind != "native"
    }

    private static let maxSafe = 9_007_199_254_740_991.0

    /// A JSON number that is a whole, safe integer.
    static func whole(_ value: PluginJSONValue?) -> Int64? {
        guard let n = value?.numberValue, n.rounded() == n, abs(n) <= maxSafe else { return nil }
        return Int64(n)
    }

    static func digits(_ text: String) -> Bool {
        !text.isEmpty && text.unicodeScalars.allSatisfy { $0.value >= 48 && $0.value <= 57 }
    }
}
