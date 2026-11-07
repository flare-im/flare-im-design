import Foundation
import SwiftUI

// What a resource pack may change, the same on four kits (`spec/resource-overlay-vectors.json`). A pack is data read by
// code already in the build: it replaces copy and colours that exist and adds emoji, and nothing else.

let flareResourceSchema = "flare.resource.v1"

private let placeholderPattern = try! NSRegularExpression(pattern: "\\{[A-Za-z0-9_]+\\}|%[sd@]")
private let colorPattern = "^#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?$"
private let safeIdPattern = "^[A-Za-z0-9_-]+$"
private let emojiKeyPattern = "^[a-z][a-z0-9_]*$"
private let httpsURLPattern = "^https://[A-Za-z0-9.-]+(?::[0-9]+)?(?:[/?#][!-~]*)?$"

/// Whether `pattern` covers all of `value`. `$` alone also stops before a final line break.
private func wholly(_ value: String, _ pattern: String) -> Bool {
    value.range(of: pattern, options: .regularExpression) == value.startIndex..<value.endIndex
}

/// One entry of `update.get_resources`, as the SDK returns it.
public struct FlareResourcePack: Sendable {
    public let id: String
    public let kind: String
    public let packVersion: Int64
    public let contentJson: String

    public init(id: String, kind: String, packVersion: Int64 = 0, contentJson: String) {
        self.id = id
        self.kind = kind
        self.packVersion = packVersion
        self.contentJson = contentJson
    }
}

struct FlareResourceEmoji: Equatable {
    var key: String
    var url: String
    var previewUrl: String?
    var labels: [String: String] = [:]
}

struct FlareResourceSticker: Equatable {
    var stickerId: String
    var url: String
    var previewUrl: String?
    var alt: String?
}

struct FlareResourceStickerPack: Equatable {
    var id: String
    var title: String
    var iconUrl: String?
    var stickers: [FlareResourceSticker]
}

struct FlareResourceEmojiResult: Equatable {
    var emoji: [FlareResourceEmoji] = []
    var stickerPacks: [FlareResourceStickerPack] = []
}

/// The pack's content when it is the object its manifest entry promised, else nil.
func flareResourceContent(kind: String, contentJson: String) -> [String: Any]? {
    guard let data = contentJson.data(using: .utf8),
          let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          parsed["schema"] as? String == flareResourceSchema,
          parsed["kind"] as? String == kind else { return nil }
    return parsed
}

/// The placeholders `text` carries, as a sorted set.
func flareResourcePlaceholders(_ text: String) -> [String] {
    let ns = text as NSString
    let found = placeholderPattern
        .matches(in: text, range: NSRange(location: 0, length: ns.length))
        .map { ns.substring(with: $0.range) }
    return Set(found).sorted()
}

private func filled(_ value: Any?) -> String? {
    guard let text = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
    return text
}

/// The entries of one language that may replace the built-in text `builtIn` answers for each key.
func flareResourceStrings(builtIn: (String) -> String?, entries: Any?) -> [String: String] {
    guard let entries = entries as? [String: Any] else { return [:] }
    var accepted: [String: String] = [:]
    for (key, value) in entries {
        guard let current = builtIn(key), let text = value as? String, filled(text) != nil else { continue }
        if flareResourcePlaceholders(current) == flareResourcePlaceholders(text) { accepted[key] = text }
    }
    return accepted
}

private func normalizedTag(_ tag: String) -> String {
    tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "_", with: "-")
}

/// The tag of `available` that speaks for `requested`, or nil: copy never crosses into another language.
func flareResourceLocale(_ requested: String, available: [String]) -> String? {
    let wanted = normalizedTag(requested)
    guard !wanted.isEmpty else { return nil }
    let tags = available.map { (normalizedTag($0), $0) }.sorted { $0.0 < $1.0 }
    var cut = wanted
    while !cut.isEmpty {
        if let exact = tags.first(where: { $0.0 == cut }) { return exact.1 }
        cut = cut.lastIndex(of: "-").map { String(cut[..<$0]) } ?? ""
    }
    return tags.first { $0.0.hasPrefix(wanted + "-") }?.1
}

/// The colours of one group whose key is known and whose value is `#RRGGBB` or `#RRGGBBAA`.
func flareResourceColors(known: Set<String>, group: Any?) -> [String: String] {
    guard let group = group as? [String: Any] else { return [:] }
    var accepted: [String: String] = [:]
    for (key, value) in group {
        if known.contains(key), let text = value as? String, wholly(text, colorPattern) { accepted[key] = text }
    }
    return accepted
}

