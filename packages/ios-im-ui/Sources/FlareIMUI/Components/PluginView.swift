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
///   settles them. A multiple choice with `maxSelections` holds back every other option once the draft is full (the
///   ticked ones still untick), submits only a draft within the limit and leads its footer with "最多选 n 项".
/// - Badges: an entry or a row with a `badge` draws it as a kit tag in its tone (entries: after the name and the me
///   tag, before the text; rows: before the first cell).
/// - Rows (a plugin page's list): one item per key — the badge and the first cell, the other cells joined with
///   " · ", and the row's action keys, which run like the footer keys and carry the row (`onAction(id, {row})`).
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
/// - Upgrade required (``PluginUnavailableReason/upgradeRequired``): the title and ``FlarePluginUpgradeNotice`` (card)
///   instead of the reason line — "更新应用后查看" and "去更新" when `upgradeStatus` says a build is offered and the host
///   passes `onUpdate`, else only the copy.
/// - Vocabulary 2 blocks (``PluginBlocksExtra``): a section's blocks under its collapsible label; stats; a chart; an
///   image the host resolves (`resolveImage`, never a URL in the view); a QR code whose refresh key hands the host the
///   query (`onQrRefresh`); a hero and a banner whose keys run like the footer keys; steps; a timeline. Fields, stats,
///   heroes and cells with a `count` or `duration` format draw compact counts and durations in the viewer's words.
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

