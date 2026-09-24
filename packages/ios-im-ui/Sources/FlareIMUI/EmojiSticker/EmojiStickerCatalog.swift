import Foundation
import ImageIO
import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias FlarePlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias FlarePlatformImage = NSImage
#endif

/// Decoded animated-webp frames + per-frame durations (empty durations ⇒ static).
public struct FlareAnimatedFrames {
    public let frames: [FlarePlatformImage]
    public let durations: [Double]
    public var isAnimated: Bool { frames.count > 1 }
}

enum FlareAnimatedImageBudget {
    static let encodedBytes = 8 * 1024 * 1024
    static let decodedBytes = 32 * 1024 * 1024
    static let sourceDimension = 4096
    static let thumbnailDimension = 256
    static let frameCount = 180
}

/// Decodes bounded thumbnail frames via ImageIO. Oversized animations fall back
/// to a static first frame; invalid or oversized sources return nil.
public func flareDecodeAnimatedWebp(url: URL?) -> FlareAnimatedFrames? {
    flareDecodeAnimatedFile(url: url)
}

func flareDecodeAnimatedFile(url: URL?, firstFrameOnly: Bool = false) -> FlareAnimatedFrames? {
    flareDecodeFileFrames(url: url, firstFrameOnly: firstFrameOnly)?.platformFrames
}

private func flareDecodeFileFrames(url: URL?, firstFrameOnly: Bool) -> FlareDecodedFrames? {
    guard let url, url.isFileURL,
          let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
          size <= FlareAnimatedImageBudget.encodedBytes,
          let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return flareDecodeAnimatedSource(source, firstFrameOnly: firstFrameOnly)
}

func flareDecodeAnimatedData(_ data: Data, firstFrameOnly: Bool = false) -> FlareAnimatedFrames? {
    flareDecodeDataFrames(data, firstFrameOnly: firstFrameOnly)?.platformFrames
}

private func flareDecodeDataFrames(_ data: Data, firstFrameOnly: Bool) -> FlareDecodedFrames? {
    guard data.count <= FlareAnimatedImageBudget.encodedBytes,
          let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    return flareDecodeAnimatedSource(source, firstFrameOnly: firstFrameOnly)
}

// ImageIO work is serialized off the UI actor; platform wrappers stay on the caller.
private struct FlareDecodedFrames: Sendable {
    let frames: [CGImage]
    let durations: [Double]

    var platformFrames: FlareAnimatedFrames {
        FlareAnimatedFrames(frames: frames.map { image in
            #if canImport(UIKit)
            UIImage(cgImage: image)
            #else
            NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height))
            #endif
        }, durations: durations)
    }
}

private actor FlareAnimatedDecoder {
    static let shared = FlareAnimatedDecoder()

    func decode(url: URL?, firstFrameOnly: Bool) -> FlareDecodedFrames? {
        guard !Task.isCancelled else { return nil }
        return flareDecodeFileFrames(url: url, firstFrameOnly: firstFrameOnly)
    }

    func decode(data: Data, firstFrameOnly: Bool) -> FlareDecodedFrames? {
        guard !Task.isCancelled else { return nil }
        return flareDecodeDataFrames(data, firstFrameOnly: firstFrameOnly)
    }
}

@MainActor
func flareDecodeAnimatedFileAsync(url: URL?, firstFrameOnly: Bool = false) async -> FlareAnimatedFrames? {
    let result = await FlareAnimatedDecoder.shared.decode(url: url, firstFrameOnly: firstFrameOnly)
    guard !Task.isCancelled else { return nil }
    return result?.platformFrames
}

@MainActor
func flareDecodeAnimatedDataAsync(_ data: Data, firstFrameOnly: Bool = false) async -> FlareAnimatedFrames? {
    let result = await FlareAnimatedDecoder.shared.decode(data: data, firstFrameOnly: firstFrameOnly)
    guard !Task.isCancelled else { return nil }
    return result?.platformFrames
}

