import Foundation

// The plugin page rules of docs/plugin-experience.md §2 (R1–R12) as pure functions, run against
// spec/plugin-view-vectors.json (actionRoles, statusValues, references, blockBoundInputs, cardHeader, refreshKey,
// accountDerivation, formPlacement, formCounter, selectOptions, actionDedupe, result, pageStates, statusCard) and
// spec/plugin-refresh-vectors.json (afterAction, afterReturn, doneTarget). The Vue twin is
// packages/vue-im-ui/src/shared/contracts/plugin-experience.ts.

/// R2: what an action is on a page.
enum PluginActionRole: String, Sendable { case primary, danger, destination, command }

/// R2: the page's archetype; `card` is a message card (not embedded).
enum PluginArchetype: String, Sendable { case card, overview, task, records }

/// One list card of a page's actions: `group` nil is the one untitled card.
struct PluginActionListGroup: Equatable, Sendable {
    let group: String?
    let actions: [PluginViewAction]
}

/// Where each top-level action draws (rules.actionRoles); a place left empty draws nothing.
struct PluginActionPlaces: Equatable, Sendable {
    var archetype: PluginArchetype
    var quick: [PluginViewAction] = []
    var list: [PluginActionListGroup] = []
    var bar: [PluginViewAction] = []
    var barSecondary: [PluginViewAction] = []
    var more: [PluginViewAction] = []
    var header: [PluginViewAction] = []
    var commands: [PluginViewAction] = []
    var danger: [PluginViewAction] = []
    var footer: [PluginViewAction] = []
    var menu: [PluginViewAction] = []
}

extension PluginActionPlaces {
    /// These places without one action (a status card draws its own key).
    func removing(_ id: String) -> PluginActionPlaces {
        var copy = self
        let keep: (PluginViewAction) -> Bool = { $0.id != id }
        copy.quick = quick.filter(keep); copy.bar = bar.filter(keep); copy.barSecondary = barSecondary.filter(keep)
        copy.more = more.filter(keep); copy.header = header.filter(keep); copy.commands = commands.filter(keep)
        copy.danger = danger.filter(keep); copy.footer = footer.filter(keep); copy.menu = menu.filter(keep)
        copy.list = list.map { PluginActionListGroup(group: $0.group, actions: $0.actions.filter(keep)) }
            .filter { !$0.actions.isEmpty }
        return copy
    }
}

/// R3: how a field, a cell, a status block, a badge or a result title draws.
struct PluginStatusDraw: Equatable, Sendable {
    /// A Tag (true) or the text as it is.
    let tag: Bool
    /// The words; empty when `unknown` (the kit draws pluginViewUnknownStatus).
    let text: String
    let tone: PluginTone?
    let unknown: Bool
}

/// R6: where an action's form opens.
enum PluginFormPlacement: String, Sendable { case sheet, page }

/// R6: how a select input draws.
enum PluginSelectControl: String, Sendable { case cards, select }

/// R4: why a page is read again.
public enum PluginRefreshReason: String, Sendable { case pull, key, timer, action, `return` }

/// R8: what a page without a view draws.
enum PluginPageFace: Equatable, Sendable { case blank, skeleton(rows: Int), error, loaded }

enum PluginExperienceRules {
    // MARK: Blocks

    /// Every block, a section's children after it.
    static func flatBlocks(_ blocks: [PluginBlock]) -> [PluginBlock] {
        blocks.flatMap { block -> [PluginBlock] in
            if case .section(let section) = block { return [block] + section.blocks }
            return [block]
        }
    }

    static func hasBlock(_ view: PluginViewModel, _ kinds: Set<String>) -> Bool {
        flatBlocks(view.blocks).contains { kinds.contains($0.kind) }
    }

    /// R6.1: the inputName of every protected-media and choices block (top level or in a section).
    static func boundInputs(_ view: PluginViewModel) -> Set<String> {
        Set(flatBlocks(view.blocks).compactMap { block -> String? in
            switch block {
            case .choices(let choices): return choices.inputName.isEmpty ? nil : choices.inputName
            case .protectedMedia(let media): return media.inputName.isEmpty ? nil : media.inputName
            default: return nil
            }
        })
    }

