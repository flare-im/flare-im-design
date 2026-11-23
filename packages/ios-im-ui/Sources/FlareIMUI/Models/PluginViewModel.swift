import Foundation

// The resolved plugin view (core SDK `ResolvedPluginView`, flare-plugin-protocol ui.rs / blocks.rs / inputs.rs) as
// data. The kit renders this shape and reads no paths; every model decodes the core's camelCase JSON as it is and
// skips what a newer protocol adds (unknown block kinds, input kinds and keys). `spec/plugin-view-vectors.json`
// holds the shapes and the render facts the four kits share.

/// A JSON value the plugin protocol carries as data: an input's default and the submitted form values.
public enum PluginJSONValue: Codable, Equatable, Hashable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([PluginJSONValue])
    case object([String: PluginJSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([PluginJSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: PluginJSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value):
            // Whole numbers (milliseconds, counts) go out without a fraction, as the core writes them.
            if value.rounded() == value, abs(value) < 9_007_199_254_740_992 { try container.encode(Int64(value)) }
            else { try container.encode(value) }
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    public var stringValue: String? { if case .string(let value) = self { return value }; return nil }
    public var numberValue: Double? { if case .number(let value) = self { return value }; return nil }
    public var boolValue: Bool? { if case .bool(let value) = self { return value }; return nil }
    public var arrayValue: [PluginJSONValue]? { if case .array(let value) = self { return value }; return nil }
    public var objectValue: [String: PluginJSONValue]? { if case .object(let value) = self { return value }; return nil }
    public var isNull: Bool { self == .null }

    public subscript(key: String) -> PluginJSONValue? { objectValue?[key] }
    public subscript(index: Int) -> PluginJSONValue? {
        guard let array = arrayValue, array.indices.contains(index) else { return nil }
        return array[index]
    }
}

extension PluginJSONValue: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    public init(nilLiteral: ()) { self = .null }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
    public init(integerLiteral value: Int) { self = .number(Double(value)) }
    public init(floatLiteral value: Double) { self = .number(value) }
    public init(stringLiteral value: String) { self = .string(value) }
    public init(arrayLiteral elements: PluginJSONValue...) { self = .array(elements) }
    public init(dictionaryLiteral elements: (String, PluginJSONValue)...) {
        self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
    }
}

/// A label/value row (v1 `fields`, and the `fields` block). `value` is the plain text; `format` is what the kit may
/// write instead (``PluginFormatRules``: a compact count, a duration in the viewer's words).
public struct PluginViewField: Codable, Equatable, Sendable {
    public let label: String; public let value: String
    public let format: PluginValueFormat?
    /// The tone its value label declares (`{label, tone}` values, an enum format): the value draws as a Tag (R3).
    public let tone: PluginTone?
    /// The plugin declared values and this one is not among them: the kit draws the unknown status, never `value`.
    public let unmapped: Bool
    public init(label: String, value: String, format: PluginValueFormat? = nil, tone: PluginTone? = nil,
                unmapped: Bool = false) {
        self.label = label; self.value = value; self.format = format; self.tone = tone; self.unmapped = unmapped
    }
    private enum CodingKeys: String, CodingKey { case label, value, format, tone, unmapped }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = try c.decode(String.self, forKey: .label)
        value = c.lenient(String.self, .value) ?? ""
        format = c.lenient(PluginValueFormat.self, .format)
        tone = c.lenient(PluginTone.self, .tone)
        unmapped = c.lenient(Bool.self, .unmapped) ?? false
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(label, forKey: .label); try c.encode(value, forKey: .value)
        try c.encodeIfPresent(format, forKey: .format); try c.encodeIfPresent(tone, forKey: .tone)
        if unmapped { try c.encode(unmapped, forKey: .unmapped) }
    }
}

/// How an action key is drawn; none is the secondary key.
public enum PluginActionStyle: String, Codable, Sendable { case primary, danger }

/// A resolved action. Its `input` stays with the core: the kit hands back the opaque `id` only. The kit reads a
/// native `target`'s `into`: a page action writing into one of the form's own inputs runs through that input's key
/// (``PluginFormRules/nativeIntoKey(_:_:)``), so the host's answer lands in the form's current scope.
public struct PluginViewAction: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let style: PluginActionStyle?
    /// Asked first in the kit DangerConfirm.
    public let confirm: String?
    /// Input ids collected first in ``PluginFormView``.
    public let form: [String]?
    /// Where the action goes, as the view gives it.
    public let target: PluginActionTarget?
    /// The page list card it joins (`common` or `records`, R2.1); nil: the untitled card.
    public let group: String?
    /// A kit icon name for its list row's leading slot.
    public let icon: String?
    /// Why it cannot run now (R2.5): the key is disabled and says so under it.
    public let disabledReason: String?

    public init(id: String, label: String, style: PluginActionStyle? = nil, confirm: String? = nil, form: [String]? = nil,
                target: PluginActionTarget? = nil, group: String? = nil, icon: String? = nil,
                disabledReason: String? = nil) {
        self.id = id; self.label = label; self.style = style; self.confirm = confirm; self.form = form
        self.target = target; self.group = group; self.icon = icon; self.disabledReason = disabledReason
    }

    private enum CodingKeys: String, CodingKey { case id, label, style, confirm, form, target, group, icon, disabledReason }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        label = try c.decode(String.self, forKey: .label)
        style = c.lenient(String.self, .style).flatMap(PluginActionStyle.init(rawValue:))
        confirm = c.lenient(String.self, .confirm)
        form = c.lenient([String].self, .form)
        target = c.lenient(PluginActionTarget.self, .target)
        group = c.lenient(String.self, .group)
        icon = c.lenient(String.self, .icon)
        disabledReason = c.lenient(String.self, .disabledReason).flatMap { $0.isEmpty ? nil : $0 }
    }
}

/// An action's target (flare-plugin-protocol UiActionTarget): `native` (`capability`, `params`, `into`),
/// `operation` or `page`. The kit only reads a native one.
public struct PluginActionTarget: Codable, Equatable, Hashable, Sendable {
    public let kind: String
    public let capability: String?
    public let params: [String: PluginJSONValue]?
    /// The page input the native capability writes into.
    public let into: String?

    public init(kind: String, capability: String? = nil, params: [String: PluginJSONValue]? = nil, into: String? = nil) {
        self.kind = kind; self.capability = capability; self.params = params; self.into = into
    }