private func flareDecodeAnimatedSource(_ source: CGImageSource, firstFrameOnly: Bool = false) -> FlareDecodedFrames? {
    let count = CGImageSourceGetCount(source)
    guard count > 0 else { return nil }
    var frames: [CGImage] = []
    var durations: [Double] = []
    var decodedBytes = 0
    let limit = firstFrameOnly || count > FlareAnimatedImageBudget.frameCount ? 1 : count
    for i in 0..<limit {
        guard !Task.isCancelled else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0,
              width <= FlareAnimatedImageBudget.sourceDimension,
              height <= FlareAnimatedImageBudget.sourceDimension else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: FlareAnimatedImageBudget.thumbnailDimension,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, i, options as CFDictionary) else { continue }
        decodedBytes += cg.bytesPerRow * cg.height
        if decodedBytes > FlareAnimatedImageBudget.decodedBytes {
            return frames.first.map { FlareDecodedFrames(frames: [$0], durations: [0.1]) }
        }
        frames.append(cg)
        var delay = 0.1
        if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any] {
            for (key, unclamped, clamped) in [
                (kCGImagePropertyWebPDictionary, kCGImagePropertyWebPUnclampedDelayTime, kCGImagePropertyWebPDelayTime),
                (kCGImagePropertyGIFDictionary, kCGImagePropertyGIFUnclampedDelayTime, kCGImagePropertyGIFDelayTime),
            ] {
                if let values = props[key] as? [CFString: Any],
                   let d = (values[unclamped] ?? values[clamped]) as? Double, d.isFinite, d > 0 {
                    delay = min(10, max(0.02, d))
                }
            }
        }
        durations.append(delay)
    }
    return frames.isEmpty ? nil : FlareDecodedFrames(frames: frames, durations: durations)
}

/// One sticker pack from the manifest.
public struct FlareStickerPack: Sendable, Identifiable {
    public let id: String       // protocol packageId (e.g. `gifs`, `classic`)
    public let dir: String      // e.g. `stickers/default`
    public let title: String
    public let stickerIds: [String]
}

/// Per-user emoji resource. The original [animatedURL] is only consumed by a
/// standalone sent emoji. Editing, inline and picker surfaces decode the first
/// frame from [staticPreviewData] (or the original URL when omitted).
public struct FlareEmojiAssetRegistration: Sendable {
    public let key: String
    public let animatedURL: URL
    public let staticPreviewData: Data?
    public let labels: [String: String]

    public init(key: String, animatedURL: URL, staticPreviewData: Data? = nil,
                labels: [String: String] = [:]) {
        self.key = key
        self.animatedURL = animatedURL
        self.staticPreviewData = staticPreviewData
        self.labels = labels
    }
}

public struct FlareStickerAssetRegistration: Sendable {
    public let stickerId: String
    public let url: URL
    public let staticPreviewData: Data?

    public init(stickerId: String, url: URL, staticPreviewData: Data? = nil) {
        self.stickerId = stickerId
        self.url = url
        self.staticPreviewData = staticPreviewData
    }
}

public struct FlareStickerPackRegistration: Sendable {
    public let id: String
    public let title: String
    public let stickers: [FlareStickerAssetRegistration]

    public init(id: String, title: String, stickers: [FlareStickerAssetRegistration]) {
        self.id = id
        self.title = title
        self.stickers = stickers
    }
}

/// Cross-platform emoji-pack + sticker catalog, backed by the flare-im-design
/// manifest bundled with this package (a committed mirror of the single source
/// `flare-im-design/assets/emoji-sticker`; see sync-resources.sh).
///
/// Resources load synchronously from `Bundle.module` on first access, so views
/// stay pure. Message views resolve assets by path convention; the picker + the
/// localized labels use the loaded manifest.
public final class FlareEmojiStickerCatalog: ObservableObject, @unchecked Sendable {
    public static let shared = FlareEmojiStickerCatalog()

