import SwiftUI

/// A plugin page drawn by the red packet renderers (docs/plugin-experience.md §4, §11): ``FlarePluginPage`` draws it
/// in place of the generic document when the view's ``FlareRedPacketPagePlan`` resolves, so any host that shows plugin
/// pages gets the red packet look from "+" to the details without naming the plugin.
///
/// - `redPacket.compose`: ``RedPacketComposerView`` over the page's form. The kit keeps the draft, checks it on submit
///   (the inputs' own rules, the share limit, the total against the money input's maximum) and focuses the wrong
///   field; a clean submit runs the bound action with the form's values. The exclusive recipient is chosen from
///   `members` in the kit contact picker; in a group the host's `memberCount` (the group's size counting the viewer,
///   never the number of `members`) is the composer's 「本群共 N 人」.
/// - `redPacket.review`: ``RedPacketReviewView`` with the page's warnings above it; its key runs the bound send action.
/// - `redPacket.detail`: ``RedPacketDetailView`` with names from `members`, else `resolveUser`; while the packet can
///   be claimed ``RedPacketOpenSheet`` lies over it: 開 runs the bound claim, the page reads again on success (R4) and
///   the claim leaves, so the sheet gives way to the details. Closing the sheet leaves the page (`onBack`).
public struct RedPacketPageView: View {
    private let plan: FlareRedPacketPagePlan
    private let view: PluginViewModel
    private let busy: Bool
    private let offline: Bool
    private let actionError: String?
    private let formErrors: [PluginFormError]
    private let settleToken: Int
    private let members: [PluginMember]
    private let memberCount: Int?
    private let membersLoading: Bool
    private let membersError: String?
    private let membersRevision: Int
    private let onMemberSearch: ((String) -> Void)?
    private let onMembersRetry: (() -> Void)?
    private let resolveUser: (@Sendable (String) async -> PluginUser?)?
    private let onAction: (String, PluginActionPayload) -> Void
    private let onRefresh: ((PluginRefreshReason) -> Void)?
    private let onBack: (() -> Void)?

    public init(plan: FlareRedPacketPagePlan, view: PluginViewModel, busyActionId: String? = nil, refreshing: Bool = false,
                offline: Bool = false, actionError: String? = nil, formErrors: [PluginFormError] = [], settleToken: Int = 0,
                members: [PluginMember] = [], memberCount: Int? = nil, membersLoading: Bool = false,
                membersError: String? = nil,
                membersRevision: Int = 0, onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil,
                resolveUser: (@Sendable (String) async -> PluginUser?)? = nil,
                onAction: @escaping (String, PluginActionPayload) -> Void,
                onRefresh: ((PluginRefreshReason) -> Void)? = nil, onBack: (() -> Void)? = nil) {
        self.plan = plan; self.view = view; self.busy = busyActionId != nil || refreshing; self.offline = offline
        self.actionError = actionError.flatMap { $0.isEmpty ? nil : $0 }; self.formErrors = formErrors
        self.settleToken = settleToken; self.members = members; self.memberCount = memberCount
        self.membersLoading = membersLoading
        self.membersError = membersError; self.membersRevision = membersRevision; self.onMemberSearch = onMemberSearch
        self.onMembersRetry = onMembersRetry; self.resolveUser = resolveUser; self.onAction = onAction
        self.onRefresh = onRefresh; self.onBack = onBack
    }

    public var body: some View {
        switch plan {
        case .compose(let compose):
            RedPacketComposePage(plan: compose, notes: Self.notes(view), busy: busy, offline: offline,
                                 actionError: actionError, formErrors: formErrors, settleToken: settleToken,
                                 members: members, memberCount: memberCount, membersLoading: membersLoading,
                                 membersError: membersError,
                                 membersRevision: membersRevision, onMemberSearch: onMemberSearch,
                                 onMembersRetry: onMembersRetry,
                                 onSubmit: { values in onAction(compose.action.id, PluginActionPayload(formValues: values)) })
                // Another action (a group's or a direct chat's) is another form: its draft starts over.
                .id(compose.action.id)
        case .review(let review):
            VStack(spacing: FlareSizes.spacingMd) {
                ForEach(Array(Self.notes(view).enumerated()), id: \.offset) { _, note in
                    StatusBannerView(text: note.text, tone: note.tone == .danger ? .danger : .warning)
                }
                RedPacketReviewView(
                    amount: review.currency.flatMap { FlarePaymentRules.amountText(review.amount, currency: $0) } ?? review.amount,
                    kindLabel: Self.reviewKindLabel(review, strings), blessing: review.blessing ?? "",
                    submitLabel: review.action.label, busy: busy, error: actionError,
                    onSubmit: offline ? nil : { () -> Void in onAction(review.action.id, .empty) })
            }
        case .detail(let detail):
            RedPacketDetailPage(plan: detail, busy: busy, offline: offline, actionError: actionError, members: members,
                                resolveUser: resolveUser, onRun: { onAction($0, .empty) }, onRefresh: onRefresh,
                                onBack: onBack)
        }
    }