    private enum CodingKeys: String, CodingKey { case kind, capability, params, into }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(String.self, forKey: .kind)
        capability = c.lenient(String.self, .capability)
        params = c.lenient([String: PluginJSONValue].self, .params)
        into = c.lenient(String.self, .into)
    }
}

/// Semantic colour of a status, a note or a people group, drawn with the `*Text` tokens.
public enum PluginTone: String, Codable, Sendable {
    case neutral, info, success, warning, danger
    public init(from decoder: Decoder) throws {
        let raw = (try? decoder.singleValueContainer().decode(String.self)) ?? ""
        // brand draws info; a tone from a newer protocol draws neutral (R3).
        self = raw == "brand" ? .info : PluginTone(rawValue: raw) ?? .neutral
    }
}

public enum PluginTextStyle: String, Codable, Sendable {
    case body, title, secondary
    public init(from decoder: Decoder) throws {
        self = PluginTextStyle(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .body
    }
}

/// `text`: a paragraph, cut at `maxLines` with an expand key.
public struct PluginTextBlock: Codable, Equatable, Sendable {
    public let text: String
    public let maxLines: Int?
    public let style: PluginTextStyle
    public init(text: String, maxLines: Int? = nil, style: PluginTextStyle = .body) {
        self.text = text; self.maxLines = maxLines; self.style = style
    }
    private enum CodingKeys: String, CodingKey { case text, maxLines, style }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decode(String.self, forKey: .text)
        maxLines = c.lenient(Int.self, .maxLines)
        style = c.lenient(PluginTextStyle.self, .style) ?? .body
    }
}

public struct PluginFieldsBlock: Codable, Equatable, Sendable {
    public let fields: [PluginViewField]
    public init(fields: [PluginViewField]) { self.fields = fields }
}

/// One option of a choices block; `count` and `percent` only while results show.
public struct PluginChoice: Codable, Equatable, Identifiable, Sendable {
    public let index: Int
    public let label: String
    public let selected: Bool
    public let count: Int?
    public let percent: Int?
    public var id: Int { index }
    public init(index: Int, label: String, selected: Bool = false, count: Int? = nil, percent: Int? = nil) {
        self.index = index; self.label = label; self.selected = selected; self.count = count; self.percent = percent
    }
    private enum CodingKeys: String, CodingKey { case index, label, selected, count, percent }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        index = try c.decode(Int.self, forKey: .index)
        label = try c.decode(String.self, forKey: .label)
        selected = c.lenient(Bool.self, .selected) ?? false
        count = c.lenient(Int.self, .count)
        percent = c.lenient(Int.self, .percent)
    }
}

/// `choices`: a poll or an RSVP. `action` is the block's own submit action (never among the footer actions).
public struct PluginChoicesBlock: Codable, Equatable, Sendable {
    public let options: [PluginChoice]
    public let multiple: Bool
    public let voted: Bool
    public let closed: Bool
    public let showResults: Bool
    public let total: Int?
    public let inputName: String
    /// A multiple choice's limit (1 up to the option count): once the draft holds that many, the other options wait.
    public let maxSelections: Int?
    public let action: PluginViewAction?
    public init(options: [PluginChoice], multiple: Bool = false, voted: Bool = false, closed: Bool = false,
                showResults: Bool = false, total: Int? = nil, inputName: String = "selection",
                maxSelections: Int? = nil, action: PluginViewAction? = nil) {
        self.options = options; self.multiple = multiple; self.voted = voted; self.closed = closed
        self.showResults = showResults; self.total = total; self.inputName = inputName
        self.maxSelections = maxSelections; self.action = action
    }
    private enum CodingKeys: String, CodingKey {
        case options, multiple, voted, closed, showResults, total, inputName, maxSelections, action
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        options = try c.decode([PluginChoice].self, forKey: .options)
        multiple = c.lenient(Bool.self, .multiple) ?? false
        voted = c.lenient(Bool.self, .voted) ?? false
        closed = c.lenient(Bool.self, .closed) ?? false
        showResults = c.lenient(Bool.self, .showResults) ?? false
        total = c.lenient(Int.self, .total)
        inputName = c.lenient(String.self, .inputName) ?? "selection"
        maxSelections = c.lenient(Int.self, .maxSelections)
        action = c.lenient(PluginViewAction.self, .action)
    }
    /// The indices the view says the viewer chose, ascending.
    public var selection: [Int] { options.filter(\.selected).map(\.index).sorted() }
    /// The limit that applies: a multiple choice's positive `maxSelections`; nil for a single choice or no limit.
    public var cap: Int? {
        guard multiple, let maxSelections, maxSelections > 0 else { return nil }
        return maxSelections
    }
}

/// An entry's or a row's enumerated value as words and a tone (the plugin's `valueLabels`, already translated; an
/// unmapped value arrives as its raw text, neutral). A tone the kit does not know draws neutral.
public struct PluginBadge: Codable, Equatable, Sendable {
    public let text: String
    public let tone: PluginTone
    /// Not among the plugin's declared values: drawn as the unknown status (R3).
    public let unmapped: Bool
    public init(text: String, tone: PluginTone = .neutral, unmapped: Bool = false) {
        self.text = text; self.tone = tone; self.unmapped = unmapped
    }
    private enum CodingKeys: String, CodingKey { case text, tone, unmapped }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = c.lenient(String.self, .text) ?? ""
        tone = c.lenient(PluginTone.self, .tone) ?? .neutral
        unmapped = c.lenient(Bool.self, .unmapped) ?? false
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(text, forKey: .text); try c.encode(tone, forKey: .tone)
        if unmapped { try c.encode(unmapped, forKey: .unmapped) }
    }
}

/// The group an entry opens in a grouped entries block: its key, the label (data, not translated) and the counts
/// the header writes ("火锅 · 3 票 · 38%"); count, total and percent are absent when the plugin gave none.
public struct PluginEntryGroup: Codable, Equatable, Sendable {
    public let key: String
    public let label: String
    public let count: Int?
    public let total: Int?
    public let percent: Int?
    public init(key: String, label: String, count: Int? = nil, total: Int? = nil, percent: Int? = nil) {
        self.key = key; self.label = label; self.count = count; self.total = total; self.percent = percent
    }
    private enum CodingKeys: String, CodingKey { case key, label, count, total, percent }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = c.lenient(String.self, .key) ?? c.lenient(Int.self, .key).map(String.init) ?? ""
        label = c.lenient(String.self, .label) ?? ""
        count = c.lenient(Int.self, .count)
        total = c.lenient(Int.self, .total)
        percent = c.lenient(Int.self, .percent)
    }
}

