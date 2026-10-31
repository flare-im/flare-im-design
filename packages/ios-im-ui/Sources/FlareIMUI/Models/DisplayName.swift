import Foundation

/// Where a named value came from (`source` on the wire). For tests and diagnostics only: every source reads the same.
public enum FlareDisplayNameSource: String, Codable, Sendable, CaseIterable {
    case alias, memberNickname, profile, snapshot, remark, name
}

/// What an unnamed value is (`entity` on the wire), after the conversation type, or a person.
public enum FlareDisplayNameEntity: String, Codable, Sendable, CaseIterable {
    case person, group, system, ai, customer, channel, broadcast, temp
}

/// A name as the core SDK projects it — a conversation's `title` and `lastSender`, a message's `sender`, a
/// participant's or a contact's `name` — camelCase JSON on the wire, which `Codable` reads and writes and
/// ``init(json:)`` reads from JSON a host already decoded (a dictionary off an SDK bridge). Decoding never
/// fails: an unknown `entity` reads as `.person`, and an unknown `kind`, a form missing its text or a value that is not
/// an object as an unnamed person without an id tail (`displayNameUnknownUser`), so a core newer than the kit still
/// draws something sensible. The SDKs carry no copy: a name that is not known stays structured and every kit writes it with the same table
/// (`spec/display-name-vectors.json`) through ``flareDisplayNameText(_:strings:)``. Views keep string parameters; a
/// host turns the projected value into text where it hands it to one.
public enum FlareDisplayName: Equatable, Hashable, Sendable, Codable {
    /// A real name, drawn as it is.
    case named(text: String, source: FlareDisplayNameSource? = nil)
    /// A group without a name, by up to three of its named members (never the reader); `total` counts the reader.
    case members(names: [String], total: Int)
    /// Nothing to call it by: what it is, and for a person the tail of their id (``flareIdTail(_:)``).
    case unnamed(entity: FlareDisplayNameEntity, idTail: String = "")

    private enum CodingKeys: String, CodingKey { case kind, text, source, names, total, entity, idTail }

    public init(from decoder: Decoder) throws {
        let unknownUser = FlareDisplayName.unnamed(entity: .person, idTail: "")
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { self = unknownUser; return }
        func text(_ key: CodingKeys) -> String? { try? c.decodeIfPresent(String.self, forKey: key) }
        switch text(.kind) {
        case "named":
            guard let name = text(.text) else { self = unknownUser; return }
            self = .named(text: name, source: text(.source).flatMap(FlareDisplayNameSource.init(rawValue:)))
        case "members":
            // Strings only, as the other kits read the list; a count is truncated to a whole number.
            let names = (try? c.decodeIfPresent([PluginJSONValue].self, forKey: .names))?.compactMap(\.stringValue)
            let total = (try? c.decodeIfPresent(Double.self, forKey: .total)).flatMap { $0.magnitude < 1e15 ? Int($0) : nil }
            self = .members(names: names ?? [], total: total ?? 0)
        case "unnamed":
            self = .unnamed(entity: text(.entity).flatMap(FlareDisplayNameEntity.init(rawValue:)) ?? .person,
                            idTail: text(.idTail) ?? "")
        default:
            self = unknownUser
        }
    }

    /// Reads a name a host holds as decoded JSON — the dictionaries, arrays, strings and numbers of `JSONSerialization`,
    /// or the same built in Swift — by the rules of the `Codable` decoding: an unknown `entity` reads as `.person`; an
    /// unknown `kind`, a `named` value without text or a value that is not an object as an unnamed person without an id
    /// tail; an unknown `source` is dropped; `members` keeps its string names and its `total` truncated to a whole
    /// number. Nil only when there is no value (nil or `NSNull`), so a host can tell a name the SDK left out from one it
    /// sent.
    public init?(json value: Any?) {
        guard let value, !(value is NSNull) else { return nil }
        let unknownUser = FlareDisplayName.unnamed(entity: .person, idTail: "")
        guard let json = value as? [String: Any] else { self = unknownUser; return }
        func text(_ key: CodingKeys) -> String? { json[key.rawValue] as? String }
        switch text(.kind) {
        case "named":
            guard let name = text(.text) else { self = unknownUser; return }
            self = .named(text: name, source: text(.source).flatMap(FlareDisplayNameSource.init(rawValue:)))
        case "members":
            let names = (json[CodingKeys.names.rawValue] as? [Any])?.compactMap { $0 as? String }
            self = .members(names: names ?? [], total: Self.wholeNumber(json[CodingKeys.total.rawValue]) ?? 0)
        case "unnamed":
            self = .unnamed(entity: text(.entity).flatMap(FlareDisplayNameEntity.init(rawValue:)) ?? .person,
                            idTail: text(.idTail) ?? "")
        default:
            self = unknownUser
        }
    }

    /// A JSON number truncated to a whole number, as `Codable` reads `total`; nil for anything else (a boolean, text).
    private static func wholeNumber(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let total = number.doubleValue
        return total.magnitude < 1e15 ? Int(total) : nil
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .named(text, source):
            try c.encode("named", forKey: .kind)
            try c.encode(text, forKey: .text)
            try c.encodeIfPresent(source, forKey: .source)
        case let .members(names, total):
            try c.encode("members", forKey: .kind)
            try c.encode(names, forKey: .names)
            try c.encode(total, forKey: .total)
        case let .unnamed(entity, idTail):
            try c.encode("unnamed", forKey: .kind)
            try c.encode(entity, forKey: .entity)
            try c.encode(idTail, forKey: .idTail)
        }
    }
}

/// The tail of an id the kits show for a person without a name: the id trimmed of surrounding white space, then its
/// last 4 Unicode scalars — not grapheme clusters, so a combining mark counts — or the whole id when it has 4 or fewer;
/// a blank id gives "". The core SDK makes `idTail` with the same rule (`spec/display-name-vectors.json` idTail).
public func flareIdTail(_ id: String) -> String {
    let scalars = id.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars
    guard scalars.count > 4 else { return String(scalars) }
    return String(String.UnicodeScalarView(scalars.suffix(4)))
}

/// The text of a projected name (`spec/display-name-vectors.json`, the same on all four kits). `named` reads as it is;
/// `members` joins the non-blank names with `displayNameSeparator` and, when the group has more people than it names
/// besides the reader, adds `displayNameMembersMore(names, total, others)` — Chinese counts the group (total, the
/// reader included), English the others (total - names - 1) — and with no name left reads as an unnamed group; `unnamed` reads by entity — a person with an id tail `displayNameUser`, without one
/// `displayNameUnknownUser`, any other entity its own word.
public func flareDisplayNameText(_ name: FlareDisplayName, strings: FlareStrings) -> String {
    switch name {
    case let .named(text, _):
        return text
    case let .members(names, total):
        let shown = names.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !shown.isEmpty else { return strings.displayNameGroup }
        let joined = shown.joined(separator: strings.displayNameSeparator)
        let others = total - shown.count - 1
        return others > 0 ? strings.displayNameMembersMore(joined, total, others) : joined
    case let .unnamed(entity, idTail):
        switch entity {
        case .person: return idTail.isEmpty ? strings.displayNameUnknownUser : strings.displayNameUser(idTail)
        case .group: return strings.displayNameGroup
        case .system: return strings.displayNameSystem
        case .ai: return strings.displayNameAi
        case .customer: return strings.displayNameCustomer
        case .channel: return strings.displayNameChannel
        case .broadcast: return strings.displayNameBroadcast
        case .temp: return strings.displayNameTemp
        }
    }
}