    @Environment(\.flareStrings) private var strings

    /// 「本群共 N 人」: a group (more than one kind on offer) shows the size the host passed.
    static func memberCount(_ plan: FlareRedPacketComposePlan, _ count: Int?) -> Int? {
        plan.kinds.count < 2 ? nil : count.flatMap { $0 > 0 ? $0 : nil }
    }

    /// The review's kind line: the plugin's own, else the kind and the share count ("拼手气红包 · 3 个").
    static func reviewKindLabel(_ review: FlareRedPacketReviewPlan, _ strings: FlareStrings) -> String {
        if let label = review.kindLabel { return label }
        guard let kind = review.kind else { return "" }
        let name = RedPacketComposerView<EmptyView>.kindLabel(kind, strings: strings)
        return review.shareCount.map { n in
            "\(name) · " + [String(n), strings.packetCountUnit].filter { !$0.isEmpty }.joined(separator: " ")
        } ?? name
    }

    /// The page's warnings and failures stay above the composer; its informational notes are the composer's to say.
    static func notes(_ view: PluginViewModel) -> [PluginNoteBlock] {
        view.blocks.compactMap { block in
            guard case .note(let note) = block, note.tone == .danger || note.tone == .warning else { return nil }
            return note
        }
    }

    // MARK: compose rules

    /// A compose-page problem: the field it belongs to (``FlareRedPacketField/form`` for the page) and its words.
    struct Issue: Equatable {
        let field: FlareRedPacketField
        let text: String
    }

    static func field(_ inputId: String) -> FlareRedPacketField {
        switch inputId {
        case "amount": return .amount
        case "shareCount": return .count
        case "greeting": return .greeting
        case "designatedUserIds": return .recipient
        default: return .form
        }
    }

    /// The form's draft by input id: a direct chat's or an exclusive packet has one share; an empty greeting is the
    /// default one.
    static func draft(_ plan: FlareRedPacketComposePlan, kind: FlareRedPacketKind, amount: String, count: Int,
                      greeting: String, recipient: String?) -> [String: PluginJSONValue] {
        let fallback = plan.inputs.first { $0.id == "greeting" }?.defaultValue?.stringValue ?? ""
        let trimmed = PluginFormRules.trimmed(greeting)
        return [
            "kind": .string(kind.rawValue),
            "amount": .string(amount),
            "shareCount": .number(Double(kind == .exclusive || plan.kinds.count == 1 ? 1 : count)),
            "greeting": .string(trimmed.isEmpty ? fallback : trimmed),
            "designatedUserIds": .array(recipient.map { [PluginJSONValue.string($0)] } ?? []),
        ]
    }

    /// The packet's total in minor units: each share times the count for an ordinary group packet, else the amount.
    static func totalMinor(_ plan: FlareRedPacketComposePlan, kind: FlareRedPacketKind, amount: String,
                           count: Int) -> String? {
        guard let minor = flareRedPacketAmountMinor(amount, exponent: plan.scale) else { return nil }
        return kind == .normal && plan.kinds.count != 1 ? times(minor, count) : minor
    }

    /// `minor` (folded ASCII digits) times a small `n`, by long multiplication: no floating point near money.
    static func times(_ minor: String, _ n: Int) -> String {
        guard n > 0 else { return "0" }
        var out: [Character] = []
        var carry = 0
        for ch in minor.reversed() {
            let value = Int(ch.asciiValue ?? 48) - 48
            let next = value * n + carry
            out.append(Character(String(next % 10)))
            carry = next / 10
        }
        while carry > 0 { out.append(Character(String(carry % 10))); carry /= 10 }
        let folded = String(out.reversed()).drop { $0 == "0" }
        return folded.isEmpty ? "0" : String(folded)
    }