    /// R6.1: an action whose form lists bound inputs only — the block runs it.
    static func isBlockAction(_ action: PluginViewAction, bound: Set<String>) -> Bool {
        guard let form = action.form, !form.isEmpty else { return false }
        return form.allSatisfy(bound.contains)
    }

    /// The inputs an action's form draws: its form without the bound ones, in order.
    static func drawnInputs(_ view: PluginViewModel, _ action: PluginViewAction) -> [PluginInput] {
        let bound = boundInputs(view)
        return view.formInputs(for: action).filter { !bound.contains($0.id) }
    }

    private static let inlineCompanions: Set<String> =
        ["note", "text", "steps", "banner", "fields", "status", "time", "choices", "protected-media", "section"]

    /// A page that declares exactly one action with drawn inputs and only instructions beside it shows that form in
    /// place (R6, the page's inline form; R6.1: block actions never make it).
    static func pageInlineForm(_ view: PluginViewModel, hasAction: Bool) -> String? {
        guard view.presentation == nil else { return nil }
        let forms = view.actions.filter { !drawnInputs(view, $0).isEmpty }
        guard forms.count == 1, flatBlocks(view.blocks).allSatisfy({ inlineCompanions.contains($0.kind) }) else { return nil }
        return PluginView.inlineAction(view, id: forms[0].id, hasAction: hasAction)?.id
    }

    // MARK: R2 roles, archetypes and places

    static func role(_ action: PluginViewAction) -> PluginActionRole {
        switch action.style {
        case .danger: return .danger
        case .primary: return .primary
        case nil: return action.target?.kind == "page" && (action.form ?? []).isEmpty ? .destination : .command
        }
    }

    /// R9: actions whose label is already drawn are dropped (the first stays); a development build warns once.
    static func dedupe(_ actions: [PluginViewAction]) -> (drawn: [PluginViewAction], dropped: [PluginViewAction]) {
        var seen = Set<String>()
        var drawn: [PluginViewAction] = [], dropped: [PluginViewAction] = []
        for action in actions {
            if seen.insert(action.label).inserted { drawn.append(action) } else { dropped.append(action) }
        }
        for action in dropped {
            pluginWarnOnce("dedupe:\(action.id):\(action.label)",
                           "plugin action \"\(action.id)\" repeats the label \"\(action.label)\"; only the first is drawn")
        }
        return (drawn, dropped)
    }

    /// view.actions (then menuActions when embedded), block actions left out, deduped.
    static func topLevelActions(_ view: PluginViewModel, embedded: Bool) -> [PluginViewAction] {
        let bound = boundInputs(view)
        let all = (view.actions + (embedded ? view.menuActions : [])).filter { !isBlockAction($0, bound: bound) }
        return dedupe(all).drawn
    }

    static func archetype(_ view: PluginViewModel, embedded: Bool, inlineFormActionId: String?,
                          actions: [PluginViewAction]? = nil) -> PluginArchetype {
        guard embedded else { return .card }
        let actions = actions ?? topLevelActions(view, embedded: embedded)
        if hasBlock(view, ["hero", "stats"]), actions.filter({ role($0) == .destination }).count >= 4 { return .overview }
        if inlineFormActionId != nil { return .task }
        if !hasBlock(view, ["rows", "entries", "timeline"]), actions.count <= 3,
           actions.contains(where: { role($0) == .primary }) { return .task }
        return .records
    }

    /// Two titled cards (common, then records) when any item declares a group, else one untitled card.
    static func listGroups(_ actions: [PluginViewAction]) -> [PluginActionListGroup] {
        guard !actions.isEmpty else { return [] }
        guard actions.contains(where: { $0.group != nil }) else { return [PluginActionListGroup(group: nil, actions: actions)] }
        return [PluginActionListGroup(group: "common", actions: actions.filter { $0.group != "records" }),
                PluginActionListGroup(group: "records", actions: actions.filter { $0.group == "records" })]
            .filter { !$0.actions.isEmpty }
    }