/// A colour the rules accepted as `0xAARRGGBB`: `#RRGGBB` is opaque, `#RRGGBBAA` puts its alpha first.
func flareResourceColorArgb(_ value: String) -> UInt32 {
    let digits = value.dropFirst()
    let rgb = UInt32(digits.prefix(6), radix: 16) ?? 0
    let alpha = digits.count == 8 ? UInt32(digits.suffix(2), radix: 16) ?? 0 : 0xFF
    return alpha << 24 | rgb
}

private func flareResourceColor(_ value: String) -> Color {
    let argb = flareResourceColorArgb(value)
    let channel = { (shift: UInt32) in Double((argb >> shift) & 0xFF) / 255 }
    return Color(.sRGB, red: channel(16), green: channel(8), blue: channel(0), opacity: channel(24))
}

private func isHttps(_ value: Any?) -> Bool {
    guard let text = value as? String else { return false }
    return wholly(text, httpsURLPattern)
}

/// JSON null reads as absent, as a missing key does.
private func present(_ value: Any?) -> Any? {
    value is NSNull ? nil : value
}

/// An image address an entry can keep: absent, or https.
private func optionalURLOK(_ value: Any?) -> Bool {
    present(value) == nil || isHttps(value)
}

private func stickerOf(_ raw: Any, seen: inout Set<String>) -> FlareResourceSticker? {
    guard let raw = raw as? [String: Any],
          let id = raw["stickerId"] as? String, wholly(id, safeIdPattern), !seen.contains(id),
          isHttps(raw["url"]), optionalURLOK(raw["previewUrl"]),
          let url = raw["url"] as? String else { return nil }
    seen.insert(id)
    return FlareResourceSticker(stickerId: id, url: url, previewUrl: present(raw["previewUrl"]) as? String, alt: filled(raw["alt"]))
}

private func emojiOf(_ raw: Any, seen: inout Set<String>) -> FlareResourceEmoji? {
    guard let raw = raw as? [String: Any],
          let key = raw["key"] as? String, wholly(key, emojiKeyPattern), !seen.contains(key),
          isHttps(raw["url"]), optionalURLOK(raw["previewUrl"]),
          let url = raw["url"] as? String else { return nil }
    seen.insert(key)
    var labels: [String: String] = [:]
    for (tag, label) in raw["labels"] as? [String: Any] ?? [:] {
        if let text = filled(label) { labels[tag] = text }
    }
    return FlareResourceEmoji(key: key, url: url, previewUrl: present(raw["previewUrl"]) as? String, labels: labels)
}

/// The emoji and sticker packs that add to the catalog. Nothing here replaces what ships with the kit.
func flareResourceEmoji(builtInEmoji: [String], builtInPacks: [String], packs: Any?) -> FlareResourceEmojiResult {
    var result = FlareResourceEmojiResult()
    guard let packs = packs as? [Any] else { return result }
    var seenKeys = Set(builtInEmoji)
    var seenPacks = Set(builtInPacks)
    for raw in packs {
        guard let raw = raw as? [String: Any],
              let id = raw["id"] as? String, wholly(id, safeIdPattern), !seenPacks.contains(id),
              let title = filled(raw["title"]), optionalURLOK(raw["iconUrl"]) else { continue }
        var seenStickers = Set<String>()
        let stickers = (raw["stickers"] as? [Any] ?? []).compactMap { stickerOf($0, seen: &seenStickers) }
        let entries = (raw["emoji"] as? [Any] ?? []).compactMap { emojiOf($0, seen: &seenKeys) }
        if stickers.isEmpty && entries.isEmpty { continue }
        seenPacks.insert(id)
        result.emoji += entries
        if !stickers.isEmpty {
            result.stickerPacks.append(FlareResourceStickerPack(
                id: id, title: title, iconUrl: present(raw["iconUrl"]) as? String, stickers: stickers))
        }
    }
    return result
}

/// The resource packs of this run, folded over what ships with the kit. Build it from `update.get_resources`, keep it in
/// the root's state, and pass what it returns to the existing environment:
///
/// ```swift
/// content
///     .flareStrings(overlay.strings(.english, locale: "en"))
///     .flareTheme(mode: mode, brand: overlay.brandTheme(.violet))
/// ```
///
/// An entry or a pack the rules refuse is left out and the rest stands; this never throws. A help pack is the host's.
/// Holds parsed JSON and never changes it, which is why it can be shared.
public struct FlareResourceOverlay: @unchecked Sendable {
    private var stringPacks: [[String: Any]] = []
    private var tokenPacks: [[String: Any]] = []
    private var emojiPacks: [Any] = []
    private var tokenRevision = ""

