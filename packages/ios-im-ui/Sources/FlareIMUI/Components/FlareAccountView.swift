import SwiftUI

/// A host-selected visual contract, independent of plugin IDs and money rules.
public enum FlarePluginPageAppearance: Sendable { case document, account }

struct FlareAccountEntry: Identifiable {
    let id: String
    let block: PluginRowsBlock
    let row: PluginRow
    var amount: String { row.cells.first?.text ?? "" }
    var title: String { row.badge?.text ?? (row.cells.count > 1 ? row.cells[1].text : block.columns.first?.label ?? "") }
    var subtitle: String {
        row.cells.enumerated().compactMap { index, cell in
            guard index >= (row.badge == nil ? 2 : 1), index < 3,
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
            return PluginViewFormat.rowsOnce(rows.rows).map { Self(id: "\(index)/\($0.key)", block: rows, row: $0) }
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
    public var settleToken: Int
    public var onAction: ((String, PluginActionPayload) -> Void)?
    @State private var hidden = false
    @State private var information = false
    @State private var selected: FlareAccountEntry?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    @Environment(\.flareStrings) private var strings
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    public init(view: PluginViewModel, busyActionId: String? = nil, error: String? = nil,
                formErrors: [PluginFormError] = [], members: [PluginMember] = [], settleToken: Int = 0,
                onAction: ((String, PluginActionPayload) -> Void)? = nil) {
        self.view = view; self.busyActionId = busyActionId; self.error = error
        self.formErrors = formErrors; self.members = members; self.settleToken = settleToken; self.onAction = onAction
    }
    private var colors: FlareColors { FlareColors.of(scheme, brand: brand) }
    private var entries: [FlareAccountEntry] { FlareAccountEntry.entries(view) }
    private var urgent: [PluginBlock] { view.blocks.filter { if case .note(let n) = $0 { return n.tone == .warning || n.tone == .danger }; return false } }
    private var otherBlocks: [PluginBlock] { view.blocks.filter { if case .rows = $0 { return false }; return !urgent.contains($0) } }
    private func projection(actions: [PluginViewAction] = [], blocks: [PluginBlock] = []) -> PluginViewModel {
        PluginViewModel(available: view.available, title: view.title, actions: actions, blocks: blocks,
                        inputs: view.inputs, unavailableReason: view.unavailableReason)
    }
    private func actions(_ projected: PluginViewModel, entry: FlareAccountEntry? = nil) -> some View {
        PluginView(view: projected, busyActionId: busyActionId, error: error, embedded: true,
                   members: members, formErrors: formErrors, settleToken: settleToken,
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
    public var body: some View {
        Group {
            if !view.available { actions(view) }
            else {
                LazyVStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    if let first = view.fields.first { overview(first) }
                    if !urgent.isEmpty { actions(projection(blocks: urgent)) }
                    actions(projection(actions: view.actions + view.menuActions))
                    if !view.fields.isEmpty || view.presentation?.props["sectionTitle"] != nil { Text(view.presentation?.props["sectionTitle"]?.stringValue ?? strings.accountTransactions).font(.system(size: FlareSizes.fontSize3xl * scale, weight: .semibold))
                        .foregroundColor(colors.textPrimary).accessibilityAddTraits(.isHeader) }
                    if entries.isEmpty {
                        EmptyStateView(title: view.presentation?.props["emptyTitle"]?.stringValue ?? strings.accountEmpty, description: view.presentation?.props["emptyDescription"]?.stringValue ?? strings.accountEmptyDescription, icon: "wallet")
                    }
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if view.presentation?.props["groupByDate"]?.boolValue != false && (index == 0 || dayKey(entry) != dayKey(entries[index - 1])) {
                            Text(dayLabel(entry)).font(.system(size: FlareSizes.fontSizeSm * scale))
                                .foregroundColor(colors.textSecondary).accessibilityAddTraits(.isHeader)
                        }
                        entryRow(entry)
                    }
                    if !otherBlocks.isEmpty {
                        DisclosureGroup(isExpanded: $information) { actions(projection(blocks: otherBlocks)) }
                        label: { Text(strings.accountInformation).foregroundColor(colors.textSecondary) }
                            .font(.system(size: FlareSizes.fontSizeMd * scale))
                    }
                }
            }
        }
        .flareBottomSheet(item: $selected, title: (view.presentation?.props["detailTitle"]?.stringValue ?? view.presentation?.props["sectionTitle"]?.stringValue ?? strings.accountEntryDetails), titleHidden: true,
                          dismissible: busyActionId == nil) { chosen in
            if let entry = entries.first(where: { $0.id == chosen.id }) { detail(entry) }
            else { Text(strings.accountEmpty).padding(FlareSizes.spacingLg) }
        }
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
        Button { selected = entry } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                Image(systemName: flareIconSymbol("wallet")).foregroundColor(colors.textSecondary)
                    .padding(FlareSizes.spacingSm).background(colors.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd))
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    Text(entry.title).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .medium)).foregroundColor(colors.textPrimary)
                    if !entry.subtitle.isEmpty { Text(entry.subtitle).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textSecondary).lineLimit(2) }
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: FlareSizes.spacingXs) {
                    Text(hidden && view.presentation?.props["maskRowAmounts"]?.boolValue == true ? "••••" : entry.amount).font(.system(size: FlareSizes.fontSizeLg * scale, weight: .semibold))
                        .foregroundColor(entry.amount.hasPrefix("+") ? colors.successText : colors.textPrimary)
                    Text(time(entry)).font(.system(size: FlareSizes.fontSizeSm * scale)).foregroundColor(colors.textTertiary)
                }.layoutPriority(1)
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
                Text(hidden && view.presentation?.props["maskRowAmounts"]?.boolValue == true ? "••••" : entry.amount).font(.system(size: FlareSizes.fontSize5xl * scale, weight: .semibold))
                    .foregroundColor(entry.amount.hasPrefix("+") ? colors.successText : colors.textPrimary)
                    .frame(maxWidth: .infinity).padding(.vertical, FlareSizes.spacingMd)
                if let badge = entry.row.badge { detailLine(strings.accountType, badge.text) }
                ForEach(Array(entry.row.cells.enumerated().dropFirst()), id: \.offset) { index, cell in
                    let column = entry.block.columns.indices.contains(index) ? entry.block.columns[index] : nil
                    detailLine(column?.label ?? "", column?.format == .time && cell.timeMs != nil
                               ? PluginViewFormat.dateTime(cell.timeMs!, nowMs: PluginViewClock.system.now(), strings, utcOffsetMinutes: nil) : cell.text)
                }
                detailLine(view.presentation?.props["rowKeyLabel"]?.stringValue ?? strings.accountEntryId, entry.row.key)
                actions(projection(actions: entry.block.actions.filter { action in entry.row.actions.contains { $0.id == action.id } }), entry: entry)
            }.padding(FlareSizes.spacingLg)
        }
    }
}
