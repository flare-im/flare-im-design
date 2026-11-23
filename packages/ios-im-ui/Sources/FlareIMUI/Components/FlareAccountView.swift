import SwiftUI

/// A host-selected visual contract, independent of plugin IDs and money rules.
public enum FlarePluginPageAppearance: Sendable { case document, account }

enum FlareAccountLayout: String { case wallet, flow, ledger }

/// 5.8: what a ledger amount's sign tells — money in (+), money out (- or −); nothing else is guessed.
enum FlareLedgerKind: Equatable { case income, spend, other }

struct FlareAccountFlowResult {
    let text: String
    let tone: FlareStatusTone
    init?(_ view: PluginViewModel) {
        let props = view.presentation?.props
        let lines = [props?["resultTitle"]?.stringValue, props?["resultDescription"]?.stringValue]
            .compactMap { $0 }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !lines.isEmpty {
            text = lines.joined(separator: "\n")
            tone = props?["resultTone"]?.stringValue.flatMap(FlareStatusTone.init(rawValue:)) ?? .neutral
        } else {
            let account = FlareAccountPresentation(view)
            guard account.layout == .flow, account.primary.isEmpty,
                  PluginView.inlineHeading(props?["formTitle"]?.stringValue) != nil,
                  !view.blocks.contains(where: { block in
                      guard case .status(let status) = block else { return false }
                      return PluginView.inlineHeading(status.text) != nil && (status.tone == .warning || status.tone == .danger)
                  }),
                  let description = PluginView.inlineHeading(props?["formUnavailableDescription"]?.stringValue) else { return nil }
            text = description
            tone = .neutral
        }
    }
}

/// Presentation slots order already-visible actions; they cannot grant a capability or invent an action.
struct FlareAccountPresentation {
    let layout: FlareAccountLayout
    let primary: [PluginViewAction]
    let shortcuts: [PluginViewAction]
    let services: [PluginViewAction]
    let groupByDate: Bool
    init(_ view: PluginViewModel) {
        layout = FlareAccountLayout(rawValue: view.presentation?.props["layout"]?.stringValue ?? "") ?? .ledger
        groupByDate = view.presentation?.props["groupByDate"]?.boolValue ?? (layout != .wallet)
        let available = view.available && !view.readOnly ? view.actions + view.menuActions : []
        let slots = layout == .flow ? ["submit"] : ["primary", "secondary", "tertiary"]
        var seen = Set<String>()
        let declared = slots.compactMap { slot -> PluginViewAction? in
            guard let id = view.presentation?.actions[slot], seen.insert(id).inserted else { return nil }
            return available.first { $0.id == id }
        }
        let preferred = declared + (layout == .flow ? available.filter { $0.style == .primary && seen.insert($0.id).inserted } : [])
        primary = preferred
        var shortcutSeen = Set(preferred.map(\.id))
        let quick = layout == .wallet ? ["shortcutPrimary", "shortcutSecondary", "shortcutTertiary"].compactMap { slot -> PluginViewAction? in
            guard let id = view.presentation?.actions[slot], shortcutSeen.insert(id).inserted else { return nil }
            return available.first { $0.id == id }
        } : []
        shortcuts = quick
        services = available.filter { action in !preferred.contains { $0.id == action.id } && !quick.contains { $0.id == action.id } }
    }
}

/// R12: a structurally derived account (no presentation; a section holding a maskable amount hero without actions,
/// and exactly one rows block of at least two columns) as the account renderer reads it — the twin of Vue
/// `flareAccountDocument` and Compose `pluginAccountDocument`: the hero and the stats lead the fields, the section's
/// other blocks come first, and a `wallet` presentation names the first two primary page actions. Any other view
/// comes back as it is.
func flareAccountDocument(_ view: PluginViewModel) -> PluginViewModel {
    guard view.presentation == nil else { return view }
    var found: (section: PluginSectionBlock, hero: Int)?
    for block in view.blocks where found == nil {
        guard case .section(let section) = block else { continue }
        if let hero = section.blocks.firstIndex(where: { if case .hero(let h) = $0 { return h.amount && h.maskable }; return false }) {
            found = (section, hero)
        }
    }
    guard let found, case .hero(let hero) = found.section.blocks[found.hero], hero.actions.isEmpty else { return view }
    let head = found.section, heroIndex = found.hero
    let rows = view.blocks.compactMap { block -> PluginRowsBlock? in if case .rows(let rows) = block { return rows }; return nil }
    guard rows.count == 1, rows[0].columns.count >= 2 else { return view }
    let page = { (action: PluginViewAction) in
        action.target?.kind == "page" && action.confirm?.isEmpty != false && action.form?.isEmpty != false
    }
    let stats = head.blocks.flatMap { block -> [PluginViewField] in
        guard case .stats(let stats) = block else { return [] }
        return stats.items.map { PluginViewField(label: $0.label, value: $0.value, format: $0.format) }
    }
    var props: [String: PluginJSONValue] = ["layout": "wallet", "summaryTitle": .string(head.label.flatMap { $0.isEmpty ? nil : $0 } ?? view.title)]
    if rows[0].actions.count == 1, page(rows[0].actions[0]) { props["rowEntryAction"] = .string(rows[0].actions[0].id) }
    var slots: [String: String] = [:]
    for (index, action) in view.actions.filter({ $0.style == .primary && page($0) }).prefix(2).enumerated() {
        slots[index == 0 ? "primary" : "secondary"] = action.id
    }
    let rest = head.blocks.enumerated().compactMap { index, block -> PluginBlock? in
        if index == heroIndex { return nil }
        if case .stats = block { return nil }
        return block
    }
    return PluginViewModel(available: view.available, title: view.title,
                           fields: [PluginViewField(label: hero.label ?? "", value: hero.value, format: hero.format)] + stats + view.fields,
                           actions: view.actions, blocks: rest + view.blocks.filter { $0 != .section(head) },
                           inputs: view.inputs, detail: view.detail, nextCursor: view.nextCursor, menuActions: view.menuActions,
                           unavailableReason: view.unavailableReason,
                           presentation: PluginPresentation(renderer: "account", props: props, actions: slots), minBuild: view.minBuild)
}

