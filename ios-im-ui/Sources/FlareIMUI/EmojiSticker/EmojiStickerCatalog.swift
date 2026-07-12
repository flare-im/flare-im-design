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

/// Decodes every frame of a (possibly animated) webp via ImageIO — no third-party
/// dependency. Returns nil if the file can't be read.
public func flareDecodeAnimatedWebp(url: URL?) -> FlareAnimatedFrames? {
    guard let url, let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    let count = CGImageSourceGetCount(source)
    guard count > 0 else { return nil }
    var frames: [FlarePlatformImage] = []
    var durations: [Double] = []
    for i in 0..<count {
        guard let cg = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
        #if canImport(UIKit)
        frames.append(UIImage(cgImage: cg))
        #else
        frames.append(NSImage(cgImage: cg, size: CGSize(width: cg.width, height: cg.height)))
        #endif
        var delay = 0.1
        if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
           let webp = props[kCGImagePropertyWebPDictionary] as? [CFString: Any] {
            if let d = webp[kCGImagePropertyWebPUnclampedDelayTime] as? Double, d > 0 {
                delay = d
            } else if let d = webp[kCGImagePropertyWebPDelayTime] as? Double, d > 0 {
                delay = d
            }
        }
        durations.append(delay)
    }
    return frames.isEmpty ? nil : FlareAnimatedFrames(frames: frames, durations: durations)
}

/// One sticker pack from the manifest.
public struct FlareStickerPack: Sendable, Identifiable {
    public let id: String       // protocol packageId (e.g. `gifs`, `classic`)
    public let dir: String      // e.g. `stickers/default`
    public let title: String
    public let stickerIds: [String]
}

/// Cross-platform emoji-pack + sticker catalog, backed by the flare-im-design
/// manifest bundled with this package (a committed mirror of the single source
/// `flare-im-design/assets/emoji-sticker`; see sync-resources.sh).
///
/// Resources load synchronously from `Bundle.module` on first access, so views
/// stay pure. Message views resolve assets by path convention; the picker + the
/// localized labels use the loaded manifest.
public final class FlareEmojiStickerCatalog: @unchecked Sendable {
    public static let shared = FlareEmojiStickerCatalog()

    public static let resourceRoot = "emoji-sticker"
    public static let stickerPackageGifs = "gifs"

    private let lock = NSLock()
    private var loaded = false
    public private(set) var emojiKeys: [String] = []
    private var emojiKeySet: Set<String> = []
    public private(set) var stickerPacks: [FlareStickerPack] = []
    private var locales: [String: [String: String]] = [:]
    private var imageCache: [String: FlarePlatformImage] = [:]

    private init() {}

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

    public func loadedEmojiKeys() -> [String] { ensureLoaded(); return emojiKeys }
    public func loadedStickerPacks() -> [FlareStickerPack] { ensureLoaded(); return stickerPacks }

    public func hasEmojiKey(_ key: String) -> Bool {
        ensureLoaded()
        return emojiKeySet.contains(key.trimmingCharacters(in: .whitespaces))
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

    public func emojiImageURL(_ key: String) -> URL? {
        let k = key.trimmingCharacters(in: .whitespaces)
        guard Self.isSafeComponent(k) else { return nil }
        return Self.resourceURL(name: k, ext: "webp", subdir: "\(Self.resourceRoot)/emoji")
    }

    public func stickerImageURL(stickerId: String, packageId: String?) -> URL? {
        let sid = stickerId.trimmingCharacters(in: .whitespaces)
        let subdir = Self.stickerSubdir(forPackageId: packageId)
        guard Self.isSafeComponent(sid), Self.isSafeComponent(subdir) else { return nil }
        return Self.resourceURL(name: sid, ext: "webp", subdir: "\(Self.resourceRoot)/stickers/\(subdir)")
    }

    /// Localized emoji-pack label; falls back to the raw key.
    public func emojiLabel(_ key: String, locale: String? = nil) -> String {
        ensureLoaded()
        let k = key.trimmingCharacters(in: .whitespaces)
        if k.isEmpty || locales.isEmpty { return k }
        let column = (locale ?? "en").lowercased().hasPrefix("zh") ? "zh-Hans" : "en"
        if let v = locales[column]?[k], !v.isEmpty { return v }
        if let v = locales["en"]?[k], !v.isEmpty { return v }
        return k
    }

    public func emojiBracketLabel(_ key: String, locale: String? = nil) -> String {
        "[\(emojiLabel(key, locale: locale))]"
    }

    /// Loads (and caches) a static platform image from a bundle URL.
    public func image(at url: URL?) -> FlarePlatformImage? {
        guard let url else { return nil }
        let key = url.path
        lock.lock()
        if let cached = imageCache[key] { lock.unlock(); return cached }
        lock.unlock()
        #if canImport(UIKit)
        let img = UIImage(contentsOfFile: url.path)
        #else
        let img = NSImage(contentsOfFile: url.path)
        #endif
        if let img {
            lock.lock(); imageCache[key] = img; lock.unlock()
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
