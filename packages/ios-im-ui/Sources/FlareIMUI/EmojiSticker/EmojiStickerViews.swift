import SwiftUI

private let bracketKey = try! NSRegularExpression(pattern: "^\\[([a-z][a-z0-9_]*)\\]$")
private let bareKey = try! NSRegularExpression(pattern: "^([a-z][a-z0-9_]*)$")
private let emojiToken = try! NSRegularExpression(pattern: "\\[([a-z][a-z0-9_]*)\\]")

private func firstGroup(_ re: NSRegularExpression, _ s: String) -> String? {
    let range = NSRange(s.startIndex..<s.endIndex, in: s)
    guard let m = re.firstMatch(in: s, range: range), m.numberOfRanges > 1,
          let r = Range(m.range(at: 1), in: s) else { return nil }
    return String(s[r])
}

private func resolvePackKey(_ raw: String) -> String? {
    let t = raw.trimmingCharacters(in: .whitespaces)
    return firstGroup(bracketKey, t) ?? firstGroup(bareKey, t)
}

/// A text body animates only when the entire trimmed wire value is one known
/// bracket token. Mixed/inline emoji remain static first-frame images.
func flareLoneEmojiPackKey(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("["), trimmed.hasSuffix("]"),
          let key = resolvePackKey(trimmed),
          FlareEmojiStickerCatalog.shared.hasEmojiKey(key) else { return nil }
    return key
}

private func flareResized(_ image: FlarePlatformImage, to side: CGFloat) -> FlarePlatformImage {
    #if canImport(UIKit)
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
    return renderer.image { _ in image.draw(in: CGRect(x: 0, y: 0, width: side, height: side)) }
    #else
    let out = NSImage(size: CGSize(width: side, height: side))
    out.lockFocus()
    image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
    out.unlockFocus()
    return out
    #endif
}

// MARK: - Emoji-pack tokens inside a text body

/// One run of a text body: plain text, or an emoji-pack token (`[key]`) the catalog can draw.
enum FlareInlineEmojiRun: Equatable {
    case text(String)
    case emoji(key: String)
}

/// Splits `text` at the emoji-pack tokens the catalog knows, so a text body can draw them inline
/// (Vue `PlainTextEmojiRich`). A token whose key the catalog does not have stays inside the plain
/// text, so `[not_a_key]` reads exactly as it was written.
func flareInlineEmojiRuns(_ text: String,
                          isKnown: (String) -> Bool = { FlareEmojiStickerCatalog.shared.hasEmojiKey($0) })
    -> [FlareInlineEmojiRun] {
    guard text.contains("[") else { return text.isEmpty ? [] : [.text(text)] }
    let ns = text as NSString
    var runs: [FlareInlineEmojiRun] = []
    var last = 0
    emojiToken.enumerateMatches(in: text, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
        guard let match, match.numberOfRanges > 1 else { return }
        let key = ns.substring(with: match.range(at: 1))
        guard isKnown(key) else { return }
        if match.range.location > last {
            runs.append(.text(ns.substring(with: NSRange(location: last, length: match.range.location - last))))
        }
        runs.append(.emoji(key: key))
        last = match.range.location + match.range.length
    }
    if last < ns.length { runs.append(.text(ns.substring(from: last))) }
    return runs
}

/// Whether `text` carries at least one emoji-pack token the catalog can draw inline.
func flareHasInlineEmoji(_ text: String,
                         isKnown: (String) -> Bool = { FlareEmojiStickerCatalog.shared.hasEmojiKey($0) }) -> Bool {
    flareInlineEmojiRuns(text, isKnown: isKnown).contains {
        if case .emoji = $0 { return true }
        return false
    }
}

private let inlineEmojiCache = NSCache<NSString, FlarePlatformImage>()

/// The image for an emoji-pack key at `side` points, resized once and kept: an inline token sits in a
/// line of text, where an animation per token would cost far more than it says, so this is the pack
/// image's first frame at text size.
func flareInlineEmojiImage(key: String, side: CGFloat) -> FlarePlatformImage? {
    let rounded = max(8, (side * 2).rounded() / 2)
    let cacheKey = "\(key)@\(rounded)" as NSString
    if let cached = inlineEmojiCache.object(forKey: cacheKey) { return cached }
    guard let image = FlareEmojiStickerCatalog.shared.emojiStaticImage(key) else { return nil }
    let resized = flareResized(image, to: rounded)
    inlineEmojiCache.setObject(resized, forKey: cacheKey, cost: Int(rounded * rounded) * 4)
    return resized
}