/// One entry of an entries block; `index` is its position in the data, from 1 (from 1 in each group of a grouped
/// block). `group` is set on the first entry of each group of a grouped block: a header row goes before it. `badge`
/// (a ledger line's kind) draws after the name and the me tag, before the text.
public struct PluginEntry: Codable, Equatable, Sendable {
    public let index: Int
    public let text: String
    public let name: String?
    public let userId: String?
    public let group: PluginEntryGroup?
    public let badge: PluginBadge?
    /// When it happened (epoch ms), drawn after the text in the device zone.
    public let timeMs: Int64?
    public init(index: Int, text: String, name: String? = nil, userId: String? = nil, group: PluginEntryGroup? = nil,
                badge: PluginBadge? = nil, timeMs: Int64? = nil) {
        self.index = index; self.text = text; self.name = name; self.userId = userId; self.group = group
        self.badge = badge; self.timeMs = timeMs
    }
    private enum CodingKeys: String, CodingKey { case index, text, name, userId, group, badge, timeMs }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        index = c.lenient(Int.self, .index) ?? 0
        text = c.lenient(String.self, .text) ?? ""
        name = c.lenient(String.self, .name)
        userId = c.lenient(String.self, .userId)
        group = c.lenient(PluginEntryGroup.self, .group)
        badge = c.lenient(PluginBadge.self, .badge)
        timeMs = c.lenient(Int64.self, .timeMs)
    }
}

/// `entries`: a numbered list (a sign-up chain); `more` offers "see all" (the detail view). `grouped` lists draw a
/// header row before each entry that carries a `group` (a poll's voters by option).
public struct PluginEntriesBlock: Codable, Equatable, Sendable {
    public let items: [PluginEntry]
    public let numbered: Bool
    public let grouped: Bool
    public let total: Int
    public let more: Bool
    public let emptyText: String?
    public init(items: [PluginEntry], numbered: Bool = true, grouped: Bool = false, total: Int? = nil, more: Bool = false,
                emptyText: String? = nil) {
        self.items = items; self.numbered = numbered; self.grouped = grouped; self.total = total ?? items.count
        self.more = more; self.emptyText = emptyText
    }
    private enum CodingKeys: String, CodingKey { case items, numbered, grouped, total, more, emptyText }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try c.decode([PluginEntry].self, forKey: .items)
        numbered = c.lenient(Bool.self, .numbered) ?? true
        grouped = c.lenient(Bool.self, .grouped) ?? false
        total = c.lenient(Int.self, .total) ?? items.count
        more = c.lenient(Bool.self, .more) ?? false
        emptyText = c.lenient(String.self, .emptyText)
    }
}

/// One row of a people block: `userIds` is already cut to the block's max.
public struct PluginPeopleGroup: Codable, Equatable, Sendable {
    public let label: String
    public let userIds: [String]
    public let count: Int
    public let tone: PluginTone?
    public init(label: String, userIds: [String], count: Int? = nil, tone: PluginTone? = nil) {
        self.label = label; self.userIds = userIds; self.count = count ?? userIds.count; self.tone = tone
    }
    private enum CodingKeys: String, CodingKey { case label, userIds, count, tone }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label) ?? ""
        userIds = c.lenient([String].self, .userIds) ?? []
        count = c.lenient(Int.self, .count) ?? userIds.count
        tone = c.lenient(PluginTone.self, .tone)
    }
}

public struct PluginPeopleBlock: Codable, Equatable, Sendable {
    public let groups: [PluginPeopleGroup]
    public init(groups: [PluginPeopleGroup]) { self.groups = groups }
}

/// `status`: a badge.
public struct PluginStatusBlock: Codable, Equatable, Sendable {
    public let label: String?
    public let text: String
    public let tone: PluginTone
    /// Not among the plugin's declared values: drawn as the unknown status (R3).
    public let unmapped: Bool
    public init(label: String? = nil, text: String, tone: PluginTone = .neutral, unmapped: Bool = false) {
        self.label = label; self.text = text; self.tone = tone; self.unmapped = unmapped
    }
    private enum CodingKeys: String, CodingKey { case label, text, tone, unmapped }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label)
        text = try c.decode(String.self, forKey: .text)
        tone = c.lenient(PluginTone.self, .tone) ?? .neutral
        unmapped = c.lenient(Bool.self, .unmapped) ?? false
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(label, forKey: .label); try c.encode(text, forKey: .text); try c.encode(tone, forKey: .tone)
        if unmapped { try c.encode(unmapped, forKey: .unmapped) }
    }
}

/// `result`: how a money action, a submission or a send ended (R7) — the state, its label and tone as the plugin's
/// values give them, the amount and a line of description. ``FlareResultView`` draws it.
public struct PluginResultBlock: Codable, Equatable, Sendable {
    public let state: String
    public let title: String
    public let tone: PluginTone
    public let unmapped: Bool
    public let amount: String?
    public let format: PluginValueFormat?
    public let description: String?
    public init(state: String, title: String, tone: PluginTone = .neutral, unmapped: Bool = false, amount: String? = nil,
                format: PluginValueFormat? = nil, description: String? = nil) {
        self.state = state; self.title = title; self.tone = tone; self.unmapped = unmapped; self.amount = amount
        self.format = format; self.description = description
    }
    private enum CodingKeys: String, CodingKey { case state, title, tone, unmapped, amount, format, description }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = c.lenient(String.self, .state) ?? ""
        title = c.lenient(String.self, .title) ?? state
        tone = c.lenient(PluginTone.self, .tone) ?? .neutral
        unmapped = c.lenient(Bool.self, .unmapped) ?? false
        amount = c.lenient(String.self, .amount)
        format = c.lenient(PluginValueFormat.self, .format)
        description = c.lenient(String.self, .description)
    }
}