struct FlareAccountEntry: Identifiable {
    let id: String
    let block: PluginRowsBlock
    let row: PluginRow
    var separateBadge = false
    /// R10: a money cell with its currency through the payment amount formatter; a signed ledger text as sent.
    var amount: String { row.cells.first.map { PluginFormatRules.money($0.text, $0.format) } ?? "" }
    var title: String { (!separateBadge ? row.badge?.text : nil) ?? (row.cells.count > 1 ? row.cells[1].text : block.columns.first?.label ?? "") }
    /// R3: the title is a value outside its declared values: the kit writes the unknown status instead.
    var titleUnmapped: Bool {
        if !separateBadge, let badge = row.badge { return badge.unmapped }
        return row.cells.count > 1 && row.cells[1].unmapped
    }
    var walletTitle: String { row.cells.count > 1 ? row.cells[1].text : "" }
    var walletCaption: String { block.columns.first?.label ?? "" }
    var walletFields: [PluginViewField] {
        row.cells.enumerated().dropFirst(2).compactMap { index, cell in
            guard !cell.text.isEmpty, block.columns.indices.contains(index) else { return nil }
            return PluginViewField(label: block.columns[index].label, value: cell.text, tone: cell.tone, unmapped: cell.unmapped)
        }
    }
    /// The words under the title; a status (a toned cell) draws as a Tag instead (``statuses``).
    var subtitle: String {
        row.cells.enumerated().compactMap { index, cell in
            guard index >= (separateBadge || row.badge == nil ? 2 : 1), index < 3,
                  block.columns.indices.contains(index), block.columns[index].format != .time,
                  !cell.text.isEmpty, cell.tone == nil, !cell.unmapped else { return nil }
            return cell.text
        }.joined(separator: " · ")
    }
    /// 5.8: the Tags under the amount — the separate badge and the toned cells after the amount (R3) — a completed
    /// (success) one left out.
    var statuses: [PluginBadge] {
        let badge = separateBadge ? row.badge.map { [$0] } ?? [] : []
        let cells = row.cells.dropFirst().filter { $0.tone != nil || $0.unmapped }
            .map { PluginBadge(text: $0.text, tone: $0.tone ?? .neutral, unmapped: $0.unmapped) }
        return (badge + cells).filter { $0.unmapped || $0.tone != .success }
    }
    var timeMs: Int64? {
        for (index, column) in block.columns.enumerated() where column.format == .time {
            if row.cells.indices.contains(index) { return row.cells[index].timeMs }
        }
        return nil
    }
    static func entries(_ view: PluginViewModel) -> [Self] {
        view.blocks.enumerated().flatMap { index, block -> [Self] in
            guard case .rows(let rows) = block else { return [] }
            return PluginViewFormat.rowsOnce(rows.rows).map { Self(id: "\(index)/\($0.key)", block: rows, row: $0, separateBadge: view.presentation?.props["rowBadgePlacement"]?.stringValue == "separate") }
        }
    }
}

func flareAccountUrgentBlocks(_ view: PluginViewModel) -> [PluginBlock] {
    let layout = view.presentation?.props["layout"]?.stringValue
    guard layout == "wallet" || layout == "ledger" else {
        return view.blocks.filter { block in
            switch block {
            case .note(let note): return note.tone == .warning || note.tone == .danger
            case .banner(let banner): return !banner.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            default: return false
            }
        }
    }
    return view.blocks.filter { block in
        switch block {
        case .note(let note): return !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (note.tone == .warning || note.tone == .danger)
        case .status(let status): return !status.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (status.tone == .warning || status.tone == .danger)
        // 5.1: a banner (the wallet's unconfirmed operation, with its own review key) leads the page.
        case .banner(let banner): return !banner.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default: return false
        }
    }
}

