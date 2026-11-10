import SwiftUI

/// A host-selected visual contract, independent of plugin IDs and money rules.
public enum FlarePluginPageAppearance: Sendable { case document, account }

enum FlareAccountLayout: String { case wallet, flow, ledger }

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

struct FlareAccountEntry: Identifiable {
    let id: String
    let block: PluginRowsBlock
    let row: PluginRow
    var separateBadge = false
    var amount: String { row.cells.first?.text ?? "" }
    var title: String { (!separateBadge ? row.badge?.text : nil) ?? (row.cells.count > 1 ? row.cells[1].text : block.columns.first?.label ?? "") }
    var walletTitle: String { row.cells.count > 1 ? row.cells[1].text : "" }
    var walletCaption: String { block.columns.first?.label ?? "" }
    var walletFields: [PluginViewField] {
        row.cells.enumerated().dropFirst(2).compactMap { index, cell in
            guard !cell.text.isEmpty, block.columns.indices.contains(index) else { return nil }
            return PluginViewField(label: block.columns[index].label, value: cell.text)
        }
    }
    var subtitle: String {
        row.cells.enumerated().compactMap { index, cell in
            guard index >= (separateBadge || row.badge == nil ? 2 : 1), index < 3,
                  block.columns.indices.contains(index), block.columns[index].format != .time,
                  !cell.text.isEmpty else { return nil }
            return cell.text
        }.joined(separator: " · ")
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
        return view.blocks.filter { if case .note(let note) = $0 { return note.tone == .warning || note.tone == .danger }; return false }
    }
    return view.blocks.filter { block in
        switch block {
        case .note(let note): return !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (note.tone == .warning || note.tone == .danger)
        case .status(let status): return !status.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (status.tone == .warning || status.tone == .danger)
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
    public var onAction: ((String, PluginActionPayload) -> Void)?
    private var contentMaxWidth: CGFloat? = FlareSizes.directoryContentMaxWidth
    @State private var hidden = false
    @State private var information = false
    @State private var selected: FlareAccountEntry?
    @State private var hoveredWallet: String?
    @FocusState private var focusedWallet: String?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    @Environment(\.flareStrings) private var strings
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    public init(view: PluginViewModel, busyActionId: String? = nil, error: String? = nil,
                formErrors: [PluginFormError] = [], members: [PluginMember] = [], membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
                onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil, settleToken: Int = 0,
                fileStates: [String: PluginFileState] = [:], onFileAction: ((PluginFileAction) -> Void)? = nil,
                onAction: ((String, PluginActionPayload) -> Void)? = nil) {
        self.fileStates = fileStates; self.onFileAction = onFileAction
        self.view = view; self.busyActionId = busyActionId; self.error = error
        self.membersLoading = membersLoading; self.membersRevision = membersRevision; self.membersError = membersError
        self.onMemberSearch = onMemberSearch; self.onMembersRetry = onMembersRetry
        self.formErrors = formErrors; self.members = members; self.settleToken = settleToken; self.onAction = onAction
    }
    func accountContentWidth(_ width: CGFloat?) -> Self {
        var result = self
        result.contentMaxWidth = flareContentMaxWidth(width)
        return result
    }
    private var colors: FlareColors { FlareColors.of(scheme, brand: brand) }
    private var entries: [FlareAccountEntry] { FlareAccountEntry.entries(view) }
    private var presentation: FlareAccountPresentation { FlareAccountPresentation(view) }
    private var flowInlineId: String? {
        guard presentation.layout == .flow, presentation.primary.count == 1 else { return nil }
        return PluginView.inlineAction(view, id: presentation.primary.first?.id, hasAction: onAction != nil)?.id
    }
    private var urgent: [PluginBlock] { flareAccountUrgentBlocks(view) }
    private var otherBlocks: [PluginBlock] { view.blocks.filter { if case .rows = $0 { return false }; return !urgent.contains($0) } }
    private func projection(fields: [PluginViewField] = [], actions: [PluginViewAction] = [], blocks: [PluginBlock] = []) -> PluginViewModel {
        PluginViewModel(available: view.available, title: view.title, fields: fields, actions: actions, blocks: blocks,
                        inputs: view.inputs, unavailableReason: view.unavailableReason)
    }
    private func actions(_ projected: PluginViewModel, entry: FlareAccountEntry? = nil,
                         layout: PluginViewActionLayout = .inline, showError: Bool = false, inlineId: String? = nil) -> some View {
        PluginView(view: projected, busyActionId: busyActionId, error: error, embedded: true, actionLayout: layout, showError: showError, labelRows: presentation.layout == .flow, inlineFormActionId: inlineId,
                   inlineFormTitle: inlineId == nil ? nil : view.presentation?.props["formTitle"]?.stringValue,
                   inlineFormDescription: inlineId == nil ? nil : view.presentation?.props["formDescription"]?.stringValue,
                   members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry, formErrors: formErrors, settleToken: settleToken,
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
                   } })
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
    private func open(_ entry: FlareAccountEntry) {
        guard busyActionId == nil else { return }
        if let action = Self.entryAction(view, entry: entry, busy: false, handled: onAction != nil) {
            onAction?(action.action.id, PluginActionPayload(row: PluginRowRef(key: entry.row.key, input: action.input)))
        } else { selected = entry }
    }
    public var body: some View {
        Group {
            if !view.available { actions(view, showError: true) }
            else if presentation.layout == .wallet {
                VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    walletOverview
                    if !presentation.shortcuts.isEmpty {
                        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                            if let title = view.presentation?.props["shortcutsTitle"]?.stringValue, !title.isEmpty { sectionHeading(title) }
                            actions(projection(actions: presentation.shortcuts), layout: .compact)
                        }
                    }
                    if entries.isEmpty { EmptyStateView(title: view.presentation?.props["emptyTitle"]?.stringValue ?? strings.accountEmpty, description: view.presentation?.props["emptyDescription"]?.stringValue ?? strings.accountEmptyDescription, icon: "wallet") }
                    if !view.fields.isEmpty || !otherBlocks.isEmpty {
                        DisclosureGroup(isExpanded: $information) { actions(projection(fields: view.fields.map { .init(label: $0.label, value: hidden ? "••••" : $0.value) }, blocks: otherBlocks)) }
                        label: { Text(view.presentation?.props["informationTitle"]?.stringValue ?? strings.accountInformation).foregroundColor(colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget, alignment: .leading).contentShape(Rectangle()) }
                    }
                    serviceSection
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
                    }
                        .padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.bgSecondary).clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
                    serviceSection
                }
            }
            else {
                LazyVStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    if view.presentation?.props["layout"]?.stringValue == "ledger" { ledgerIntroduction }
                    else { legacyIntroduction }
                    if view.presentation?.props["layout"]?.stringValue == "ledger" {
                        if !urgent.isEmpty { actions(projection(blocks: urgent)) }
                        if let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
                    }
                    if let first = view.fields.first { overview(first) }
                    if view.presentation?.props["layout"]?.stringValue != "ledger" {
                        if !urgent.isEmpty { actions(projection(blocks: urgent)) }
                        if let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
                    }
                    if !view.fields.isEmpty || view.presentation?.props["sectionTitle"] != nil { Text(view.presentation?.props["sectionTitle"]?.stringValue ?? strings.accountTransactions).font(.system(size: FlareSizes.fontSize3xl * scale, weight: .semibold))
                        .foregroundColor(colors.textPrimary).accessibilityAddTraits(.isHeader) }
                    if entries.isEmpty {
                        EmptyStateView(title: view.presentation?.props["emptyTitle"]?.stringValue ?? strings.accountEmpty, description: view.presentation?.props["emptyDescription"]?.stringValue ?? strings.accountEmptyDescription, icon: "wallet")
                    }
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if presentation.groupByDate && (index == 0 || dayKey(entry) != dayKey(entries[index - 1])) {
                            Text(dayLabel(entry)).font(.system(size: FlareSizes.fontSizeSm * scale))
                                .foregroundColor(colors.textSecondary).accessibilityAddTraits(.isHeader)
                        }
                        entryRow(entry)
                    }
                    if !otherBlocks.isEmpty {
                        DisclosureGroup(isExpanded: $information) {
                            actions(projection(blocks: otherBlocks))
                        }
                        label: { Text(view.presentation?.props["informationTitle"]?.stringValue ?? strings.accountInformation).foregroundColor(colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget, alignment: .leading).contentShape(Rectangle()) }
                            .font(.system(size: FlareSizes.fontSizeMd * scale))
                    }
                    if !(view.actions + view.menuActions).isEmpty {
                        if let title = view.presentation?.props["servicesTitle"]?.stringValue { sectionHeading(title) }
                        actions(projection(actions: view.actions + view.menuActions), layout: .list)
                            .padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
                            .background(colors.bgSecondary).clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
                    }
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
    }
    private func sectionHeading(_ title: String) -> some View {
        Text(title).font(.system(size: FlareSizes.fontSizeXl * scale, weight: .semibold))
            .foregroundColor(colors.textPrimary).accessibilityAddTraits(.isHeader)
    }
    @ViewBuilder private var serviceSection: some View {
        if !presentation.services.isEmpty {
            if let title = view.presentation?.props["servicesTitle"]?.stringValue { sectionHeading(title) }
            actions(projection(actions: presentation.services), layout: .list, showError: presentation.layout != .wallet && flowInlineId == nil)
                .padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
                .background(colors.bgSecondary).clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
        }
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
    private var walletOverview: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            FlareAccountHeaderLayout {
                sectionHeading(view.presentation?.props["sectionTitle"]?.stringValue ?? view.presentation?.props["summaryTitle"]?.stringValue ?? view.title)
                HStack(spacing: FlareSizes.spacingSm) {
                    if !presentation.primary.isEmpty { actions(projection(actions: presentation.primary), layout: .compact) }
                    IconButtonView(icon: hidden ? "eye-off" : "eye", accessibilityLabel: hidden ? strings.accountShowBalance : strings.accountHideBalance) { hidden.toggle() }
                }
            }
            if !urgent.isEmpty { actions(projection(blocks: urgent)) }
            if let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
            if entries.isEmpty {
                if let first = view.fields.first {
                    VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                        Text(first.label).foregroundColor(colors.textSecondary)
                        Text(hidden ? "••••" : first.value).font(.system(size: FlareSizes.fontSize3xl * scale, weight: .semibold))
                    }.padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.bgSecondary).clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
                }
            } else {
                FlareAccountWalletGrid {
                    ForEach(entries) { entry in walletCard(entry) }
                }
            }
        }
    }
    private func walletCard(_ entry: FlareAccountEntry) -> some View {
        let direct = Self.entryAction(view, entry: entry, busy: false, handled: onAction != nil)
        return Button { open(entry) } label: {
            VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                HStack {
                    FlareIconImage(name: "wallet", size: FlareSizes.iconSizeMd).foregroundColor(colors.primaryText).accessibilityHidden(true)
                    Text(entry.walletTitle).font(.system(size: FlareSizes.fontSize4xl * scale, weight: .semibold))
                    Spacer(minLength: FlareSizes.spacingSm)
                    if direct == nil { FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm).foregroundColor(colors.textSecondary).accessibilityHidden(true) }
                }
                Text(entry.walletCaption).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
                Text(hidden ? "••••" : entry.amount).font(.system(size: FlareSizes.fontSize5xl * scale, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(hidden ? strings.accountBalanceHidden : entry.amount)
                LazyVGrid(columns: (0..<min(2, max(1, entry.walletFields.count))).map { _ in GridItem(.flexible(), spacing: FlareSizes.spacingMd, alignment: .leading) }, alignment: .leading, spacing: FlareSizes.spacingSm) {
                    ForEach(Array(entry.walletFields.enumerated()), id: \.offset) { _, field in
                        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                            Text(field.label).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
                            Text(hidden ? "••••" : field.value).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .medium))
                        }.fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let direct {
                    Divider().overlay(colors.borderSecondary)
                    HStack {
                        Text(direct.action.label).font(.system(size: FlareSizes.fontSizeSm * scale, weight: .semibold))
                        Spacer(minLength: FlareSizes.spacingSm)
                        FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm).accessibilityHidden(true)
                    }.foregroundColor(colors.primaryText).padding(.top, FlareSizes.spacingXs)
                }
            }.foregroundColor(colors.textPrimary).padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
                .background(colors.bgSecondary).clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
                .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).strokeBorder(colors.borderSecondary, lineWidth: 1))
                .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(busyActionId != nil)
            .focused($focusedWallet, equals: entry.id)
            .onHover { hoveredWallet = $0 ? entry.id : nil }
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(focusedWallet == entry.id ? colors.focusRing : (hoveredWallet == entry.id && busyActionId == nil ? colors.borderHover : .clear), lineWidth: focusedWallet == entry.id ? 3 : 1))
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text(direct?.action.label ?? strings.accountEntryDetails))
    }
    private func overview(_ first: PluginViewField) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            HStack {
                Text(first.label).foregroundColor(colors.textSecondary)
                Spacer()
                IconButtonView(icon: hidden ? "eye-off" : "eye",
                               accessibilityLabel: hidden ? strings.accountShowBalance : strings.accountHideBalance) { hidden.toggle() }
            }
            Text(hidden ? "••••" : first.value)
                .font(.system(size: FlareSizes.componentRedPacketAmountFontSize * scale, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityLabel(hidden ? strings.accountBalanceHidden : first.value)
                .minimumScaleFactor(0.6)
            FlareFlowLayout(spacing: FlareSizes.spacingXl, lineSpacing: FlareSizes.spacingMd) {
                ForEach(Array(view.fields.dropFirst().enumerated()), id: \.offset) { _, field in
                    VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                        Text(field.label).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary)
                        Text(hidden ? "••••" : field.value).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .semibold)).foregroundColor(colors.textPrimary)
                    }
                }
            }
        }
        .font(.system(size: FlareSizes.fontSizeMd * scale))
        .padding(FlareSizes.spacingLg).frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.bgSecondary).clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
    }
    private func entryRow(_ entry: FlareAccountEntry) -> some View {
        Button { open(entry) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                Image(systemName: flareIconSymbol("wallet")).foregroundColor(colors.textSecondary)
                    .padding(FlareSizes.spacingSm).background(colors.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd))
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    Text(entry.title).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .medium)).foregroundColor(colors.textPrimary)
                    if entry.separateBadge, let badge = entry.row.badge { PluginBadgeView(badge: badge) }
                    if !entry.subtitle.isEmpty { Text(entry.subtitle).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary).lineLimit(2) }
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: FlareSizes.spacingXs) {
                    Text(hidden && view.presentation?.props["maskRowAmounts"]?.boolValue == true ? "••••" : entry.amount).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .semibold))
                        .foregroundColor(entry.amount.hasPrefix("+") ? colors.successText : colors.textPrimary).fixedSize(horizontal: false, vertical: true)
                    Text(time(entry)).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textTertiary)
                }.frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: flareIconSymbol("chevron-right")).font(.system(size: FlareSizes.iconSizeSm)).foregroundColor(colors.textTertiary)
            }.padding(.vertical, FlareSizes.spacingSm).frame(minHeight: FlareSizes.touchTarget)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(busyActionId != nil)
    }
    private func detailLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            Text(label).foregroundColor(colors.textSecondary)
            Spacer(minLength: FlareSizes.spacingMd)
            Text(value).foregroundColor(colors.textPrimary).multilineTextAlignment(.trailing).textSelection(.enabled)
        }.font(.system(size: FlareSizes.fontSizeMd * scale)).padding(.vertical, FlareSizes.spacingSm)
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
                Text(hidden && view.presentation?.props["maskRowAmounts"]?.boolValue == true ? "••••" : entry.amount).font(.system(size: FlareSizes.fontSize5xl * scale, weight: .semibold))
                    .foregroundColor(entry.amount.hasPrefix("+") ? colors.successText : colors.textPrimary)
                    .frame(maxWidth: .infinity).padding(.vertical, FlareSizes.spacingMd)
                if let badge = entry.row.badge {
                    HStack { Text(view.presentation?.props["rowBadgeLabel"]?.stringValue ?? strings.accountType).foregroundColor(colors.textSecondary); Spacer(); PluginBadgeView(badge: badge) }
                }
                ForEach(Array(entry.row.cells.enumerated().dropFirst()), id: \.offset) { index, cell in
                    let column = entry.block.columns.indices.contains(index) ? entry.block.columns[index] : nil
                    detailLine(column?.label ?? "", column?.format == .time && cell.timeMs != nil
                               ? PluginViewFormat.dateTime(cell.timeMs!, nowMs: PluginViewClock.system.now(), strings, utcOffsetMinutes: nil) : cell.text)
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