    static func places(_ view: PluginViewModel, embedded: Bool, inlineFormActionId: String?) -> PluginActionPlaces {
        let actions = topLevelActions(view, embedded: embedded)
        var places = PluginActionPlaces(archetype: archetype(view, embedded: embedded,
                                                             inlineFormActionId: inlineFormActionId, actions: actions))
        if places.archetype == .card {
            let ordered = actions.filter { role($0) == .primary } + actions.filter { role($0) != .primary }
            places.footer = Array(ordered.prefix(3))
            places.menu = view.menuActions + ordered.dropFirst(3)
            return places
        }
        // §6.3: a capture action writing `into` an input of the page's inline form is that input's slot, not a key.
        let inlineForm = Set(view.actions.first { $0.id == inlineFormActionId }?.form ?? [])
        let drawn = actions.filter { action in
            guard let target = action.target, target.kind == "native", let into = target.into else { return true }
            return !inlineForm.contains(into)
        }
        places.danger = drawn.filter { role($0) == .danger }
        let rest = drawn.filter { role($0) != .danger }
        // A command that declares a group is always a list item (more on task and records pages), never a key.
        let key = { (a: PluginViewAction) in role(a) == .primary || (role(a) == .command && a.group == nil) }
        switch places.archetype {
        case .overview:
            let quick = Array(rest.filter { role($0) == .primary }.prefix(2))
                + rest.filter { role($0) == .command && $0.group == nil }.prefix(2)
            let ids = Set(quick.map(\.id))
            places.quick = quick
            places.list = listGroups(rest.filter { !ids.contains($0.id) })
        case .task:
            let bar = rest.first { role($0) == .primary }
            places.bar = bar.map { [$0] } ?? []
            places.barSecondary = Array(rest.filter { $0.id != bar?.id && key($0) }.prefix(2))
            let taken = Set(places.barSecondary.map(\.id))
            places.more = rest.filter { $0.id != bar?.id && !taken.contains($0.id) }
        default:
            let header = rest.first { role($0) == .primary }
            places.header = header.map { [$0] } ?? []
            places.commands = rest.filter { $0.id != header?.id && key($0) }
            let taken = Set(places.commands.map(\.id))
            places.more = rest.filter { $0.id != header?.id && !taken.contains($0.id) }
        }
        return places
    }

    // MARK: R1 refresh key, R12 account appearance

    static func showsRefreshKey(_ view: PluginViewModel, inlineFormActionId: String?) -> Bool {
        guard view.available else { return false }
        if let presentation = view.presentation, presentation.renderer != "account" { return false }
        if hasBlock(view, ["result"]) { return false }
        let data = !view.fields.isEmpty
            || hasBlock(view, ["rows", "entries", "stats", "hero", "timeline", "people", "status"])
            || flatBlocks(view.blocks).contains { if case .fields(let f) = $0 { return !f.fields.isEmpty }; return false }
        return data && archetype(view, embedded: true, inlineFormActionId: inlineFormActionId) != .task
    }

    static func appearance(_ explicit: FlarePluginPageAppearance?, _ view: PluginViewModel?) -> FlarePluginPageAppearance {
        if let explicit { return explicit }
        guard let view else { return .document }
        if let presentation = view.presentation { return presentation.renderer == "account" ? .account : .document }
        let head = view.blocks.contains { block in
            guard case .section(let section) = block else { return false }
            return section.blocks.contains { child in
                if case .hero(let hero) = child { return hero.amount && hero.maskable && hero.actions.isEmpty }
                return false
            }
        }
        let rows = view.blocks.compactMap { block -> PluginRowsBlock? in if case .rows(let r) = block { return r }; return nil }
        return head && rows.count == 1 && rows[0].columns.count >= 2 ? .account : .document
    }

    // MARK: R6 forms

    static func formPlacement(_ kinds: [PluginInputKind], inline: Bool) -> PluginFormPlacement {
        let page: Set<PluginInputKind> = [.file, .document, .image, .members]
        return !inline && kinds.count <= 4 && !kinds.contains(where: page.contains) ? .sheet : .page
    }