    public static let resourceRoot = "emoji-sticker"
    public static let stickerPackageGifs = "gifs"

    private let lock = NSLock()
    private var loaded = false
    public private(set) var emojiKeys: [String] = []
    private var emojiKeySet: Set<String> = []
    public private(set) var stickerPacks: [FlareStickerPack] = []
    private var locales: [String: [String: String]] = [:]
    private var runtimeEmoji: [String: FlareEmojiAssetRegistration] = [:]
    private var runtimeStickerPacks: [String: FlareStickerPackRegistration] = [:]
    private let imageCache = NSCache<NSURL, FlarePlatformImage>()
    @Published public private(set) var revision = 0

    private init() {
        imageCache.countLimit = 128
        imageCache.totalCostLimit = FlareAnimatedImageBudget.decodedBytes
    }

    private func ensureLoaded() {
        lock.lock(); defer { lock.unlock() }
        if loaded { return }
        loaded = true

        guard let manifestURL = Self.resourceURL(name: "manifest", ext: "json", subdir: Self.resourceRoot),
              let data = try? Data(contentsOf: manifestURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        if let emoji = json["emoji"] as? [String: Any], let keys = emoji["keys"] as? [String] {
            emojiKeys = keys
            emojiKeySet = Set(keys)
        }
        if let packs = json["stickerPacks"] as? [[String: Any]] {
            stickerPacks = packs.map { p in
                let items = (p["items"] as? [[String: Any]]) ?? []
                return FlareStickerPack(
                    id: p["id"] as? String ?? "",
                    dir: p["dir"] as? String ?? "",
                    title: p["title"] as? String ?? "",
                    stickerIds: items.compactMap { $0["id"] as? String }
                )
            }
        }
        if let localesURL = Self.resourceURL(name: "emoji-locales", ext: "json", subdir: Self.resourceRoot),
           let ldata = try? Data(contentsOf: localesURL),
           let ljson = try? JSONSerialization.jsonObject(with: ldata) as? [String: [String: String]] {
            locales = ljson
        }
    }

    public var isLoaded: Bool { ensureLoaded(); return loaded }

    public func loadedEmojiKeys() -> [String] {
        ensureLoaded()
        lock.lock(); defer { lock.unlock() }
        return emojiKeys.filter { runtimeEmoji[$0] == nil } + runtimeEmoji.keys.sorted()
    }

    public func loadedStickerPacks() -> [FlareStickerPack] {
        ensureLoaded()
        lock.lock(); defer { lock.unlock() }
        return stickerPacks.filter { runtimeStickerPacks[$0.id] == nil } + runtimeStickerPacks.values
            .sorted { $0.id < $1.id }
            .map { FlareStickerPack(id: $0.id, dir: "", title: $0.title,
                                    stickerIds: $0.stickers.map(\.stickerId)) }
    }

    public func hasEmojiKey(_ key: String) -> Bool {
        ensureLoaded()
        let normalized = key.trimmingCharacters(in: .whitespaces)
        lock.lock(); defer { lock.unlock() }
        return runtimeEmoji[normalized] != nil || emojiKeySet.contains(normalized)
    }

    /// On-disk sticker subdir for a protocol packageId (`gifs` → `default`).
    public static func stickerSubdir(forPackageId packageId: String?) -> String {
        let p = (packageId ?? "").trimmingCharacters(in: .whitespaces)
        return (p.isEmpty || p == stickerPackageGifs) ? "default" : p
    }

    private static func resourceURL(name: String, ext: String, subdir: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: ext, subdirectory: subdir)
    }

    /// Guards asset lookups against path traversal / injection from untrusted keys/ids.
    private static func isSafeComponent(_ value: String) -> Bool {
        !value.isEmpty && value.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil
    }

    private static func isEmojiKey(_ value: String) -> Bool {
        value.range(of: "^[a-z][a-z0-9_]*$", options: .regularExpression) != nil
    }