/// `progress`: a bar with "value/total".
public struct PluginProgressBlock: Codable, Equatable, Sendable {
    public let label: String?
    public let value: Double
    public let total: Double
    public let percent: Int
    public init(label: String? = nil, value: Double, total: Double, percent: Int) {
        self.label = label; self.value = value; self.total = total; self.percent = percent
    }
    private enum CodingKeys: String, CodingKey { case label, value, total, percent }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label)
        value = c.lenient(Double.self, .value) ?? 0
        total = c.lenient(Double.self, .total) ?? 0
        percent = c.lenient(Int.self, .percent) ?? (total > 0 ? Int((value / total * 100).rounded()) : 0)
    }
}

/// `time`: an instant or a range in milliseconds, formatted in the device zone; `countdown` counts down to `atMs`.
public struct PluginTimeBlock: Codable, Equatable, Sendable {
    public let label: String?
    public let atMs: Int64
    public let endMs: Int64?
    public let countdown: Bool
    public init(label: String? = nil, atMs: Int64, endMs: Int64? = nil, countdown: Bool = false) {
        self.label = label; self.atMs = atMs; self.endMs = endMs; self.countdown = countdown
    }
    private enum CodingKeys: String, CodingKey { case label, atMs, endMs, countdown }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label)
        guard let at = flarePluginInstant(c.lenient(Double.self, .atMs)) else {
            throw DecodingError.keyNotFound(CodingKeys.atMs, .init(codingPath: c.codingPath, debugDescription: "atMs"))
        }
        atMs = at
        endMs = flarePluginInstant(c.lenient(Double.self, .endMs))
        countdown = c.lenient(Bool.self, .countdown) ?? false
    }
}

/// `note`: a tinted note.
public struct PluginNoteBlock: Codable, Equatable, Sendable {
    public let text: String
    public let tone: PluginTone?
    public init(text: String, tone: PluginTone? = nil) { self.text = text; self.tone = tone }
    private enum CodingKeys: String, CodingKey { case text, tone }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decode(String.self, forKey: .text)
        tone = c.lenient(PluginTone.self, .tone)
    }
}

/// How a rows column writes its cells: text as given, time as an instant in the device zone.
public enum PluginRowsColumnFormat: String, Codable, Sendable {
    case text, time
    public init(from decoder: Decoder) throws {
        self = PluginRowsColumnFormat(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .text
    }
}

public struct PluginRowsColumn: Codable, Equatable, Sendable {
    public let label: String
    public let format: PluginRowsColumnFormat
    public init(label: String, format: PluginRowsColumnFormat = .text) { self.label = label; self.format = format }
    private enum CodingKeys: String, CodingKey { case label, format }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label) ?? ""
        format = c.lenient(PluginRowsColumnFormat.self, .format) ?? .text
    }
}

/// One cell: its text, the instant of a time column, and what the column's `valueFormat` adds to the text.
public struct PluginRowCell: Codable, Equatable, Sendable {
    public let text: String
    public let timeMs: Int64?
    public let format: PluginValueFormat?
    /// The tone its column's value label declares: the cell draws as a Tag (R3).
    public let tone: PluginTone?
    /// Not among the column's declared values: drawn as the unknown status.
    public let unmapped: Bool
    public init(text: String, timeMs: Int64? = nil, format: PluginValueFormat? = nil, tone: PluginTone? = nil,
                unmapped: Bool = false) {
        self.text = text; self.timeMs = timeMs; self.format = format; self.tone = tone; self.unmapped = unmapped
    }
    private enum CodingKeys: String, CodingKey { case text, timeMs, format, tone, unmapped }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = c.lenient(String.self, .text) ?? ""
        timeMs = flarePluginInstant(c.lenient(Double.self, .timeMs))
        format = c.lenient(PluginValueFormat.self, .format)
        tone = c.lenient(PluginTone.self, .tone)
        unmapped = c.lenient(Bool.self, .unmapped) ?? false
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(text, forKey: .text); try c.encodeIfPresent(timeMs, forKey: .timeMs)
        try c.encodeIfPresent(format, forKey: .format); try c.encodeIfPresent(tone, forKey: .tone)
        if unmapped { try c.encode(unmapped, forKey: .unmapped) }
    }
}

/// A block action a row offers, with the input the core bound for that row: it goes back as the action's `row`.
public struct PluginRowAction: Codable, Equatable, Sendable {
    public let id: String
    public let input: [String: PluginJSONValue]
    public init(id: String, input: [String: PluginJSONValue] = [:]) { self.id = id; self.input = input }
    private enum CodingKeys: String, CodingKey { case id, input }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        input = c.lenient([String: PluginJSONValue].self, .input) ?? [:]
    }
}

/// One row: its key (unique in the block), a cell per column, the actions it offers and its badge.
public struct PluginRow: Codable, Equatable, Identifiable, Sendable {
    public let key: String
    public let cells: [PluginRowCell]
    public let actions: [PluginRowAction]
    public let badge: PluginBadge?
    public var id: String { key }
    public init(key: String, cells: [PluginRowCell], actions: [PluginRowAction] = [], badge: PluginBadge? = nil) {
        self.key = key; self.cells = cells; self.actions = actions; self.badge = badge
    }
    private enum CodingKeys: String, CodingKey { case key, cells, actions, badge }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(String.self, forKey: .key)
        cells = c.lenient([PluginRowCell].self, .cells) ?? []
        actions = (c.lenient([PluginLossy<PluginRowAction>].self, .actions) ?? []).compactMap(\.value)
        badge = c.lenient(PluginBadge.self, .badge)
    }
}

/// `rows`: a plugin page's list (a wallet's ledger). The rows page with the page; `actions` are the block's actions
/// a row offers by id; `filters` names the view inputs the page shows as its filters (absent: every input).
public struct PluginRowsBlock: Codable, Equatable, Sendable {
    public let columns: [PluginRowsColumn]
    public let rows: [PluginRow]
    public let actions: [PluginViewAction]
    public let emptyText: String?
    public let filters: [String]?
    /// Day headings over the rows by the first time column (`flarePluginRowDayHeadings`).
    public let groupByDay: Bool
    /// A kit icon name: the rows draw as records, the 5.8 ledger line led by this icon (spec rules.rowsIcon).
    public let icon: String?
    public init(columns: [PluginRowsColumn], rows: [PluginRow], actions: [PluginViewAction] = [],
                emptyText: String? = nil, filters: [String]? = nil, groupByDay: Bool = false, icon: String? = nil) {
        self.columns = columns; self.rows = rows; self.actions = actions; self.emptyText = emptyText
        self.filters = filters; self.groupByDay = groupByDay; self.icon = icon
    }
    private enum CodingKeys: String, CodingKey { case columns, rows, actions, emptyText, filters, groupByDay, icon }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        columns = c.lenient([PluginRowsColumn].self, .columns) ?? []
        rows = (c.lenient([PluginLossy<PluginRow>].self, .rows) ?? []).compactMap(\.value)
        actions = (c.lenient([PluginLossy<PluginViewAction>].self, .actions) ?? []).compactMap(\.value)
        emptyText = c.lenient(String.self, .emptyText)
        filters = c.lenient([String].self, .filters)
        groupByDay = c.lenient(Bool.self, .groupByDay) ?? false
        icon = c.lenient(String.self, .icon).flatMap { $0.isEmpty ? nil : $0 }
    }
}

