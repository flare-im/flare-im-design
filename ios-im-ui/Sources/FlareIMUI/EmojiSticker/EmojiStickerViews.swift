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

/// A static webp image from the bundled resource, with a fallback view.
public struct FlareBundleImage<Fallback: View>: View {
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

/// Emoji-pack message body (`[key]` / bare key / a raw unicode emoji).
public struct FlareEmojiPackMessage: View {
    private let emoji: String
    private let isSelf: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.locale) private var locale

    public init(emoji: String, isSelf: Bool = false) {
        self.emoji = emoji
        self.isSelf = isSelf
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if let key = resolvePackKey(emoji) {
            let label = FlareEmojiStickerCatalog.shared.emojiBracketLabel(key, locale: locale.identifier)
            FlareBundleImage(url: FlareEmojiStickerCatalog.shared.emojiImageURL(key)) {
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
        let colors = FlareColors.of(scheme)
        let maxSide: CGFloat = 120
        var w = CGFloat((width ?? 0) > 0 ? width! : 68)
        var h = CGFloat((height ?? 0) > 0 ? height! : 68)
        if w > maxSide || h > maxSide {
            let scale = maxSide / max(w, h)
            w *= scale; h *= scale
        }
        let bundleURL = stickerId.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil
            : FlareEmojiStickerCatalog.shared.stickerImageURL(stickerId: stickerId, packageId: packageId)
        return FlareBundleImage(url: bundleURL) {
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .fill(colors.bgHover)
                .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary))
                .overlay(Image(systemName: "face.smiling").foregroundColor(colors.textSecondary))
        }
        .frame(width: w, height: h)
    }
}

/// Renders plain text with inline `[key]` emoji images (unknown keys show their
/// localized label). Call only after excluding Markdown.
public struct FlarePlainTextEmojiRich: View {
    private let text: String
    private let font: Font
    private let color: Color?
    private let inlineSize: CGFloat
    @Environment(\.locale) private var locale

    public init(_ text: String, font: Font = .body, color: Color? = nil, inlineSize: CGFloat = 18) {
        self.text = text
        self.font = font
        self.color = color
        self.inlineSize = inlineSize
    }

    public var body: some View {
        composed().font(font).foregroundColor(color)
    }

    private func composed() -> Text {
        let catalog = FlareEmojiStickerCatalog.shared
        let ns = text as NSString
        let matches = emojiToken.matches(in: text, range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty { return Text(text) }

        var result = Text("")
        var cursor = 0
        for m in matches {
            if m.range.location > cursor {
                result = result + Text(ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor)))
            }
            let key = ns.substring(with: m.range(at: 1))
            if catalog.hasEmojiKey(key), let img = catalog.image(at: catalog.emojiImageURL(key)) {
                result = result + Text(Image(flarePlatformImage: flareResized(img, to: inlineSize)))
            } else {
                result = result + Text(catalog.emojiBracketLabel(key, locale: locale.identifier))
            }
            cursor = m.range.location + m.range.length
        }
        if cursor < ns.length {
            result = result + Text(ns.substring(from: cursor))
        }
        return result
    }
}

/// Composer emoji-pack + sticker picker. One tab for the emoji pack plus one per
/// sticker pack; taps emit `onInsertEmoji` / `onSendSticker`.
public struct FlareEmojiStickerPicker: View {
    private let onInsertEmoji: ((String) -> Void)?
    private let onSendSticker: ((_ packageId: String, _ stickerId: String) -> Void)?
    private let emojiLabel: String
    @State private var tab = 0
    @Environment(\.colorScheme) private var scheme

    public init(emojiLabel: String = "Emoji",
                onInsertEmoji: ((String) -> Void)? = nil,
                onSendSticker: ((_ packageId: String, _ stickerId: String) -> Void)? = nil) {
        self.emojiLabel = emojiLabel
        self.onInsertEmoji = onInsertEmoji
        self.onSendSticker = onSendSticker
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let catalog = FlareEmojiStickerCatalog.shared
        let packs = catalog.loadedStickerPacks()
        let current = min(max(tab, 0), packs.count)
        let columns = [GridItem(.adaptive(minimum: current == 0 ? 44 : 76), spacing: 8)]

        return VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    if current == 0 {
                        ForEach(catalog.loadedEmojiKeys(), id: \.self) { key in
                            FlareBundleImage(url: catalog.emojiImageURL(key)) { Color.clear }
                                .frame(width: 40, height: 40)
                                .onTapGesture { onInsertEmoji?(key) }
                        }
                    } else {
                        let pack = packs[current - 1]
                        ForEach(pack.stickerIds, id: \.self) { id in
                            FlareBundleImage(url: catalog.stickerImageURL(stickerId: id, packageId: pack.id)) { Color.clear }
                                .frame(width: 72, height: 72)
                                .onTapGesture { onSendSticker?(pack.id, id) }
                        }
                    }
                }
                .padding(10)
            }
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    let labels = [emojiLabel] + packs.map { $0.title }
                    ForEach(Array(labels.enumerated()), id: \.offset) { idx, label in
                        let selected = idx == current
                        Text(label)
                            .font(.system(size: FlareSizes.fontSizeSm, weight: selected ? .semibold : .regular))
                            .foregroundColor(selected ? colors.textPrimary : colors.textSecondary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                                .fill(selected ? colors.bgHover : Color.clear))
                            .onTapGesture { tab = idx }
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
            }
        }
        .frame(height: 300)
    }
}