    /// `a` > `b`, both folded minor-unit digit strings.
    static func greater(_ a: String, _ b: String) -> Bool { a.count != b.count ? a.count > b.count : a > b }

    static func countLimit(_ n: Int, _ strings: FlareStrings) -> String {
        strings.packetCountLimit.replacingOccurrences(of: "{n}", with: String(n))
    }

    static func moneyRange(_ rules: PluginMoneyRules?, _ strings: FlareStrings) -> String {
        strings.pluginFormMoneyRange.replacingOccurrences(of: "{min}", with: rules?.min ?? "")
            .replacingOccurrences(of: "{max}", with: rules?.max ?? "")
            .replacingOccurrences(of: "{currency}", with: rules?.currency ?? "")
    }

    static func issueText(_ issue: PluginFormIssue, _ input: PluginInput?, _ strings: FlareStrings) -> String {
        // §4.2: a missing exclusive recipient reads 请选择发给谁, not the generic "<label>: 必填" (as Vue, Compose).
        if input.map({ field($0.id) }) == .recipient, issue == .required || issue == .tooFewItems {
            return strings.packetChooseRecipient
        }
        let text = PluginFormRules.issueText(issue, input, strings)
        return input.map { "\($0.label): \(text)" } ?? text
    }

    /// The first problem with `draft` before anything is prepared (web RedPacketPageContent): each shown input by its
    /// own rule — the share count also against the plugin's live limit — then the total against the money maximum.
    static func validate(_ plan: FlareRedPacketComposePlan, draft: [String: PluginJSONValue], totalMinor: String?,
                         strings: FlareStrings) -> Issue? {
        for input in PluginFormRules.visibleInputs(plan.inputs, draft) {
            let value = draft[input.id]
            let shares = input.id == "shareCount" && input.kind == .number
            if shares, let n = value?.numberValue {
                let declared = input.max.flatMap { $0 > 0 && $0.rounded() == $0 ? Int(exactly: $0) : nil }
                if let max = [declared, plan.maxRecipients].compactMap({ $0 }).min(), n > Double(max) {
                    return Issue(field: .count, text: countLimit(max, strings))
                }
            }
            let issue: PluginFormIssue?
            if shares {
                // The kit's empty count is 0: the declared range applies before a payment is prepared.
                let n = value?.numberValue ?? 0
                issue = n.rounded() != n || n <= 0 ? .required
                    : (input.min.map { n < $0 } ?? false) || (input.max.map { n > $0 } ?? false) ? .outOfRange : nil
            } else {
                issue = PluginFormRules.check(input, value)
            }
            guard let issue else { continue }
            if input.kind == .money, input.money?.min != nil, input.money?.max != nil {
                return Issue(field: field(input.id), text: moneyRange(input.money, strings))
            }
            return Issue(field: field(input.id), text: issueText(issue, input, strings))
        }
        if let totalMinor, let max = plan.money.money?.max,
           let maxMinor = flareRedPacketAmountMinor(max, exponent: plan.scale), greater(totalMinor, maxMinor) {
            return Issue(field: .amount, text: "\(strings.packetFieldTotal): \(moneyRange(plan.money.money, strings))")
        }
        return nil
    }
}

/// The send page: the kit composer over the plugin's form.
private struct RedPacketComposePage: View {
    let plan: FlareRedPacketComposePlan
    let notes: [PluginNoteBlock]
    let busy: Bool
    let offline: Bool
    let actionError: String?
    let formErrors: [PluginFormError]
    let settleToken: Int
    let members: [PluginMember]
    let memberCount: Int?
    let membersLoading: Bool
    let membersError: String?
    let membersRevision: Int
    let onMemberSearch: ((String) -> Void)?
    let onMembersRetry: (() -> Void)?
    let onSubmit: ([String: PluginJSONValue]) -> Void
    @State private var kind: FlareRedPacketKind
    @State private var amount = ""
    @State private var count = 1
    @State private var greeting: String
    @State private var chosen: FlareContactPickerEntry?
    @State private var picking = false
    @State private var attempted = false
    /// The host's form errors show until the sender edits; a new settle brings them back.
    @State private var hostErrors = true
    @State private var focus: FlareRedPacketField?
    @Environment(\.flareStrings) private var strings