/// Visual arrangement only. Every arrangement uses the same guarded action/form runner. `page` is the plugin page's
/// archetype layout (R2 of docs/plugin-experience.md, ``PluginExperienceRules/places(_:embedded:inlineFormActionId:)``):
/// overview quick keys and list cards, a task's bar, a records page's header key and command row, the danger card.
public enum PluginViewActionLayout: Sendable { case inline, compact, list, page }

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
    private let actionLayout: PluginViewActionLayout
    private let showError: Bool
    private let labelRows: Bool
    private let inlineFormActionId: String?
    private let inlineFormTitle: String?
    private let inlineFormDescription: String?
    private let resolveUser: (@Sendable (String) async -> PluginUser?)?
    let members: [PluginMember]
    private let membersLoading: Bool
    private let membersRevision: Int
    private let membersError: String?
    private let onMemberSearch: ((String) -> Void)?
    private let onMembersRetry: (() -> Void)?
    let formErrors: [PluginFormError]
    let settleToken: Int
    private let fileStates: [String: PluginFileState]
    private let onFileAction: ((PluginFileAction) -> Void)?
    private let onAction: ((String, PluginActionPayload) -> Void)?
    private let onOpenDetail: (() -> Void)?
    private let upgradeStatus: PluginUpgradeStatus?
    private let upgradeBusy: Bool
    private let onUpdate: (() -> Void)?
    private let resolveImage: (@Sendable (PluginImageSource) async -> URL?)?
    private let onQrRefresh: ((PluginQrRefresh) -> Void)?
    private var locationStates: [String: PluginLocationState] = [:]
    private var onLocationAction: ((PluginLocationAction) -> Void)?
    private var protectedMedia: [String: PluginProtectedMediaState] = [:]
    private var onProtectedMediaRead: ((PluginProtectedMediaRead) -> Void)?
    /// R8: offline keeps the view and disables every action.
    private var offline = false
    /// R7: the result block's done key.
    private var onDone: (() -> Void)?
    private let clock: PluginViewClock
    @State private var references = false
    /// A host drawing the task bar's keys itself (the account view's setup key) takes them on a pointer too.
    @Environment(\.flarePluginHoistsBar) var hoistsBar
    @State private var interaction = PluginChoicesInteraction()
    @State private var users: [String: PluginUser]
    @State private var confirming: PluginActionRun?
    @State private var formRun: PluginActionRun?
    /// A page action's native target handed to the form holding its `into` input.
    @State private var nativeRequest: PluginNativeIntoRequest?
    @State private var formSubmitted = false
    @State private var inlineForm = PluginInlineFormState()
    /// The row whose key last went out: `busyActionId` spins that row's key, not every row's.
    @State private var activeRow: String?
    /// The host's signals as last seen, so a change is compared whole.
    @State private var host: PluginHostSignal
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    /// R3: the plugin and page a development warning names (set by ``FlarePluginPage``).
    @Environment(\.flarePluginScope) private var scope

    /// - Parameters:
    ///   - displayName: The card envelope's `displayName` (the plugin's name): it leads the unavailable reason line.
    ///   - viewerId: The viewer's user id: entries of that user carry the "我" tag.
    ///   - showError: Hide only the outer banner; the original error still settles and validates an active form.
    ///   - inlineFormTitle: Optional heading immediately before an eligible inline form; also bounds it to the primary pane width.
    ///   - inlineFormDescription: Optional supporting text under that heading. Blank metadata keeps the existing form layout.
    ///   - upgradeStatus: `update.plugin_upgrade_status` for `view.minBuild`, on an upgrade-required view.
    ///   - onUpdate: Opens the update flow (``FlarePluginUpgradeNotice``).
    ///   - resolveImage: The address of an image block's picture (a package asset or a private upload); nil: none.
    ///   - onQrRefresh: A QR block's refresh key: the host runs the query and passes back a view with the fresh code.
    ///   - locationStates: Location inputs: the host's fix, a running locate or a failure, by input id.
    ///   - onLocationAction: A location input's locate or clear key: the host runs the page's locationOnce action into
    ///     the input and passes its fix back in `locationStates`; on clear it drops that input's state.
    ///   - protectedMedia: What the host has for each protected media item, by item id: the read's address (the
    ///     server's https grant address), a running read or a failure.
    ///   - onProtectedMediaRead: A protected media read (with its reason when the block asks one): the host runs and
    ///     audits it, then fills `protectedMedia` with ``FlarePluginProtectedMedia/url(result:urlPath:)``.
    public init(view: PluginViewModel, icon: String? = nil, displayName: String? = nil, viewerId: String? = nil,
                busy: Bool = false, busyActionId: String? = nil,
                error: String? = nil, embedded: Bool = false, inset: PluginViewInset = .none,
                actionLayout: PluginViewActionLayout = .inline,
                showError: Bool = true,
                labelRows: Bool = false,
                inlineFormActionId: String? = nil,
                inlineFormTitle: String? = nil,
                inlineFormDescription: String? = nil,
                resolveUser: (@Sendable (String) async -> PluginUser?)? = nil, members: [PluginMember] = [], membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
                onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil,
                formErrors: [PluginFormError] = [], settleToken: Int = 0,
                fileStates: [String: PluginFileState] = [:], onFileAction: ((PluginFileAction) -> Void)? = nil,
                onAction: ((String, PluginActionPayload) -> Void)? = nil, onOpenDetail: (() -> Void)? = nil,
                upgradeStatus: PluginUpgradeStatus? = nil, upgradeBusy: Bool = false, onUpdate: (() -> Void)? = nil,
                resolveImage: (@Sendable (PluginImageSource) async -> URL?)? = nil,
                onQrRefresh: ((PluginQrRefresh) -> Void)? = nil,
                locationStates: [String: PluginLocationState] = [:],
                onLocationAction: ((PluginLocationAction) -> Void)? = nil,
                protectedMedia: [String: PluginProtectedMediaState] = [:],
                onProtectedMediaRead: ((PluginProtectedMediaRead) -> Void)? = nil,
                offline: Bool = false, onDone: (() -> Void)? = nil) {
        self.init(view: view, icon: icon, displayName: displayName, viewerId: viewerId, busy: busy,
                  busyActionId: busyActionId, error: error, embedded: embedded,
                  inset: inset, actionLayout: actionLayout, showError: showError, labelRows: labelRows, inlineFormActionId: inlineFormActionId, inlineFormTitle: inlineFormTitle, inlineFormDescription: inlineFormDescription, resolveUser: resolveUser, members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry,  formErrors: formErrors,
                  settleToken: settleToken, fileStates: fileStates, onFileAction: onFileAction, onAction: onAction, onOpenDetail: onOpenDetail, clock: .system, users: [:],
                  upgradeStatus: upgradeStatus, upgradeBusy: upgradeBusy, onUpdate: onUpdate, resolveImage: resolveImage,
                  onQrRefresh: onQrRefresh)
        self.locationStates = locationStates; self.onLocationAction = onLocationAction
        self.protectedMedia = protectedMedia; self.onProtectedMediaRead = onProtectedMediaRead
        self.offline = offline; self.onDone = onDone
    }

    /// This view as a page's body (how ``FlarePluginPage`` passes its own on): offline and the result's done key.
    func pageState(offline: Bool, onDone: (() -> Void)?) -> PluginView {
        var copy = self
        copy.offline = offline; copy.onDone = onDone
        return copy
    }

    /// This view with the host's capability state: location inputs and protected media (how ``FlarePluginPage``
    /// passes its own on).
    func hostCapabilities(locationStates: [String: PluginLocationState],
                          onLocationAction: ((PluginLocationAction) -> Void)?,
                          protectedMedia: [String: PluginProtectedMediaState],
                          onProtectedMediaRead: ((PluginProtectedMediaRead) -> Void)?) -> PluginView {
        var copy = self
        copy.locationStates = locationStates; copy.onLocationAction = onLocationAction
        copy.protectedMedia = protectedMedia; copy.onProtectedMediaRead = onProtectedMediaRead
        return copy
    }

    /// The card at a fixed clock and with users already resolved — how the tests pin `now`, the zone and names.
    init(view: PluginViewModel, icon: String?, displayName: String? = nil, viewerId: String? = nil, busy: Bool,
         busyActionId: String?, error: String?, embedded: Bool,
         inset: PluginViewInset = .none, actionLayout: PluginViewActionLayout = .inline,
         showError: Bool = true,
         labelRows: Bool = false,
         inlineFormActionId: String? = nil,
         inlineFormTitle: String? = nil,
         inlineFormDescription: String? = nil,
         resolveUser: (@Sendable (String) async -> PluginUser?)?,
         members: [PluginMember], membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
                onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil, formErrors: [PluginFormError], settleToken: Int = 0,
         fileStates: [String: PluginFileState] = [:], onFileAction: ((PluginFileAction) -> Void)? = nil,
         onAction: ((String, PluginActionPayload) -> Void)?, onOpenDetail: (() -> Void)?, clock: PluginViewClock,
         users: [String: PluginUser], upgradeStatus: PluginUpgradeStatus? = nil, upgradeBusy: Bool = false,
         onUpdate: (() -> Void)? = nil, resolveImage: (@Sendable (PluginImageSource) async -> URL?)? = nil,
         onQrRefresh: ((PluginQrRefresh) -> Void)? = nil) {
        self.upgradeStatus = upgradeStatus; self.upgradeBusy = upgradeBusy; self.onUpdate = onUpdate
        self.resolveImage = resolveImage; self.onQrRefresh = onQrRefresh
        self.view = view; self.icon = icon; self.displayName = displayName; self.viewerId = viewerId
        self.busy = busy; self.busyActionId = busyActionId; self.error = error
        self.embedded = embedded; self.inset = inset; self.resolveUser = resolveUser; self.members = members
        self.membersLoading = membersLoading; self.membersRevision = membersRevision; self.membersError = membersError
        self.onMemberSearch = onMemberSearch; self.onMembersRetry = onMembersRetry
        self.actionLayout = actionLayout
        self.showError = showError
        self.labelRows = labelRows
        self.inlineFormActionId = inlineFormActionId
        self.inlineFormTitle = inlineFormTitle
        self.inlineFormDescription = inlineFormDescription
        self.formErrors = formErrors; self.settleToken = settleToken
        self.fileStates = fileStates; self.onFileAction = onFileAction
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
    private var locked: Bool { busy || busyActionId != nil || view.readOnly || inlineForm.pending || offline }

    /// An action whose form can show in place: every input it draws (block-bound ones left out, R6.1) is known and
    /// none is a password.
    static func inlineAction(_ view: PluginViewModel, id: String?, hasAction: Bool) -> PluginViewAction? {
        guard view.available, !view.readOnly, hasAction, let id,
              let action = view.actions.first(where: { $0.id == id }), action.confirm?.isEmpty != false,
              let form = action.form, !form.isEmpty else { return nil }
        let bound = PluginExperienceRules.boundInputs(view)
        let drawn = form.filter { !bound.contains($0) }
        let inputs = PluginExperienceRules.drawnInputs(view, action)
        return !drawn.isEmpty && inputs.count == drawn.count && !inputs.contains(where: { $0.kind == .password })
            ? action : nil
    }
    private var inlineAction: PluginViewAction? { Self.inlineAction(view, id: inlineFormActionId, hasAction: onAction != nil) }

    static func inlineHeading(_ value: String?) -> String? {
        value.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// The keys of the action row: the footer actions, and on an embedded view (no title row) the menu actions.
    static func actionRow(_ view: PluginViewModel, embedded: Bool) -> [PluginViewAction] {
        guard !view.readOnly else { return [] }
        return view.actions + (embedded ? view.menuActions : [])
    }

    /// The ⋯ key is on the title row: a card (not embedded) with menu actions, or more than three footer actions
    /// (R2.4: the fourth on go to the menu after the menu actions).
    static func showsMenuKey(_ view: PluginViewModel, embedded: Bool) -> Bool {
        !embedded && view.available && !view.readOnly
            && !PluginExperienceRules.places(view, embedded: false, inlineFormActionId: nil).menu.isEmpty
    }

    /// Where this view's actions draw (R2); a status card's key leaves its other places.
    private var places: PluginActionPlaces {
        let places = PluginExperienceRules.places(view, embedded: embedded, inlineFormActionId: inlineAction?.id)
        var drawn = statusCardKey.map { key in places.removing(key.id) } ?? places
        // The page's own form submits through its own key (pinned on touch), never a second launcher.
        if pageLayout, let inline = inlineAction { drawn = drawn.removing(inline.id) }
        return drawn
    }

    private var pageLayout: Bool { embedded && actionLayout == .page && view.available && !view.readOnly }

    /// The status card's primary key (6.1), on a page that draws one.
    private var statusCardKey: PluginViewAction? {
        guard embedded, actionLayout == .page, PluginExperienceRules.statusCard(view) else { return nil }
        return PluginExperienceRules.topLevelActions(view, embedded: true)
            .first { PluginExperienceRules.role($0) == .primary }
    }

    private var formPending: Bool {
        guard let formRun else { return false }
        return busy || busyActionId == formRun.action.id
    }

    private var failure: String? { error.flatMap { $0.isEmpty ? nil : $0 } }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let reason = PluginViewFormat.reasonLine(view, displayName: displayName, strings)
        let places = self.places
        // A card's footer holds its first three actions (R2.4); a page draws its places; the account view keeps its
        // own arrangement.
        // An unbound copy draws no keys at all.
        let keys = view.readOnly ? [] : !embedded ? places.footer
            : pageLayout ? [] : Self.actionRow(view, embedded: embedded).filter { $0.id != inlineAction?.id }
        let special = flareHasResolvedPresentation(view)
        let formTitle = Self.inlineHeading(inlineFormTitle)
        let formDescription = Self.inlineHeading(inlineFormDescription)
        // R1: a page's blocks are 16 apart (a card keeps its tighter rhythm).
        let content = VStack(alignment: .leading, spacing: embedded ? FlareSizes.spacingLg : FlareSizes.spacingMd) {
            if !embedded && !special {
                header(colors)
            } else if !view.available, !view.title.isEmpty {
                // No title row: an unavailable view still says what it was.
                Text(view.title)
                    .font(.system(size: FlareSizes.fontSizeMd * textScale))
                    .foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if view.upgradeRequired {
                FlarePluginUpgradeNotice(variant: .card, status: upgradeStatus, busy: upgradeBusy, onUpdate: onUpdate)
            } else if !view.available, let reason {
                Text(reason)
                    .font(.system(size: FlareSizes.fontSizeMd * textScale))
                    .foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if special {
                ResolvedPresentationView(view: view, busy: locked,
                    onRequest: { id in if let action = view.actions.first(where: { $0.id == id }) { run(action, PluginActionPayload()) } })
                if view.readOnly, let reason { Text(reason).foregroundColor(colors.textTertiary) }
            } else if view.available, pageLayout, let result = PluginExperienceRules.resultBlock(view) {
                resultView(result)
            } else if view.available {
                let card = pageLayout && PluginExperienceRules.statusCard(view)
                if card { statusCardView(colors) }
                let fields = card ? Self.statusCardRest(view).fields : view.fields
                if !fields.isEmpty { PluginFieldRows(fields: fields) }
                let skipped = (card ? Self.statusCardRest(view).skipped : [])
                let quickAt = pageLayout ? Self.quickIndex(view) : nil
                ForEach(Array(view.blocks.enumerated()), id: \.offset) { index, block in
                    if index == quickAt {
                        // R2.1: the overview card — the hero or stats with the quick keys at its foot.
                        VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
                            blockView(block, at: index)
                            if !places.quick.isEmpty { quickRow(places.quick, colors) }
                        }
                        .padding(FlareSizes.spacingLg)
                        .flarePluginCard(colors)
                    } else if !skipped.contains(index) {
                        blockView(block, at: index)
                    }
                }
                if let action = inlineAction {
                    VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                        if let title = formTitle {
                            Text(title).font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .semibold))
                                .foregroundColor(colors.textPrimary).fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                        }
                        if let description = formDescription {
                            Text(description).font(.system(size: FlareSizes.fontSizeMd * textScale))
                                .foregroundColor(colors.textSecondary).fixedSize(horizontal: false, vertical: true)
                        }
                    // R2.5: the key spins only while this form's own action runs; offline, another action or a
                    // read-only view only disable it.
                    let running = busy || busyActionId == action.id || inlineForm.pending
                    PluginFormView(inputs: PluginExperienceRules.drawnInputs(view, action), errors: inlineForm.submitted ? formErrors : [],
                                   submitLabel: action.label, busy: running, disabled: locked && !running, error: failure, members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry,  embedded: true,
                                   fileStates: fileStates, onFileAction: onFileAction,
                                   locationStates: locationStates, onLocationAction: onLocationAction,
                                   nativeRequest: nativeRequest,
                                   pinSubmit: pageLayout && !FlarePluginPage.refreshKeyInHeader, onSubmit: { values in
                        guard !locked, Self.inlineAction(view, id: action.id, hasAction: onAction != nil) != nil,
                              inlineForm.begin(action.id) else { return }
                        emit(PluginActionRun(action: action, payload: .empty, block: nil), formValues: values)
                    }).id("\(action.id)/\(inlineForm.revision)")
                    // R6: the form column is at most 560, at the leading side.
                    }.frame(maxWidth: FlareSizes.componentFormColumnWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if pageLayout {
                    pagePlaces(places, colors)
                } else if !keys.isEmpty {
                    VStack(spacing: FlareSizes.spacing2xs) {
                        if !embedded { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
                        if actionLayout == .list {
                            VStack(spacing: 0) {
                                ForEach(Array(keys.enumerated()), id: \.element.id) { index, action in
                                    if index > 0 { Divider() }
                                    listAction(action, colors)
                                }
                                if let onOpenDetail, PluginViewFormat.showsDetailKey(view, embedded: embedded) { detailKey(onOpenDetail) }
                            }
                        } else {
                        FlareFlowLayout(spacing: actionLayout == .compact ? FlareSizes.spacingSm : FlareSizes.spacingMd, lineSpacing: FlareSizes.spacingSm,
                                        trailingLast: onOpenDetail != nil && PluginViewFormat.showsDetailKey(view, embedded: embedded),
                                        constrainSubviews: true) {
                            actionKeys(keys)
                            if let onOpenDetail, PluginViewFormat.showsDetailKey(view, embedded: embedded) {
                                detailKey(onOpenDetail)
                            }
                        }
                        }
                    }
                }
                // R2.5: why a footer key is off, under the keys.
                ForEach(keys.filter { $0.disabledReason != nil }) { action in
                    PluginCaption(text: action.disabledReason ?? "")
                }
                if view.readOnly, let reason {
                    Text(reason)
                        .font(.system(size: FlareSizes.fontSizeSm * textScale))
                        .foregroundColor(colors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if showError, inlineAction == nil, let failure {
                StatusBannerView(text: failure, tone: .danger)
            }
        }
        // A resolved presentation in the timeline (a red packet card) keeps its own width, so the message row can put an
        // own card at the trailing edge (as Compose, Vue); everything else fills its place.
        .frame(maxWidth: actionLayout == .compact || (special && !embedded) ? nil : .infinity, alignment: .leading)
        Group {
            if embedded || special {
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
                .overlay(shape.stroke(colors.borderSecondary.opacity(0.6), lineWidth: 1).allowsHitTesting(false))
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
        // R6: up to four plain fields in a sheet; a longer form (or files, documents, members) as a page.
        .flareBottomSheet(item: formRunBinding(.sheet), title: formRun?.action.label, dismissible: !formPending) { request in
            actionForm(request, page: false)
        }
        .flareFullScreen(item: formRunBinding(.page), label: formRun?.action.label, dismissible: !formPending) { request in
            PluginPageFormLayer(title: request.action.label, onClose: { if !formPending { formRun = nil; formSubmitted = false } }) {
                actionForm(request, page: true)
            }
        }
        // R8: an open action form shows that action's failure itself; the page keeps no second banner behind it (as Vue).
        .preference(key: PluginFormOpenKey.self, value: formRun != nil)
        // A custom presentation or a result draws its own keys: nothing goes to the page's header or bar.
        .preference(key: PluginPageChromeKey.self,
                    value: !pageLayout || special ? nil
                        : PluginExperienceRules.resultBlock(view) != nil ? resultChrome : pageChrome(places))
        .onChange(of: view) { _ in interaction.viewChanged() }
        .onChange(of: inlineAction?.id) { _ in inlineForm = PluginInlineFormState() }
        // A native request belongs to the form it was handed to: a later form starts without it.
        .onChange(of: formRun == nil) { closed in if closed { nativeRequest = nil } }
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
            // R5 (spec cardHeader): icon, the title taking the rest of the row on one line, then details and ⋯.
            Text(view.title)
                .font(.system(size: FlareSizes.fontSizeSm * textScale, weight: .medium))
                .foregroundColor(colors.textSecondary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let onOpenDetail, places.footer.isEmpty,
               PluginViewFormat.showsDetailKey(view, embedded: embedded) {
                headDetailKey(onOpenDetail, colors)
                    .padding(.leading, FlareSizes.spacingXs)
            }
            if Self.showsMenuKey(view, embedded: embedded) {
                menuKey(colors)
            }
        }
    }

    /// R5: the head's details key — 13 secondary text and a 16 chevron, a 44 target.
    private func headDetailKey(_ open: @escaping () -> Void, _ colors: FlareColors) -> some View {
        Button(action: open) {
            HStack(spacing: FlareSizes.spacing3xs) {
                Text(strings.pluginViewDetail).font(.system(size: FlareSizes.fontSizeMd * textScale))
                FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm, weight: .semibold)
                    .accessibilityHidden(true)
            }
            .foregroundColor(colors.textSecondary)
            .flareTouchTarget()
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .fixedSize()
    }

    /// The menu actions as kit menu items, in order; style danger in the error colour.
    static func menuItems(_ view: PluginViewModel) -> [FlareActionItem] {
        view.menuActions.map { FlareActionItem(id: $0.id, label: $0.label, danger: $0.style == .danger) }
    }

    /// The ⋯ key at the end of the title row (R5: IconButton sm, 30 with a 16 glyph): the kit action menu of the menu
    /// actions.
    private func menuKey(_ colors: FlareColors) -> some View {
        let side = FlareControlSize.sm.square
        let menu = places.menu
        return ActionMenuView(items: menu.map { FlareActionItem(id: $0.id, label: $0.label, danger: $0.style == .danger) },
                              accessibilityLabel: strings.pluginViewMore,
                              onSelect: { id in
                                  guard let action = menu.first(where: { $0.id == id }) else { return }
                                  run(action, .empty)
                              }) {
            FlareIconImage(name: "more", size: FlareControlSize.sm.glyph * textScale, weight: .medium)
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
                capped: Set(choices.options.map(\.index).filter { interaction.capped(choices, at: index, option: $0) }),
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
        case .rows(let rows):
            PluginRowsBlockView(block: rows, clock: clock, busyActionId: busyActionId, activeRow: activeRow,
                                enabled: onAction != nil && !view.readOnly && !locked, labelRows: labelRows,
                                pageRows: embedded && actionLayout == .page, users: users,
                                emptyAction: emptyCreate.map { action in AnyView(placeKey(action, variant: .primary)) }) { key, row in
                run(key.action, PluginActionPayload(row: PluginRowRef(key: row.key, input: key.input)))
            }
        case .section(let section):
            // A child's position keys its choices state apart from the top-level blocks'.
            PluginSectionBlockView(block: section) { child, block in
                AnyView(blockView(block, at: Self.sectionChildIndex(section: index, child: child)))
            }
            // R1: on a page a group starts 24 after what comes before it (16 + 8).
            .padding(.top, embedded && index > 0 ? FlareSizes.spacing2xl - FlareSizes.spacingLg : 0)
        case .stats(let stats): PluginStatsBlockView(block: stats)
        case .chart(let chart): PluginChartBlockView(block: chart)
        case .image(let image): PluginImageBlockView(block: image, resolveImage: resolveImage)
        case .qr(let qr):
            PluginQrBlockView(block: qr, clock: clock, onRefresh: view.readOnly ? nil : onQrRefresh, disabled: locked)
        case .hero(let hero):
            PluginHeroBlockView(block: hero, busyActionId: busyActionId, disabled: locked,
                                onAction: onAction == nil || view.readOnly ? nil : { run($0, .empty) })
        case .steps(let steps): PluginStepsBlockView(block: steps)
        case .banner(let banner):
            PluginBannerBlockView(block: banner, disabled: locked,
                                  onAction: onAction == nil || view.readOnly ? nil : { run($0, .empty) })
        case .timeline(let timeline): PluginTimelineBlockView(block: timeline, clock: clock)
        case .protectedMedia(let media):
            PluginProtectedMediaBlockView(block: media, states: protectedMedia, busy: locked,
                                          onRead: view.readOnly ? nil : onProtectedMediaRead)
        case .result(let result):
            // A card or the account view: the outcome as its tag; a page draws FlareResultView instead.
            PluginStatusBlockView(block: PluginStatusBlock(text: result.title, tone: result.tone, unmapped: result.unmapped))
        }
    }

    /// The position a section's child keys its local state by: apart from every top-level position.
    static func sectionChildIndex(section: Int, child: Int) -> Int { 1000 + section * 10 + child }

    private func detailKey(_ open: @escaping () -> Void) -> some View {
        ButtonView(label: strings.pluginViewDetail, variant: .quiet, size: .sm, disabled: locked,
                   appearance: .text, action: open)
    }

    private func actionKeys(_ actions: [PluginViewAction]) -> some View {
        ForEach(actions) { action in
            ButtonView(label: action.label, variant: PluginViewFormat.variant(action),
                       size: .sm, loading: busyActionId == action.id,
                       disabled: (locked && busyActionId != action.id) || onAction == nil || action.disabledReason != nil,
                       block: actionLayout == .list,
                       // A card's footer keys are buttons (R2.4, R2.6); only the account view keeps text keys.
                       appearance: embedded && actionLayout == .inline ? .text : .standard,
                       maintainTouchTarget: true) { run(action, .empty) }
        }
    }
    /// R2.1: an action as a kit settings row — the primary text whatever its role, its icon in the leading slot, a
    /// chevron only on a destination. A danger row is centred in the error colour without a chevron (§12.3, as the
    /// page's danger card, Vue `is-danger`, Compose `PluginDangerCard`) and always asks first.
    @ViewBuilder
    private func listAction(_ action: PluginViewAction, _ colors: FlareColors) -> some View {
        let spinning = busyActionId == action.id
        let off = !spinning && (locked || onAction == nil || action.disabledReason != nil)
        if action.style == .danger {
            Button { run(action.confirm == nil ? Self.confirming(action) : action, .empty) } label: {
                Text(action.label)
                    .font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .medium))
                    .foregroundColor(colors.errorText)
                    .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget)
                    .overlay(alignment: .trailing) { if spinning { ProgressView().controlSize(.small) } }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(off || spinning)
            .opacity(off ? FlareOpacity.disabled : 1)
        } else {
            FlareSettingsRow(item: FlareSettingsItem(
                key: action.id, label: action.label,
                icon: action.icon.flatMap { flareIconNames.contains($0) ? $0 : nil },
                kind: !spinning && PluginExperienceRules.role(action) == .destination ? .navigation : .action,
                disabled: off),
                onSelect: { _ in run(action, .empty) })
                .overlay(alignment: .trailing) { if spinning { ProgressView().controlSize(.small) } }
        }
    }

    /// Opens a form run in the place R6 gives it: the presenter of the other place sees nothing.
    private func formRunBinding(_ placement: PluginFormPlacement) -> Binding<PluginActionRun?> {
        Binding(get: { formRun.flatMap { Self.formPlacement(view, $0.action) == placement ? $0 : nil } },
                set: { if $0 == nil { formRun = nil } })
    }

    /// An action's form: in a sheet with cancel and submit, or as a page whose submit is pinned on touch.
    private func actionForm(_ request: PluginActionRun, page: Bool) -> some View {
        PluginFormView(inputs: PluginExperienceRules.drawnInputs(view, request.action), errors: formSubmitted ? formErrors : [],
                       submitLabel: request.action.label,
                       busy: formPending, error: formSubmitted ? failure : nil, members: members, membersLoading: membersLoading, membersRevision: membersRevision, membersError: membersError, onMemberSearch: onMemberSearch, onMembersRetry: onMembersRetry,
                       embedded: page,
                       fileStates: fileStates, onFileAction: onFileAction,
                       locationStates: locationStates, onLocationAction: onLocationAction,
                       nativeRequest: nativeRequest, pinSubmit: page && !FlarePluginPage.refreshKeyInHeader,
                       onSubmit: { values in formSubmitted = true; emit(request, formValues: values) },
                       onCancel: { if !formPending { formRun = nil; formSubmitted = false } })
            .pageForm()
    }

    // MARK: Behaviour

    /// The host reported: settle the optimistic choice, and close or keep a submitted form.
    private func hostChanged(to next: PluginHostSignal) {
        let old = host
        host = next
        interaction.hostChanged(from: old, to: next)
        if let action = inlineAction { inlineForm.settle(from: old, to: next, actionId: action.id) }
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
        // R2.5: a disabled action runs nothing — no confirm, no form.
        guard !locked, onAction != nil, action.disabledReason == nil else { return }
        // A native target writing `into` an input of a form on this view runs through that input's own key, so
        // the host's answer is written into the form's current scope (no earlier touch of the input needed).
        if payload.row == nil, let target = action.target {
            if takesNativeInto(target) {
                nativeRequest = PluginNativeIntoRequest(target: target)
                return
            }
            // The input belongs to another action's form that is not open (a page's capture keys beside its
            // submit): open that form and run the target through the input's key there.
            if formRun == nil, let holder = nativeIntoHolder(target, excluding: action.id) {
                nativeRequest = PluginNativeIntoRequest(target: target)
                let request = PluginActionRun(action: holder, payload: .empty, block: block)
                if case .confirm = PluginActionFlow.start(holder) { confirming = request } else { proceed(request) }
                return
            }
        }
        let request = PluginActionRun(action: action, payload: payload, block: block)
        if case .confirm = PluginActionFlow.start(action) { confirming = request } else { proceed(request) }
    }

    /// Whether a form on this view (the inline form, or the open form sheet) holds the input `target` writes
    /// into, with the host listening for that input's key.
    private func takesNativeInto(_ target: PluginActionTarget) -> Bool {
        var forms: [PluginViewAction] = []
        if let inline = inlineAction { forms.append(inline) }
        if let open = formRun?.action { forms.append(open) }
        return forms.contains { form in
            view.formInputs(for: form).contains { input in
                switch PluginFormRules.nativeIntoKey(target, input) {
                case "file": return onFileAction != nil
                case "location": return onLocationAction != nil
                default: return false
                }
            }
        }
    }

    /// Another action of this view whose form holds the input `target` writes into.
    private func nativeIntoHolder(_ target: PluginActionTarget, excluding id: String) -> PluginViewAction? {
        view.actions.first { other in
            other.id != id && view.formInputs(for: other).contains { input in
                switch PluginFormRules.nativeIntoKey(target, input) {
                case "file": return onFileAction != nil
                case "location": return onLocationAction != nil
                default: return false
                }
            }
        }
    }

    private func proceed(_ request: PluginActionRun) {
        if case .form = PluginActionFlow.confirmed(request.action) {
            formSubmitted = false
            formRun = request
            return
        }
        emit(request, formValues: nil)
    }

    private func emit(_ request: PluginActionRun, formValues: [String: PluginJSONValue]?) {
        let payload = PluginActionFlow.payload(request.payload, formValues: formValues)
        if let block = request.block, let selection = payload.selection {
            interaction.submitted(block: block, actionId: request.action.id, selection: selection)
        }
        activeRow = payload.row?.key
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

// MARK: - Page places (R2, R5, R7, R8, 6.1)

extension PluginView {
    /// Where an action form opens (R6): a sheet for ≤ 4 drawn fields without files or members, else a page form (a
    /// large sheet here).
    static func formPlacement(_ view: PluginViewModel, _ action: PluginViewAction) -> PluginFormPlacement {
        PluginExperienceRules.formPlacement(PluginExperienceRules.drawnInputs(view, action).map(\.kind), inline: false)
    }

    /// The top-level block the overview card's quick keys follow: the first hero or stats, or a section holding one.
    static func quickIndex(_ view: PluginViewModel) -> Int? {
        view.blocks.firstIndex { block in
            switch block {
            case .hero, .stats: return true
            case .section(let section):
                return section.blocks.contains { if case .hero = $0 { return true }; if case .stats = $0 { return true }; return false }
            default: return false
            }
        }
    }

    /// What a status card (6.1) takes from the view: the status field, the description, the steps; the blocks it
    /// replaces (the steps, the first text or note, banners) and the fields left to draw.
    static func statusCardRest(_ view: PluginViewModel)
        -> (status: PluginViewField?, description: String?, steps: PluginStepsBlock?, fields: [PluginViewField], skipped: Set<Int>) {
        let status = view.fields.first { $0.tone != nil || $0.unmapped } ?? view.fields.first
        var description: String?, steps: PluginStepsBlock?, skipped = Set<Int>()
        for (index, block) in view.blocks.enumerated() {
            switch block {
            case .steps(let s) where steps == nil: steps = s; skipped.insert(index)
            case .text(let t) where description == nil: description = t.text; skipped.insert(index)
            case .note(let n) where description == nil: description = n.text; skipped.insert(index)
            case .banner: skipped.insert(index)
            default: break
            }
        }
        var fields = view.fields
        if let status, let at = fields.firstIndex(of: status) { fields.remove(at: at) }
        return (status, description, steps, fields, skipped)
    }

    /// The create action an empty rows block offers on this page.
    var emptyCreate: PluginViewAction? {
        guard pageLayout else { return nil }
        return PluginExperienceRules.emptyCreateAction(view, places: places)
    }

    /// R7 on touch: the result's done key pinned to the page's bottom bar.
    var resultChrome: PluginPageChrome? {
        guard !FlarePluginPage.refreshKeyInHeader, let onDone else { return nil }
        return PluginPageChrome(header: [], bar: [PluginViewAction(id: "flare.result.done", label: strings.pluginViewDone,
                                                                    style: .primary)],
                                barSecondary: [], busyActionId: nil, locked: busy || busyActionId != nil, offline: false,
                                run: { _ in onDone() })
    }

    /// The page chrome this view hands up: the header key, and on touch the pinned bar (R2.2, R2.3).
    func pageChrome(_ places: PluginActionPlaces) -> PluginPageChrome {
        let empty = emptyCreate?.id
        let touch = !FlarePluginPage.refreshKeyInHeader || hoistsBar
        return PluginPageChrome(header: places.header.filter { $0.id != empty },
                                bar: touch ? places.bar : [], barSecondary: touch ? places.barSecondary : [],
                                busyActionId: busyActionId, locked: locked || onAction == nil, offline: offline,
                                run: { action in run(action, .empty) })
    }

    /// One action key of a page place; the busy action spins, the rest wait (R2.5).
    func placeKey(_ action: PluginViewAction, variant: FlareButtonVariant, size: FlareControlSize = .md,
                  block: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            ButtonView(label: action.label, variant: action.style == .danger ? .danger : variant, size: size,
                       loading: busyActionId == action.id,
                       disabled: (locked && busyActionId != action.id) || onAction == nil || action.disabledReason != nil,
                       block: block) { run(action, .empty) }
                .frame(minWidth: block ? nil : FlareSizes.componentActionMinWidth)
            if let reason = action.disabledReason {
                PluginCaption(text: reason)
            }
        }
    }

    /// R2.1: the overview card's quick keys — phone equal widths 48 high, pointer natural widths 40 high.
    func quickRow(_ actions: [PluginViewAction], _ colors: FlareColors) -> some View {
        let touch = !FlarePluginPage.refreshKeyInHeader
        return VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            HStack(spacing: FlareSizes.spacingSm) {
                ForEach(actions) { action in
                    placeKey(action, variant: PluginExperienceRules.role(action) == .primary ? .primary : .secondary,
                             size: touch ? .lg : .md, block: touch)
                }
                if !touch { Spacer(minLength: 0) }
            }
            if offline { PluginCaption(text: strings.pluginViewAvailableOnline) }
        }
    }

    /// The places after the body: a pointer's task row, the command row, the list cards, more, danger.
    @ViewBuilder func pagePlaces(_ places: PluginActionPlaces, _ colors: FlareColors) -> some View {
        let touch = !FlarePluginPage.refreshKeyInHeader || hoistsBar
        if !touch, !(places.bar + places.barSecondary).isEmpty {
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                HStack(spacing: FlareSizes.spacingSm) {
                    ForEach(places.bar) { placeKey($0, variant: .primary) }
                    ForEach(places.barSecondary) { placeKey($0, variant: .secondary) }
                }
                if offline { PluginCaption(text: strings.pluginViewAvailableOnline) }
            }
            .padding(.top, FlareSizes.spacingMd)
        }
        if !places.commands.isEmpty {
            FlareFlowLayout(spacing: FlareSizes.spacingSm, lineSpacing: FlareSizes.spacingSm) {
                ForEach(places.commands) { placeKey($0, variant: .secondary) }
            }
        }
        ForEach(Array(places.list.enumerated()), id: \.offset) { _, group in
            listCard(group.group == "records" ? strings.pluginViewGroupRecords
                     : group.group == "common" ? strings.pluginViewGroupCommon : nil, group.actions, colors)
        }
        if !places.more.isEmpty { listCard(strings.pluginViewMore, places.more, colors) }
        if !places.danger.isEmpty { listCard(nil, places.danger, colors, danger: true) }
    }

    /// A kit list card of actions: rows in the primary text whatever the role, an action's icon in the leading slot,
    /// a chevron only on a destination; danger rows in the error colour without one (always through DangerConfirm).
    func listCard(_ title: String?, _ actions: [PluginViewAction], _ colors: FlareColors, danger: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if let title {
                Text(title)
                    .font(.system(size: FlareTextRoles.section.fontSize * textScale, weight: .semibold))
                    .foregroundColor(colors.textSecondary)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    if index > 0 { Divider().overlay(colors.borderSecondary) }
                    let spinning = busyActionId == action.id
                    let off = locked || onAction == nil || action.disabledReason != nil
                    VStack(alignment: danger ? .center : .leading, spacing: 0) {
                        if danger {
                            // R2.1: a danger row is centred, in the error colour (§12.3), without a chevron.
                            Button { run(action.confirm == nil ? Self.confirming(action) : action, .empty) } label: {
                                Text(action.label)
                                    .font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .medium))
                                    .foregroundColor(colors.errorText)
                                    .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget)
                                    .overlay(alignment: .trailing) { if spinning { ProgressView().controlSize(.small) } }
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(off)
                            .opacity(off && !spinning ? FlareOpacity.disabled : 1)
                        } else {
                            FlareSettingsRow(item: FlareSettingsItem(
                                key: action.id, label: action.label,
                                icon: action.icon.flatMap { flareIconNames.contains($0) ? $0 : nil },
                                // The running row trades its chevron for a spinner (R2.5).
                                kind: !spinning && PluginExperienceRules.role(action) == .destination ? .navigation : .action,
                                disabled: off, danger: false),
                                onSelect: { _ in run(action, .empty) })
                                .overlay(alignment: .trailing) { if spinning { ProgressView().controlSize(.small) } }
                        }
                        // R2.5: why the row is off, under its label (a danger row's too).
                        if let reason = action.disabledReason {
                            PluginCaption(text: reason)
                                .padding(.leading, danger || action.icon == nil ? 0 : FlareSizes.iconSizeMd + FlareSizes.spacingMd)
                                .padding(.bottom, FlareSizes.spacingSm)
                        }
                    }
                    .padding(.horizontal, FlareSizes.spacingLg)
                    .accessibilityElement(children: .combine)
                }
            }
            .flarePluginCard(colors)
        }
    }

    /// A danger action with no confirm of its own still asks first (R2.1), in its own words.
    static func confirming(_ action: PluginViewAction) -> PluginViewAction {
        PluginViewAction(id: action.id, label: action.label, style: action.style, confirm: action.label,
                         form: action.form, target: action.target, group: action.group, icon: action.icon,
                         disabledReason: action.disabledReason)
    }

    /// R7: the result block as FlareResultView; the view's fields are its details and its actions follow as secondary
    /// keys. The page polls while it is pending (``FlarePluginPage``).
    func resultView(_ result: PluginResultBlock) -> some View {
        let facts = PluginExperienceRules.resultFacts(result, unknownTitle: strings.pluginViewUnknownStatus)
        let actions = PluginExperienceRules.topLevelActions(view, embedded: true)
        return FlareResultView(
            title: facts.title, tone: facts.tone,
            amount: result.amount.map { PluginFormatRules.text($0, result.format, strings) },
            description: result.description, details: view.fields, busy: locked,
            // R7: on touch the done key is pinned to the page's bottom bar (``resultChrome``).
            onDone: FlarePluginPage.refreshKeyInHeader ? onDone : nil,
            actions: actions.isEmpty ? nil : AnyView(VStack(spacing: FlareSizes.spacingSm) {
                ForEach(actions) { placeKey($0, variant: .secondary, size: .lg, block: true) }
            }))
    }

    /// 6.1: the status card — a tone icon 48, the status as the title, a description line, the steps and the key.
    func statusCardView(_ colors: FlareColors) -> some View {
        let parts = Self.statusCardRest(view)
        let draw = parts.status.map {
            PluginExperienceRules.statusDraw(text: $0.value, tone: $0.tone, unmapped: $0.unmapped, context: "\(scope)statusCard:\($0.label)")
        }
        let tone = draw?.tone ?? .neutral
        let title = draw.map { $0.unknown ? strings.pluginViewUnknownStatus : $0.text } ?? view.title
        let icon = PluginExperienceRules.statusCardIcon(tone, unknown: draw?.unknown == true, hasKey: statusCardKey != nil)
        // 6.1: a 24 icon in a 48 tone circle.
        let circle = FlareSizes.iconSizeLg * 2
        return VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            HStack(spacing: FlareSizes.spacingMd) {
                FlareIconImage(name: icon, size: FlareSizes.iconSizeLg, weight: .semibold)
                    .foregroundColor(pluginToneText(tone, colors))
                    .frame(width: circle, height: circle)
                    .background(Circle().fill(pluginToneFill(tone, colors).opacity(FlareOpacity.tintWeak)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                    Text(title).font(.system(size: FlareTextRoles.title.fontSize * textScale, weight: .bold))
                        .foregroundColor(colors.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    if let description = parts.description {
                        Text(description).font(.system(size: FlareSizes.fontSizeLg * textScale))
                            .foregroundColor(colors.textSecondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if let steps = parts.steps { PluginStepsBlockView(block: steps) }
            if let key = statusCardKey {
                placeKey(key, variant: .primary, size: .lg, block: true)
                if offline { PluginCaption(text: strings.pluginViewAvailableOnline) }
            }
        }
        .padding(FlareSizes.spacingLg)
        .flarePluginCard(colors)
    }
}

/// R6: an action's long form as a page of its own — the action's name as the title, a back key that closes it while
/// it is not running, the form in its 560 column, its submit pinned to the bottom on touch.
struct PluginPageFormLayer<Content: View>: View {
    let title: String
    let onClose: () -> Void
    @ViewBuilder let content: Content
    @State private var submit: PluginFormSubmit?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        FlareScreen(title: title, onBack: onClose, surface: .surface) {
            content
                .frame(maxWidth: FlareSizes.componentFormColumnWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FlarePluginPage.pageMargin)
                .padding(.vertical, FlareSizes.spacingMd)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let submit {
                VStack(spacing: FlareSizes.spacingSm) {
                    ButtonView(label: submit.label, size: .lg, loading: submit.busy, disabled: submit.disabled, block: true,
                               action: submit.submit)
                    if let caption = submit.caption { PluginCaption(text: caption) }
                }
                .padding(.horizontal, FlareSizes.spacingLg)
                .padding(.vertical, FlareSizes.spacingMd)
                .background(colors.bgPrimary.ignoresSafeArea(edges: .bottom))
                .overlay(alignment: .top) { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
            }
        }
        .onPreferenceChange(PluginFormSubmitKey.self) { submit = $0 }
    }
}

/// What a plugin page view hands its page: the header key and, on touch, the bottom bar's keys (R2.2, R2.3). The keys
/// run through the view's own runner (confirm, form, settle).
struct PluginPageChrome: Equatable {
    var header: [PluginViewAction]
    var bar: [PluginViewAction]
    var barSecondary: [PluginViewAction]
    var busyActionId: String?
    var locked: Bool
    var offline: Bool
    var run: (PluginViewAction) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.header == rhs.header && lhs.bar == rhs.bar && lhs.barSecondary == rhs.barSecondary
            && lhs.busyActionId == rhs.busyActionId && lhs.locked == rhs.locked && lhs.offline == rhs.offline
    }
}

/// Whether an action form (sheet or page) is open in a plugin view below: the page then leaves its failure to the form.
struct PluginFormOpenKey: PreferenceKey {
    static var defaultValue: Bool { false }
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

struct PluginPageChromeKey: PreferenceKey {
    static var defaultValue: PluginPageChrome? { nil }
    static func reduce(value: inout PluginPageChrome?, nextValue: () -> PluginPageChrome?) {
        if value == nil { value = nextValue() }
    }
}

/// A caption line under a key (R2.5 reasons, R8 offline).
struct PluginCaption: View {
    let text: String
    @ScaledMetric(relativeTo: .caption) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        Text(text).font(.system(size: FlareTextRoles.caption.fontSize * textScale))
            .foregroundColor(FlareColors.of(scheme, brand: flareBrandTheme).textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A field's value (R3): a toned value as the kit Tag, an unmapped one as the unknown status (never the raw text),
/// else the text through its format.
struct PluginFieldValue: View {
    let field: PluginViewField
    var alignment: Alignment = .leading
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flarePluginScope) private var scope

    var body: some View {
        let draw = PluginExperienceRules.statusDraw(text: field.value, tone: field.tone, unmapped: field.unmapped,
                                                    context: "\(scope)field:\(field.label)")
        Group {
            if draw.tag {
                PluginBadgeView(badge: PluginBadge(text: draw.unknown ? strings.pluginViewUnknownStatus : draw.text,
                                                   tone: draw.tone ?? .neutral))
            } else {
                Text(PluginFormatRules.text(field.value, field.format, strings))
                    .foregroundColor(FlareColors.of(scheme, brand: flareBrandTheme).textPrimary)
                    .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
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

/// Label/value rows; a value with a `count` or `duration` format is written in the viewer's words, a toned or
/// unmapped value as its Tag (R3). Reference fields fold into "单号与凭据" after the others, each with a copy key.
struct PluginFieldRows: View {
    let fields: [PluginViewField]
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let split = PluginExperienceRules.splitReferences(fields)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            ForEach(Array(split.main.enumerated()), id: \.offset) { _, field in
                HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingMd) {
                    Text(field.label).foregroundColor(colors.textSecondary)
                        .frame(minWidth: 56, alignment: .leading)
                    PluginFieldValue(field: field)
                }
                .font(.system(size: FlareSizes.fontSizeLg * textScale))
                .accessibilityElement(children: .combine)
            }
            if !split.references.isEmpty { PluginReferenceRows(fields: split.references) }
        }
    }
}

/// R3: the reference fields folded into "单号与凭据" — closed at first, each row with a copy key.
struct PluginReferenceRows: View {
    let fields: [PluginViewField]
    @State private var referencesOpen = false
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            if !fields.isEmpty {
                Button { referencesOpen.toggle() } label: {
                    HStack(spacing: FlareSizes.spacingXs) {
                        Text(strings.pluginViewReferences)
                            .font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .semibold))
                            .foregroundColor(colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        FlareIconImage(name: referencesOpen ? "chevron-up" : "chevron-down", size: FlareSizes.iconSizeSm)
                            .foregroundColor(colors.textTertiary)
                    }
                    .frame(minHeight: FlareSizes.touchTargetMin)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isHeader)
                .accessibilityValue(referencesOpen ? strings.collapse : strings.expand)
                if referencesOpen {
                    ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                        let value = PluginFormatRules.text(field.value, field.format, strings)
                        HStack(alignment: .center, spacing: FlareSizes.spacingMd) {
                            Text(field.label).foregroundColor(colors.textSecondary)
                                .frame(minWidth: 56, alignment: .leading)
                            Text(value).foregroundColor(colors.textPrimary).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            IconButtonView(icon: "copy",
                                           accessibilityLabel: strings.pluginViewCopyReference.replacingOccurrences(of: "{label}", with: field.label),
                                           size: .sm) { flarePluginBundleCopy(value) }
                        }
                        .font(.system(size: FlareSizes.fontSizeMd * textScale))
                    }
                }
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

/// The options of a choices block, their results and the multiple submit key. Options the limit holds back (`capped`)
/// stay listed, dimmed and not tappable.
struct PluginChoicesBlockView: View {
    let block: PluginChoicesBlock
    let shown: [Int]
    var capped: Set<Int> = []
    let interactive: Bool
    let submitEnabled: Bool
    let submitLoading: Bool
    let onPick: (Int) -> Void
    let onSubmit: () -> Void
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.locale) private var locale

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
        let votes = PluginViewFormat.votesText(option, showResults: block.showResults, strings, locale: locale)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusMd, style: .continuous)
        let held = interactive && capped.contains(option.index)
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
        .disabled(!interactive || held)
        .opacity(held ? FlareOpacity.disabled : 1)
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
/// that opens a group, and an entry of the viewer carries the "我" tag. An entry's parts go number, avatar, name, me,
/// badge, text.
struct PluginEntriesBlockView: View {
    let block: PluginEntriesBlock
    let users: [String: PluginUser]
    var viewerId: String?
    let onSeeAll: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.locale) private var locale

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if block.items.isEmpty {
                // R8: the block's empty text as the compact empty state.
                if let empty = block.emptyText, !empty.isEmpty {
                    EmptyStateView(title: empty, icon: "clock", compact: true).frame(maxWidth: .infinity)
                }
            } else {
                // Positions, not indices: a grouped list numbers each group from 1, so an index repeats.
                ForEach(Array(block.items.enumerated()), id: \.offset) { _, entry in
                    if let group = entry.group {
                        Text(PluginViewFormat.groupHeader(group, strings, locale: locale))
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
            if let badge = entry.badge {
                PluginBadgeView(badge: badge)
            }
            Text(entry.text).font(.system(size: FlareSizes.fontSizeLg * textScale))
                .foregroundColor(colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let timeMs = entry.timeMs {
                Text(PluginViewFormat.dateTime(timeMs, nowMs: PluginViewClock.system.now(), strings,
                                               utcOffsetMinutes: nil))
                    .font(.system(size: FlareSizes.fontSizeSm * textScale).monospacedDigit())
                    .foregroundColor(colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// The ground of a badge: a 6% tint of the tone over the primary surface; neutral is the tertiary background.
func pluginBadgeGround(_ tone: PluginTone, _ colors: FlareColors) -> Color {
    switch tone {
    case .neutral: return colors.bgTertiary
    case .info: return colors.info.opacity(0.06)
    case .success: return colors.success.opacity(0.06)
    case .warning: return colors.warning.opacity(0.06)
    case .danger: return colors.error.opacity(0.06)
    }
}

/// An entry's or a row's badge as the kit tag (spec rules.badge): the tone's ink on its faint tint over the primary
/// surface (neutral: secondary text on the tertiary background), caption size, one line, a hairline of the ink. It is
/// words, never a control: it reads as part of its item.
struct PluginBadgeView: View {
    let badge: PluginBadge
    @ScaledMetric(relativeTo: .caption) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flarePluginScope) private var scope

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let draw = PluginExperienceRules.statusDraw(text: badge.text, tone: badge.tone, unmapped: badge.unmapped,
                                                    context: "\(scope)badge")
        let tone = draw.tone ?? .neutral
        let ink = pluginToneText(tone, colors)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusSm, style: .continuous)
        Text(draw.unknown ? strings.pluginViewUnknownStatus : draw.text)
            .font(.system(size: FlareTextRoles.caption.fontSize * textScale, weight: .medium))
            .foregroundColor(ink)
            .lineLimit(1)
            .padding(.horizontal, FlareSizes.spacing2xs)
            .padding(.vertical, FlareSizes.spacing3xs)
            .background(ZStack {
                shape.fill(colors.bgPrimary)
                shape.fill(pluginBadgeGround(tone, colors))
            })
            // Decoration only: the edge must not take a tap meant for the row around it.
            .overlay(shape.stroke(ink.opacity(0.18), lineWidth: 1).allowsHitTesting(false))
    }
}

/// A rows block as a list (spec rules.pageRows): one item per key, the first kept — the badge and the first cell,
/// then the other cells joined with " · " — and the row's keys (the block actions it offers) at the item's end. No
/// rows: the block's empty text, else the kit's. The rows page with their page: no load more of their own.
struct PluginRowsBlockView: View {
    let block: PluginRowsBlock
    let clock: PluginViewClock
    let busyActionId: String?
    /// The row whose key last went out: its key spins while `busyActionId` is that action.
    let activeRow: String?
    let enabled: Bool
    var labelRows = false
    /// On a plugin page (rules.pageRows): only there is a row whose only key opens a page the whole row (rules.rowTap);
    /// a card's rows keep their keys, as on the other kits.
    var pageRows = false
    /// The host's names for the user ids person cells carry (spec rules.rowsIcon: a name, never the id).
    var users: [String: PluginUser] = [:]
    /// R8: the page's create action under the empty state.
    var emptyAction: AnyView? = nil
    let onKey: (PluginRowKey, PluginRow) -> Void
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flarePluginClearFilters) private var clearFilters

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let rows = PluginViewFormat.rowsOnce(block.rows).map { PluginViewFormat.namedRow($0, resolved: users) }
        if rows.isEmpty, let clearFilters {
            // 5.8: nothing under the filter: say so and offer to clear it.
            EmptyStateView(title: strings.pluginViewFilterEmpty, icon: block.icon ?? "clock",
                           actions: AnyView(ButtonView(label: strings.pluginViewClearFilter, variant: .secondary, size: .sm,
                                                       action: clearFilters)),
                           compact: true)
                .frame(maxWidth: .infinity)
        } else if rows.isEmpty {
            let empty = block.emptyText.flatMap { $0.isEmpty ? nil : $0 } ?? strings.pluginViewEmpty
            EmptyStateView(title: empty, icon: block.icon ?? "clock", actions: emptyAction, compact: true)
                .frame(maxWidth: .infinity)
        } else {
            let now = clock.now()
            let days = PluginViewFormat.rowDayHeadings(
                PluginRowsBlock(columns: block.columns, rows: rows, groupByDay: block.groupByDay),
                nowMs: now, strings, utcOffsetMinutes: clock.utcOffsetMinutes)
            // 5.8: a day heading sticks to the page's top edge while its rows scroll under it (as Vue, Compose); the
            // heading's own ground hides the rows passing behind it.
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Self.daySections(days, count: rows.count), id: \.self) { section in
                    Section {
                        ForEach(section, id: \.self) { position in
                            if position > 0 && days[position] == nil { PluginDivider() }
                            line(rows[position], position: position, count: rows.count, now: now, colors)
                        }
                    } header: {
                        if let first = section.first, let day = days[first] {
                            Text(day)
                                .font(.system(size: FlareSizes.fontSizeSm * textScale, weight: .semibold))
                                .foregroundColor(colors.textSecondary)
                                .padding(.top, first == 0 ? 0 : FlareSizes.spacingMd)
                                .padding(.bottom, FlareSizes.spacingXs)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(colors.bgPrimary)
                                .accessibilityAddTraits(.isHeader)
                        }
                    }
                }
            }
        }
    }

    /// The row positions grouped under their day headings: a new group starts at each heading (the first group has
    /// none when the rows are not grouped by day).
    static func daySections(_ days: [String?], count: Int) -> [[Int]] {
        (0..<count).reduce(into: [[Int]]()) { sections, position in
            if sections.isEmpty || days[position] != nil { sections.append([position]) } else { sections[sections.count - 1].append(position) }
        }
    }

    @ViewBuilder
    private func line(_ row: PluginRow, position: Int, count rowCount: Int, now: Int64, _ colors: FlareColors) -> some View {
        tappable(row, colors) {
            if block.icon != nil && !labelRows {
                record(row, line: PluginViewFormat.recordLine(block, row, nowMs: now, strings,
                                                              utcOffsetMinutes: clock.utcOffsetMinutes), colors)
            } else {
                item(row, lines: PluginViewFormat.rowLines(block, row, nowMs: now, strings,
                                                           utcOffsetMinutes: clock.utcOffsetMinutes), colors)
            }
        }
        .padding(.top, position == 0 ? 0 : FlareSizes.spacingSm)
        .padding(.bottom, position == rowCount - 1 ? 0 : FlareSizes.spacingSm)
    }

    private func rowTap(_ row: PluginRow) -> PluginRowKey? {
        Self.rowTap(block, row, pageRows: pageRows, labelRows: labelRows)
    }

    /// rules.rowTap on a page's list only (Vue `rows-layout="list"` without label rows, Compose's page rows).
    static func rowTap(_ block: PluginRowsBlock, _ row: PluginRow, pageRows: Bool, labelRows: Bool) -> PluginRowKey? {
        pageRows && !labelRows ? PluginViewFormat.rowTap(block, row) : nil
    }

    /// R2.3 (rules.rowTap): a row whose only key opens a page is one button that runs it, ending with a 16 chevron;
    /// it is off while the view is busy.
    @ViewBuilder
    private func tappable<Content: View>(_ row: PluginRow, _ colors: FlareColors,
                                         @ViewBuilder _ content: () -> Content) -> some View {
        if let tap = rowTap(row) {
            Button { onKey(tap, row) } label: {
                HStack(spacing: FlareSizes.spacingSm) {
                    content()
                    // The row that ran its action spins in place of the chevron, as its key would.
                    if Self.spins(tap, row: row, busyActionId: busyActionId, activeRow: activeRow) {
                        ProgressView().controlSize(.small)
                    } else {
                        FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm)
                            .foregroundColor(colors.textTertiary)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
        } else {
            content()
        }
    }

    /// A row key spins while its action is busy and it is the row that ran it: several rows share an action id.
    static func spins(_ key: PluginRowKey, row: PluginRow, busyActionId: String?, activeRow: String?) -> Bool {
        busyActionId == key.action.id && activeRow == row.key
    }

    /// §4.7 / 5.8: a record row — the icon in a 36 circle, the title over its line, the value with its Tags at the end;
    /// its keys follow as on any row.
    private func record(_ row: PluginRow, line: PluginRecordLine, _ colors: FlareColors) -> some View {
        let keys = rowTap(row) == nil ? PluginViewFormat.rowKeys(block, row) : []
        let income = line.value.trimmingCharacters(in: .whitespaces).hasPrefix("+")
        return HStack(spacing: FlareSizes.spacingMd) {
            HStack(spacing: FlareSizes.spacingMd) {
                FlareIconImage(name: PluginViewFormat.recordIcon(block.icon, value: line.value), size: FlareSizes.iconSizeMd)
                    .foregroundColor(income ? colors.successText : colors.textSecondary)
                    .frame(width: FlareSizes.componentRecordIconSize, height: FlareSizes.componentRecordIconSize)
                    .background(Circle().fill(income ? colors.success.opacity(FlareOpacity.tintWeak) : colors.bgTertiary))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                    HStack(spacing: FlareSizes.spacingXs) {
                        Text(line.title).font(.system(size: FlareSizes.fontSizeXl * textScale))
                            .foregroundColor(colors.textPrimary).lineLimit(1)
                        if let badge = row.badge { PluginBadgeView(badge: badge) }
                    }
                    if let secondary = line.line {
                        Text(secondary).font(.system(size: FlareSizes.fontSizeSm * textScale))
                            .foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: FlareSizes.spacing3xs) {
                    Text(PluginViewFormat.signedValue(line.value))
                        .font(.system(size: FlareSizes.fontSize2xl * textScale, weight: .semibold).monospacedDigit())
                        .foregroundColor(income ? colors.successText : colors.textPrimary)
                        .lineLimit(1)
                    ForEach(Array(line.tags.enumerated()), id: \.offset) { _, cell in
                        PluginBadgeView(badge: PluginBadge(text: cell.text, tone: cell.tone ?? .neutral, unmapped: cell.unmapped))
                    }
                }
            }
            // The record reads as one item; its keys stay their own controls.
            .accessibilityElement(children: .combine)
            if !keys.isEmpty {
                HStack(spacing: FlareSizes.spacingXs) {
                    ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                        let spinning = Self.spins(key, row: row, busyActionId: busyActionId, activeRow: activeRow)
                        ButtonView(label: key.action.label, variant: PluginViewFormat.variant(key.action), size: .sm,
                                   loading: spinning, disabled: !enabled && !spinning) { onKey(key, row) }
                    }
                }
                .fixedSize()
            }
        }
        .frame(minHeight: FlareSizes.componentRecordRowHeight)
    }

    private func item(_ row: PluginRow, lines: PluginRowLines, _ colors: FlareColors) -> some View {
        let keys = rowTap(row) == nil ? PluginViewFormat.rowKeys(block, row) : []
        return HStack(spacing: FlareSizes.spacingSm) {
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                if labelRows, let label = block.columns.first?.label, !label.isEmpty {
                    Text(label).font(.system(size: FlareSizes.fontSizeSm * textScale)).foregroundColor(colors.textSecondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingXs) {
                    if let badge = row.badge { PluginBadgeView(badge: badge) }
                    Text(lines.primary)
                        .font(.system(size: FlareSizes.fontSizeMd * textScale).monospacedDigit())
                        .foregroundColor(colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    // R3: a cell with a tone (a status column) draws its Tag on the item.
                    ForEach(Array(row.cells.enumerated()).filter { $0.element.tone != nil || $0.element.unmapped }, id: \.offset) { _, cell in
                        PluginBadgeView(badge: PluginBadge(text: cell.text, tone: cell.tone ?? .neutral, unmapped: cell.unmapped))
                    }
                }
                if labelRows {
                    PluginFieldRows(fields: PluginViewFormat.rowFields(block, row, nowMs: clock.now(), strings, utcOffsetMinutes: clock.utcOffsetMinutes))
                } else if let secondary = lines.secondary {
                    Text(secondary)
                        .font(.system(size: FlareSizes.fontSizeSm * textScale))
                        .foregroundColor(colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // The badge and the cells read as one item, in drawing order; the keys stay their own controls.
            .accessibilityElement(children: .combine)
            if !keys.isEmpty {
                HStack(spacing: FlareSizes.spacingXs) {
                    ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                        let spinning = Self.spins(key, row: row, busyActionId: busyActionId, activeRow: activeRow)
                        ButtonView(label: key.action.label, variant: PluginViewFormat.variant(key.action), size: .sm,
                                   loading: spinning, disabled: !enabled && !spinning) { onKey(key, row) }
                    }
                }
                .fixedSize()
            }
        }
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

/// A badge, after its label; a value outside the plugin's values reads the unknown status (R3).
struct PluginStatusBlockView: View {
    let block: PluginStatusBlock
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flarePluginScope) private var scope

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacingSm) {
            if let label = block.label, !label.isEmpty {
                Text(label).font(.system(size: FlareSizes.fontSizeMd * textScale)).foregroundColor(colors.textSecondary)
            }
            // R3: the one Tag look (``PluginBadgeView``), the unknown status for a value outside the declared ones.
            PluginBadgeView(badge: PluginBadge(text: block.text, tone: block.tone, unmapped: block.unmapped))
                .fixedSize()
                .environment(\.flarePluginScope, "\(scope)status:\(block.label ?? ""):")
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
            await flarePluginSleep(ms: delay)
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
        if block.tone == .info {
            // R1: an info note is a caption in the secondary text, no ground.
            Text(block.text)
                .font(.system(size: FlareTextRoles.caption.fontSize * textScale))
                .foregroundColor(colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(block.text)
                .font(.system(size: FlareSizes.fontSizeMd * textScale))
                .foregroundColor(block.tone == nil || block.tone == .neutral ? colors.textSecondary : pluginToneText(block.tone, colors))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm, style: .continuous)
                    .fill(pluginToneGround(block.tone, colors)))
        }
    }
}

private struct FlarePluginHoistsBarKey: EnvironmentKey { static let defaultValue = false }
private struct FlarePluginScopeKey: EnvironmentKey { static let defaultValue = "" }
private struct FlarePluginClearFiltersKey: EnvironmentKey { static let defaultValue: (() -> Void)? = nil }

extension EnvironmentValues {
    /// 5.8: set while a page filter is applied — an empty list says "这个筛选下没有记录" with "清除筛选" running it.
    var flarePluginClearFilters: (() -> Void)? {
        get { self[FlarePluginClearFiltersKey.self] }
        set { self[FlarePluginClearFiltersKey.self] = newValue }
    }

    /// R3: what a development warning about a plugin value names before its path — "pluginId page " on a page.
    var flarePluginScope: String {
        get { self[FlarePluginScopeKey.self] }
        set { self[FlarePluginScopeKey.self] = newValue }
    }

    /// The task bar's keys go up in ``PluginPageChrome`` on every device: the host draws them (see `FlareAccountView`).
    var flarePluginHoistsBar: Bool {
        get { self[FlarePluginHoistsBarKey.self] }
        set { self[FlarePluginHoistsBarKey.self] = newValue }
    }
}
