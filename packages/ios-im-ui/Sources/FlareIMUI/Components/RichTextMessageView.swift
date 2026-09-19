import SwiftUI

/// rich text — the RichDoc v2 document the core stores for a rich-text message (`docJson`),
/// drawn as headings, paragraphs, quotes, code, lists and rules with their marks, links, mentions and emoji
/// (`spec/rich-doc-vectors.json`), under the message's `title` when it has one. A document that is not
/// drawable shows `plainText`, the core's own flat text; a message with neither shows the rich-text term.
///
/// A link opens only when ``safeExternalURL(_:)`` accepts it — through `onLinkTap` when the host takes links,
/// else through the platform opener — and a refused link keeps its words. A spoiler stays covered, and is
/// named for VoiceOver, until the reader taps it. Colours follow ``TextMessageView``.
public struct RichTextMessageView: View {
    private let blocks: [FlareRichBlock]?
    private let plainText: String
    private let title: String
    private let docJson: String
    private let isSelf: Bool
    private let selectable: Bool
    private let onLinkTap: ((String) -> Void)?
    @State private var revealed = false
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// The address a covered spoiler's run links to: tapping it reveals, it never leaves the kit.
    static let spoilerURL = URL(string: "flare-spoiler:reveal")!

    public init(docJson: String, plainText: String = "", title: String = "", isSelf: Bool = false,
                selectable: Bool = false, onLinkTap: ((String) -> Void)? = nil) {
        self.docJson = docJson
        self.blocks = flareParseRichDoc(docJson)
        self.plainText = plainText
        self.title = title
        self.isSelf = isSelf
        self.selectable = selectable
        self.onLinkTap = onLinkTap
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let paint = Paint(colors: colors, isSelf: isSelf, size: FlareSizes.fontSizeXl * textScale,
                          strings: strings, revealed: revealed)
        VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
            let heading = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !heading.isEmpty {
                Text(heading).font(.system(size: paint.size * 1.12, weight: .bold))
            }
            if let blocks, !blocks.isEmpty {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    Self.block(block, paint: paint)
                }
            } else {
                let flat = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
                Text(flat.isEmpty ? strings.previewRichText : flat).font(.system(size: paint.size))
            }
        }
        .foregroundColor(paint.foreground)
        .lineSpacing(4)
        .textSelectableIf(selectable)
        .onChange(of: docJson) { _ in revealed = false }
        .environment(\.openURL, OpenURLAction { url in
            switch Self.linkTap(url, hostHandles: onLinkTap != nil) {
            case .reveal:
                revealed = true
                return .handled
            case .link(.host(let raw)):
                onLinkTap?(raw)
                return .handled
            case .link(.system(let safe)):
                return .systemAction(safe)
            case .link(.ignored):
                return .handled
            }
        })
    }

    /// What a tap on a run's address does: a covered spoiler reveals, anything else is a link and goes where
    /// a link in a text body goes.
    enum Tap: Equatable {
        case reveal
        case link(TextMessageView.LinkTap)
    }

    static func linkTap(_ url: URL, hostHandles: Bool) -> Tap {
        url == spoilerURL ? .reveal : .link(TextMessageView.linkTap(url.absoluteString, hostHandles: hostHandles))
    }

    /// Everything a block needs to draw itself.
    struct Paint {
        let colors: FlareColors
        let isSelf: Bool
        let size: CGFloat
        let strings: FlareStrings
        let revealed: Bool
        var foreground: Color { isSelf ? colors.messageOutgoingForeground : colors.messageIncomingForeground }
        var link: Color { isSelf ? colors.messageOutgoingForeground : colors.primary }
    }

    static func block(_ block: FlareRichBlock, paint: Paint) -> AnyView {
        switch block {
        case .paragraph(let runs):
            return AnyView(paragraph(runs, paint: paint, size: paint.size, weight: .regular))
        case .heading(let level, let runs):
            let scale: CGFloat = level == 1 ? 1.18 : level == 2 ? 1.12 : 1.04
            return AnyView(paragraph(runs, paint: paint, size: paint.size * scale, weight: .bold))
        case .quote(let inner):
            return AnyView(
                VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
                    ForEach(Array(inner.enumerated()), id: \.offset) { _, child in Self.block(child, paint: paint) }
                }
                .foregroundColor(paint.foreground.opacity(0.82))
                .padding(.horizontal, FlareSizes.spacingSm)
                .padding(.vertical, FlareSizes.spacingXs)
                .background(paint.foreground.opacity(0.08))
                .overlay(alignment: .leading) { Rectangle().fill(paint.foreground.opacity(0.42)).frame(width: 3) }
            )
        case .code(let text, _):
            return AnyView(
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(verbatim: text)
                        .font(.system(size: paint.size * 0.92, design: .monospaced))
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, FlareSizes.spacingSm)
                        .padding(.vertical, FlareSizes.spacingXs)
                }
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(paint.foreground.opacity(0.08)))
            )
        case .list(let ordered, let items):
            return AnyView(
                VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingXs) {
                            Text(ordered ? "\(index + 1)." : "•").font(.system(size: paint.size))
                            VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
                                ForEach(Array(item.enumerated()), id: \.offset) { _, child in Self.block(child, paint: paint) }
                            }
                        }
                    }
                }
            )
        case .divider:
            return AnyView(Rectangle().fill(paint.foreground.opacity(0.18)).frame(height: 1).frame(maxWidth: .infinity))
        }
    }

    /// One paragraph or heading: its runs as one Text, so links stay tappable and the lines wrap as one.
    static func paragraph(_ runs: [FlareRichRun], paint: Paint, size: CGFloat, weight: Font.Weight) -> some View {
        let text = runs.reduce(Text(verbatim: "")) { result, run in result + Self.text(run, paint: paint, size: size, weight: weight) }
        let covered = !paint.revealed && runs.contains { $0.has(.spoiler) }
        return text
            .accessibilityLabel(covered ? Text(verbatim: spokenText(runs, paint: paint)) : text)
    }

    /// What VoiceOver reads for runs with a covered spoiler: the spoiler's name in its place.
    static func spokenText(_ runs: [FlareRichRun], paint: Paint) -> String {
        runs.map { $0.has(.spoiler) && !paint.revealed ? paint.strings.messageSpoilerReveal : $0.text }.joined()
    }

    static func text(_ run: FlareRichRun, paint: Paint, size: CGFloat, weight: Font.Weight) -> Text {
        if let key = run.emoji, !key.isEmpty, FlareEmojiStickerCatalog.shared.hasEmojiKey(key),
           !(run.has(.spoiler) && !paint.revealed),
           let image = flareInlineEmojiImage(key: key, side: size * 1.2) {
            return Text(Image(flarePlatformImage: image))
        }
        return Text(attributed(run, paint: paint, size: size, weight: weight))
    }

    static func attributed(_ run: FlareRichRun, paint: Paint, size: CGFloat, weight: Font.Weight) -> AttributedString {
        if run.has(.spoiler) && !paint.revealed {
            // The words are not drawn at all while covered: blank space as wide as them, on a ground in the
            // text colour.
            var covered = AttributedString(flareRichSpoilerCover(run.text))
            covered.font = .system(size: size, weight: weight)
            covered.backgroundColor = paint.foreground
            covered.link = spoilerURL
            return covered
        }
        var out = AttributedString(run.text)
        var runWeight = run.has(.bold) ? Font.Weight.bold : weight
        if run.mention != nil { runWeight = paint.isSelf ? .semibold : .medium }
        var font = Font.system(size: run.code ? size * 0.92 : size, weight: runWeight,
                               design: run.code ? .monospaced : .default)
        if run.has(.italic) { font = font.italic() }
        out.font = font
        if run.has(.underline) { out.underlineStyle = .single }
        if run.has(.strike) { out.strikethroughStyle = .single }
        if run.code { out.backgroundColor = paint.foreground.opacity(0.10) }
        if run.mention != nil, !paint.isSelf { out.foregroundColor = paint.colors.primaryText }
        if let href = run.link, let safe = safeExternalURL(href), let url = URL(string: safe) {
            out.link = url
            out.foregroundColor = paint.link
            out.underlineStyle = .single
        }
        return out
    }
}