/// One display block, tagged by `kind`; a kind the kit does not know is skipped.
public enum PluginBlock: Codable, Equatable, Sendable {
    case text(PluginTextBlock)
    case fields(PluginFieldsBlock)
    case choices(PluginChoicesBlock)
    case entries(PluginEntriesBlock)
    case people(PluginPeopleBlock)
    case status(PluginStatusBlock)
    case progress(PluginProgressBlock)
    case time(PluginTimeBlock)
    case divider
    case note(PluginNoteBlock)
    case rows(PluginRowsBlock)
    case section(PluginSectionBlock)
    case stats(PluginStatsBlock)
    case chart(PluginChartBlock)
    case image(PluginImageBlock)
    case qr(PluginQrBlock)
    case hero(PluginHeroBlock)
    case steps(PluginStepsBlock)
    case banner(PluginBannerBlock)
    case timeline(PluginTimelineBlock)
    case protectedMedia(PluginProtectedMediaBlock)
    case result(PluginResultBlock)

    public var kind: String {
        switch self {
        case .text: return "text"
        case .fields: return "fields"
        case .choices: return "choices"
        case .entries: return "entries"
        case .people: return "people"
        case .status: return "status"
        case .progress: return "progress"
        case .time: return "time"
        case .divider: return "divider"
        case .note: return "note"
        case .rows: return "rows"
        case .section: return "section"
        case .stats: return "stats"
        case .chart: return "chart"
        case .image: return "image"
        case .qr: return "qr"
        case .hero: return "hero"
        case .steps: return "steps"
        case .banner: return "banner"
        case .timeline: return "timeline"
        case .protectedMedia: return "protected-media"
        case .result: return "result"
        }
    }

    private enum KindKey: String, CodingKey { case kind }

    public init(from decoder: Decoder) throws {
        let kind = try decoder.container(keyedBy: KindKey.self).decode(String.self, forKey: .kind)
        switch kind {
        case "text": self = .text(try PluginTextBlock(from: decoder))
        case "fields": self = .fields(try PluginFieldsBlock(from: decoder))
        case "choices": self = .choices(try PluginChoicesBlock(from: decoder))
        case "entries": self = .entries(try PluginEntriesBlock(from: decoder))
        case "people": self = .people(try PluginPeopleBlock(from: decoder))
        case "status": self = .status(try PluginStatusBlock(from: decoder))
        case "progress": self = .progress(try PluginProgressBlock(from: decoder))
        case "time": self = .time(try PluginTimeBlock(from: decoder))
        case "divider": self = .divider
        case "note": self = .note(try PluginNoteBlock(from: decoder))
        case "rows": self = .rows(try PluginRowsBlock(from: decoder))
        case "section": self = .section(try PluginSectionBlock(from: decoder))
        case "stats": self = .stats(try PluginStatsBlock(from: decoder))
        case "chart": self = .chart(try PluginChartBlock(from: decoder))
        case "image": self = .image(try PluginImageBlock(from: decoder))
        case "qr": self = .qr(try PluginQrBlock(from: decoder))
        case "hero": self = .hero(try PluginHeroBlock(from: decoder))
        case "steps": self = .steps(try PluginStepsBlock(from: decoder))
        case "banner": self = .banner(try PluginBannerBlock(from: decoder))
        case "timeline": self = .timeline(try PluginTimelineBlock(from: decoder))
        case "protected-media": self = .protectedMedia(try PluginProtectedMediaBlock(from: decoder))
        case "result": self = .result(try PluginResultBlock(from: decoder))
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "block kind \(kind)"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: KindKey.self)
        try container.encode(kind, forKey: .kind)
        switch self {
        case .text(let block): try block.encode(to: encoder)
        case .fields(let block): try block.encode(to: encoder)
        case .choices(let block): try block.encode(to: encoder)
        case .entries(let block): try block.encode(to: encoder)
        case .people(let block): try block.encode(to: encoder)
        case .status(let block): try block.encode(to: encoder)
        case .progress(let block): try block.encode(to: encoder)
        case .time(let block): try block.encode(to: encoder)
        case .divider: break
        case .note(let block): try block.encode(to: encoder)
        case .rows(let block): try block.encode(to: encoder)
        case .section(let block): try block.encode(to: encoder)
        case .stats(let block): try block.encode(to: encoder)
        case .chart(let block): try block.encode(to: encoder)
        case .image(let block): try block.encode(to: encoder)
        case .qr(let block): try block.encode(to: encoder)
        case .hero(let block): try block.encode(to: encoder)
        case .steps(let block): try block.encode(to: encoder)
        case .banner(let block): try block.encode(to: encoder)
        case .timeline(let block): try block.encode(to: encoder)
        case .protectedMedia(let block): try block.encode(to: encoder)
        case .result(let block): try block.encode(to: encoder)
        }
    }
}

/// Form input kinds (UiInput).
public enum PluginInputKind: String, Codable, Sendable, CaseIterable {
    case text, password, textarea, number, toggle, select, datetime, options, members, file, money, image, document
    /// A one-time location the engine writes when the page's locationOnce action completes (``PluginLocationValue``).
    case location

    /// Inputs whose value is an uploaded file's `{fileId}`, uploaded through `file`: file, image and document.
    public var isUpload: Bool { self == .file || self == .image || self == .document }
}

public struct PluginInputCondition: Codable, Equatable, Sendable {
    public let field: String
    public let anyOf: [String]
    public init(field: String, anyOf: [String]) { self.field = field; self.anyOf = anyOf }
}

