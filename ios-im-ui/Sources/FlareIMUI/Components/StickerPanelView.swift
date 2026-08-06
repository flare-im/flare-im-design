import SwiftUI

// MARK: - StickerPanel

/// Sticker panel — sticker pack grid with a bottom pack rail.
/// Spec: Composer/StickerPanel (`StickerPanelView`).
public struct StickerPanelView: View {
    private let packs: [StickerPack]
    private let recents: [StickerItem]
    private let onSelect: ((StickerItem) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var activeKey = ""

    public init(packs: [StickerPack], recents: [StickerItem] = [], onSelect: ((StickerItem) -> Void)? = nil) {
        self.packs = packs; self.recents = recents; self.onSelect = onSelect
    }

    private static let recentKey = "__recent"

    private var railPacks: [StickerPack] {
        var out = [StickerPack]()
        if !recents.isEmpty {
            out.append(StickerPack(key: Self.recentKey, label: "最近", coverEmoji: "🕘", stickers: recents))
        }
        out.append(contentsOf: packs)
        return out
    }

    private var activePack: StickerPack? {
        railPacks.first(where: { $0.key == activeKey }) ?? railPacks.first
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 8) {
            Text(activePack?.label ?? "")
                .font(.system(size: 12, weight: .semibold)).foregroundColor(colors.textTertiary)
            grid(colors)
            rail(colors)
        }
        .padding(10)
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
        .onAppear {
            if activeKey.isEmpty { activeKey = railPacks.first?.key ?? "" }
        }
    }

    private func grid(_ colors: FlareColors) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(activePack?.stickers ?? []) { sticker in
                    cell(colors, sticker)
                        .onTapGesture { onSelect?(sticker) }
                }
            }
        }
        .frame(height: 208)
    }

    private func cell(_ colors: FlareColors, _ sticker: StickerItem) -> some View {
        RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    if let urlStr = sticker.url, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFit()
                        } placeholder: {
                            Text(sticker.placeholder ?? "🎨").font(.system(size: 32))
                        }
                        .padding(6)
                    } else {
                        Text(sticker.placeholder ?? "🎨").font(.system(size: 32))
                    }
                }
            )
            .contentShape(Rectangle())
    }

    private func rail(_ colors: FlareColors) -> some View {
        VStack(spacing: 6) {
            Divider().overlay(colors.borderPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(railPacks) { pack in
                        packTab(colors, pack)
                    }
                }
            }
        }
    }

    private func packTab(_ colors: FlareColors, _ pack: StickerPack) -> some View {
        let active = pack.key == activeKey
        return Button { activeKey = pack.key } label: {
            Group {
                if pack.key == Self.recentKey {
                    Image(systemName: "clock").font(.system(size: 16)).foregroundColor(colors.textSecondary)
                } else if let coverStr = pack.coverURL, let url = URL(string: coverStr) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFit()
                    } placeholder: {
                        Text(pack.coverEmoji ?? "🎨").font(.system(size: 18))
                    }
                    .padding(4)
                } else {
                    Text(pack.coverEmoji ?? "🎨").font(.system(size: 18))
                }
            }
            .frame(width: 38, height: 38)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                .fill(active ? colors.bgSelected : Color.clear))
        }.buttonStyle(.plain)
    }
}
