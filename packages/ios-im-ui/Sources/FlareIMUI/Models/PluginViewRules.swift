import Foundation

// The rules the plugin components share with the other kits (`spec/plugin-view-vectors.json` → rules): names for
// unresolved users, the copy of choices, time and countdowns, the optimistic choices state and the form's light
// check. Pure, so the vectors run against them directly; the views only draw what these return.

/// What the plugin view formats time against: now, and the zone (nil: the device zone at each instant).
struct PluginViewClock: Equatable, Sendable {
    var nowMs: Int64?
    var utcOffsetMinutes: Int?

    static let system = PluginViewClock(nowMs: nil, utcOffsetMinutes: nil)

    func now() -> Int64 { nowMs ?? Int64((Date().timeIntervalSince1970 * 1000).rounded(.down)) }
}

/// A countdown's text and when to draw it again (nil once the moment has passed).
struct PluginCountdown: Equatable, Sendable {
    let text: String
    let refreshMs: Int?
}

/// One local calendar minute.
struct PluginWallClock: Equatable, Sendable {
    let year: Int, month: Int, day: Int, hour: Int, minute: Int
}

enum PluginViewFormat {
    static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    /// The name drawn for a user id the host could not resolve: its last 4 characters (the whole id when shorter).
    static func fallbackName(_ userId: String) -> String {
        userId.count > 4 ? String(userId.suffix(4)) : userId
    }

    /// The user drawn for an id: the host's answer, else initials over the fallback name.
    static func user(_ userId: String, resolved: [String: PluginUser]) -> PluginUser {
        resolved[userId] ?? PluginUser(name: fallbackName(userId))
    }

    /// An entry's name: its own, else the resolved user's, else the fallback; nil when it names no one.
    static func entryName(_ entry: PluginEntry, resolved: [String: PluginUser]) -> String? {
        if let name = entry.name, !name.isEmpty { return name }
        guard let userId = entry.userId, !userId.isEmpty else { return nil }
        return user(userId, resolved: resolved).name
    }

    /// The user ids a view names whose names come from the host.
    static func userIds(in view: PluginViewModel) -> [String] {
        var ids: [String] = []
        for block in view.blocks {
            switch block {
            case .people(let people):
                for group in people.groups { for id in group.userIds where !ids.contains(id) { ids.append(id) } }
            case .entries(let entries):
                for entry in entries.items {
                    if let id = entry.userId, !id.isEmpty, (entry.name ?? "").isEmpty, !ids.contains(id) { ids.append(id) }
                }
            default: break
            }
        }
        return ids
    }

    static func votes(_ count: Int, _ strings: FlareStrings) -> String {
        strings.pluginViewVotes.replacingOccurrences(of: "{count}", with: String(count))
    }

    static func seeAll(_ total: Int, _ strings: FlareStrings) -> String {
        strings.pluginViewSeeAll.replacingOccurrences(of: "{count}", with: String(total))
    }

    /// Whether a card draws its own view details key (spec rules.detailKey): the view has a detail, is available and is
    /// not embedded, and no entries block shows its see all. The card also needs an `onOpenDetail`.
    static func showsDetailKey(_ view: PluginViewModel, embedded: Bool) -> Bool {
        guard view.detail, view.available, !embedded else { return false }
        return !view.blocks.contains { if case .entries(let entries) = $0 { return entries.more }; return false }
    }