public struct PluginFileUploadPolicy: Codable, Equatable, Sendable {
    public let prepareOperation: String
    public let completeOperation: String
    public let purpose: String
    public init(prepareOperation: String, completeOperation: String, purpose: String) {
        self.prepareOperation = prepareOperation; self.completeOperation = completeOperation; self.purpose = purpose
    }
}

public struct PluginFileInput: Codable, Equatable, Sendable {
    public let accept: [String]
    public let maxBytes: Int
    public let upload: PluginFileUploadPolicy
    public init(accept: [String], maxBytes: Int, upload: PluginFileUploadPolicy) {
        self.accept = accept; self.maxBytes = maxBytes; self.upload = upload
    }
    public var valid: Bool {
        maxBytes > 0 && maxBytes <= 5_242_880 && !accept.isEmpty &&
        accept.allSatisfy { $0.range(of: #"^[A-Za-z0-9.+-]+/[A-Za-z0-9.+-]+$"#, options: .regularExpression) != nil } &&
        !upload.prepareOperation.isEmpty && !upload.completeOperation.isEmpty && !upload.purpose.isEmpty
    }
}

/// One choice of a select input.
public struct PluginInputChoice: Codable, Equatable, Sendable {
    public let value: String
    public let label: String
    public init(value: String, label: String) { self.value = value; self.label = label }
}

/// A resolved form input (UiInput): labels translated, `defaultPath` already folded into `defaultValue`.
public struct PluginInput: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: PluginInputKind
    public let label: String
    public let required: Bool
    public let placeholder: String?
    /// Characters (text 256, textarea 2000, an options item 100 when absent).
    public let maxLength: Int?
    /// number: the smallest value; options, members: the fewest items.
    public let min: Double?
    /// number: the largest value; options, members: the most items (members 1 is a single pick).
    public let max: Double?
    /// The initial value (`default` on the wire).
    public let defaultValue: PluginJSONValue?
    /// select only.
    public let choices: [PluginInputChoice]?
    /// file, image and document: what may be uploaded and how.
    public let file: PluginFileInput?
    /// money only: the currency, scale and bounds the core SDK read.
    public let money: PluginMoneyRules?
    /// document only: which side of the document it captures.
    public let side: PluginDocumentSide?
    /// location only: how precise a fix it takes.
    public let precision: PluginLocationPrecision?
    public let showWhen: PluginInputCondition?
    /// R6: the help under the field (already translated); nil draws none.
    public let help: String?

    public init(id: String, kind: PluginInputKind, label: String, required: Bool = false, placeholder: String? = nil,
                maxLength: Int? = nil, min: Double? = nil, max: Double? = nil, defaultValue: PluginJSONValue? = nil,
                choices: [PluginInputChoice]? = nil, file: PluginFileInput? = nil, money: PluginMoneyRules? = nil,
                side: PluginDocumentSide? = nil, showWhen: PluginInputCondition? = nil,
                precision: PluginLocationPrecision? = nil, help: String? = nil) {
        self.id = id; self.kind = kind; self.label = label; self.required = required; self.placeholder = placeholder
        self.maxLength = maxLength; self.min = min; self.max = max; self.defaultValue = defaultValue; self.choices = choices
        self.file = file; self.money = money; self.side = side; self.showWhen = showWhen; self.precision = precision
        self.help = help
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, label, required, placeholder, maxLength, min, max, choices, file, money, side, showWhen, precision
        case help
        case defaultValue = "default"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = try c.decode(PluginInputKind.self, forKey: .kind)
        label = c.lenient(String.self, .label) ?? ""
        required = c.lenient(Bool.self, .required) ?? false
        placeholder = c.lenient(String.self, .placeholder)
        maxLength = c.lenient(Int.self, .maxLength)
        min = c.lenient(Double.self, .min)
        max = c.lenient(Double.self, .max)
        defaultValue = c.lenient(PluginJSONValue.self, .defaultValue)
        choices = c.lenient([PluginInputChoice].self, .choices)
        file = try c.decodeIfPresent(PluginFileInput.self, forKey: .file)
        money = try c.decodeIfPresent(PluginMoneyRules.self, forKey: .money)
        side = try c.decodeIfPresent(PluginDocumentSide.self, forKey: .side)
        precision = try c.decodeIfPresent(PluginLocationPrecision.self, forKey: .precision)
        showWhen = try c.decodeIfPresent(PluginInputCondition.self, forKey: .showWhen)
        help = c.lenient(String.self, .help).flatMap { $0.isEmpty ? nil : $0 }
        if kind.isUpload && file?.valid != true {
            throw DecodingError.dataCorruptedError(forKey: .file, in: c, debugDescription: "Invalid file policy")
        }
        if kind == .location && precision == nil {
            throw DecodingError.dataCorruptedError(forKey: .precision, in: c, debugDescription: "Missing precision")
        }
        if kind == .money && money == nil {
            throw DecodingError.dataCorruptedError(forKey: .money, in: c, debugDescription: "Missing money rules")
        }
    }
}

/// What is wrong with a submitted value (UiFormIssue).
public enum PluginFormIssue: String, Codable, Sendable, CaseIterable {
    case required, unknown, invalidType, tooLong, outOfRange, notAChoice, tooFewItems, tooManyItems, invalidItem,
         duplicateItem
    public init(from decoder: Decoder) throws {
        self = PluginFormIssue(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .invalidType
    }
}

/// One problem with a submitted value (UiFormError), shown under its input.
public struct PluginFormError: Codable, Equatable, Sendable {
    public let input: String
    public let issue: PluginFormIssue
    public init(input: String, issue: PluginFormIssue) { self.input = input; self.issue = issue }
}

/// What the host's `resolveUser` answers for a user id.
public struct PluginUser: Codable, Equatable, Sendable {
    public let name: String
    public let avatarUrl: String?
    public init(name: String, avatarUrl: String? = nil) { self.name = name; self.avatarUrl = avatarUrl }
}

/// A candidate for a members input.
public struct PluginMember: Codable, Equatable, Identifiable, Sendable {
    public let userId: String
    public let name: String
    public let avatarUrl: String?
    public var id: String { userId }
    public init(userId: String, name: String, avatarUrl: String? = nil) {
        self.userId = userId; self.name = name; self.avatarUrl = avatarUrl
    }
}

/// The row a rows action ran on: its key and the input the view bound for that action (`rows[].actions[].input`).
public struct PluginRowRef: Codable, Equatable, Sendable {
    public let key: String
    public let input: [String: PluginJSONValue]
    public init(key: String, input: [String: PluginJSONValue] = [:]) { self.key = key; self.input = input }
}

/// What `onAction(id, payload)` carries: the chosen option indices (ascending), the form's values by input id, and
/// the row of a rows action.
public struct PluginActionPayload: Codable, Equatable, Sendable {
    public var selection: [Int]?
    public var formValues: [String: PluginJSONValue]?
    public var row: PluginRowRef?
    public init(selection: [Int]? = nil, formValues: [String: PluginJSONValue]? = nil, row: PluginRowRef? = nil) {
        self.selection = selection; self.formValues = formValues; self.row = row
    }
    public static let empty = PluginActionPayload()
}

/// The page a ``FlarePluginPage`` shows, as the core SDK's page action request names it.
public struct PluginPageRef: Codable, Equatable, Hashable, Sendable {
    public let pluginId: String
    public let page: String
    public init(pluginId: String, page: String) { self.pluginId = pluginId; self.page = page }
}

/// A resolved plugin page (the core SDK's `pluginPage` result): the view, plus `data`, what the page was resolved
/// against (the first page's source result, or the arguments of a page without a source). The view's fields read
/// straight through (`page.title`, `page.nextCursor`). An unavailable page is `{available: false, title: "",
/// unavailableReason}` and has no data.
@dynamicMemberLookup
public struct PluginPageViewModel: Codable, Equatable, Sendable {
    public let refreshMs: Int?
    public let view: PluginViewModel
    /// Passed back as is by every action run on the page; the kit reads nothing in it.
    public let data: PluginJSONValue?
    /// The page's sibling pages (§4.7, spec rules.pageTabs): 2 to 4 tabs, the shown page selected.
    public let tabs: [PluginPageTab]