/// Account overview and ledger over resolved page fields/rows. Amount strings and action input are opaque.
public struct FlareAccountView: View {
    public let view: PluginViewModel
    public var busyActionId: String?
    public var error: String?
    public var formErrors: [PluginFormError]
    public var members: [PluginMember]
    public var membersLoading: Bool
    public var membersRevision: Int
    public var membersError: String?
    public var onMemberSearch: ((String) -> Void)?
    public var onMembersRetry: (() -> Void)?
    public var settleToken: Int
    public var fileStates: [String: PluginFileState]
    public var onFileAction: ((PluginFileAction) -> Void)?
    /// R8: the page shows what was read last; every action waits (drawn, not hidden) until the host is online.
    public var offline: Bool
    public var onAction: ((String, PluginActionPayload) -> Void)?
    /// People in the page's blocks are named through the host (as on ``PluginView``); entries of `viewerId` carry "我".
    public var resolveUser: (@Sendable (String) async -> PluginUser?)?
    public var viewerId: String?
    private var contentMaxWidth: CGFloat? = FlareSizes.directoryContentMaxWidth
    /// R8: the page around it shows the action failure (a dismissible banner at its top), so this view does not.
    private var showsErrorBanner = true
    private var phoneForm: Bool?
    @State private var hidden = false
    @State private var information = false
    @State private var selected: FlareAccountEntry?
    @State private var hoveredWallet: String?
    /// The guarded main keys' runner, read from their ``PluginView`` (``primaryKeys(_:)``).
    @State private var keysChrome: PluginPageChrome?
    @FocusState private var focusedWallet: String?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    @Environment(\.flareStrings) private var strings
    @Environment(\.locale) private var locale
    @Environment(\.flarePluginClearFilters) private var clearFilters
    /// R3: the plugin and page a development warning names.
    @Environment(\.flarePluginScope) private var scope
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    public init(view: PluginViewModel, busyActionId: String? = nil, error: String? = nil,
                formErrors: [PluginFormError] = [], members: [PluginMember] = [], membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
                onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil, settleToken: Int = 0,
                fileStates: [String: PluginFileState] = [:], onFileAction: ((PluginFileAction) -> Void)? = nil,
                offline: Bool = false,
                resolveUser: (@Sendable (String) async -> PluginUser?)? = nil, viewerId: String? = nil,
                onAction: ((String, PluginActionPayload) -> Void)? = nil) {
        self.fileStates = fileStates; self.onFileAction = onFileAction
        self.view = flareAccountDocument(view); self.busyActionId = busyActionId; self.error = error
        self.membersLoading = membersLoading; self.membersRevision = membersRevision; self.membersError = membersError
        self.onMemberSearch = onMemberSearch; self.onMembersRetry = onMembersRetry
        self.formErrors = formErrors; self.members = members; self.settleToken = settleToken; self.onAction = onAction
        self.offline = offline; self.resolveUser = resolveUser; self.viewerId = viewerId
    }
    func accountContentWidth(_ width: CGFloat?) -> Self {
        var result = self
        result.contentMaxWidth = flareContentMaxWidth(width)
        return result
    }
    /// The phone form whatever the size class says (the size class is iOS only: a Mac host's tests ask for it here).
    func accountPhoneForm(_ phone: Bool) -> Self {
        var result = self
        result.phoneForm = phone
        return result
    }
    /// The page shows the action failure above this view (R8).
    func accountErrorShownAbove() -> Self {
        var result = self
        result.showsErrorBanner = false
        return result
    }
    private var colors: FlareColors { FlareColors.of(scheme, brand: brand) }
    private var entries: [FlareAccountEntry] { FlareAccountEntry.entries(view) }
    private var presentation: FlareAccountPresentation { FlareAccountPresentation(view) }
    /// 0.2: the phone form (a compact width) draws the overview card with its keys and the other wallets as rows;
    /// shortcut: the size class stands for the window width, so macOS always takes the desktop form; read the width
    /// (breakpoints.sm) when a narrow desktop window needs the phone form.
    private var phone: Bool {
        if let phoneForm { return phoneForm }
        #if os(iOS)
        return sizeClass == .compact
        #else
        return false
        #endif
    }
    /// R2.5 / R8: the account view's own keys wait while an action runs, offline, or with no host to run them.
    private var keysLocked: Bool { busyActionId != nil || offline || onAction == nil }
    private var flowInlineId: String? {
        guard presentation.layout == .flow, presentation.primary.count == 1 else { return nil }
        return PluginView.inlineAction(view, id: presentation.primary.first?.id, hasAction: onAction != nil)?.id
    }
    private var urgent: [PluginBlock] { flareAccountUrgentBlocks(view) }
    private var otherBlocks: [PluginBlock] { view.blocks.filter { if case .rows = $0 { return false }; return !urgent.contains($0) } }
    private var informationTitle: String { view.presentation?.props["informationTitle"]?.stringValue ?? strings.accountInformation }
    /// What the information panel lists: a wallet's fields (masked with the balance; a status keeps its Tag) — none
    /// before there is an account (5.2) — and the blocks the page drew nowhere else.
    private var informationFields: [PluginViewField] {
        guard presentation.layout == .wallet, !entries.isEmpty else { return [] }
        return view.fields.map { field in
            if field.unmapped { return PluginViewField(label: field.label, value: strings.pluginViewUnknownStatus, tone: .neutral) }
            return hidden && field.tone == nil ? PluginViewField(label: field.label, value: "••••") : field
        }
    }
    private func projection(fields: [PluginViewField] = [], actions: [PluginViewAction] = [], blocks: [PluginBlock] = []) -> PluginViewModel {
        PluginViewModel(available: view.available, title: view.title, fields: fields, actions: actions, blocks: blocks,
                        inputs: view.inputs, unavailableReason: view.unavailableReason)
    }
    private func actions(_ projected: PluginViewModel, entry: FlareAccountEntry? = nil,
                         layout: PluginViewActionLayout = .inline, showError: Bool = false, inlineId: String? = nil) -> some View {
        PluginView(view: projected, viewerId: viewerId, busyActionId: busyActionId, error: error, embedded: true, actionLayout: layout, showError: showError && (showsErrorBanner || entry != nil), labelRows: presentation.layout == .flow, inlineFormActionId: inlineId,
                   inlineFormTitle: inlineId == nil ? nil : view.presentation?.props["formTitle"]?.stringValue,
                   inlineFormDescription: inlineId == nil ? nil : view.presentation?.props["formDescription"]?.stringValue,
                   resolveUser: resolveUser, members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry, formErrors: formErrors, settleToken: settleToken,
                   fileStates: fileStates, onFileAction: onFileAction,
                   onAction: onAction.map { emit in { id, payload in
                       var result = payload
                       if let entry, let binding = entry.row.actions.first(where: { $0.id == id }) {
                           result.row = PluginRowRef(key: entry.row.key, input: binding.input)
                           // A simple detail action hands navigation back to its page; do not leave a sheet over it.
                           // Form actions retain their sheet so validation/settling can still update the form.
                           if entry.block.actions.first(where: { $0.id == id })?.form?.isEmpty != false { selected = nil }
                       }
                       emit(id, result)
                   } }, offline: offline)
    }
    private func dayKey(_ entry: FlareAccountEntry) -> String {
        guard let ms = entry.timeMs else { return "unknown" }
        let day = Calendar.current.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: Double(ms) / 1000))
        return "\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
    }
    private func dayLabel(_ entry: FlareAccountEntry) -> String {
        guard let ms = entry.timeMs else { return strings.accountOtherEntries }
        let date = Date(timeIntervalSince1970: Double(ms) / 1000)
        if Calendar.current.isDateInToday(date) { return strings.accountToday }
        if Calendar.current.isDateInYesterday(date) { return strings.accountYesterday }
        return PluginViewFormat.render(Calendar.current.component(.year, from: date) == Calendar.current.component(.year, from: Date()) ? strings.accountDayFormat : strings.accountDayYearFormat,
                                       PluginViewFormat.wallClock(ms, utcOffsetMinutes: nil))
    }
    /// 5.8: the rows by day, in order; a day the list returns to later starts a group of its own.
    private var days: [(label: String, entries: [FlareAccountEntry])] {
        var groups: [(key: String, label: String, entries: [FlareAccountEntry])] = []
        for entry in entries {
            let key = dayKey(entry)
            if groups.last?.key == key { groups[groups.count - 1].entries.append(entry) }
            else { groups.append((key, dayLabel(entry), [entry])) }
        }
        return groups.map { (label: $0.label, entries: $0.entries) }
    }
    private func time(_ entry: FlareAccountEntry) -> String {
        guard let ms = entry.timeMs else { return "" }
        let formatter = DateFormatter(); formatter.locale = locale; formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }
    static func entryAction(_ view: PluginViewModel, entry: FlareAccountEntry, busy: Bool, handled: Bool) -> PluginRowKey? {
        guard view.available, !view.readOnly, !busy, handled,
              let id = view.presentation?.props["rowEntryAction"]?.stringValue else { return nil }
        return PluginViewFormat.rowKeys(entry.block, entry.row).first { $0.action.id == id && $0.action.confirm?.isEmpty != false && $0.action.form?.isEmpty != false }
    }
    /// An action the account view's own keys run in one tap: no confirmation, no form, no native capture. Every other
    /// one goes through ``PluginView`` so its guards stay.
    static func direct(_ action: PluginViewAction) -> Bool {
        action.confirm?.isEmpty != false && action.form?.isEmpty != false && action.target?.kind != "native"
    }
    /// 5.2: with no account the page's key is the action that opens one — the first primary action that collects a
    /// form (`create`: an operation with a form); the page links beside it are not it.
    static func setupAction(_ actions: [PluginViewAction]) -> PluginViewAction? {
        actions.first { $0.style == .primary && !($0.form ?? []).isEmpty }
    }
    /// 5.2: the opening requests' key under it — the page destination declared next to the opening action (before it,
    /// else after). No words are read: the first page link of the list would be another destination (收款方式).
    static func setupProgress(_ actions: [PluginViewAction], create: PluginViewAction) -> PluginViewAction? {
        guard let at = actions.firstIndex(where: { $0.id == create.id }) else { return nil }
        return [at - 1, at + 1].filter(actions.indices.contains).map { actions[$0] }
            .first { PluginExperienceRules.role($0) == .destination && direct($0) }
    }
    static func ledgerKind(_ amount: String) -> FlareLedgerKind {
        switch amount.first(where: { !$0.isWhitespace }) {
        case "+": return .income
        case "-", "\u{2212}": return .spend
        default: return .other
        }
    }
    /// R10: money out reads with the minus sign (U+2212), never a hyphen.
    static func signedAmount(_ amount: String) -> String {
        guard let index = amount.firstIndex(where: { !$0.isWhitespace }), amount[index] == "-" else { return amount }
        return amount.replacingCharacters(in: index...index, with: "\u{2212}")
    }
    private func open(_ entry: FlareAccountEntry) {
        guard busyActionId == nil, !offline else { return }
        if let action = Self.entryAction(view, entry: entry, busy: false, handled: onAction != nil) {
            onAction?(action.action.id, PluginActionPayload(row: PluginRowRef(key: entry.row.key, input: action.input)))
        } else { selected = entry }
    }
    private func run(_ action: PluginViewAction) {
        guard !keysLocked, action.disabledReason == nil else { return }
        onAction?(action.id, .empty)
    }
    /// R3: a value with a tone, or outside its declared values, as its Tag (the unknown status for the latter, never the
    /// raw value); nil for plain text.
    private func tag(_ text: String, tone: PluginTone?, unmapped: Bool, context: String) -> PluginBadgeView? {
        let drawn = PluginExperienceRules.statusDraw(text: text, tone: tone, unmapped: unmapped, context: scope + context)
        guard drawn.tag else { return nil }
        return PluginBadgeView(badge: PluginBadge(text: drawn.unknown ? strings.pluginViewUnknownStatus : drawn.text, tone: drawn.tone ?? .neutral))
    }
    public var body: some View {
        Group {
            if !view.available { actions(view, showError: true) }
            else if presentation.layout == .wallet {
                VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    if entries.isEmpty { walletSetup } else { walletOverview }
                    if !presentation.shortcuts.isEmpty {
                        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                            if let title = view.presentation?.props["shortcutsTitle"]?.stringValue, !title.isEmpty { sectionHeading(title) }
                            actions(projection(actions: presentation.shortcuts), layout: .compact)
                        }
                    }
                    actionCards(walletList, information: !informationFields.isEmpty || !otherBlocks.isEmpty)
                }
            }
            else if presentation.layout == .flow {
                VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    flowIntroduction
                    if let result = FlareAccountFlowResult(view) { StatusBannerView(text: result.text, tone: result.tone) }
                    VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                        if let title = view.presentation?.props["sectionTitle"]?.stringValue { sectionHeading(title) }
                        actions(projection(fields: view.fields, actions: presentation.primary, blocks: view.blocks),
                                layout: .compact, showError: presentation.services.isEmpty, inlineId: flowInlineId)
                        if offline, !presentation.primary.isEmpty { offlineCaption }
                    }
                        .padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
                        .flarePluginCard(colors)
                    serviceSection
                }
            }
            else {
                // 5.8: day headings stick while their rows scroll under them (the page body is a scroll view).
                LazyVStack(alignment: .leading, spacing: FlareSizes.spacingMd, pinnedViews: [.sectionHeaders]) {
                    if view.presentation?.props["layout"]?.stringValue == "ledger" { ledgerIntroduction }
                    else { legacyIntroduction }
                    if view.presentation?.props["layout"]?.stringValue == "ledger" {
                        if !urgent.isEmpty { actions(projection(blocks: urgent)) }
                        if showsErrorBanner, let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
                    }
                    if let first = view.fields.first { overview(first) }
                    if view.presentation?.props["layout"]?.stringValue != "ledger" {
                        if !urgent.isEmpty { actions(projection(blocks: urgent)) }
                        if showsErrorBanner, let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
                    }
                    if !view.fields.isEmpty || view.presentation?.props["sectionTitle"] != nil { Text(view.presentation?.props["sectionTitle"]?.stringValue ?? strings.accountTransactions).font(.system(size: FlareSizes.fontSize3xl * scale, weight: .semibold))
                        .foregroundColor(colors.textPrimary).accessibilityAddTraits(.isHeader) }
                    if entries.isEmpty, let clearFilters {
                        // 5.8: nothing under the filter: say so and offer to clear it.
                        EmptyStateView(title: strings.pluginViewFilterEmpty, icon: "clock",
                                       actions: AnyView(ButtonView(label: strings.pluginViewClearFilter, variant: .secondary,
                                                                   size: .sm, action: clearFilters)),
                                       compact: true)
                            .frame(maxWidth: .infinity)
                    } else if entries.isEmpty {
                        // R8 / 5.8: the compact records empty state.
                        EmptyStateView(title: view.presentation?.props["emptyTitle"]?.stringValue ?? strings.accountEmpty, description: view.presentation?.props["emptyDescription"]?.stringValue ?? strings.accountEmptyDescription, icon: "clock", compact: true)
                            .frame(maxWidth: .infinity)
                    }
                    if presentation.groupByDate {
                        ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                            Section { ForEach(day.entries) { entry in entryRow(entry) } } header: { dayHeading(day.label) }
                        }
                    } else {
                        ForEach(entries) { entry in entryRow(entry) }
                    }
                    // R2.1: the services as list cards (grouped when declared) and the danger card; the information row
                    // closes the last list card.
                    actionCards(allActions, information: !otherBlocks.isEmpty)
                }
            }
        }
        .frame(maxWidth: contentMaxWidth ?? .infinity, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
        .flareBottomSheet(item: $selected, title: (view.presentation?.props["detailTitle"]?.stringValue ?? view.presentation?.props["sectionTitle"]?.stringValue ?? strings.accountEntryDetails), titleHidden: true,
                          dismissible: busyActionId == nil) { chosen in
            if let entry = entries.first(where: { $0.id == chosen.id }) { detail(entry) }
            else { Text(strings.accountEmpty).padding(FlareSizes.spacingLg) }
        }
        // 5.1: account information is a panel the list row opens (W-06), not a fold on the page.
        .flareBottomSheet(isPresented: $information, title: informationTitle, titleHidden: true) {
            ScrollView {
                VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    HStack {
                        Text(informationTitle).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .semibold)).accessibilityAddTraits(.isHeader)
                        Spacer()
                        IconButtonView(icon: "close", accessibilityLabel: strings.close) { information = false }
                    }
                    // 5.1 (W-06): the account's facts as a description list, label left, value right.
                    if !informationFields.isEmpty { PluginDescriptionRows(fields: informationFields) }
                    if !otherBlocks.isEmpty { actions(projection(blocks: otherBlocks)) }
                }.padding(FlareSizes.spacingLg)
            }
        }
    }
    private func sectionHeading(_ title: String) -> some View {
        Text(title).font(.system(size: FlareSizes.fontSizeXl * scale, weight: .semibold))
            .foregroundColor(colors.textPrimary).accessibilityAddTraits(.isHeader)
    }
    /// R1: a group's title (13/600, secondary).
    private func groupHeading(_ title: String) -> some View {
        Text(title).font(.system(size: FlareSizes.fontSizeMd * scale, weight: .semibold))
            .foregroundColor(colors.textSecondary).accessibilityAddTraits(.isHeader)
    }
    private func dayHeading(_ label: String) -> some View {
        Text(label).font(.system(size: FlareSizes.fontSizeSm * scale, weight: .semibold)).foregroundColor(colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, FlareSizes.spacingXs)
            .background(colors.bgPrimary).accessibilityAddTraits(.isHeader)
    }
    private var offlineCaption: some View {
        Text(strings.pluginViewAvailableOnline).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    private var eyeKey: some View {
        IconButtonView(icon: hidden ? "eye-off" : "eye", accessibilityLabel: hidden ? strings.accountShowBalance : strings.accountHideBalance) { hidden.toggle() }
            .accessibilityAddTraits(hidden ? .isSelected : [])
    }
    @ViewBuilder private var serviceSection: some View {
        if !presentation.services.isEmpty {
            actionCards(presentation.services, information: false)
            // A flow without its own inline form shows the action failure under its services (R8).
            if showsErrorBanner, flowInlineId == nil, let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
        }
    }
    private func listCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }.frame(maxWidth: .infinity).flarePluginCard(colors)
    }
    /// R2.1: the list cards of `list` without its danger actions, then those in a card of their own at the foot —
    /// centred, in the error colour, always asking first (``PluginView``'s danger card).
    @ViewBuilder private func actionCards(_ list: [PluginViewAction], information: Bool) -> some View {
        let danger = list.filter { PluginExperienceRules.role($0) == .danger }
        listCards(list.filter { PluginExperienceRules.role($0) != .danger }, information: information)
        if !danger.isEmpty {
            actions(projection(actions: danger), layout: .page)
                // Its page chrome is empty: keep it from the page's own header and bar.
                .transformPreference(PluginPageChromeKey.self) { $0 = nil }
        }
    }
    private var listDivider: some View { Divider().overlay(colors.borderSecondary) }
    /// R2.1: the list cards — common, then records and settings when the actions declare groups, else one card under
    /// the services title — closing with the account information row (5.1).
    @ViewBuilder private func listCards(_ list: [PluginViewAction], information: Bool) -> some View {
        let groups = PluginExperienceRules.listGroups(list)
        ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
            VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                if let title = group.group.map({ $0 == "records" ? strings.pluginViewGroupRecords : strings.pluginViewGroupCommon })
                    ?? view.presentation?.props["servicesTitle"]?.stringValue {
                    groupHeading(title)
                }
                listCard {
                    ForEach(Array(group.actions.enumerated()), id: \.element.id) { row, action in
                        if row > 0 { listDivider }
                        listRow(action)
                    }
                    if information, index == groups.count - 1 { listDivider; informationRow }
                }
            }
        }
        if information, groups.isEmpty { listCard { informationRow } }
    }
    /// The kit settings row (the action's icon in the leading slot, chevron on a destination); an action with a
    /// confirmation or a form stays a ``PluginView`` row so its guards run.
    @ViewBuilder private func listRow(_ action: PluginViewAction) -> some View {
        if Self.direct(action) {
            VStack(alignment: .leading, spacing: 0) {
                FlareSettingsRow(item: FlareSettingsItem(key: action.id, label: action.label, icon: action.icon,
                                                         kind: PluginExperienceRules.role(action) == .destination ? .navigation : .action,
                                                         disabled: keysLocked || action.disabledReason != nil,
                                                         danger: action.style == .danger),
                                 onSelect: { _ in run(action) })
                // R2.5: why the row is off, under its label.
                if let reason = action.disabledReason {
                    PluginCaption(text: reason)
                        .padding(.leading, action.icon == nil ? 0 : FlareSizes.iconSizeMd + FlareSizes.spacingMd)
                        .padding(.bottom, FlareSizes.spacingSm)
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg)
            .accessibilityElement(children: .combine)
        } else {
            actions(projection(actions: [action]), layout: .list).padding(.horizontal, FlareSizes.spacingLg)
        }
    }
    private var informationRow: some View {
        FlareSettingsRow(item: FlareSettingsItem(key: "account-information", label: informationTitle, icon: "info"),
                         onSelect: { _ in information = true })
            .padding(.horizontal, FlareSizes.spacingLg)
    }
    /// One of the account's keys: 48 high and full width on a phone, at least 120 wide elsewhere.
    /// `width`: the key's width off a phone (the setup key's `component.accountSetupActionWidth`).
    private func key(_ action: PluginViewAction, variant: FlareButtonVariant, busy: Bool, disabled: Bool,
                     width: CGFloat? = nil, perform: @escaping () -> Void) -> some View {
        ButtonView(label: action.label, variant: variant, size: phone ? .lg : .md, loading: busy, disabled: disabled,
                   block: true, action: perform)
            .frame(minWidth: phone || width != nil ? nil : FlareSizes.componentActionMinWidth)
            .frame(width: phone ? nil : width)
            .fixedSize(horizontal: !phone && width == nil, vertical: false)
    }
    /// The account's main keys (R2.1 quick row: equal widths) with the offline caption under them (R8). Keys with a
    /// confirmation or a form run through ``PluginView``'s own runner (confirm, form, settle): its page places draw them
    /// on a pointer; on touch its task bar (``PluginPageChrome``) is read here and drawn in this row, not pinned to the page.
    @ViewBuilder private func primaryKeys(_ keys: [PluginViewAction], width: CGFloat? = nil) -> some View {
        // A sized key (setup) is centred off a phone; the overview's keys start at the leading side (5.1).
        let centred = !phone && width != nil
        VStack(alignment: centred ? .center : .leading, spacing: FlareSizes.spacingXs) {
            if keys.allSatisfy(Self.direct) {
                HStack(spacing: FlareSizes.spacingSm) {
                    ForEach(keys) { action in
                        key(action, variant: PluginViewFormat.variant(action), busy: busyActionId == action.id,
                            disabled: keysLocked && busyActionId != action.id, width: width) { run(action) }
                    }
                }
                if offline { offlineCaption }
            } else {
                actions(projection(actions: keys), layout: .page)
                    // A sized key (setup) is drawn here on every device, so its width holds on a pointer too.
                    .environment(\.flarePluginHoistsBar, width != nil)
                    .onPreferenceChange(PluginPageChromeKey.self) { keysChrome = $0 }
                    .transformPreference(PluginPageChromeKey.self) { $0 = nil }
                if let chrome = keysChrome, !(chrome.bar + chrome.barSecondary).isEmpty {
                    HStack(spacing: FlareSizes.spacingSm) {
                        ForEach(chrome.bar + chrome.barSecondary) { action in
                            key(action, variant: PluginViewFormat.variant(action), busy: chrome.busyActionId == action.id,
                                disabled: (chrome.locked && chrome.busyActionId != action.id) || action.disabledReason != nil,
                                width: width) { chrome.run(action) }
                        }
                    }
                    if chrome.offline { offlineCaption }
                }
            }
        }.frame(maxWidth: .infinity, alignment: centred ? .center : .leading)
    }
    /// 5.1: the overview's notices — the page's banners (the unconfirmed operation, with its own review key) and
    /// warnings, then the failure.
    @ViewBuilder private var walletNotices: some View {
        if !urgent.isEmpty { actions(projection(blocks: urgent)) }
        if showsErrorBanner, let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
    }
    /// The page's actions in declaration order.
    private var allActions: [PluginViewAction] { view.available && !view.readOnly ? view.actions + view.menuActions : [] }
    /// 5.1 / 5.2: the list's actions — the services (with no account, less the opening key and its progress key) and,
    /// on a phone, the main slots' destinations (the overview card keeps the others).
    private var walletList: [PluginViewAction] {
        if entries.isEmpty {
            let create = Self.setupAction(allActions)
            let taken = [create?.id, create.flatMap { Self.setupProgress(allActions, create: $0) }?.id]
            return presentation.services.filter { !taken.contains($0.id) }
        }
        let moved = phone ? presentation.primary.filter { PluginExperienceRules.role($0) == .destination } : []
        return moved + presentation.services
    }
    /// 5.2: no account yet — no balance and no top-up or withdrawal (W-01): the setup state, the opening key and the
    /// opening requests' key under it.
    @ViewBuilder private var walletSetup: some View {
        walletNotices
        VStack(spacing: FlareSizes.spacingMd) {
            FlareIconImage(name: "wallet", size: FlareSizes.iconSizeLg).foregroundColor(colors.primaryText)
                .padding(FlareSizes.spacingMd).background(Circle().fill(colors.bgSelected)).accessibilityHidden(true)
            Text(strings.walletSetupTitle).font(.system(size: FlareSizes.fontSize4xl * scale, weight: .bold))
                .foregroundColor(colors.textPrimary).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
            Text(strings.walletSetupBody).font(.system(size: FlareSizes.fontSizeMd * scale)).foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if let create = Self.setupAction(allActions) {
                // 5.2: 48 high full width on a phone, `component.accountSetupActionWidth` elsewhere.
                primaryKeys([create], width: FlareSizes.componentAccountSetupActionWidth)
                if let progress = Self.setupProgress(allActions, create: create) {
                    key(progress, variant: .secondary, busy: busyActionId == progress.id,
                        disabled: keysLocked && busyActionId != progress.id) { run(progress) }
                        .frame(maxWidth: .infinity, alignment: phone ? .leading : .center)
                }
            }
        }
        .padding(.vertical, FlareSizes.spacing2xl).frame(maxWidth: .infinity)
    }
    private var walletOverview: some View {
        let title = view.presentation?.props["sectionTitle"]?.stringValue ?? view.presentation?.props["summaryTitle"]?.stringValue ?? view.title
        return VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            if phone {
                FlareAccountHeaderLayout {
                    sectionHeading(title)
                    eyeKey
                }
            }
            walletNotices
            if phone, let lead = entries.first {
                // 5.1: the default wallet is the overview card with its keys; any other wallet is a row under it.
                walletCard(lead, quick: presentation.primary.filter { PluginExperienceRules.role($0) != .destination })
                let others = Array(entries.dropFirst())
                if !others.isEmpty {
                    groupHeading(view.presentation?.props["otherWalletsTitle"]?.stringValue ?? strings.accountOtherWallets)
                    listCard {
                        ForEach(Array(others.enumerated()), id: \.element.id) { index, entry in
                            if index > 0 { listDivider }
                            walletRow(entry)
                        }
                    }
                }
            } else {
                // §12.23: no title row on a pointer (the page header names the page; the section keeps the title for
                // the reader): the cards in two equal columns, then the quick keys with the eye at the row's end.
                VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
                    FlareAccountWalletGrid {
                        ForEach(entries) { entry in walletCard(entry, pc: true) }
                    }
                    // R2.1 on a pointer: the main keys start the row — 40 high, at least 120 wide.
                    HStack(alignment: .top, spacing: FlareSizes.spacingSm) {
                        if presentation.primary.isEmpty { Spacer(minLength: 0) } else { primaryKeys(presentation.primary) }
                        eyeKey.frame(height: FlareSizes.controlHeightMd)
                    }
                    .accessibilityIdentifier("flare-account-quick-row")
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text(title))
            }
        }
    }
    /// A wallet card (5.1). `pc` (§12.23): the wallet and its name, the balance and one foot line「状态 Tag · 查看明细 ›」—
    /// no balance label and no plain details.
    private func walletCard(_ entry: FlareAccountEntry, quick: [PluginViewAction] = [], pc: Bool = false) -> some View {
        let direct = Self.entryAction(view, entry: entry, busy: offline, handled: onAction != nil)
        let statuses = !pc ? [] : entry.walletFields.compactMap { tag($0.value, tone: $0.tone, unmapped: $0.unmapped, context: "account:\($0.label)") }
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusCard, style: .continuous)
        return VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
            Button { open(entry) } label: {
                VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                    HStack {
                        FlareIconImage(name: "wallet", size: FlareSizes.iconSizeMd).foregroundColor(colors.primaryText).accessibilityHidden(true)
                        Text(entry.walletTitle).font(.system(size: FlareSizes.fontSize4xl * scale, weight: .semibold))
                        Spacer(minLength: FlareSizes.spacingSm)
                        if direct == nil { FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm).foregroundColor(colors.textSecondary).accessibilityHidden(true) }
                    }
                    if !pc { Text(entry.walletCaption).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary) }
                    // R10: the overview amount is 32/700 in the primary text colour, tabular; never the brand colour (G-04).
                    Text(hidden ? "••••" : entry.amount).font(.system(size: FlareSizes.componentAmountHeroFontSize * scale, weight: .bold)).monospacedDigit()
                        .foregroundColor(colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(hidden ? strings.accountBalanceHidden : entry.amount)
                    if pc, !statuses.isEmpty || direct != nil {
                        let dot = Text("·").foregroundColor(colors.textTertiary)
                        HStack(spacing: FlareSizes.spacingXs) {
                            ForEach(Array(statuses.enumerated()), id: \.offset) { index, status in
                                if index > 0 { dot }
                                status
                            }
                            if let direct {
                                if !statuses.isEmpty { dot }
                                HStack(spacing: FlareSizes.spacing3xs) {
                                    Text(direct.action.label).font(.system(size: FlareSizes.fontSizeSm * scale, weight: .medium))
                                    FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm).accessibilityHidden(true)
                                }.foregroundColor(colors.primaryText)
                            }
                        }
                        .accessibilityIdentifier("account-entry-foot:\(entry.id)")
                    }
                    if !pc { LazyVGrid(columns: (0..<min(2, max(1, entry.walletFields.count))).map { _ in GridItem(.flexible(), spacing: FlareSizes.spacingMd, alignment: .leading) }, alignment: .leading, spacing: FlareSizes.spacingSm) {
                        ForEach(Array(entry.walletFields.enumerated()), id: \.offset) { _, field in
                            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                                Text(field.label).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
                                // W-04: a status reads as its Tag; figures hide with the balance.
                                if let tag = tag(field.value, tone: field.tone, unmapped: field.unmapped, context: "account:\(field.label)") { tag }
                                else { Text(hidden ? "••••" : field.value).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .medium)) }
                            }.fixedSize(horizontal: false, vertical: true)
                        }
                    } }
                    if !pc, let direct {
                        Divider().overlay(colors.borderSecondary)
                        HStack {
                            Text(direct.action.label).font(.system(size: FlareSizes.fontSizeSm * scale, weight: .semibold))
                            Spacer(minLength: FlareSizes.spacingSm)
                            FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm).accessibilityHidden(true)
                        }.foregroundColor(colors.primaryText).padding(.top, FlareSizes.spacingXs)
                    }
                }.foregroundColor(colors.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(busyActionId != nil || offline)
                .focused($focusedWallet, equals: entry.id)
                .accessibilityElement(children: .combine)
                .accessibilityHint(Text(direct?.action.label ?? strings.accountEntryDetails))
            if !quick.isEmpty { primaryKeys(quick) }
        }.padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
            // §5.1: the overview card is radius.card on bg.primary.
            .flarePluginCard(colors)
            .onHover { hoveredWallet = $0 ? entry.id : nil }
            .overlay(shape.stroke(hoveredWallet == entry.id && busyActionId == nil ? colors.borderHover : .clear, lineWidth: 1).allowsHitTesting(false))
            .flareFocusRing(focusedWallet == entry.id, cornerRadius: FlareSizes.radiusCard, color: colors.borderSelected)
    }
    /// 5.1: another wallet under the phone's overview card — its name and currency, the balance, a chevron.
    private func walletRow(_ entry: FlareAccountEntry) -> some View {
        let caption = entry.walletFields.first { $0.tone == nil && !$0.unmapped }?.value ?? entry.walletCaption
        return Button { open(entry) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                    Text(entry.walletTitle).font(.system(size: FlareSizes.fontSizeXl * scale)).foregroundColor(colors.textPrimary).lineLimit(1)
                    Text(hidden ? "••••" : caption).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Text(hidden ? "••••" : entry.amount).font(.system(size: FlareSizes.fontSize2xl * scale, weight: .semibold)).monospacedDigit()
                    .foregroundColor(colors.textPrimary)
                    .accessibilityLabel(hidden ? strings.accountBalanceHidden : entry.amount)
                FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm).foregroundColor(colors.textTertiary).accessibilityHidden(true)
            }.padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
                .frame(minHeight: FlareSizes.touchTarget).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(busyActionId != nil || offline)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text(Self.entryAction(view, entry: entry, busy: offline, handled: onAction != nil)?.action.label ?? strings.accountEntryDetails))
    }
    private var flowIntroduction: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if let step = view.presentation?.props["stepLabel"]?.stringValue, !step.isEmpty {
                Text(step).font(.system(size: FlareSizes.fontSizeSm * scale, weight: .semibold)).foregroundColor(colors.primaryText)
            }
            if let title = view.presentation?.props["summaryTitle"]?.stringValue, !title.isEmpty { sectionHeading(title) }
            if let description = view.presentation?.props["description"]?.stringValue, !description.isEmpty {
                Text(description).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var ledgerIntroduction: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if let context = view.presentation?.props["contextLabel"]?.stringValue, !context.isEmpty {
                Text(context).font(.system(size: FlareSizes.fontSizeMd * scale, weight: .medium)).foregroundColor(colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let description = view.presentation?.props["description"]?.stringValue, !description.isEmpty {
                Text(description).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    @ViewBuilder private var legacyIntroduction: some View {
        if let step = view.presentation?.props["stepLabel"]?.stringValue, !step.isEmpty {
            Text(step).font(.system(size: FlareSizes.fontSizeSm * scale, weight: .semibold)).foregroundColor(colors.primaryText)
        }
        if let title = view.presentation?.props["summaryTitle"]?.stringValue, !title.isEmpty { sectionHeading(title) }
        if let description = view.presentation?.props["description"]?.stringValue, !description.isEmpty {
            Text(description).font(.system(size: FlareSizes.fontSizeMd * scale)).foregroundColor(colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let context = view.presentation?.props["contextLabel"]?.stringValue, !context.isEmpty {
            Text(context).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    private func overview(_ first: PluginViewField) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            HStack {
                Text(first.label).foregroundColor(colors.textSecondary)
                Spacer()
                eyeKey
            }
            let amount = PluginFormatRules.text(first.value, first.format, strings)
            Text(hidden ? "••••" : amount)
                .font(.system(size: FlareSizes.componentAmountHeroFontSize * scale, weight: .bold)).monospacedDigit()
                .foregroundColor(colors.textPrimary)
                .accessibilityLabel(hidden ? strings.accountBalanceHidden : amount)
                .minimumScaleFactor(0.6)
            FlareFlowLayout(spacing: FlareSizes.spacingXl, lineSpacing: FlareSizes.spacingMd) {
                ForEach(Array(view.fields.dropFirst().enumerated()), id: \.offset) { _, field in
                    VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                        Text(field.label).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
                        if let tag = tag(field.value, tone: field.tone, unmapped: field.unmapped, context: "account:\(field.label)") { tag }
                        else { Text(hidden ? "••••" : PluginFormatRules.text(field.value, field.format, strings)).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .semibold)).foregroundColor(colors.textPrimary) }
                    }
                }
            }
        }
        .font(.system(size: FlareSizes.fontSizeMd * scale))
        .padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
        .flarePluginCard(colors)
    }
    /// 5.8: a 36 round icon by what the sign tells (money in: arrow-down on the success ground; money out: send);
    /// any other row takes the internal move's refresh, as the rows block does — recharge and withdrawal are not
    /// guessed from words.
    private func ledgerIcon(_ kind: FlareLedgerKind) -> some View {
        FlareIconImage(name: kind == .income ? "arrow-down" : kind == .spend ? "send" : "refresh", size: FlareSizes.iconSizeMd)
            .foregroundColor(kind == .income ? colors.successText : colors.textSecondary)
            .frame(width: FlareSizes.componentRecordIconSize, height: FlareSizes.componentRecordIconSize)
            .background(Circle().fill(pluginBadgeGround(kind == .income ? .success : .neutral, colors)))
            .accessibilityHidden(true)
    }
    private func entryRow(_ entry: FlareAccountEntry) -> some View {
        let kind = Self.ledgerKind(entry.amount)
        let masked = hidden && view.presentation?.props["maskRowAmounts"]?.boolValue == true
        let subtitle = [time(entry), entry.subtitle].filter { !$0.isEmpty }.joined(separator: " · ")
        return Button { open(entry) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                ledgerIcon(kind)
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    Text(entry.titleUnmapped ? strings.pluginViewUnknownStatus : entry.title).font(.system(size: FlareSizes.fontSizeXl * scale)).foregroundColor(colors.textPrimary)
                    if !subtitle.isEmpty { Text(subtitle).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary).lineLimit(2) }
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: FlareSizes.spacingXs) {
                    // R10: money in in the success ink with "+", money out in the primary ink with "−".
                    Text(masked ? "••••" : Self.signedAmount(entry.amount)).font(.system(size: FlareSizes.fontSize2xl * scale, weight: .semibold)).monospacedDigit()
                        .foregroundColor(kind == .income ? colors.successText : colors.textPrimary).fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(masked ? strings.accountBalanceHidden : Self.signedAmount(entry.amount))
                    ForEach(Array(entry.statuses.enumerated()), id: \.offset) { _, status in
                        tag(status.text, tone: status.tone, unmapped: status.unmapped, context: "account:\(entry.block.columns.first?.label ?? "")")
                    }
                }.frame(maxWidth: .infinity, alignment: .trailing)
            // 5.8: a record row is 64 high, without a chevron (the row itself opens it).
            }.padding(.vertical, FlareSizes.spacingSm).frame(minHeight: FlareSizes.componentRecordRowHeight)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(busyActionId != nil || offline)
    }
    private func detailLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            Text(label).foregroundColor(colors.textSecondary)
            Spacer(minLength: FlareSizes.spacingMd)
            Text(value).foregroundColor(colors.textPrimary).multilineTextAlignment(.trailing).textSelection(.enabled)
        }.font(.system(size: FlareSizes.fontSizeMd * scale)).padding(.vertical, FlareSizes.spacingSm)
    }
    private func detailTag(_ label: String, _ tag: PluginBadgeView) -> some View {
        HStack { Text(label).foregroundColor(colors.textSecondary); Spacer(); tag }
            .font(.system(size: FlareSizes.fontSizeMd * scale)).padding(.vertical, FlareSizes.spacingSm)
    }
    private func detail(_ entry: FlareAccountEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                HStack {
                    Text((view.presentation?.props["detailTitle"]?.stringValue ?? view.presentation?.props["sectionTitle"]?.stringValue ?? strings.accountEntryDetails)).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .semibold))
                    Spacer()
                    IconButtonView(icon: "close", accessibilityLabel: strings.close, disabled: busyActionId != nil) { selected = nil }
                }
                if let label = entry.block.columns.first?.label, !label.isEmpty { Text(label).foregroundColor(colors.textSecondary).frame(maxWidth: .infinity) }
                // 5.9: the amount reads like a result's, 32/700 and tabular.
                Text(hidden && view.presentation?.props["maskRowAmounts"]?.boolValue == true ? "••••" : entry.amount)
                    .font(.system(size: FlareSizes.componentAmountHeroFontSize * scale, weight: .bold)).monospacedDigit()
                    .foregroundColor(Self.ledgerKind(entry.amount) == .income ? colors.successText : colors.textPrimary)
                    .frame(maxWidth: .infinity).padding(.vertical, FlareSizes.spacingMd)
                if let badge = entry.row.badge,
                   let tag = tag(badge.text, tone: badge.tone, unmapped: badge.unmapped, context: "account:\(entry.block.columns.first?.label ?? "")") {
                    detailTag(view.presentation?.props["rowBadgeLabel"]?.stringValue ?? strings.accountType, tag)
                }
                ForEach(Array(entry.row.cells.enumerated().dropFirst()), id: \.offset) { index, cell in
                    let column = entry.block.columns.indices.contains(index) ? entry.block.columns[index] : nil
                    if let tag = tag(cell.text, tone: cell.tone, unmapped: cell.unmapped, context: "account:\(column?.label ?? "")") {
                        detailTag(column?.label ?? "", tag)
                    } else {
                        detailLine(column?.label ?? "", column?.format == .time && cell.timeMs != nil
                                   ? PluginViewFormat.dateTime(cell.timeMs!, nowMs: PluginViewClock.system.now(), strings, utcOffsetMinutes: nil) : cell.text)
                    }
                }
                detailLine(view.presentation?.props["rowKeyLabel"]?.stringValue ?? strings.accountEntryId, entry.row.key)
                actions(projection(actions: entry.block.actions.filter { action in entry.row.actions.contains { $0.id == action.id } }), entry: entry, showError: true)
            }.padding(FlareSizes.spacingLg)
        }
    }
}

