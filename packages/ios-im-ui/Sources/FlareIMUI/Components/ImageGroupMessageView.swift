import SwiftUI

/// image group — an album: square tiles laid out by the shared rule (`spec/image-group-layout-vectors.json`), the
/// last drawn tile covered with `+N` when the album holds more images than tiles, and the album's `description`
/// under them.
///
/// Presentational: a tile calls `onOpen` with its image's index — the covered tile opens its own image — and the
/// host decides what opens (one image, or the conversation's gallery). Every tile is a button named with its
/// position in the album; without `onOpen` the tiles are pictures only.
public struct ImageGroupMessageView: View {
    private let images: [FlareImageContent]
    private let description: String
    private let isSelf: Bool
    private let width: CGFloat
    private let onOpen: ((Int) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(images: [FlareImageContent], description: String = "", isSelf: Bool = false, width: CGFloat = 240,
                onOpen: ((Int) -> Void)? = nil) {
        self.images = images; self.description = description; self.isSelf = isSelf; self.width = width
        self.onOpen = onOpen
    }

    public var body: some View {
        let layout = FlareImageGroupLayout.forCount(images.count)
        if layout.visible > 0 {
            let colors = FlareColors.of(scheme, brand: flareBrandTheme)
            let gap = FlareSizes.spacingXs
            let side = (width - gap * CGFloat(layout.columns - 1)) / CGFloat(layout.columns)
            let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
            VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(Array(stride(from: 0, to: layout.visible, by: layout.columns)), id: \.self) { start in
                        HStack(spacing: gap) {
                            ForEach(start..<min(start + layout.columns, layout.visible), id: \.self) { index in
                                tile(index, side: side, layout: layout, colors: colors)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg, style: .continuous))
                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(isSelf ? colors.messageOutgoingForeground : colors.messageIncomingForeground)
                }
            }
            .frame(width: width, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(strings.messageImageGroupLabel(images.count))
        }
    }

    /// The name VoiceOver reads for the tile at `index`.
    static func label(_ index: Int, count: Int, layout: FlareImageGroupLayout, strings: FlareStrings) -> String {
        layout.covers(index)
            ? strings.messageImageGroupItemMore(index + 1, count, layout.more)
            : strings.messageImageGroupItem(index + 1, count)
    }

    @ViewBuilder
    private func tile(_ index: Int, side: CGFloat, layout: FlareImageGroupLayout, colors: FlareColors) -> some View {
        let image = images[index]
        let source = (image.thumbnailURL ?? "").isEmpty ? image.url : (image.thumbnailURL ?? image.url)
        let picture = ZStack {
            NetImage(url: source) {
                colors.bgTertiary.overlay(IconView("image", color: colors.textTertiary))
            }
            .frame(width: side, height: side)
            .clipped()
            if layout.covers(index) {
                Color.black.opacity(0.45)
                Text(verbatim: "+\(layout.more)")
                    .font(.system(size: FlareSizes.fontSize2xl, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: side, height: side)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.label(index, count: images.count, layout: layout, strings: strings))
        if let onOpen {
            Button { onOpen(index) } label: { picture }
                .buttonStyle(.plain)
        } else {
            picture
        }
    }
}