    public init(view: PluginViewModel, data: PluginJSONValue? = nil, refreshMs: Int? = nil, tabs: [PluginPageTab] = []) {
        self.view = view; self.data = data; self.refreshMs = refreshMs; self.tabs = tabs
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<PluginViewModel, T>) -> T { view[keyPath: keyPath] }

    private enum CodingKeys: String, CodingKey { case data, refreshMs, tabs }

    public init(from decoder: Decoder) throws {
        view = try PluginViewModel(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        refreshMs = c.lenient(Int.self, .refreshMs)
        data = c.lenient(PluginJSONValue.self, .data)
        tabs = (c.lenient([PluginLossy<PluginPageTab>].self, .tabs) ?? []).compactMap(\.value)
    }

    public func encode(to encoder: Encoder) throws {
        try view.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(data, forKey: .data)
        try c.encodeIfPresent(refreshMs, forKey: .refreshMs)
        if !tabs.isEmpty { try c.encode(tabs, forKey: .tabs) }
    }
}

/// One sibling page a page offers as a tab (`tabs[]`): its page id, its label and whether it is the one shown.
public struct PluginPageTab: Codable, Equatable, Hashable, Sendable {
    public let page: String
    public let label: String
    public let selected: Bool
    public init(page: String, label: String, selected: Bool = false) {
        self.page = page; self.label = label; self.selected = selected
    }
    private enum CodingKeys: String, CodingKey { case page, label, selected }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        page = try c.decode(String.self, forKey: .page)
        label = c.lenient(String.self, .label) ?? ""
        selected = c.lenient(Bool.self, .selected) ?? false
    }
}

/// What ``FlarePluginPage``'s `onAction(id, payload)` carries: the core SDK's page action request without the platform
/// and the gesture, so the host passes it to `invokePageAction` as it is.
public struct PluginPageActionPayload: Codable, Equatable, Sendable {
    public var page: PluginPageRef
    /// The view's `data`, when it has some.
    public var data: PluginJSONValue?
    public var row: PluginRowRef?
    public var selection: [Int]?
    public var formValues: [String: PluginJSONValue]?

    public init(page: PluginPageRef, data: PluginJSONValue? = nil, row: PluginRowRef? = nil, selection: [Int]? = nil,
                formValues: [String: PluginJSONValue]? = nil) {
        self.page = page; self.data = data; self.row = row; self.selection = selection; self.formValues = formValues
    }

    /// An action run on `page`'s view: the page, the view's data and what the action carries.
    public init(page: PluginPageRef, view: PluginPageViewModel?, payload: PluginActionPayload) {
        self.init(page: page, data: view?.data, row: payload.row, selection: payload.selection,
                  formValues: payload.formValues)
    }
}

/// Why a view is unavailable or read-only (`ResolvedPluginView.unavailableReason`, snake_case on the wire).
public enum PluginUnavailableReason: String, Codable, Sendable, CaseIterable {
    case disabled
    case notInstalled = "not_installed"
    case noPermission = "no_permission"
    case unsupportedPlatform = "unsupported_platform"
    case incompatibleVersion = "incompatible_version"
    case catalogUnreachable = "catalog_unreachable"
    /// A forged or forwarded copy of a card: drawn read-only (the core SDK has already stripped its actions).
    case unboundCopy = "unbound_copy"
    /// This build cannot draw it; the view's `minBuild` names the first one that can, when the plugin declared one
    /// (``FlarePluginUpgradeNotice``).
    case upgradeRequired = "upgrade_required"
}

/// A resolved plugin view (core SDK `ResolvedPluginView`). v1 cards (title, fields, actions) decode unchanged.
public struct PluginPresentation: Codable, Equatable, Sendable {
    public let renderer: String
    public let props: [String: PluginJSONValue]
    public let actions: [String: String]
}

public struct PluginViewModel: Codable, Equatable, Sendable {
    public let presentation: PluginPresentation?
    /// False: only the title shows (a disabled plugin, history).
    public let available: Bool
    public let title: String
    public let fields: [PluginViewField]
    /// Footer actions; block-owned actions are not here.
    public let actions: [PluginViewAction]
    /// Display blocks in order; kinds the kit does not know were skipped when decoding.
    public let blocks: [PluginBlock]
    /// Every input of the document; an action's `form` names the ones it collects.
    public let inputs: [PluginInput]
    /// The contribution has a detail view ("see all").
    public let detail: Bool
    /// A detail or page view's next page: the cursor the host asks the core SDK for (``PluginDetailSheetView`` and
    /// ``FlarePluginPage`` draw "load more" with it); nil (or blank) on the last page and on cards.
    public let nextCursor: String?
    /// Actions the plugin placed in the card's ⋯ menu, in order (`placement: "menu"`); run like the footer actions.
    public let menuActions: [PluginViewAction]
    /// Why the view is unavailable (`available` false) or a read-only copy (``PluginUnavailableReason/unboundCopy``).
    public let unavailableReason: PluginUnavailableReason?
    /// ``PluginUnavailableReason/upgradeRequired``: the first build that draws it, when the plugin declared one; the
    /// host asks `update.plugin_upgrade_status` with it.
    public let minBuild: Int64?