    static func showsCounter(maxLength: Int?, length: Int) -> Bool {
        guard let maxLength else { return false }
        return maxLength <= 200 && length > 0
    }

    static func selectControl(choices: Int) -> (control: PluginSelectControl, disabled: Bool) {
        if choices == 0 { return (.select, true) }
        return (choices <= 4 ? .cards : .select, false)
    }

    // MARK: R3 status values and references

    /// Unmapped → the unknown Tag, neutral, one development warning per context and raw value; a tone → a Tag; no
    /// tone → the text.
    static func statusDraw(text: String, tone: PluginTone?, unmapped: Bool, context: String = "") -> PluginStatusDraw {
        if unmapped {
            pluginWarnOnce("unmapped:\(context):\(text)",
                           "plugin value \"\(text)\" at \(context) is not among its declared values; drawing the unknown status")
            return PluginStatusDraw(tag: true, text: "", tone: .neutral, unknown: true)
        }
        if let tone { return PluginStatusDraw(tag: true, text: text, tone: tone, unknown: false) }
        return PluginStatusDraw(tag: false, text: text, tone: nil, unknown: false)
    }

    static func splitReferences(_ fields: [PluginViewField]) -> (main: [PluginViewField], references: [PluginViewField]) {
        let isReference: (PluginViewField) -> Bool = { if case .reference? = $0.format { return true }; return false }
        return (fields.filter { !isReference($0) }, fields.filter(isReference))
    }

    // MARK: R5 card head

    static func cardHead(detail: Bool, footerActions: Int, menuActions: Int) -> (order: [String], detailInFooter: Bool) {
        let inFooter = detail && footerActions > 0
        return (["icon", "title"] + (detail && !inFooter ? ["detail"] : []) + (menuActions > 0 ? ["more"] : []), inFooter)
    }

    // MARK: R7 result

    static let resultPollMs = 3000
    static let resultPollForMs = 60000

    static func resultIcon(_ tone: PluginTone) -> String {
        switch tone {
        case .success: return "success"
        case .info: return "clock"
        case .warning: return "warning"
        case .danger: return "error"
        case .neutral: return "info"
        }
    }

    /// The icon, tone and title a result draws, whether the page polls and what is announced.
    static func resultFacts(_ block: PluginResultBlock, unknownTitle: String) -> (icon: String, tone: PluginTone, title: String,
                                                                               unknown: Bool, poll: Bool, announce: String) {
        let drawn = statusDraw(text: block.title, tone: block.tone, unmapped: block.unmapped, context: "result:\(block.state)")
        let tone = drawn.tone ?? .neutral
        let title = drawn.unknown ? unknownTitle : block.title
        let announce = [title, block.description ?? ""].filter { !$0.isEmpty }.joined(separator: " ")
        return (resultIcon(tone), tone, title, drawn.unknown, !block.unmapped && block.state == "pending", announce)
    }

    static func resultBlock(_ view: PluginViewModel) -> PluginResultBlock? {
        for block in view.blocks { if case .result(let result) = block { return result } }
        return nil
    }

    // MARK: R8 page states

    static let skeletonDelayMs = 300

    /// Before a view: nothing for 300 ms, then the records skeleton (6 rows); a failed read with nothing to show is
    /// the error face.
    static func face(loading: Bool, elapsedMs: Int, error: String?, hasView: Bool) -> PluginPageFace {
        if hasView { return .loaded }
        if !loading, let error, !error.isEmpty { return .error }
        return elapsedMs < skeletonDelayMs ? .blank : .skeleton(rows: 6)
    }

    /// R8: an empty rows block offers the page's create action (its first primary) under its empty state; the action
    /// then leaves its other place.
    static func emptyCreateAction(_ view: PluginViewModel, places: PluginActionPlaces) -> PluginViewAction? {
        guard let rows = view.rowsBlock, PluginViewFormat.rowsOnce(rows.rows).isEmpty else { return nil }
        return (places.header + places.bar + places.quick).first { role($0) == .primary }
    }