    /// No packs: what a root starts from, before the packs are read.
    public static let empty = FlareResourceOverlay(packs: [])

    public init(packs: [FlareResourcePack]) {
        for pack in packs {
            guard let content = flareResourceContent(kind: pack.kind, contentJson: pack.contentJson) else { continue }
            switch pack.kind {
            case "strings":
                if let locales = content["locales"] as? [String: Any] { stringPacks.append(locales) }
            case "tokens":
                tokenPacks.append(content)
                tokenRevision += "+\(pack.id).\(pack.packVersion)"
            case "emoji":
                emojiPacks += content["packs"] as? [Any] ?? []
            default:
                break
            }
        }
    }

    public var isEmpty: Bool { stringPacks.isEmpty && tokenPacks.isEmpty && emojiPacks.isEmpty }

    /// What the strings packs say for `locale`, in pack order: a later pack wins a key. `builtIn` answers for a table's
    /// keys, so a host's own table takes its entries under the same rules: a known key, the same placeholders.
    public func stringValues(locale: String, builtIn: (String) -> String?) -> [String: String] {
        var accepted: [String: String] = [:]
        for locales in stringPacks {
            guard let tag = flareResourceLocale(locale, available: Array(locales.keys)) else { continue }
            accepted.merge(flareResourceStrings(builtIn: builtIn, entries: locales[tag])) { _, later in later }
        }
        return accepted
    }

    /// One mode's colours, in pack order: a later pack wins a key. `colors` is light and `dark` dark; neither reaches
    /// the other.
    func colorValues(dark: Bool, known: Set<String>) -> [String: String] {
        var accepted: [String: String] = [:]
        for pack in tokenPacks {
            accepted.merge(flareResourceColors(known: known, group: pack[dark ? "dark" : "colors"])) { _, later in later }
        }
        return accepted
    }

    /// `base` with what the packs say for `locale`, the language `base` is written in.
    public func strings(_ base: FlareStrings, locale: String) -> FlareStrings {
        var folded = base
        for (key, value) in stringValues(locale: locale, builtIn: { base.stringValue(forKey: $0) }) {
            folded.setStringValue(value, forKey: key)
        }
        return folded
    }

    /// `base`, a theme's colours for that mode, with what the packs set for it.
    public func colors(_ base: FlareColors, dark: Bool) -> FlareColors {
        let accepted = colorValues(dark: dark, known: flareColorKeys)
        return accepted.isEmpty ? base : base.applying(accepted.mapValues(flareResourceColor))
    }

    /// `base` with what the packs set for both modes. It takes a name of its own: brands compare by name, so the
    /// environment would not see new colours under the old one and what is on screen would keep them.
    public func brandTheme(_ base: FlareBrandTheme) -> FlareBrandTheme {
        guard !colorValues(dark: false, known: flareColorKeys).isEmpty
            || !colorValues(dark: true, known: flareColorKeys).isEmpty else { return base }
        return FlareBrandTheme(
            name: base.name + tokenRevision,
            light: colors(base.light, dark: false),
            dark: colors(base.dark, dark: true)
        )
    }

    /// Adds the packs' emoji and stickers to `catalog`. Publishes the catalog's revision, so it runs on the main actor.
    @MainActor
    public func registerEmoji(in catalog: FlareEmojiStickerCatalog = .shared) {
        guard !emojiPacks.isEmpty else { return }
        let result = flareResourceEmoji(
            builtInEmoji: catalog.bundledEmojiKeys(),
            builtInPacks: catalog.bundledStickerPackIds(),
            packs: emojiPacks
        )
        if !result.emoji.isEmpty {
            catalog.registerEmojiAssets(result.emoji.compactMap { item in
                URL(string: item.url).map { FlareEmojiAssetRegistration(key: item.key, animatedURL: $0, labels: item.labels) }
            })
        }
        if !result.stickerPacks.isEmpty {
            catalog.registerStickerPacks(result.stickerPacks.map { pack in
                FlareStickerPackRegistration(id: pack.id, title: pack.title, stickers: pack.stickers.compactMap { item in
                    URL(string: item.url).map { FlareStickerAssetRegistration(stickerId: item.stickerId, url: $0) }
                })
            })
        }
    }
}