    public init(available: Bool, title: String, fields: [PluginViewField] = [], actions: [PluginViewAction] = [],
                blocks: [PluginBlock] = [], inputs: [PluginInput] = [], detail: Bool = false, nextCursor: String? = nil,
                menuActions: [PluginViewAction] = [], unavailableReason: PluginUnavailableReason? = nil, presentation: PluginPresentation? = nil,
                minBuild: Int64? = nil) {
        self.presentation = presentation
        self.minBuild = minBuild
        self.available = available; self.title = title; self.fields = fields; self.actions = actions
        self.blocks = blocks; self.inputs = inputs; self.detail = detail; self.nextCursor = nextCursor
        self.menuActions = menuActions; self.unavailableReason = unavailableReason
    }

    /// A forwarded or forged copy: its content draws, nothing on it acts.
    public var readOnly: Bool { unavailableReason == .unboundCopy }

    /// This build cannot draw it: the kit shows ``FlarePluginUpgradeNotice`` instead.
    public var upgradeRequired: Bool { !available && unavailableReason == .upgradeRequired }

    private enum CodingKeys: String, CodingKey {
        case available, title, fields, actions, blocks, inputs, detail, nextCursor, menuActions, unavailableReason, presentation
        case minBuild
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        presentation = c.lenient(PluginPresentation.self, .presentation)
        available = c.lenient(Bool.self, .available) ?? false
        title = c.lenient(String.self, .title) ?? ""
        fields = c.lenient([PluginViewField].self, .fields) ?? []
        actions = (c.lenient([PluginLossy<PluginViewAction>].self, .actions) ?? []).compactMap(\.value)
        blocks = (c.lenient([PluginLossy<PluginBlock>].self, .blocks) ?? []).compactMap(\.value)
        inputs = (c.lenient([PluginLossy<PluginInput>].self, .inputs) ?? []).compactMap(\.value)
        detail = c.lenient(Bool.self, .detail) ?? false
        // A blank cursor is the last page.
        nextCursor = c.lenient(String.self, .nextCursor).flatMap {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0
        }
        menuActions = (c.lenient([PluginLossy<PluginViewAction>].self, .menuActions) ?? []).compactMap(\.value)
        unavailableReason = c.lenient(PluginUnavailableReason.self, .unavailableReason)
        minBuild = flarePluginWhole(c.lenient(Double.self, .minBuild))
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(available, forKey: .available)
        try c.encode(title, forKey: .title)
        try c.encode(fields, forKey: .fields)
        try c.encode(actions, forKey: .actions)
        if !blocks.isEmpty { try c.encode(blocks, forKey: .blocks) }
        if !inputs.isEmpty { try c.encode(inputs, forKey: .inputs) }
        if detail { try c.encode(detail, forKey: .detail) }
        try c.encodeIfPresent(nextCursor, forKey: .nextCursor)
        if !menuActions.isEmpty { try c.encode(menuActions, forKey: .menuActions) }
        try c.encodeIfPresent(presentation, forKey: .presentation)
        try c.encodeIfPresent(unavailableReason, forKey: .unavailableReason)
        try c.encodeIfPresent(minBuild, forKey: .minBuild)
    }

    /// The inputs an action's form collects, in the order of `action.form`; ids the view does not hold are dropped.
    public func formInputs(for action: PluginViewAction) -> [PluginInput] {
        (action.form ?? []).compactMap { id in inputs.first { $0.id == id } }
    }

    /// The view's rows block, if it has one (a plugin page holds at most one).
    public var rowsBlock: PluginRowsBlock? {
        for block in blocks { if case .rows(let rows) = block { return rows } }
        return nil
    }
}

/// An array element that decodes to nil instead of failing the array.
struct PluginLossy<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws { value = try? T(from: decoder) }
}

/// The widest instant every kit can draw (ECMAScript `Date` range, spec rules.instant): later or earlier plugin data is
/// treated as absent instead of trapping the host.
let flarePluginInstantLimitMs: Double = 8_640_000_000_000_000

/// A plugin instant (ms since the epoch) as an exact `Int64`, or nil when it is not finite or outside
/// ±``flarePluginInstantLimitMs``.
func flarePluginInstant(_ value: Double?) -> Int64? {
    guard let value, value.isFinite, abs(value) <= flarePluginInstantLimitMs else { return nil }
    return Int64(exactly: value.rounded(.towardZero))
}

/// A non-negative whole number (a build) as an exact `Int64`, or nil when it is negative, not finite or too large.
func flarePluginWhole(_ value: Double?) -> Int64? {
    guard let value, value.isFinite, value >= 0 else { return nil }
    return Int64(exactly: value.rounded(.towardZero))
}

/// The longest single sleep of a ticking view (a day); it wakes, re-reads the clock and sleeps again, so a far-future
/// instant never overflows the nanosecond count.
let flarePluginMaxSleepMs: Int64 = 86_400_000

/// Sleeps `ms` milliseconds, at most ``flarePluginMaxSleepMs``.
func flarePluginSleep(ms: Int64) async {
    let bounded = UInt64(max(0, min(ms, flarePluginMaxSleepMs)))
    try? await Task.sleep(nanoseconds: bounded * 1_000_000)
}

extension KeyedDecodingContainer {
    /// The value at `key`, or nil when it is absent, null or of another type.
    func lenient<T: Decodable>(_ type: T.Type, _ key: Key) -> T? {
        (try? decodeIfPresent(type, forKey: key)) ?? nil
    }
}