func flareAccountWalletColumnCount(width: CGFloat, count: Int) -> Int {
    count > 1 && width >= FlareSizes.primaryPaneMinWidth * 2 + FlareSizes.spacingMd ? 2 : 1
}

struct FlareAccountWalletGrid: Layout {
    private func geometry(_ proposal: ProposedViewSize, _ subviews: Subviews) -> (CGFloat, Int, CGFloat, [CGFloat]) {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? FlareSizes.primaryPaneMinWidth
        let columns = flareAccountWalletColumnCount(width: width, count: subviews.count)
        let cell = max(0, (width - FlareSizes.spacingMd * CGFloat(columns - 1)) / CGFloat(columns))
        var heights: [CGFloat] = []
        for index in subviews.indices {
            let row = index / columns
            if row == heights.count { heights.append(0) }
            heights[row] = max(heights[row], subviews[index].sizeThatFits(ProposedViewSize(width: cell, height: nil)).height)
        }
        return (width, columns, cell, heights)
    }
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let (width, _, _, heights) = geometry(proposal, subviews)
        return CGSize(width: width, height: heights.reduce(0, +) + CGFloat(max(0, heights.count - 1)) * FlareSizes.spacingMd)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let (_, columns, cell, heights) = geometry(ProposedViewSize(width: bounds.width, height: nil), subviews)
        for index in subviews.indices {
            let row = index / columns
            let y = heights.prefix(row).reduce(0, +) + CGFloat(row) * FlareSizes.spacingMd
            subviews[index].place(at: CGPoint(x: bounds.minX + CGFloat(index % columns) * (cell + FlareSizes.spacingMd), y: bounds.minY + y),
                                 anchor: .topLeading, proposal: ProposedViewSize(width: cell, height: nil))
        }
    }
}