    init(plan: FlareRedPacketComposePlan, notes: [PluginNoteBlock], busy: Bool, offline: Bool, actionError: String?,
         formErrors: [PluginFormError], settleToken: Int, members: [PluginMember], memberCount: Int?, membersLoading: Bool,
         membersError: String?, membersRevision: Int, onMemberSearch: ((String) -> Void)?,
         onMembersRetry: (() -> Void)?, onSubmit: @escaping ([String: PluginJSONValue]) -> Void) {
        self.plan = plan; self.notes = notes; self.busy = busy; self.offline = offline; self.actionError = actionError
        self.formErrors = formErrors; self.settleToken = settleToken; self.members = members; self.memberCount = memberCount
        self.membersLoading = membersLoading; self.membersError = membersError; self.membersRevision = membersRevision
        self.onMemberSearch = onMemberSearch; self.onMembersRetry = onMembersRetry; self.onSubmit = onSubmit
        _kind = State(initialValue: plan.kinds.first ?? .normal)
        _greeting = State(initialValue: plan.inputs.first { $0.id == "greeting" }?.defaultValue?.stringValue ?? "")
    }

    private var draft: [String: PluginJSONValue] {
        RedPacketPageView.draft(plan, kind: kind, amount: amount, count: count, greeting: greeting, recipient: chosen?.userId)
    }

    private var totalMinor: String? { RedPacketPageView.totalMinor(plan, kind: kind, amount: amount, count: count) }

    private var issue: RedPacketPageView.Issue? {
        if let actionError { return .init(field: .form, text: actionError) }
        if hostErrors, let first = formErrors.first {
            return .init(field: RedPacketPageView.field(first.input),
                         text: RedPacketPageView.issueText(first.issue, plan.inputs.first { $0.id == first.input }, strings))
        }
        return attempted ? RedPacketPageView.validate(plan, draft: draft, totalMinor: totalMinor, strings: strings) : nil
    }

    var body: some View {
        let shown = issue
        VStack(spacing: FlareSizes.spacingMd) {
            ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                StatusBannerView(text: note.text, tone: note.tone == .danger ? .danger : .warning)
            }
            RedPacketComposerView(
                kinds: plan.kinds, kind: kind, amount: amount, currencyExponent: plan.scale, count: count,
                greeting: greeting,
                total: FlareRedPacketMoney.money(minor: totalMinor ?? "0", exponent: plan.scale, currency: plan.currency) ?? "",
                error: shown?.text, busy: busy, locked: offline, submitLabel: plan.action.label,
                errorField: shown?.field ?? .form, focusField: focus,
                currencySymbol: FlareRedPacketMoney.symbols[plan.currency.uppercased()],
                memberCount: RedPacketPageView.memberCount(plan, memberCount),
                onKindChange: { kind = $0 }, onAmountChange: { amount = $0 }, onCountChange: { count = $0 },
                onGreetingChange: { greeting = $0 }, onSubmit: submit) {
                ButtonView(label: chosen?.name ?? strings.select, variant: .text, size: .sm, disabled: busy || offline) {
                    picking = true
                    onMemberSearch?("")
                }
            }
        }
        .onChange(of: [kind.rawValue, amount, String(count), greeting, chosen?.userId ?? ""]) { _ in hostErrors = false }
        .onChange(of: settleToken) { _ in hostErrors = true }
        .onChange(of: membersRevision) { _ in chosen = nil; picking = false }
        .flareBottomSheet(isPresented: $picking, title: strings.packetFieldRecipient, titleHidden: true, size: .large,
                          fill: true) {
            ContactPickerView(
                groups: [FlareContactPickerGroup(
                    id: FlareContactPickerGroup.groupMembers, label: strings.packetFieldRecipient,
                    entries: members.map { FlareContactPickerEntry(userId: $0.userId, name: $0.name, avatarUrl: $0.avatarUrl) })],
                multiple: false, title: strings.packetFieldRecipient, loading: membersLoading, error: membersError,
                onSearch: onMemberSearch, onRetry: onMembersRetry,
                onSelect: { entries in
                    guard !busy else { return }
                    chosen = entries.first
                    picking = false
                },
                onCancel: { picking = false })
        }
    }

    private func submit() {
        guard !busy, !offline else { return }
        attempted = true
        if let found = RedPacketPageView.validate(plan, draft: draft, totalMinor: totalMinor, strings: strings) {
            if found.field != .form { focus = found.field }
            return
        }
        onSubmit(PluginFormRules.values(plan.inputs, draft))
    }
}