    // MARK: 6.1 status card

    /// The status card's icon by the status (the 6.1 table): not submitted (neutral) `admin`; info is a draft to go
    /// on with (`edit`) while the card offers its key, else under review (`clock`); approved `success`, rejected
    /// `error`, expired `warning`; a value outside the declared ones `info`.
    static func statusCardIcon(_ tone: PluginTone, unknown: Bool, hasKey: Bool) -> String {
        if unknown { return "info" }
        switch tone {
        case .neutral: return "admin"
        case .info: return hasKey ? "edit" : "clock"
        case .success: return "success"
        case .warning: return "warning"
        case .danger: return "error"
        }
    }

    static func statusCard(_ view: PluginViewModel) -> Bool {
        if let presentation = view.presentation { return presentation.renderer == "status.card" }
        guard case .steps? = view.blocks.first else { return false }
        return view.fields.contains { $0.tone != nil || $0.unmapped }
    }
}

/// R4: what a settled action and a return mean for the page (spec/plugin-refresh-vectors.json).
public enum PluginRefreshRules {
    enum Settle: String { case ok, error, formErrors, cancelled }
    public enum Return: String, Sendable { case pop, done, messageCard }

    /// The kit asks for a read once an action it ran settled cleanly while the page shows.
    static func afterAction(_ settle: Settle, visible: Bool) -> PluginRefreshReason? {
        settle == .ok && visible ? .action : nil
    }

    /// What the host does when control comes back: refresh this page, the flow's origin, or close.
    public static func afterReturn(_ event: Return, origin: Bool) -> (refresh: Bool, page: String) {
        switch event {
        case .pop: return (true, "self")
        case .done: return origin ? (true, "origin") : (false, "close")
        case .messageCard: return (false, "close")
        }
    }

    /// §12.1 (doneTarget): the page a result's done key lands on — the nearest page below the top one (`stack` bottom
    /// to top) that is an overview or a records page; nil closes the host's plugin page stack.
    public static func doneTarget(_ stack: [PluginPageKind]) -> Int? {
        stack.dropLast().lastIndex { $0 == .overview || $0 == .records }
    }

    /// What a page is for ``doneTarget(_:)``, read from the view it shows as ``FlarePluginPage`` draws it (`appearance`
    /// nil derives it, R12): a result block makes it a result page; an account is its layout's archetype (wallet: an
    /// overview, flow: a task, else records); a document page is its R2 archetype. No view yet: a task (passed over).
    public static func pageKind(_ view: PluginViewModel?, appearance: FlarePluginPageAppearance? = nil) -> PluginPageKind {
        guard let view, view.available else { return .task }
        if PluginExperienceRules.resultBlock(view) != nil { return .result }
        if PluginExperienceRules.appearance(appearance, view) == .account {
            guard let presentation = view.presentation else { return .overview }
            switch presentation.props["layout"]?.stringValue {
            case "wallet": return .overview
            case "flow": return .task
            default: return .records
            }
        }
        let inline = PluginExperienceRules.pageInlineForm(view, hasAction: true)
        switch PluginExperienceRules.archetype(view, embedded: true, inlineFormActionId: inline) {
        case .overview: return .overview
        case .records: return .records
        case .task, .card: return .task
        }
    }
}

/// §12.1: what a plugin page is to the done key (spec/plugin-refresh-vectors.json doneTarget).
public enum PluginPageKind: String, Sendable { case overview, task, records, result }

private final class PluginWarnings: @unchecked Sendable {
    static let shared = PluginWarnings()
    private let lock = NSLock()
    private var keys = Set<String>()
    func first(_ key: String) -> Bool { lock.lock(); defer { lock.unlock() }; return keys.insert(key).inserted }
}

/// One console warning per key in a development build (R3 unmapped values, R9 repeated labels).
func pluginWarnOnce(_ key: String, _ message: String) {
    #if DEBUG
    if PluginWarnings.shared.first(key) { print("[flare-im] \(message)") }
    #endif
}
