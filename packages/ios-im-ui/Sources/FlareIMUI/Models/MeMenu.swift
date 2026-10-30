import Foundation

/// Where a 我 page menu item comes from: one of the app's own pages, or a plugin's account entry.
public enum FlareMeMenuItemKind: String, Sendable, Codable {
    case builtin, plugin
}

/// One item of the social SDK's `features.meMenu` result. Decoding reads the SDK JSON as given and ignores the
/// fields the kit does not draw (`target`, `summary`, `contributionId`); the host keeps the SDK value for dispatch.
public struct FlareMeMenuItem: Sendable, Equatable, Decodable {
    public let kind: FlareMeMenuItemKind
    public let id: String
    public let icon: String?
    public let title: String?
    public let order: Int

    public init(kind: FlareMeMenuItemKind, id: String, icon: String? = nil, title: String? = nil, order: Int = 0) {
        self.kind = kind; self.id = id; self.icon = icon; self.title = title; self.order = order
    }

    private enum CodingKeys: String, CodingKey { case kind, id, icon, title, order }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(FlareMeMenuItemKind.self, forKey: .kind)
        id = try c.decode(String.self, forKey: .id)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        order = (try? c.decodeIfPresent(Int.self, forKey: .order)) ?? 0
    }
}

/// The social SDK's `features.meMenu` result: the items in the SDK's order, and whether the list is complete
/// (`complete: false` while plugin entries could not all be read; the host decides when to read it again).
public struct FlareMeMenu: Sendable, Equatable, Decodable {
    public let items: [FlareMeMenuItem]
    public let complete: Bool

    public init(items: [FlareMeMenuItem], complete: Bool = true) {
        self.items = items; self.complete = complete
    }

    private enum CodingKeys: String, CodingKey { case items, complete }

    /// An item whose kind is neither `builtin` nor `plugin` (a kind from a newer SDK) is dropped, not an error.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try c.decodeIfPresent([Lossy].self, forKey: .items) ?? []
        items = raw.compactMap(\.item)
        complete = (try? c.decodeIfPresent(Bool.self, forKey: .complete)) ?? false
    }

    /// The SDK's JSON text; nil when it is not a menu.
    public static func parse(_ json: String) -> FlareMeMenu? {
        try? JSONDecoder().decode(FlareMeMenu.self, from: Data(json.utf8))
    }

    private struct Lossy: Decodable {
        let item: FlareMeMenuItem?
        init(from decoder: Decoder) throws { item = try? FlareMeMenuItem(from: decoder) }
    }
}

/// The built-in items the kit knows, with their copy.
private func flareMeMenuBuiltinLabel(_ id: String, _ strings: FlareStrings) -> String? {
    switch id {
    case "moments": return strings.meMenuMoments
    case "reports": return strings.meMenuReports
    case "invite": return strings.meMenuInvite
    case "settings": return strings.meMenuSettings
    default: return nil
    }
}

/// The 我 page menu as settings sections (spec/me-menu-vectors.json), the same function on every kit:
///
/// - Section one holds every item but `settings`, in the SDK's order (the SDK orders the menu; the kit never sorts by
///   `order`); `settings` alone is section two, last. An empty section is left out.
/// - A built-in item's label is `labels[id]`, else the kit copy (`meMenuMoments`, `meMenuReports`, `meMenuInvite`,
///   `meMenuSettings`); a built-in id the kit does not know is dropped.
/// - A plugin item's label is its title trimmed, else `meMenuPluginFallback`.
/// - An item's detail is `summaries[id]` trimmed, when not empty: a plugin item's `features.meMenuSummary` text, or the
///   host's subtitle for a built-in page (what 我的邀请 holds).
/// - The icon goes through ``flareIconNameOrFallback(_:)``; an item without one draws `plugin`.
/// - Of two items with one id the first is kept. Every row is a navigation row keyed by the item's id.
///
/// The host still dispatches by key (its own route for a built-in item, ``FlarePluginPage`` for a plugin item) and
/// decides when to read the menu again.
public func flareMeMenuSections(_ menu: FlareMeMenu, labels: [String: String] = [:],
                                summaries: [String: String] = [:],
                                strings: FlareStrings = FlareStrings()) -> [FlareSettingsSection] {
    var seen = Set<String>()
    var main: [FlareSettingsItem] = []
    var settings: [FlareSettingsItem] = []
    for item in menu.items where seen.insert(item.id).inserted {
        let label: String
        switch item.kind {
        case .builtin:
            guard let copy = flareMeMenuBuiltinLabel(item.id, strings) else { continue }
            label = labels[item.id] ?? copy
        case .plugin:
            let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            label = title.isEmpty ? strings.meMenuPluginFallback : title
        }
        let summary = summaries[item.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let detail: String? = summary.isEmpty ? nil : summary
        let row = FlareSettingsItem(key: item.id, label: label, icon: flareIconNameOrFallback(item.icon) ?? "plugin",
                                    kind: .navigation, detail: detail)
        if item.kind == .builtin, item.id == "settings" { settings.append(row) } else { main.append(row) }
    }
    return [main, settings].filter { !$0.isEmpty }.map { FlareSettingsSection(items: $0) }
}