/// An animated (or static) webp from the bundled resource, with a fallback view.
/// Decodes every frame via ImageIO and cycles them at each frame's own duration.
struct FlareAnimatedBundleImage<Fallback: View>: View {
    private let url: URL?
    private let fallback: () -> Fallback
    @State private var frames: [FlarePlatformImage] = []
    @State private var durations: [Double] = []
    @State private var index = 0
    @State private var decoded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(url: URL?, @ViewBuilder fallback: @escaping () -> Fallback) {
        self.url = url
        self.fallback = fallback
    }

    public var body: some View {
        Group {
            if !frames.isEmpty {
                Image(flarePlatformImage: frames[min(index, frames.count - 1)])
                    .resizable().scaledToFit()
            } else if decoded {
                fallback()
            } else {
                Color.clear
            }
        }
        .task(id: "\(url?.absoluteString ?? ""):\(reduceMotion)") {
            index = 0
            frames = []
            durations = []
            decoded = false
            let result: FlareAnimatedFrames?
            if let url, ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
                do {
                    let data = try await flareLoadAnimatedData(from: url)
                    guard !Task.isCancelled else { return }
                    result = await flareDecodeAnimatedDataAsync(data, firstFrameOnly: reduceMotion)
                } catch { result = nil }
            } else {
                result = await flareDecodeAnimatedFileAsync(url: url, firstFrameOnly: reduceMotion)
            }
            guard !Task.isCancelled else { return }
            frames = result?.frames ?? []
            durations = result?.durations ?? []
            decoded = true
            guard frames.count > 1, !reduceMotion else { return }
            while !Task.isCancelled {
                let delay = durations.indices.contains(index) ? durations[index] : 0.1
                try? await Task.sleep(nanoseconds: UInt64(max(0.02, delay) * 1_000_000_000))
                if Task.isCancelled { break }
                index = (index + 1) % frames.count
            }
        }
    }
}

/// A static webp image from the bundled resource, with a fallback view.
struct FlareBundleImage<Fallback: View>: View {
    private let url: URL?
    private let fallback: () -> Fallback
    public init(url: URL?, @ViewBuilder fallback: @escaping () -> Fallback) {
        self.url = url
        self.fallback = fallback
    }
    public var body: some View {
        if let url, let img = FlareEmojiStickerCatalog.shared.image(at: url) {
            Image(flarePlatformImage: img).resizable().scaledToFit()
        } else {
            fallback()
        }
    }
}

/// Static first-frame renderer for local/remote and runtime-registered assets.
/// It never schedules a frame loop, even when [url] points to animated webp.
struct FlareStaticResourceImage<Fallback: View>: View {
    private let url: URL?
    private let data: Data?
    private let fallback: () -> Fallback
    @State private var image: FlarePlatformImage?
    @State private var decoded = false

    init(url: URL?, data: Data? = nil, @ViewBuilder fallback: @escaping () -> Fallback) {
        self.url = url
        self.data = data
        self.fallback = fallback
    }

    var body: some View {
        Group {
            if let image { Image(flarePlatformImage: image).resizable().scaledToFit() }
            else if decoded { fallback() }
            else { Color.clear }
        }
        .task(id: "\(url?.absoluteString ?? ""):\(data?.count ?? 0)") {
            decoded = false
            image = nil
            let frame: FlarePlatformImage?
            if let data {
                frame = await flareDecodeAnimatedDataAsync(data, firstFrameOnly: true)?.frames.first
            } else if let url, ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
                let remote = try? await flareLoadAnimatedData(from: url)
                frame = remote.flatMap { flareDecodeAnimatedData($0, firstFrameOnly: true)?.frames.first }
            } else {
                frame = await flareDecodeAnimatedFileAsync(url: url, firstFrameOnly: true)?.frames.first
            }
            guard !Task.isCancelled else { return }
            image = frame
            decoded = true
        }
    }
}

/// Emoji-pack message body (`[key]` / bare key / a raw unicode emoji).
public struct FlareEmojiPackMessage: View {
    private let emoji: String
    private let isSelf: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.locale) private var locale
    @ObservedObject private var catalog = FlareEmojiStickerCatalog.shared

    public init(emoji: String, isSelf: Bool = false) {
        self.emoji = emoji
        self.isSelf = isSelf
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if let key = resolvePackKey(emoji) {
            let label = catalog.emojiBracketLabel(key, locale: locale.identifier)
            FlareAnimatedBundleImage(url: catalog.emojiImageURL(key)) {
                Text(label)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 120, height: 120)
        } else {
            Text(emoji).font(.system(size: 48))
        }
    }
}

