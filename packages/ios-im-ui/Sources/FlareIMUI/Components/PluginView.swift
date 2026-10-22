import SwiftUI

/// Plugin card — the core SDK's resolved plugin view drawn as a kit business card. Spec: Message/PluginView
/// (`PluginView`). Render facts follow `spec/plugin-view-vectors.json`.
///
/// No plugin code, path or URL is executed: actions go out as opaque ids with the viewer's selection or form values
/// (`onAction(id, payload)`) and the host invokes them.
/// - Shell: card width ``FlareSizes/componentRichCardWidth`` (within the parent), radius lg, a hairline border and the
///   card shadow; the title row carries `icon` (a kit icon name). `embedded` drops the shell and the title row (the
///   detail sheet); `inset` ``PluginViewInset/sheet`` pads the view like ``PluginFormView`` (spacing md on top, lg at
///   the sides, xl at the bottom), so it goes straight into a kit bottom sheet, and ``PluginViewInset/sheetTop`` does
///   the same without the bottom inset for a view with more of the sheet under it (a preface above the form). The
///   inset pads every state: the embedded body, available or not, and a card shell kept in a sheet (around it).
///   `available` false shows only the title (embedded, which has no title row: as one line of secondary text).
/// - Actions: style danger → the danger key, primary → the primary key, else the secondary key. `confirm` asks in the
///   kit DangerConfirm first; `form` collects ``PluginFormView`` in a kit bottom sheet, whose submit emits
///   `onAction(id, {formValues})`.
/// - Choices: a single choice submits on tap; a multiple choice toggles a draft submitted by a key named after the
///   block's action. The submitted options show at once and revert when `error` turns non-empty; a new `view`
///   settles them.
/// - Settling: the host increments `settleToken` once per finished action, after setting that result's `error` and
///   `formErrors`. A clean result closes the submitted form and keeps an optimistic choice marked until the new
///   view; an error reverts the choice (an open form stays and shows it); form errors keep the form open with them
///   (a choice it carries reverts). `busyActionId` leaving the action settles the same way as a fallback; a host that
///   sets and clears it within one update settles only through the token.
/// - `busy` disables everything; `busyActionId` too, and spins that action's key. `error` shows at the card's foot.
/// - People and entries name users through `resolveUser`; without an answer the avatar draws initials and the name is
///   the id's last 4 characters. "See all" (entries with more) calls `onOpenDetail`; the host opens
///   ``PluginDetailSheetView``. A view with a detail that no entries block offers gets a full-width quiet "view
///   details" key under the action keys (not embedded, and only with `onOpenDetail`), disabled while busy.
/// - Time is formatted in the device zone (`pluginViewDateTimeFormat`); a countdown redraws every second under an hour
///   and every minute otherwise.
/// - Menu actions (`view.menuActions`, the plugin's `placement: "menu"`): the title row ends with a ⋯ key
///   (`pluginViewMore`) that opens the kit ``ActionMenuView`` with one item per action (danger in the error colour);
///   an item runs exactly like a key (confirm, then form, then `onAction(id, {})`); busy disables it. An embedded view
///   has no title row: its menu actions are keys after the footer actions.
/// - Grouped entries: a header row ("火锅 · 3 票 · 38%") before each entry that opens a group; an entry of the viewer
///   (`viewerId`) carries the "我" tag.
/// - Unavailable (`available` false): the title and one reason line, led by the envelope's `displayName`
///   ("投票 · 插件已停用"). A read-only copy (``PluginUnavailableReason/unboundCopy``) draws its content with nothing
///   that acts, and closes with "副本，仅供查看".
/// - The shell is the message's card surface: the timeline draws no bubble around it. A quoting card's quote sits
///   inside the shell, above the title row (``FlareMessageCardQuoteSlot``).
/// Where a ``PluginView`` sits: the padding it gives itself, in every state.
public enum PluginViewInset: String, Sendable, CaseIterable {
    /// None: the host's surface pads it.
    case none
    /// The kit bottom sheet's insets — spacing md on top, lg at the sides, xl at the bottom (``PluginFormView``'s).
    case sheet
    /// The top of a sheet with more under it (a preface above ``PluginFormView``): md on top, lg at the sides and no
    /// bottom inset, so the next part's own top inset is the gap.
    case sheetTop
}

