import SwiftUI

// MARK: - EmojiPicker

/// Emoji picker — searchable emoji grid with skin tones, recents and category rail.
/// Spec: Composer/EmojiPicker (`EmojiPickerView`).
public struct EmojiPickerView: View {
    private let categories: [EmojiCategory]
    private let recents: [String]
    private let skinTones: Bool
    private let onSelect: ((String) -> Void)?
    private let onToneChange: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var query = ""
    @State private var activeKey = ""
    @State private var tone = ""

    public init(categories: [EmojiCategory], recents: [String] = [], skinTones: Bool = false,
                onSelect: ((String) -> Void)? = nil, onToneChange: ((String) -> Void)? = nil) {
        self.categories = categories; self.recents = recents; self.skinTones = skinTones
        self.onSelect = onSelect; self.onToneChange = onToneChange
    }

    private static let tones = ["", "\u{1F3FB}", "\u{1F3FC}", "\u{1F3FD}", "\u{1F3FE}", "\u{1F3FF}"]
    private static let recentKey = "__recent"

    private var searching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    private var displayedEmojis: [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            var seen = Set<String>()
            var out = [String]()
            for cat in categories {
                for e in cat.emojis where e.contains(q) {
                    if seen.insert(e).inserted { out.append(e) }
                }
            }
            return out
        }
        if activeKey == Self.recentKey { return recents }
        if let cat = categories.first(where: { $0.key == activeKey }) { return cat.emojis }
        return categories.first?.emojis ?? []
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 8) {
            searchRow(colors)
            grid(colors)
            if !searching { rail(colors) }
        }
        .padding(10)
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
        .onAppear {
            if activeKey.isEmpty {
                activeKey = recents.isEmpty ? (categories.first?.key ?? "") : Self.recentKey
            }
        }
    }

    private func searchRow(_ colors: FlareColors) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundColor(colors.textTertiary)
                TextField("搜索表情", text: $query)
                    .font(.system(size: 13)).foregroundColor(colors.textPrimary)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))

            if skinTones {
                HStack(spacing: 2) {
                    ForEach(Self.tones, id: \.self) { t in
                        let active = t == tone
                        Button { tone = t; onToneChange?(t) } label: {
                            Text("✋" + t).font(.system(size: 15))
                                .frame(width: 24, height: 24)
                                .background(RoundedRectangle(cornerRadius: 6)
                                    .fill(active ? colors.bgSelected : Color.clear))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func grid(_ colors: FlareColors) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 8)
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(displayedEmojis.enumerated()), id: \.offset) { _, e in
                    Button { onSelect?(tone.isEmpty ? e : e + tone) } label: {
                        Text(tone.isEmpty ? e : e + tone).font(.system(size: 22))
                            .frame(maxWidth: .infinity).frame(height: 34)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        }
        .frame(height: 200)
    }

    private func rail(_ colors: FlareColors) -> some View {
        VStack(spacing: 6) {
            Divider().overlay(colors.borderPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    if !recents.isEmpty {
                        tab(colors, key: Self.recentKey, symbol: "clock", glyph: nil)
                    }
                    ForEach(categories) { cat in
                        tab(colors, key: cat.key, symbol: cat.symbol,
                            glyph: cat.symbol == nil ? cat.emojis.first : nil)
                    }
                }
            }
        }
    }

    private func tab(_ colors: FlareColors, key: String, symbol: String?, glyph: String?) -> some View {
        let active = key == activeKey
        return Button { activeKey = key } label: {
            Group {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 15)).foregroundColor(colors.textSecondary)
                } else {
                    Text(glyph ?? "•").font(.system(size: 16))
                }
            }
            .frame(width: 32, height: 32)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                .fill(active ? colors.bgSelected : Color.clear))
        }.buttonStyle(.plain)
    }
}