    /// The line under a choices block: ended, and the total while results show.
    static func choicesFooter(_ block: PluginChoicesBlock, _ strings: FlareStrings) -> String? {
        var parts: [String] = []
        if block.closed { parts.append(strings.pluginViewEnded) }
        if block.showResults, let total = block.total { parts.append(votes(total, strings)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func percentText(_ option: PluginChoice, showResults: Bool) -> String? {
        guard showResults, let percent = option.percent else { return nil }
        return "\(percent)%"
    }

    static func votesText(_ option: PluginChoice, showResults: Bool, _ strings: FlareStrings) -> String? {
        guard showResults, let count = option.count else { return nil }
        return votes(count, strings)
    }

    /// A number as a progress block writes it: whole numbers without a fraction.
    static func number(_ value: Double) -> String {
        if value.rounded() == value, abs(value) < 1e15 { return String(Int64(value)) }
        var text = String(format: "%.2f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }

    static func progressText(_ block: PluginProgressBlock) -> String { "\(number(block.value))/\(number(block.total))" }

    /// style danger → the danger key, primary → the primary key, none → the secondary key.
    static func variant(_ action: PluginViewAction) -> FlareButtonVariant {
        switch action.style {
        case .danger: return .danger
        case .primary: return .primary
        case nil: return .secondary
        }
    }

    // MARK: Time

    static func wallClock(_ ms: Int64, utcOffsetMinutes: Int?) -> PluginWallClock {
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let offset = utcOffsetMinutes.map { $0 * 60 } ?? TimeZone.current.secondsFromGMT(for: date)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: offset) ?? .current
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return PluginWallClock(year: c.year ?? 1970, month: c.month ?? 1, day: c.day ?? 1, hour: c.hour ?? 0,
                               minute: c.minute ?? 0)
    }

    private static func pad2(_ n: Int) -> String { n < 10 ? "0\(n)" : String(n) }

    /// Renders a date-time pattern: y year, M month, MMM Jan..Dec, d day, HH hour, mm minute; the rest is literal.
    static func render(_ pattern: String, _ at: PluginWallClock) -> String {
        let chars = Array(pattern)
        var out = ""
        var i = 0
        while i < chars.count {
            let c = chars[i]
            guard "yMdHm".contains(c) else { out.append(c); i += 1; continue }
            var j = i
            while j < chars.count, chars[j] == c { j += 1 }
            let run = String(chars[i..<j])
            switch run {
            case "y": out += String(at.year)
            case "M": out += String(at.month)
            case "MMM": out += months[max(0, min(11, at.month - 1))]
            case "d": out += String(at.day)
            case "HH": out += pad2(at.hour)
            case "mm": out += pad2(at.minute)
            default: out += run
            }
            i = j
        }
        return out
    }

    /// One instant as the time blocks write it: the year only outside the current one.
    static func dateTime(_ ms: Int64, nowMs: Int64, _ strings: FlareStrings, utcOffsetMinutes: Int?) -> String {
        let at = wallClock(ms, utcOffsetMinutes: utcOffsetMinutes)
        let now = wallClock(nowMs, utcOffsetMinutes: utcOffsetMinutes)
        return render(at.year == now.year ? strings.pluginViewDateTimeFormat : strings.pluginViewDateTimeYearFormat, at)
    }

    /// A time block's text: an instant, a range on one day ("…14:00–15:00") or across days ("… – …").
    static func timeText(atMs: Int64, endMs: Int64?, nowMs: Int64, _ strings: FlareStrings,
                         utcOffsetMinutes: Int?) -> String {
        let start = dateTime(atMs, nowMs: nowMs, strings, utcOffsetMinutes: utcOffsetMinutes)
        guard let endMs else { return start }
        let a = wallClock(atMs, utcOffsetMinutes: utcOffsetMinutes)
        let b = wallClock(endMs, utcOffsetMinutes: utcOffsetMinutes)
        if a.year == b.year, a.month == b.month, a.day == b.day { return "\(start)–\(pad2(b.hour)):\(pad2(b.minute))" }
        return "\(start) – \(dateTime(endMs, nowMs: nowMs, strings, utcOffsetMinutes: utcOffsetMinutes))"
    }

    /// The countdown to `atMs`: mm:ss under an hour (each second), hours and minutes under a day, days and hours
    /// beyond (each minute), and the deadline-passed text once it is reached.
    static func countdown(atMs: Int64, nowMs: Int64, _ strings: FlareStrings) -> PluginCountdown {
        let r = atMs - nowMs
        if r <= 0 { return PluginCountdown(text: strings.pluginViewDeadlinePassed, refreshMs: nil) }
        func unit(_ template: String, _ n: Int64) -> String { template.replacingOccurrences(of: "{n}", with: String(n)) }
        let time: String
        if r < 3_600_000 {
            let s = Int(r / 1000)
            time = "\(pad2(s / 60)):\(pad2(s % 60))"
            return PluginCountdown(text: strings.pluginViewRemaining.replacingOccurrences(of: "{time}", with: time),
                                   refreshMs: 1000)
        }
        if r < 86_400_000 {
            let h = r / 3_600_000
            let m = (r % 3_600_000) / 60_000
            time = unit(strings.myInviteUnitHours, h) + (m > 0 ? " " + unit(strings.myInviteUnitMinutes, m) : "")
        } else {
            let d = r / 86_400_000
            let h = (r % 86_400_000) / 3_600_000
            time = unit(strings.myInviteUnitDays, d) + (h > 0 ? " " + unit(strings.myInviteUnitHours, h) : "")
        }
        return PluginCountdown(text: strings.pluginViewRemaining.replacingOccurrences(of: "{time}", with: time),
                               refreshMs: 60_000)
    }

    /// How long until the countdown's text changes: the next whole second (under an hour) or minute, so the text
    /// turns over on the boundary; nil once it has passed.
    static func countdownDelay(atMs: Int64, nowMs: Int64) -> Int64? {
        let r = atMs - nowMs
        guard r > 0 else { return nil }
        let step: Int64 = r < 3_600_000 ? 1000 : 60_000
        return r % step + 1
    }
}

// MARK: - Choices

/// The choices blocks' local state: the multiple-choice drafts and the submit awaiting the host. A submitted
/// selection shows at once and pauses the block until a new view arrives (the truth) or the host reports a failure
/// (`error` turns non-empty, or the host settles — `settleToken` moves, or `busyActionId` leaves the action — while
/// `error` or `formErrors` is set), which reverts it. A clean settle keeps the mark until the new view.
struct PluginChoicesInteraction: Equatable, Sendable {
    struct Pending: Equatable, Sendable {
        let block: Int
        let actionId: String
        let selection: [Int]
    }

    /// Multiple-choice drafts by block position.
    var drafts: [Int: [Int]] = [:]
    var pending: Pending?

    func isInteractive(_ block: PluginChoicesBlock, at index: Int, locked: Bool) -> Bool {
        block.action != nil && !block.closed && !locked && pending?.block != index
    }

    /// The indices drawn as chosen: the submit awaiting the host, else the draft, else the view's.
    func shown(_ block: PluginChoicesBlock, at index: Int) -> [Int] {
        if let pending, pending.block == index { return pending.selection }
        if block.multiple, block.action != nil, !block.closed { return drafts[index] ?? block.selection }
        return block.selection
    }

    /// The multiple submit key: a non-empty draft that differs from the view's selection.
    func submitEnabled(_ block: PluginChoicesBlock, at index: Int) -> Bool {
        let draft = drafts[index] ?? block.selection
        return !draft.isEmpty && Set(draft) != Set(block.selection)
    }

    /// A tap on an option. Single choice: the selection to submit (nil for the only selected option). Multiple: the
    /// draft toggles and nothing is submitted.
    mutating func tap(_ block: PluginChoicesBlock, at index: Int, option: Int, locked: Bool) -> [Int]? {
        guard isInteractive(block, at: index, locked: locked) else { return nil }
        if block.multiple {
            var draft = Set(drafts[index] ?? block.selection)
            if draft.contains(option) { draft.remove(option) } else { draft.insert(option) }
            drafts[index] = draft.sorted()
            return nil
        }
        return block.selection == [option] ? nil : [option]
    }

    /// The multiple draft to submit, ascending; nil while the key is off.
    func submission(_ block: PluginChoicesBlock, at index: Int, locked: Bool) -> [Int]? {
        guard block.multiple, isInteractive(block, at: index, locked: locked), submitEnabled(block, at: index) else { return nil }
        return (drafts[index] ?? block.selection).sorted()
    }

    /// The selection went to the host: it shows until settled.
    mutating func submitted(block index: Int, actionId: String, selection: [Int]) {
        pending = Pending(block: index, actionId: actionId, selection: selection.sorted())
    }

    /// A new view is the truth.
    mutating func viewChanged() { pending = nil; drafts = [:] }

    mutating func revert() {
        guard let pending else { return }
        drafts[pending.block] = nil
        self.pending = nil
    }

    mutating func errorChanged(from old: String?, to new: String?) {
        if let new, !new.isEmpty, new != old { revert() }
    }

    /// The fallback settle: `busyActionId` left the pending action.
    mutating func busyActionChanged(from old: String?, to new: String?, error: String?,
                                    formErrors: [PluginFormError] = []) {
        guard let old, old != new, pending?.actionId == old else { return }
        settled(error: error, formErrors: formErrors)
    }

    /// The host settled the action (`settleToken` moved): a result with an error or form errors reverts the submit,
    /// read now, so the same error text as before still reverts; a clean one keeps the mark until the new view.
    mutating func settled(error: String?, formErrors: [PluginFormError] = []) {
        if PluginHostSignal.failed(error: error, formErrors: formErrors) { revert() }
    }

    /// One host change, seen whole: a new error reverts; `settleToken` moving or `busyActionId` leaving the pending
    /// action settles. Signals arriving together settle once (settling is idempotent).
    mutating func hostChanged(from old: PluginHostSignal, to new: PluginHostSignal) {
        errorChanged(from: old.error, to: new.error)
        if new.settleToken != old.settleToken {
            settled(error: new.error, formErrors: new.formErrors)
        }
        busyActionChanged(from: old.busyActionId, to: new.busyActionId, error: new.error, formErrors: new.formErrors)
    }
}

// MARK: - Settling

/// What the host reports about the card's actions, observed as one value so every field of a change is read
/// together: a host may set the error, clear `busyActionId` and move `settleToken` in a single update.
struct PluginHostSignal: Equatable, Sendable {
    var busy = false
    var busyActionId: String?
    var error: String?
    var formErrors: [PluginFormError] = []
    var settleToken = 0

    static func failed(error: String?, formErrors: [PluginFormError]) -> Bool {
        !(error ?? "").isEmpty || !formErrors.isEmpty
    }

    /// The result reports a failure: an error or form errors.
    var failed: Bool { Self.failed(error: error, formErrors: formErrors) }
}

/// What a host change does to an open form the user submitted: nothing yet, close it (a clean result) or keep it
/// open with the error or the form errors.
enum PluginFormSettle: Equatable, Sendable { case wait, close, keep }

enum PluginSettleRules {
    /// The form of `actionId` settles when `settleToken` moves, or (the fallback) when the card or that action stops
    /// being busy.
    static func form(from old: PluginHostSignal, to new: PluginHostSignal, actionId: String) -> PluginFormSettle {
        let wasPending = old.busy || old.busyActionId == actionId
        let pending = new.busy || new.busyActionId == actionId
        guard new.settleToken != old.settleToken || (wasPending && !pending) else { return .wait }
        return new.failed ? .keep : .close
    }
}

// MARK: - Forms

enum PluginFormRules {
    static func maxLength(_ input: PluginInput) -> Int? {
        if let length = input.maxLength { return length }
        switch input.kind {
        case .text: return 256
        case .textarea: return 2000
        case .options: return 100
        default: return nil
        }
    }

    /// The most option rows or members of an input (options 50, members 500 when absent).
    static func maxItems(_ input: PluginInput) -> Int {
        if let max = input.max { return Int(max) }
        switch input.kind {
        case .options: return 50
        case .members: return 500
        default: return 1
        }
    }

    /// The fewest option rows the editor keeps.
    static func minRows(_ input: PluginInput) -> Int { Swift.max(Int(input.min ?? 1), 1) }

    /// Characters as the core counts them: Unicode code points.
    static func length(_ text: String) -> Int { text.unicodeScalars.count }

    static func trimmed(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    private static func text(of value: PluginJSONValue) -> String {
        switch value {
        case .string(let s): return s
        case .number(let n): return PluginViewFormat.number(n)
        case .bool(let b): return b ? "true" : "false"
        default: return ""
        }
    }

    /// The editable draft of one input: `values[id]`, else its default.
    static func draftValue(_ input: PluginInput, values: [String: PluginJSONValue]?) -> PluginJSONValue {
        let raw = values?[input.id] ?? input.defaultValue
        switch input.kind {
        case .toggle:
            switch raw {
            case .bool(let b)?: return .bool(b)
            case .number(let n)?: return .bool(n != 0)
            case .string(let s)?: return .bool(!s.isEmpty)
            case .array?, .object?: return .bool(true)
            default: return .bool(false)
            }
        case .options:
            if let items = raw?.arrayValue { return .array(items.map { .string(text(of: $0)) }) }
            return .array(Array(repeating: .string(""), count: minRows(input)))
        case .members:
            return .array((raw?.arrayValue ?? []).compactMap { $0.stringValue.map(PluginJSONValue.string) })
        case .text, .textarea, .select:
            return .string(raw?.stringValue ?? "")
        case .number, .datetime:
            if let n = raw?.numberValue, n.isFinite { return .number(n) }
            return .null
        }
    }

    static func draft(_ inputs: [PluginInput], values: [String: PluginJSONValue]?) -> [String: PluginJSONValue] {
        Dictionary(inputs.map { ($0.id, draftValue($0, values: values)) }, uniquingKeysWith: { first, _ in first })
    }

    private static func items(_ value: PluginJSONValue?) -> [String] {
        (value?.arrayValue ?? []).map { trimmed(text(of: $0)) }.filter { !$0.isEmpty }
    }

    /// The client's light check of one input: required and length.
    static func check(_ input: PluginInput, _ draft: PluginJSONValue?) -> PluginFormIssue? {
        let limit = maxLength(input)
        switch input.kind {
        case .text, .textarea:
            let value = trimmed(draft?.stringValue ?? "")
            if input.required, value.isEmpty { return .required }
            if let limit, length(value) > limit { return .tooLong }
            return nil
        case .number, .datetime:
            return input.required && (draft?.numberValue == nil) ? .required : nil
        case .select:
            return input.required && (draft?.stringValue ?? "").isEmpty ? .required : nil
        case .options:
            let rows = items(draft)
            if input.required, rows.isEmpty { return .required }
            if let limit, rows.contains(where: { length($0) > limit }) { return .tooLong }
            return nil
        case .members:
            return input.required && (draft?.arrayValue ?? []).isEmpty ? .required : nil
        case .toggle:
            return nil
        }
    }

    static func check(_ inputs: [PluginInput], _ draft: [String: PluginJSONValue]) -> [PluginFormError] {
        inputs.compactMap { input in check(input, draft[input.id]).map { PluginFormError(input: input.id, issue: $0) } }
    }

    /// What submit hands over: trimmed text, cleaned option rows, only the inputs with a value.
    static func values(_ inputs: [PluginInput], _ draft: [String: PluginJSONValue]) -> [String: PluginJSONValue] {
        var out: [String: PluginJSONValue] = [:]
        for input in inputs {
            let value = draft[input.id]
            switch input.kind {
            case .text, .textarea:
                let text = trimmed(value?.stringValue ?? "")
                if !text.isEmpty { out[input.id] = .string(text) }
            case .number, .datetime:
                if let n = value?.numberValue, n.isFinite { out[input.id] = .number(n) }
            case .toggle:
                out[input.id] = .bool(value?.boolValue ?? false)
            case .select:
                if let s = value?.stringValue, !s.isEmpty { out[input.id] = .string(s) }
            case .options:
                let rows = items(value)
                if !rows.isEmpty { out[input.id] = .array(rows.map(PluginJSONValue.string)) }
            case .members:
                if let ids = value?.arrayValue, !ids.isEmpty { out[input.id] = .array(ids) }
            }
        }
        return out
    }

    /// The words for one form error under its input.
    static func issueText(_ issue: PluginFormIssue, _ input: PluginInput?, _ strings: FlareStrings) -> String {
        switch issue {
        case .required: return strings.pluginFormRequired
        case .tooLong: return strings.pluginFormTooLong
        case .outOfRange: return strings.pluginFormOutOfRange
        case .duplicateItem: return strings.pluginFormDuplicateItem
        case .tooFewItems:
            return strings.pluginFormTooFewItems.replacingOccurrences(of: "{n}", with: String(Int(input?.min ?? 1)))
        case .tooManyItems:
            return strings.pluginFormTooManyItems.replacingOccurrences(of: "{n}", with: String(input.map(maxItems) ?? 1))
        default: return strings.pluginFormInvalid
        }
    }

    /// "{length}/{maxLength}" under a text or textarea.
    static func counter(_ input: PluginInput, _ draft: PluginJSONValue?) -> String? {
        guard input.kind == .text || input.kind == .textarea, let limit = maxLength(input) else { return nil }
        return "\(length(trimmed(draft?.stringValue ?? "")))/\(limit)"
    }
}

/// A form being filled in: the draft, which inputs were edited (their client issue shows; their host error is
/// spent) and whether submit was tried (every issue shows).
struct PluginFormState: Equatable, Sendable {
    var draft: [String: PluginJSONValue]
    var edited: Set<String> = []
    var editedSinceErrors: Set<String> = []
    var attempted = false

    init(inputs: [PluginInput], values: [String: PluginJSONValue]?) {
        draft = PluginFormRules.draft(inputs, values: values)
    }

    mutating func set(_ id: String, _ value: PluginJSONValue) {
        draft[id] = value
        edited.insert(id)
        editedSinceErrors.insert(id)
    }

    /// New host errors apply again to every input.
    mutating func hostErrorsChanged() { editedSinceErrors = [] }

    /// The text under an input: the host's first error for it, else the client's issue once it may show.
    func errorText(_ input: PluginInput, hostErrors: [PluginFormError], _ strings: FlareStrings) -> String? {
        if !editedSinceErrors.contains(input.id), let host = hostErrors.first(where: { $0.input == input.id }) {
            return PluginFormRules.issueText(host.issue, input, strings)
        }
        guard attempted || edited.contains(input.id) else { return nil }
        return PluginFormRules.check(input, draft[input.id]).map { PluginFormRules.issueText($0, input, strings) }
    }

    /// Runs the check: the values to submit, or nil (and every issue shows) when one fails.
    mutating func submit(_ inputs: [PluginInput]) -> [String: PluginJSONValue]? {
        attempted = true
        guard PluginFormRules.check(inputs, draft).isEmpty else { return nil }
        return PluginFormRules.values(inputs, draft)
    }

    // Options rows.

    func rows(_ id: String) -> [String] { (draft[id]?.arrayValue ?? []).map { $0.stringValue ?? "" } }

    func canAddRow(_ input: PluginInput) -> Bool { rows(input.id).count < PluginFormRules.maxItems(input) }

    func canRemoveRow(_ input: PluginInput) -> Bool { rows(input.id).count > PluginFormRules.minRows(input) }

    mutating func setRow(_ input: PluginInput, _ index: Int, _ value: String) {
        var rows = self.rows(input.id)
        guard rows.indices.contains(index) else { return }
        rows[index] = value
        set(input.id, .array(rows.map(PluginJSONValue.string)))
    }

    mutating func addRow(_ input: PluginInput) {
        guard canAddRow(input) else { return }
        set(input.id, .array((self.rows(input.id) + [""]).map(PluginJSONValue.string)))
    }

    mutating func removeRow(_ input: PluginInput, _ index: Int) {
        var rows = self.rows(input.id)
        guard canRemoveRow(input), rows.indices.contains(index) else { return }
        rows.remove(at: index)
        set(input.id, .array(rows.map(PluginJSONValue.string)))
    }
}
