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
/// participant's or a contact's `name` — camelCase JSON on the wire, which `Codable` reads and writes. The SDKs carry no
/// copy: a name that is not known stays structured and every kit writes it with the same table
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
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(String.self, forKey: .kind) {
        case "named":
            self = .named(text: try c.decode(String.self, forKey: .text),
                          source: try? c.decodeIfPresent(FlareDisplayNameSource.self, forKey: .source))
        case "members":
            self = .members(names: try c.decodeIfPresent([String].self, forKey: .names) ?? [],
                            total: try c.decodeIfPresent(Int.self, forKey: .total) ?? 0)
        case "unnamed":
            self = .unnamed(entity: try c.decode(FlareDisplayNameEntity.self, forKey: .entity),
                            idTail: try c.decodeIfPresent(String.self, forKey: .idTail) ?? "")
        case let kind:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: c, debugDescription: "not a display name kind: \(kind)")
        }
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
/// besides the reader, adds `displayNameMembersMore` with N = total - names - 1, and with no name left reads as an
/// unnamed group; `unnamed` reads by entity — a person with an id tail `displayNameUser`, without one
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
        return others > 0 ? strings.displayNameMembersMore(joined, others) : joined
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
