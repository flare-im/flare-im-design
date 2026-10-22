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

/// A label/value row (v1 `fields`, and the `fields` block).
public struct PluginViewField: Codable, Equatable, Sendable {
    public let label: String; public let value: String
    public init(label: String, value: String) { self.label = label; self.value = value }
}

/// How an action key is drawn; none is the secondary key.
public enum PluginActionStyle: String, Codable, Sendable { case primary, danger }

/// A resolved action. Its `target` and `input` stay with the core: the kit hands back the opaque `id` only.
public struct PluginViewAction: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let style: PluginActionStyle?
    /// Asked first in the kit DangerConfirm.
    public let confirm: String?
    /// Input ids collected first in ``PluginFormView``.
    public let form: [String]?

    public init(id: String, label: String, style: PluginActionStyle? = nil, confirm: String? = nil, form: [String]? = nil) {
        self.id = id; self.label = label; self.style = style; self.confirm = confirm; self.form = form
    }

    private enum CodingKeys: String, CodingKey { case id, label, style, confirm, form }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        label = try c.decode(String.self, forKey: .label)
        style = c.lenient(String.self, .style).flatMap(PluginActionStyle.init(rawValue:))
        confirm = c.lenient(String.self, .confirm)
        form = c.lenient([String].self, .form)
    }
}

/// Semantic colour of a status, a note or a people group, drawn with the `*Text` tokens.
public enum PluginTone: String, Codable, Sendable {
    case neutral, info, success, warning, danger
    public init(from decoder: Decoder) throws {
        self = PluginTone(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .neutral
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
    public let action: PluginViewAction?
    public init(options: [PluginChoice], multiple: Bool = false, voted: Bool = false, closed: Bool = false,
                showResults: Bool = false, total: Int? = nil, inputName: String = "selection", action: PluginViewAction? = nil) {
        self.options = options; self.multiple = multiple; self.voted = voted; self.closed = closed
        self.showResults = showResults; self.total = total; self.inputName = inputName; self.action = action
    }
    private enum CodingKeys: String, CodingKey { case options, multiple, voted, closed, showResults, total, inputName, action }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        options = try c.decode([PluginChoice].self, forKey: .options)
        multiple = c.lenient(Bool.self, .multiple) ?? false
        voted = c.lenient(Bool.self, .voted) ?? false
        closed = c.lenient(Bool.self, .closed) ?? false
        showResults = c.lenient(Bool.self, .showResults) ?? false
        total = c.lenient(Int.self, .total)
        inputName = c.lenient(String.self, .inputName) ?? "selection"
        action = c.lenient(PluginViewAction.self, .action)
    }
    /// The indices the view says the viewer chose, ascending.
    public var selection: [Int] { options.filter(\.selected).map(\.index).sorted() }
}

/// One entry of an entries block; `index` is its position in the data, from 1.
public struct PluginEntry: Codable, Equatable, Sendable {
    public let index: Int
    public let text: String
    public let name: String?
    public let userId: String?
    public init(index: Int, text: String, name: String? = nil, userId: String? = nil) {
        self.index = index; self.text = text; self.name = name; self.userId = userId
    }
    private enum CodingKeys: String, CodingKey { case index, text, name, userId }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        index = c.lenient(Int.self, .index) ?? 0
        text = c.lenient(String.self, .text) ?? ""
        name = c.lenient(String.self, .name)
        userId = c.lenient(String.self, .userId)
    }
}