    /// Adds or replaces account-scoped emoji assets while keeping `[key]` as
    /// the storage/wire value. Call the clear method on account switch.
    public func registerEmojiAssets(_ assets: [FlareEmojiAssetRegistration]) {
        ensureLoaded()
        lock.lock()
        for asset in assets {
            let key = asset.key.trimmingCharacters(in: .whitespaces)
            guard Self.isEmojiKey(key),
                  (asset.staticPreviewData?.count ?? 0) <= FlareAnimatedImageBudget.encodedBytes else { continue }
            runtimeEmoji[key] = FlareEmojiAssetRegistration(
                key: key, animatedURL: asset.animatedURL,
                staticPreviewData: asset.staticPreviewData, labels: asset.labels
            )
        }
        lock.unlock()
        revision &+= 1
    }

    public func unregisterEmojiAsset(_ key: String) {
        lock.lock(); let removed = runtimeEmoji.removeValue(forKey: key.trimmingCharacters(in: .whitespaces)); lock.unlock()
        if removed != nil { revision &+= 1 }
    }

    public func clearRegisteredEmojiAssets() {
        lock.lock(); let changed = !runtimeEmoji.isEmpty; runtimeEmoji.removeAll(); lock.unlock()
        if changed { revision &+= 1 }
    }

    public func registerStickerPacks(_ packs: [FlareStickerPackRegistration]) {
        ensureLoaded()
        lock.lock()
        for pack in packs {
            let id = pack.id.trimmingCharacters(in: .whitespaces)
            guard Self.isSafeComponent(id), !pack.title.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let stickers = pack.stickers.filter {
                Self.isSafeComponent($0.stickerId.trimmingCharacters(in: .whitespaces)) &&
                    ($0.staticPreviewData?.count ?? 0) <= FlareAnimatedImageBudget.encodedBytes
            }.map {
                FlareStickerAssetRegistration(
                    stickerId: $0.stickerId.trimmingCharacters(in: .whitespaces),
                    url: $0.url, staticPreviewData: $0.staticPreviewData
                )
            }
            runtimeStickerPacks[id] = FlareStickerPackRegistration(
                id: id, title: pack.title.trimmingCharacters(in: .whitespaces), stickers: stickers
            )
        }
        lock.unlock()
        revision &+= 1
    }

    public func unregisterStickerPack(_ packageId: String) {
        lock.lock(); let removed = runtimeStickerPacks.removeValue(forKey: packageId.trimmingCharacters(in: .whitespaces)); lock.unlock()
        if removed != nil { revision &+= 1 }
    }

    public func clearRegisteredStickerPacks() {
        lock.lock(); let changed = !runtimeStickerPacks.isEmpty; runtimeStickerPacks.removeAll(); lock.unlock()
        if changed { revision &+= 1 }
    }

    public func emojiImageURL(_ key: String) -> URL? {
        let k = key.trimmingCharacters(in: .whitespaces)
        guard Self.isSafeComponent(k) else { return nil }
        lock.lock(); let runtime = runtimeEmoji[k]?.animatedURL; lock.unlock()
        if let runtime { return runtime }
        return Self.resourceURL(name: k, ext: "webp", subdir: "\(Self.resourceRoot)/emoji")
    }

    public func stickerImageURL(stickerId: String, packageId: String?) -> URL? {
        let sid = stickerId.trimmingCharacters(in: .whitespaces)
        let subdir = Self.stickerSubdir(forPackageId: packageId)
        guard Self.isSafeComponent(sid), Self.isSafeComponent(subdir) else { return nil }
        let runtimePackageId = (packageId ?? "").isEmpty ? Self.stickerPackageGifs : packageId!
        lock.lock()
        let runtime = runtimeStickerPacks[runtimePackageId]?.stickers.first { $0.stickerId == sid }?.url
        lock.unlock()
        if let runtime { return runtime }
        return Self.resourceURL(name: sid, ext: "webp", subdir: "\(Self.resourceRoot)/stickers/\(subdir)")
    }