/// Two semantic groups: trailing controls on one row, leading controls when wrapped.
struct FlareAccountHeaderLayout: Layout {
    private func sizes(_ subviews: Subviews, width: CGFloat?) -> [CGSize] {
        subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)) }
    }
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let items = sizes(subviews, width: proposal.width)
        let width = proposal.width ?? items.map(\.width).reduce(0, +) + FlareSizes.spacingMd
        let wrapped = items.map(\.width).reduce(0, +) + FlareSizes.spacingMd > width
        return CGSize(width: width, height: wrapped ? items.map(\.height).reduce(0, +) + FlareSizes.spacingMd : items.map(\.height).max() ?? 0)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let items = sizes(subviews, width: bounds.width)
        let wrapped = items.map(\.width).reduce(0, +) + FlareSizes.spacingMd > bounds.width
        var y = bounds.minY
        for index in subviews.indices {
            let size = items[index]
            let x = !wrapped && index > 0 ? bounds.maxX - size.width : bounds.minX
            subviews[index].place(at: CGPoint(x: x, y: wrapped ? y : bounds.minY + ((items.map(\.height).max() ?? 0) - size.height) / 2), anchor: .topLeading, proposal: ProposedViewSize(size))
            y += size.height + FlareSizes.spacingMd
        }
    }
}