/// `entries`: a numbered list (a sign-up chain); `more` offers "see all" (the detail view).
public struct PluginEntriesBlock: Codable, Equatable, Sendable {
    public let items: [PluginEntry]
    public let numbered: Bool
    public let total: Int
    public let more: Bool
    public let emptyText: String?
    public init(items: [PluginEntry], numbered: Bool = true, total: Int? = nil, more: Bool = false, emptyText: String? = nil) {
        self.items = items; self.numbered = numbered; self.total = total ?? items.count; self.more = more
        self.emptyText = emptyText
    }
    private enum CodingKeys: String, CodingKey { case items, numbered, total, more, emptyText }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try c.decode([PluginEntry].self, forKey: .items)
        numbered = c.lenient(Bool.self, .numbered) ?? true
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
    public init(label: String? = nil, text: String, tone: PluginTone = .neutral) {
        self.label = label; self.text = text; self.tone = tone
    }
    private enum CodingKeys: String, CodingKey { case label, text, tone }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label)
        text = try c.decode(String.self, forKey: .text)
        tone = c.lenient(PluginTone.self, .tone) ?? .neutral
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
        guard let at = c.lenient(Double.self, .atMs) else {
            throw DecodingError.keyNotFound(CodingKeys.atMs, .init(codingPath: c.codingPath, debugDescription: "atMs"))
        }
        atMs = Int64(at)
        endMs = c.lenient(Double.self, .endMs).map { Int64($0) }
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

/// One display block, tagged by `kind`. `rows` (admin tables) is the Vue kit's only; a native kit skips it with any
/// kind it does not know.
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
        }
    }
}

/// Form input kinds (UiInput).
public enum PluginInputKind: String, Codable, Sendable, CaseIterable {
    case text, textarea, number, toggle, select, datetime, options, members
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

    public init(id: String, kind: PluginInputKind, label: String, required: Bool = false, placeholder: String? = nil,
                maxLength: Int? = nil, min: Double? = nil, max: Double? = nil, defaultValue: PluginJSONValue? = nil,
                choices: [PluginInputChoice]? = nil) {
        self.id = id; self.kind = kind; self.label = label; self.required = required; self.placeholder = placeholder
        self.maxLength = maxLength; self.min = min; self.max = max; self.defaultValue = defaultValue; self.choices = choices
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, label, required, placeholder, maxLength, min, max, choices
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

/// What `onAction(id, payload)` carries: the chosen option indices (ascending) or the form's values by input id.
public struct PluginActionPayload: Codable, Equatable, Sendable {
    public var selection: [Int]?
    public var formValues: [String: PluginJSONValue]?
    public init(selection: [Int]? = nil, formValues: [String: PluginJSONValue]? = nil) {
        self.selection = selection; self.formValues = formValues
    }
    public static let empty = PluginActionPayload()
}

/// A resolved plugin view (core SDK `ResolvedPluginView`). v1 cards (title, fields, actions) decode unchanged.
public struct PluginViewModel: Codable, Equatable, Sendable {
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
    /// A detail view's next page: the cursor the host asks the core SDK for (``PluginDetailSheetView`` draws "load
    /// more" with it); nil (or blank) on the last page and on cards.
    public let nextCursor: String?

    public init(available: Bool, title: String, fields: [PluginViewField] = [], actions: [PluginViewAction] = [],
                blocks: [PluginBlock] = [], inputs: [PluginInput] = [], detail: Bool = false, nextCursor: String? = nil) {
        self.available = available; self.title = title; self.fields = fields; self.actions = actions
        self.blocks = blocks; self.inputs = inputs; self.detail = detail; self.nextCursor = nextCursor
    }

    private enum CodingKeys: String, CodingKey { case available, title, fields, actions, blocks, inputs, detail, nextCursor }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
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
    }

    /// The inputs an action's form collects, in the order of `action.form`; ids the view does not hold are dropped.
    public func formInputs(for action: PluginViewAction) -> [PluginInput] {
        (action.form ?? []).compactMap { id in inputs.first { $0.id == id } }
    }
}

/// An array element that decodes to nil instead of failing the array.
struct PluginLossy<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws { value = try? T(from: decoder) }
}

extension KeyedDecodingContainer {
    /// The value at `key`, or nil when it is absent, null or of another type.
    func lenient<T: Decodable>(_ type: T.Type, _ key: Key) -> T? {
        (try? decodeIfPresent(type, forKey: key)) ?? nil
    }
}