    public func emojiStaticPreviewData(_ key: String) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return runtimeEmoji[key.trimmingCharacters(in: .whitespaces)]?.staticPreviewData
    }

    public func stickerStaticPreviewData(stickerId: String, packageId: String?) -> Data? {
        let pid = (packageId ?? "").isEmpty ? Self.stickerPackageGifs : packageId!
        lock.lock(); defer { lock.unlock() }
        return runtimeStickerPacks[pid]?.stickers.first { $0.stickerId == stickerId.trimmingCharacters(in: .whitespaces) }?.staticPreviewData
    }

    public func emojiStaticImage(_ key: String) -> FlarePlatformImage? {
        if let data = emojiStaticPreviewData(key),
           let frame = flareDecodeAnimatedData(data, firstFrameOnly: true)?.frames.first { return frame }
        return image(at: emojiImageURL(key))
    }

    public func stickerStaticImage(stickerId: String, packageId: String?) -> FlarePlatformImage? {
        if let data = stickerStaticPreviewData(stickerId: stickerId, packageId: packageId),
           let frame = flareDecodeAnimatedData(data, firstFrameOnly: true)?.frames.first { return frame }
        return image(at: stickerImageURL(stickerId: stickerId, packageId: packageId))
    }

    /// Localized emoji-pack label; falls back to the raw key.
    public func emojiLabel(_ key: String, locale: String? = nil) -> String {
        ensureLoaded()
        let k = key.trimmingCharacters(in: .whitespaces)
        if k.isEmpty { return k }
        let column = (locale ?? "en").lowercased().hasPrefix("zh") ? "zh-Hans" : "en"
        lock.lock(); let runtimeLabels = runtimeEmoji[k]?.labels; lock.unlock()
        if let value = runtimeLabels?[column], !value.isEmpty { return value }
        if let value = runtimeLabels?["en"], !value.isEmpty { return value }
        if locales.isEmpty { return k }
        if let v = locales[column]?[k], !v.isEmpty { return v }
        if let v = locales["en"]?[k], !v.isEmpty { return v }
        return k
    }

    /// A plain line with `[pack_key]` tokens read in the reader's language: a conversation row or a reply
    /// strip shows 一百分, not `[hundred_points]`. The bubble draws the real image instead; this is for the
    /// places that are only text. Vue's `formatPackKeysInPlainTextForPreview`, same rule.
    public func localizePackKeysInText(_ text: String, locale: String? = nil) -> String {
        guard !text.isEmpty else { return text }
        guard let re = try? NSRegularExpression(pattern: "\\[([a-z][a-z0-9_]*)\\]") else { return text }
        let ns = text as NSString
        var out = ""
        var last = 0
        for match in re.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            out += ns.substring(with: NSRange(location: last, length: match.range.location - last))
            out += emojiLabel(ns.substring(with: match.range(at: 1)), locale: locale)
            last = match.range.location + match.range.length
        }
        out += ns.substring(from: last)
        return out
    }

    public func emojiBracketLabel(_ key: String, locale: String? = nil) -> String {
        "[\(emojiLabel(key, locale: locale))]"
    }

    /// Loads (and caches) a static platform image from a bundle URL.
    public func image(at url: URL?) -> FlarePlatformImage? {
        guard let url else { return nil }
        let key = url as NSURL
        if let cached = imageCache.object(forKey: key) { return cached }
        let img = flareDecodeAnimatedFile(url: url, firstFrameOnly: true)?.frames.first
        if let img {
            imageCache.setObject(img, forKey: key, cost: Int(img.size.width * img.size.height) * 4)
        }
        return img
    }
}

extension Image {
    /// A SwiftUI `Image` from a platform image (cross-platform init).
    init(flarePlatformImage image: FlarePlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: image)
        #else
        self.init(nsImage: image)
        #endif
    }
}