/// The details page, with the open sheet over it while the viewer can claim.
private struct RedPacketDetailPage: View {
    let plan: FlareRedPacketDetailPlan
    let busy: Bool
    let offline: Bool
    let actionError: String?
    let members: [PluginMember]
    let resolveUser: (@Sendable (String) async -> PluginUser?)?
    let onRun: (String) -> Void
    let onRefresh: ((PluginRefreshReason) -> Void)?
    let onBack: (() -> Void)?
    @State private var people: [String: PluginUser] = [:]
    /// The viewer looked past the sheet ("view result", or closed it on a page without a way back).
    @State private var dismissed = false
    @Environment(\.flareStrings) private var strings

    private var ids: [String] {
        var seen = Set<String>()
        return ([plan.senderId] + plan.claims.map(\.id) + plan.designatedUserIds)
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private func person(_ id: String) -> PluginUser? { people[id] }

    private var sender: PluginUser { person(plan.senderId) ?? PluginUser(name: strings.displayNameUnknownUser) }

    private var sheetOpen: Bool { plan.claimAction != nil && !dismissed }

    private var sheetState: FlareRedPacketOpenState { busy ? .opening : actionError != nil ? .error : .ready }

    var body: some View {
        VStack(spacing: FlareSizes.spacingLg) {
            if let actionError {
                StatusBannerView(text: plan.paidClaimPending ? strings.packetClaimPendingReview : actionError,
                                 tone: plan.paidClaimPending ? .warning : .danger)
            }
            RedPacketDetailView(
                senderName: sender.name, senderAvatar: sender.avatarUrl, details: plan.details,
                designatedName: plan.designatedUserIds.first.flatMap { person($0)?.name },
                claims: plan.claims.map { line in
                    FlareRedPacketClaim(id: line.id, name: person(line.id)?.name ?? strings.displayNameUnknownUser,
                                        avatar: person(line.id)?.avatarUrl, amountMinor: line.amountMinor,
                                        claimedAtMs: line.claimedAtMs, best: line.best)
                },
                onDeposited: walletTap)
            if let claim = plan.claimAction, dismissed {
                ButtonView(label: claim.label, size: .lg, loading: busy, disabled: offline, block: true) { dismissed = false }
                    .flareRedPacketTint()
            }
        }
        .task(id: ids) { await resolve(ids) }
        // Only a dismissal of a sheet still meant to show is a close: a claim that went through takes the sheet
        // away by itself and leaves the details.
        .flareRedPacketOpenSheet(isPresented: Binding(get: { sheetOpen }, set: { if !$0, sheetOpen { close() } })) {
            RedPacketOpenSheet(
                senderName: sender.name, senderAvatar: sender.avatarUrl, blessing: plan.details.greeting,
                kindLabel: RedPacketComposerView<EmptyView>.kindLabel(plan.details.kind, strings: strings),
                state: sheetState, message: actionError, reviewOnError: onRefresh != nil,
                onOpen: openTap, onViewDetails: viewDetails, onClose: close)
        }
    }

    /// "已存入钱包 ›": the bound wallet page.
    private var walletTap: (() -> Void)? {
        guard let action = plan.walletAction, !offline else { return nil }
        return { onRun(action.id) }
    }

    /// 開: the bound claim, once; a failed claim tries again from the same key (§12.12).
    private var openTap: (() -> Void)? {
        guard let claim = plan.claimAction, !offline else { return nil }
        return { if !busy { onRun(claim.id) } }
    }

    /// The sheet's close: never while opening (§12.12); otherwise the page goes too, or, without a way back, the
    /// details stay.
    private func close() {
        guard !busy else { return }
        dismissed = true
        onBack?()
    }

    /// "View result" after a failed claim: the details, read again, never another claim.
    private func viewDetails() {
        dismissed = true
        if actionError != nil, !busy { onRefresh?(.key) }
    }

    /// Names and avatars: the page's members first, then the host's directory.
    @MainActor private func resolve(_ ids: [String]) async {
        var found: [String: PluginUser] = [:]
        for id in ids {
            if let member = members.first(where: { $0.userId == id }) {
                found[id] = PluginUser(name: member.name, avatarUrl: member.avatarUrl)
            } else if let user = await resolveUser?(id) {
                found[id] = user
            }
            if Task.isCancelled { return }
        }
        people = found
    }
}