/// Sticker message body — a bundled pack sticker (packageId + stickerId), else url.
public struct FlareStickerPackMessage: View {
    private let stickerId: String
    private let packageId: String?
    private let url: String?
    private let width: Int?
    private let height: Int?
    private let isSelf: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @ObservedObject private var catalog = FlareEmojiStickerCatalog.shared

    public init(stickerId: String, packageId: String? = nil, url: String? = nil,
                width: Int? = nil, height: Int? = nil, isSelf: Bool = false) {
        self.stickerId = stickerId
        self.packageId = packageId
        self.url = url
        self.width = width
        self.height = height
        self.isSelf = isSelf
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let maxSide: CGFloat = 120
        var w = CGFloat((width ?? 0) > 0 ? width! : 68)
        var h = CGFloat((height ?? 0) > 0 ? height! : 68)
        if w > maxSide || h > maxSide {
            let scale = maxSide / max(w, h)
            w *= scale; h *= scale
        }
        let bundleURL = stickerId.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil
            : catalog.stickerImageURL(stickerId: stickerId, packageId: packageId)
        let remoteURL = url.flatMap(URL.init(string:)).flatMap {
            ["https", "http"].contains($0.scheme?.lowercased() ?? "") ? $0 : nil
        }
        return FlareStaticResourceImage(
            url: bundleURL ?? remoteURL,
            data: catalog.stickerStaticPreviewData(stickerId: stickerId, packageId: packageId)
        ) {
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .fill(colors.bgHover)
                .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary))
                .overlay(Image(systemName: "face.smiling").foregroundColor(colors.textSecondary))
        }
        .frame(width: w, height: h)
    }
}

/// Composer emoji-pack + sticker picker. One tab for the emoji pack plus one per
/// sticker pack; taps emit `onInsertEmoji` / `onSendSticker`.
public struct FlareEmojiStickerPicker: View {
    private let onInsertEmoji: ((String) -> Void)?
    private let onSendSticker: ((_ packageId: String, _ stickerId: String) -> Void)?
    private let emojiLabel: String
    private let height: CGFloat?
    @Environment(\.locale) private var locale
    @State private var tab = 0
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @ObservedObject private var catalog = FlareEmojiStickerCatalog.shared

    public init(emojiLabel: String = "Emoji", height: CGFloat? = 300,
                onInsertEmoji: ((String) -> Void)? = nil,
                onSendSticker: ((_ packageId: String, _ stickerId: String) -> Void)? = nil) {
        self.emojiLabel = emojiLabel
        self.height = height
        self.onInsertEmoji = onInsertEmoji
        self.onSendSticker = onSendSticker
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let packs = catalog.loadedStickerPacks()
        let current = min(max(tab, 0), packs.count)
        let columns = [GridItem(.adaptive(minimum: current == 0 ? 44 : 76), spacing: 8)]

        return VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    if current == 0 {
                        ForEach(catalog.loadedEmojiKeys(), id: \.self) { key in
                            Button { onInsertEmoji?(key) } label: {
                                FlareStaticResourceImage(
                                    url: catalog.emojiImageURL(key),
                                    data: catalog.emojiStaticPreviewData(key)
                                ) { Text(catalog.emojiBracketLabel(key, locale: locale.identifier)) }
                                    .frame(width: 32, height: 32)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(onInsertEmoji == nil)
                            .accessibilityLabel(catalog.emojiBracketLabel(key, locale: locale.identifier))
                        }
                    } else {
                        let pack = packs[current - 1]
                        ForEach(pack.stickerIds, id: \.self) { id in
                            Button { onSendSticker?(pack.id, id) } label: {
                                FlareStaticResourceImage(
                                    url: catalog.stickerImageURL(stickerId: id, packageId: pack.id),
                                    data: catalog.stickerStaticPreviewData(stickerId: id, packageId: pack.id)
                                ) { Text(id) }
                                    .frame(width: 72, height: 72)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(onSendSticker == nil)
                            .accessibilityLabel("\(pack.title) \(id)")
                        }
                    }
                }
                .padding(FlareSizes.spacing2sm)
            }
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    let labels = [emojiLabel] + packs.map { $0.title }
                    ForEach(Array(labels.enumerated()), id: \.offset) { idx, label in
                        let selected = idx == current
                        Button { tab = idx } label: {
                        Text(label)
                            .font(.system(size: FlareSizes.fontSizeSm, weight: selected ? .semibold : .regular))
                            .foregroundColor(selected ? colors.textPrimary : colors.textSecondary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                                .fill(selected ? colors.bgHover : Color.clear))
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
            }
        }
        .frame(height: height)
    }
}