public struct PluginView: View {
    private let view: PluginViewModel
    private let icon: String?
    private let displayName: String?
    private let viewerId: String?
    private let busy: Bool
    let busyActionId: String?
    let error: String?
    private let embedded: Bool
    let inset: PluginViewInset
    private let resolveUser: (@Sendable (String) async -> PluginUser?)?
    let members: [PluginMember]
    let formErrors: [PluginFormError]
    let settleToken: Int
    private let onAction: ((String, PluginActionPayload) -> Void)?
    private let onOpenDetail: (() -> Void)?
    private let clock: PluginViewClock
    @State private var interaction = PluginChoicesInteraction()
    @State private var users: [String: PluginUser]
    @State private var confirming: PluginActionRun?
    @State private var formRun: PluginActionRun?
    @State private var formSubmitted = false
    /// The host's signals as last seen, so a change is compared whole.
    @State private var host: PluginHostSignal
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - displayName: The card envelope's `displayName` (the plugin's name): it leads the unavailable reason line.
    ///   - viewerId: The viewer's user id: entries of that user carry the "我" tag.
    public init(view: PluginViewModel, icon: String? = nil, displayName: String? = nil, viewerId: String? = nil,
                busy: Bool = false, busyActionId: String? = nil,
                error: String? = nil, embedded: Bool = false, inset: PluginViewInset = .none,
                resolveUser: (@Sendable (String) async -> PluginUser?)? = nil, members: [PluginMember] = [],
                formErrors: [PluginFormError] = [], settleToken: Int = 0,
                onAction: ((String, PluginActionPayload) -> Void)? = nil, onOpenDetail: (() -> Void)? = nil) {
        self.init(view: view, icon: icon, displayName: displayName, viewerId: viewerId, busy: busy,
                  busyActionId: busyActionId, error: error, embedded: embedded,
                  inset: inset, resolveUser: resolveUser, members: members, formErrors: formErrors,
                  settleToken: settleToken, onAction: onAction, onOpenDetail: onOpenDetail, clock: .system, users: [:])
    }

    /// The card at a fixed clock and with users already resolved — how the tests pin `now`, the zone and names.
    init(view: PluginViewModel, icon: String?, displayName: String? = nil, viewerId: String? = nil, busy: Bool,
         busyActionId: String?, error: String?, embedded: Bool,
         inset: PluginViewInset = .none, resolveUser: (@Sendable (String) async -> PluginUser?)?,
         members: [PluginMember], formErrors: [PluginFormError], settleToken: Int = 0,
         onAction: ((String, PluginActionPayload) -> Void)?, onOpenDetail: (() -> Void)?, clock: PluginViewClock,
         users: [String: PluginUser]) {
        self.view = view; self.icon = icon; self.displayName = displayName; self.viewerId = viewerId
        self.busy = busy; self.busyActionId = busyActionId; self.error = error
        self.embedded = embedded; self.inset = inset; self.resolveUser = resolveUser; self.members = members
        self.formErrors = formErrors; self.settleToken = settleToken
        self.onAction = onAction; self.onOpenDetail = onOpenDetail; self.clock = clock
        self._users = State(initialValue: users)
        self._host = State(initialValue: PluginHostSignal(busy: busy, busyActionId: busyActionId, error: error,
                                                          formErrors: formErrors, settleToken: settleToken))
    }

    /// The padding of `inset` (spec rules.inset): sheet is the bottom sheet's (``PluginFormView``'s), sheetTop the same
    /// without the bottom one, none nothing. It goes around whatever the view draws, the card shell included.
    static func insetPadding(_ inset: PluginViewInset) -> EdgeInsets {
        switch inset {
        case .none: return EdgeInsets()
        case .sheet:
            return EdgeInsets(top: FlareSizes.spacingMd, leading: FlareSizes.spacingLg, bottom: FlareSizes.spacingXl,
                              trailing: FlareSizes.spacingLg)
        case .sheetTop:
            return EdgeInsets(top: FlareSizes.spacingMd, leading: FlareSizes.spacingLg, bottom: 0,
                              trailing: FlareSizes.spacingLg)
        }
    }

    /// What the host reports now, compared whole on every change.
    private var hostSignal: PluginHostSignal {
        PluginHostSignal(busy: busy, busyActionId: busyActionId, error: error, formErrors: formErrors,
                         settleToken: settleToken)
    }

    /// Every action, choice and submit waits while the card or one of its actions is busy; a read-only copy never acts.
    private var locked: Bool { busy || busyActionId != nil || view.readOnly }

    /// The keys of the action row: the footer actions, and on an embedded view (no title row) the menu actions.
    static func actionRow(_ view: PluginViewModel, embedded: Bool) -> [PluginViewAction] {
        guard !view.readOnly else { return [] }
        return view.actions + (embedded ? view.menuActions : [])
    }

    /// The ⋯ key is on the title row: a card (not embedded) with menu actions.
    static func showsMenuKey(_ view: PluginViewModel, embedded: Bool) -> Bool {
        !embedded && view.available && !view.readOnly && !view.menuActions.isEmpty
    }

    private var formPending: Bool {
        guard let formRun else { return false }
        return busy || busyActionId == formRun.action.id
    }

    private var failure: String? { error.flatMap { $0.isEmpty ? nil : $0 } }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let reason = PluginViewFormat.reasonLine(view, displayName: displayName, strings)
        let keys = Self.actionRow(view, embedded: embedded)
        let content = VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            if !embedded {
                header(colors)
            } else if !view.available, !view.title.isEmpty {
                // No title row: an unavailable view still says what it was.
                Text(view.title)
                    .font(.system(size: FlareSizes.fontSizeMd * textScale))
                    .foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !view.available, let reason {
                Text(reason)
                    .font(.system(size: FlareSizes.fontSizeMd * textScale))
                    .foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if view.available {
                if !view.fields.isEmpty { PluginFieldRows(fields: view.fields) }
                ForEach(Array(view.blocks.enumerated()), id: \.offset) { index, block in
                    blockView(block, at: index)
                }
                if !keys.isEmpty { actionKeys(keys) }
                if let onOpenDetail, PluginViewFormat.showsDetailKey(view, embedded: embedded) {
                    ButtonView(label: strings.pluginViewDetail, variant: .quiet, size: .sm, disabled: locked,
                               block: true, action: onOpenDetail)
                }
                if view.readOnly, let reason {
                    Text(reason)
                        .font(.system(size: FlareSizes.fontSizeSm * textScale))
                        .foregroundColor(colors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let failure {
                StatusBannerView(text: failure, tone: .danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Group {
            if embedded {
                content
            } else {
                let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusLg, style: .continuous)
                VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    // A quoting card's quote, inside the shell above the title row.
                    FlareMessageCardQuoteSlot()
                    content
                }
                .padding(FlareSizes.spacingMd)
                .frame(maxWidth: FlareSizes.componentRichCardWidth, alignment: .leading)
                .background(shape.fill(colors.bgPrimary))
                // Decoration only: the hairline must not take the taps meant for the card's keys.
                .overlay(shape.stroke(colors.borderSecondary, lineWidth: 1).allowsHitTesting(false))
                .flareShadow(FlareShadows.of(scheme).card)
            }
        }
        // Every state takes the inset; a card shell kept in a sheet takes it around the shell.
        .padding(Self.insetPadding(inset))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(view.title)
        .flareBottomSheet(item: $confirming, title: confirming?.action.label, titleHidden: true) { request in
            DangerConfirmView(title: request.action.label, description: request.action.confirm ?? "", target: "",
                              confirmText: request.action.label,
                              onConfirm: { confirming = nil; proceed(request) }, onCancel: { confirming = nil })
        }
        .flareBottomSheet(item: $formRun, title: formRun?.action.label, dismissible: !formPending) { request in
            PluginFormView(inputs: view.formInputs(for: request.action), errors: formSubmitted ? formErrors : [],
                           busy: formPending, error: formSubmitted ? failure : nil, members: members,
                           onSubmit: { values in formSubmitted = true; emit(request, formValues: values) },
                           onCancel: { if !formPending { formRun = nil; formSubmitted = false } })
        }
        .onChange(of: view) { _ in interaction.viewChanged() }
        // Every host signal arrives in one value (`next`), so an error set in the same update as the settle is read.
        .onChange(of: hostSignal) { next in hostChanged(to: next) }
        .task(id: PluginViewFormat.userIds(in: view)) { await resolve(PluginViewFormat.userIds(in: view)) }
    }

    // MARK: Parts

    private func header(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingXs) {
            if let icon, flareIconNames.contains(icon) {
                FlareIconImage(name: icon, size: FlareSizes.iconSizeSm * textScale, weight: .semibold)
                    .foregroundColor(colors.primaryText)
                    .accessibilityHidden(true)
            }
            Text(view.title)
                .font(.system(size: FlareSizes.fontSizeXl * textScale, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if Self.showsMenuKey(view, embedded: embedded) {
                Spacer(minLength: FlareSizes.spacingSm)
                menuKey(colors)
            }
        }
    }

    /// The menu actions as kit menu items, in order; style danger in the error colour.
    static func menuItems(_ view: PluginViewModel) -> [FlareActionItem] {
        view.menuActions.map { FlareActionItem(id: $0.id, label: $0.label, danger: $0.style == .danger) }
    }

    /// The ⋯ key at the end of the title row: the kit action menu of the menu actions.
    private func menuKey(_ colors: FlareColors) -> some View {
        let side = FlareSizes.iconSizeMd * textScale
        return ActionMenuView(items: Self.menuItems(view), accessibilityLabel: strings.pluginViewMore,
                              onSelect: { id in
                                  guard let action = view.menuActions.first(where: { $0.id == id }) else { return }
                                  run(action, .empty)
                              }) {
            FlareIconImage(name: "more", size: side, weight: .semibold)
                .foregroundColor(colors.textSecondary)
                .frame(width: side, height: side)
                .flareTouchTarget()
        }
        .disabled(locked || onAction == nil)
        .opacity(locked || onAction == nil ? FlareOpacity.disabled : 1)
        // The title row keeps the glyph's size; the 44pt around it takes the tap.
        .flareCompactLayout(width: side, height: side)
    }

    @ViewBuilder private func blockView(_ block: PluginBlock, at index: Int) -> some View {
        switch block {
        case .text(let text): PluginTextBlockView(block: text)
        case .fields(let fields): PluginFieldRows(fields: fields.fields)
        case .choices(let choices):
            PluginChoicesBlockView(
                block: choices,
                shown: interaction.shown(choices, at: index),
                interactive: onAction != nil && !view.readOnly && interaction.isInteractive(choices, at: index, locked: locked),
                submitEnabled: interaction.submitEnabled(choices, at: index),
                submitLoading: choices.action.map { $0.id == busyActionId } ?? false,
                onPick: { pick(choices, at: index, option: $0) },
                onSubmit: { submitDraft(choices, at: index) }
            )
        case .entries(let entries):
            PluginEntriesBlockView(block: entries, users: users, viewerId: viewerId,
                                   onSeeAll: view.readOnly ? nil : onOpenDetail)
        case .people(let people): PluginPeopleBlockView(block: people, users: users)
        case .status(let status): PluginStatusBlockView(block: status)
        case .progress(let progress): PluginProgressBlockView(block: progress)
        case .time(let time): PluginTimeBlockView(block: time, clock: clock)
        case .divider: PluginDivider()
        case .note(let note): PluginNoteBlockView(block: note)
        }
    }

    @ViewBuilder private func actionKeys(_ actions: [PluginViewAction]) -> some View {
        let keys = ForEach(actions) { action in
            ButtonView(label: action.label, variant: PluginViewFormat.variant(action),
                       loading: busyActionId == action.id,
                       disabled: (locked && busyActionId != action.id) || onAction == nil, block: true) {
                run(action, .empty)
            }
        }
        if actions.count > 2 {
            VStack(spacing: FlareSizes.spacingSm) { keys }
        } else {
            HStack(spacing: FlareSizes.spacingSm) { keys }
        }
    }

    // MARK: Behaviour

    /// The host reported: settle the optimistic choice, and close or keep a submitted form.
    private func hostChanged(to next: PluginHostSignal) {
        let old = host
        host = next
        interaction.hostChanged(from: old, to: next)
        guard let formRun, formSubmitted else { return }
        if PluginSettleRules.form(from: old, to: next, actionId: formRun.action.id) == .close {
            self.formRun = nil
            formSubmitted = false
        }
    }

    private func pick(_ block: PluginChoicesBlock, at index: Int, option: Int) {
        guard let action = block.action else { return }
        guard let selection = interaction.tap(block, at: index, option: option, locked: locked) else { return }
        run(action, PluginActionPayload(selection: selection), block: index)
    }

    private func submitDraft(_ block: PluginChoicesBlock, at index: Int) {
        guard let action = block.action,
              let selection = interaction.submission(block, at: index, locked: locked) else { return }
        run(action, PluginActionPayload(selection: selection), block: index)
    }

    /// Confirm, then collect the form, then hand the action over.
    private func run(_ action: PluginViewAction, _ payload: PluginActionPayload, block: Int? = nil) {
        guard !locked, onAction != nil else { return }
        let request = PluginActionRun(action: action, payload: payload, block: block)
        if let confirm = action.confirm, !confirm.isEmpty { confirming = request } else { proceed(request) }
    }

    private func proceed(_ request: PluginActionRun) {
        if let form = request.action.form, !form.isEmpty {
            formSubmitted = false
            formRun = request
            return
        }
        emit(request, formValues: nil)
    }

    private func emit(_ request: PluginActionRun, formValues: [String: PluginJSONValue]?) {
        var payload = request.payload
        if let formValues { payload.formValues = formValues }
        if let block = request.block, let selection = payload.selection {
            interaction.submitted(block: block, actionId: request.action.id, selection: selection)
        }
        onAction?(request.action.id, payload)
    }

    private func resolve(_ ids: [String]) async {
        guard let resolveUser else { return }
        let found = await Self.resolved(ids, known: users, resolveUser: resolveUser)
        if !found.isEmpty { users.merge(found) { _, new in new } }
    }

    /// The host's answers for the ids not known yet; an id it cannot answer keeps the fallback.
    static func resolved(_ ids: [String], known: [String: PluginUser],
                         resolveUser: @Sendable (String) async -> PluginUser?) async -> [String: PluginUser] {
        var found: [String: PluginUser] = [:]
        for id in ids where known[id] == nil && found[id] == nil {
            if let user = await resolveUser(id) { found[id] = user }
        }
        return found
    }
}

/// An action on its way out: confirmation and form come first; `block` marks a choices submit.
struct PluginActionRun: Identifiable {
    let id = UUID()
    let action: PluginViewAction
    let payload: PluginActionPayload
    let block: Int?
}

// MARK: - Blocks

/// The semantic colour of a tone as text (`*Text` tokens; neutral is the secondary text).
func pluginToneText(_ tone: PluginTone?, _ colors: FlareColors) -> Color {
    switch tone ?? .neutral {
    case .neutral: return colors.textSecondary
    case .info: return colors.infoText
    case .success: return colors.successText
    case .warning: return colors.warningText
    case .danger: return colors.errorText
    }
}

/// The ground a tone tints (the fill of the pair, faint).
func pluginToneGround(_ tone: PluginTone?, _ colors: FlareColors) -> Color {
    switch tone ?? .neutral {
    case .neutral: return colors.bgTertiary
    case .info: return colors.info.opacity(0.12)
    case .success: return colors.success.opacity(0.12)
    case .warning: return colors.warning.opacity(0.12)
    case .danger: return colors.error.opacity(0.12)
    }
}

/// Label/value rows.
struct PluginFieldRows: View {
    let fields: [PluginViewField]
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingMd) {
                    Text(field.label).foregroundColor(colors.textSecondary)
                        .frame(minWidth: 56, alignment: .leading)
                    Text(field.value).foregroundColor(colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: FlareSizes.fontSizeLg * textScale))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// A paragraph cut at `maxLines`, with expand / collapse once it overflows.
struct PluginTextBlockView: View {
    let block: PluginTextBlock
    @State private var expanded = false
    @State private var overflows = false
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    private var font: Font {
        switch block.style {
        case .title: return .system(size: FlareSizes.fontSize2xl * textScale, weight: .semibold)
        case .body: return .system(size: FlareSizes.fontSizeLg * textScale)
        case .secondary: return .system(size: FlareSizes.fontSizeMd * textScale)
        }
    }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let color = block.style == .secondary ? colors.textSecondary : colors.textPrimary
        VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
            Text(block.text).font(font).foregroundColor(color)
                .lineLimit(expanded ? nil : block.maxLines)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GeometryReader { shown in
                    // The whole text at the same width, never drawn: taller than the cut text means it overflows.
                    Text(block.text).font(font).fixedSize(horizontal: false, vertical: true)
                        .frame(width: shown.size.width, alignment: .leading)
                        .hidden()
                        .background(GeometryReader { full in
                            Color.clear
                                .onAppear { measure(full: full.size.height, shown: shown.size.height) }
                                .onChange(of: full.size.height) { measure(full: $0, shown: shown.size.height) }
                                .onChange(of: shown.size.height) { measure(full: full.size.height, shown: $0) }
                        })
                })
            if block.maxLines != nil, overflows || expanded {
                Button { expanded.toggle() } label: {
                    Text(expanded ? strings.collapse : strings.expand)
                        .font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .medium))
                        .foregroundColor(colors.primaryText)
                        .padding(.vertical, FlareSizes.spacing2xs)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func measure(full: CGFloat, shown: CGFloat) {
        guard !expanded else { return }
        let next = full > shown + 0.5
        if next != overflows { overflows = next }
    }
}

/// The options of a choices block, their results and the multiple submit key.
struct PluginChoicesBlockView: View {
    let block: PluginChoicesBlock
    let shown: [Int]
    let interactive: Bool
    let submitEnabled: Bool
    let submitLoading: Bool
    let onPick: (Int) -> Void
    let onSubmit: () -> Void
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let chosen = Set(shown)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            ForEach(block.options) { option in
                row(option, selected: chosen.contains(option.index), colors)
            }
            if let action = block.action, block.multiple, !block.closed {
                ButtonView(label: action.label, variant: action.style == .danger ? .danger : .primary,
                           loading: submitLoading, disabled: !(interactive && submitEnabled), block: true,
                           action: onSubmit)
            }
            if let footer = PluginViewFormat.choicesFooter(block, strings) {
                Text(footer).font(.system(size: FlareSizes.fontSizeSm * textScale)).foregroundColor(colors.textTertiary)
            }
        }
    }

    private func row(_ option: PluginChoice, selected: Bool, _ colors: FlareColors) -> some View {
        let percent = PluginViewFormat.percentText(option, showResults: block.showResults)
        let votes = PluginViewFormat.votesText(option, showResults: block.showResults, strings)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusMd, style: .continuous)
        return Button { onPick(option.index) } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                if block.multiple && interactive {
                    PluginCheckBox(on: selected)
                }
                Text(option.label)
                    .font(.system(size: FlareSizes.fontSizeLg * textScale, weight: selected ? .medium : .regular))
                    .foregroundColor(colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if selected && !(block.multiple && interactive) {
                    FlareIconImage(name: "check", size: FlareSizes.iconSizeSm * textScale, weight: .semibold)
                        .foregroundColor(colors.primaryText)
                }
                if let percent {
                    Text(percent).font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .semibold).monospacedDigit())
                        .foregroundColor(selected ? colors.primaryText : colors.textSecondary)
                }
                if let votes {
                    Text(votes).font(.system(size: FlareSizes.fontSizeSm * textScale).monospacedDigit())
                        .foregroundColor(colors.textTertiary)
                }
            }
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTargetMin, alignment: .leading)
            .background(alignment: .leading) {
                if block.showResults {
                    GeometryReader { geo in
                        Rectangle().fill(colors.primary.opacity(selected ? 0.16 : 0.08))
                            .frame(width: geo.size.width * CGFloat(min(max(option.percent ?? 0, 0), 100)) / 100)
                    }
                }
            }
            .background(shape.fill(colors.bgSecondary))
            .clipShape(shape)
            .overlay(shape.stroke(selected ? colors.borderSelected : colors.borderPrimary, lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(!interactive)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([option.label, percent, votes].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The square a multiple choice draws while it can still be changed.
struct PluginCheckBox: View {
    let on: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusXs, style: .continuous)
        ZStack {
            shape.fill(on ? colors.primary : colors.bgPrimary)
            shape.stroke(on ? colors.primary : colors.borderHover, lineWidth: 1.5)
            if on {
                FlareIconImage(name: "check", size: 11, weight: .bold).foregroundColor(.white)
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}

/// A numbered list of entries, its empty text and "see all". A grouped list draws a header row before each entry
/// that opens a group, and an entry of the viewer carries the "我" tag.
struct PluginEntriesBlockView: View {
    let block: PluginEntriesBlock
    let users: [String: PluginUser]
    var viewerId: String?
    let onSeeAll: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if block.items.isEmpty {
                if let empty = block.emptyText, !empty.isEmpty {
                    Text(empty).font(.system(size: FlareSizes.fontSizeMd * textScale)).foregroundColor(colors.textTertiary)
                }
            } else {
                // Positions, not indices: a grouped list numbers each group from 1, so an index repeats.
                ForEach(Array(block.items.enumerated()), id: \.offset) { _, entry in
                    if let group = entry.group {
                        Text(PluginViewFormat.groupHeader(group, strings))
                            .font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .semibold))
                            .foregroundColor(colors.textSecondary)
                            .padding(.top, FlareSizes.spacingXs)
                            .accessibilityAddTraits(.isHeader)
                    }
                    row(entry, colors)
                }
            }
            if block.more {
                Button { onSeeAll?() } label: {
                    HStack(spacing: FlareSizes.spacing2xs) {
                        Text(PluginViewFormat.seeAll(block.total, strings))
                            .font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .medium))
                        FlareIconImage(name: "chevron-right", size: FlareSizes.fontSizeSm * textScale, weight: .semibold)
                    }
                    .foregroundColor(colors.primaryText)
                    .frame(minHeight: FlareSizes.touchTargetMin)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(onSeeAll == nil)
            }
        }
    }

    private func row(_ entry: PluginEntry, _ colors: FlareColors) -> some View {
        let name = PluginViewFormat.entryName(entry, resolved: users)
        let me = PluginViewFormat.isMe(entry, viewerId: viewerId)
        return HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingSm) {
            if let number = PluginViewFormat.entryNumber(entry, block: block) {
                Text("\(number).")
                    .font(.system(size: FlareSizes.fontSizeMd * textScale).monospacedDigit())
                    .foregroundColor(colors.textTertiary)
                    .frame(minWidth: 20 * textScale, alignment: .trailing)
            }
            if let userId = entry.userId, !userId.isEmpty {
                AvatarView(userId: userId, displayName: name ?? "", avatarURL: users[userId]?.avatarUrl,
                           size: 20 * textScale)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 4 }
                    .accessibilityHidden(true)
            }
            if let name {
                Text(name).font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .semibold))
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }
            if me {
                Text(strings.pluginViewMe)
                    .font(.system(size: FlareSizes.fontSizeXs * textScale, weight: .semibold))
                    .foregroundColor(colors.primaryText)
                    .padding(.horizontal, FlareSizes.spacingXs)
                    .padding(.vertical, FlareSizes.spacing3xs)
                    .background(Capsule().fill(colors.bgSelected))
            }
            Text(entry.text).font(.system(size: FlareSizes.fontSizeLg * textScale))
                .foregroundColor(colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// One row per group: overlapping avatars, the label and the count in the group's tone.
struct PluginPeopleBlockView: View {
    let block: PluginPeopleBlock
    let users: [String: PluginUser]
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let side = 24 * textScale
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            ForEach(Array(block.groups.enumerated()), id: \.offset) { _, group in
                HStack(spacing: FlareSizes.spacingSm) {
                    if !group.userIds.isEmpty {
                        HStack(spacing: -side / 3) {
                            ForEach(group.userIds, id: \.self) { userId in
                                let user = PluginViewFormat.user(userId, resolved: users)
                                AvatarView(userId: userId, displayName: user.name, avatarURL: user.avatarUrl, size: side)
                                    .overlay(Circle().stroke(colors.bgPrimary, lineWidth: 1.5))
                            }
                        }
                        .accessibilityHidden(true)
                    }
                    Text(group.label).font(.system(size: FlareSizes.fontSizeMd * textScale))
                        .foregroundColor(pluginToneText(group.tone, colors))
                    Text(String(group.count))
                        .font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .semibold).monospacedDigit())
                        .foregroundColor(pluginToneText(group.tone, colors))
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// A badge, after its label.
struct PluginStatusBlockView: View {
    let block: PluginStatusBlock
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacingSm) {
            if let label = block.label, !label.isEmpty {
                Text(label).font(.system(size: FlareSizes.fontSizeMd * textScale)).foregroundColor(colors.textSecondary)
            }
            Text(block.text)
                .font(.system(size: FlareSizes.fontSizeSm * textScale, weight: .semibold))
                .foregroundColor(pluginToneText(block.tone, colors))
                .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacing3xs)
                .background(Capsule().fill(pluginToneGround(block.tone, colors)))
        }
        .accessibilityElement(children: .combine)
    }
}

/// A bar with "value/total".
struct PluginProgressBlockView: View {
    let block: PluginProgressBlock
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let text = PluginViewFormat.progressText(block)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            HStack {
                if let label = block.label, !label.isEmpty {
                    Text(label).font(.system(size: FlareSizes.fontSizeMd * textScale)).foregroundColor(colors.textSecondary)
                }
                Spacer(minLength: FlareSizes.spacingSm)
                Text(text).font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .semibold).monospacedDigit())
                    .foregroundColor(colors.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(colors.bgTertiary)
                    Capsule().fill(colors.primary)
                        .frame(width: geo.size.width * CGFloat(min(max(block.percent, 0), 100)) / 100)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(block.label ?? "")
        .accessibilityValue(text)
    }
}

/// An instant or a range in the device zone, and its countdown.
struct PluginTimeBlockView: View {
    let block: PluginTimeBlock
    let clock: PluginViewClock
    @State private var nowMs: Int64
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    init(block: PluginTimeBlock, clock: PluginViewClock) {
        self.block = block; self.clock = clock
        self._nowMs = State(initialValue: clock.now())
    }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let text = PluginViewFormat.timeText(atMs: block.atMs, endMs: block.endMs, nowMs: nowMs, strings,
                                             utcOffsetMinutes: clock.utcOffsetMinutes)
        let countdown = block.countdown ? PluginViewFormat.countdown(atMs: block.atMs, nowMs: nowMs, strings) : nil
        HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingSm) {
            if let label = block.label, !label.isEmpty {
                Text(label).font(.system(size: FlareSizes.fontSizeMd * textScale)).foregroundColor(colors.textSecondary)
            }
            Text(text).font(.system(size: FlareSizes.fontSizeLg * textScale).monospacedDigit())
                .foregroundColor(colors.textPrimary)
            Spacer(minLength: 0)
            if let countdown {
                Text(countdown.text)
                    .font(.system(size: FlareSizes.fontSizeSm * textScale, weight: .medium).monospacedDigit())
                    .foregroundColor(countdown.refreshMs == nil ? colors.textTertiary : colors.warningText)
            }
        }
        .accessibilityElement(children: .combine)
        .task(id: block) { await tick() }
    }

    /// Redraws the countdown when its text turns over; a fixed test clock never ticks.
    private func tick() async {
        guard block.countdown, clock.nowMs == nil else { return }
        while !Task.isCancelled {
            let now = clock.now()
            if now != nowMs { nowMs = now }
            guard let delay = PluginViewFormat.countdownDelay(atMs: block.atMs, nowMs: now) else { return }
            try? await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000)
        }
    }
}

struct PluginDivider: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        Rectangle().fill(FlareColors.of(scheme, brand: flareBrandTheme).borderSecondary).frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// A tinted note.
struct PluginNoteBlockView: View {
    let block: PluginNoteBlock
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Text(block.text)
            .font(.system(size: FlareSizes.fontSizeMd * textScale))
            .foregroundColor(block.tone == nil || block.tone == .neutral ? colors.textSecondary : pluginToneText(block.tone, colors))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm, style: .continuous)
                .fill(pluginToneGround(block.tone, colors)))
    }
}
