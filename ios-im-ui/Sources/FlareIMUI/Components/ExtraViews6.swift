import SwiftUI

// MARK: - VoicePlayer

/// Voice player — playable voice message bubble with waveform, speed and transcript.
/// Spec: Message/VoicePlayer (`VoicePlayerView`).
public struct VoicePlayerView: View {
    private let durationLabel: String
    private let elapsedLabel: String?
    private let progress: Double
    private let playing: Bool
    private let amplitudes: [Double]
    private let speed: Double
    private let transcript: String?
    private let transcriptOpen: Bool
    private let unplayed: Bool
    private let outbound: Bool
    private let onToggle: (() -> Void)?
    private let onSeek: ((Double) -> Void)?
    private let onCycleSpeed: (() -> Void)?
    private let onToggleTranscript: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(durationLabel: String, elapsedLabel: String? = nil, progress: Double = 0,
                playing: Bool = false, amplitudes: [Double] = [], speed: Double = 1,
                transcript: String? = nil, transcriptOpen: Bool = false, unplayed: Bool = false,
                outbound: Bool = false, onToggle: (() -> Void)? = nil, onSeek: ((Double) -> Void)? = nil,
                onCycleSpeed: (() -> Void)? = nil, onToggleTranscript: (() -> Void)? = nil) {
        self.durationLabel = durationLabel; self.elapsedLabel = elapsedLabel; self.progress = progress
        self.playing = playing; self.amplitudes = amplitudes; self.speed = speed
        self.transcript = transcript; self.transcriptOpen = transcriptOpen; self.unplayed = unplayed
        self.outbound = outbound; self.onToggle = onToggle; self.onSeek = onSeek
        self.onCycleSpeed = onCycleSpeed; self.onToggleTranscript = onToggleTranscript
    }

    private static let barCount = 32

    private var bars: [Double] {
        if amplitudes.isEmpty {
            return (0..<Self.barCount).map { 0.3 + 0.4 * (sin(Double($0) * 0.5) * 0.5 + 0.5) }
        }
        var out = [Double]()
        for i in 0..<Self.barCount { out.append(amplitudes[i % amplitudes.count]) }
        return out
    }

    private var speedLabel: String {
        if speed == speed.rounded() {
            return "\(Int(speed))×"
        }
        return String(format: "%.1f×", speed)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 8) {
            bar(colors)
            if transcript != nil {
                transcriptSection(colors)
            }
        }
        .padding(12)
        .frame(width: 264)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(outbound ? colors.bgSelected : colors.bgPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(outbound ? colors.primary.opacity(0.24) : colors.borderPrimary, lineWidth: 1)
                )
        )
    }

    private func bar(_ colors: FlareColors) -> some View {
        HStack(spacing: 10) {
            playButton(colors)
            waveform(colors)
            Text(playing && elapsedLabel != nil ? elapsedLabel! : durationLabel)
                .font(.system(size: 12).monospacedDigit())
                .foregroundColor(colors.textTertiary)
            speedButton(colors)
        }
    }

    private func playButton(_ colors: FlareColors) -> some View {
        Button { onToggle?() } label: {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 14)).foregroundColor(.white)
                }
                .frame(width: 36, height: 36)
                if unplayed && !playing {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.bgPrimary, lineWidth: 1.5))
                        .offset(x: 2, y: -2)
                }
            }
            .frame(width: 36, height: 36)
        }.buttonStyle(.plain)
    }

    private func waveform(_ colors: FlareColors) -> some View {
        let filled = Int((progress * Double(Self.barCount)).rounded())
        return GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(Array(bars.enumerated()), id: \.offset) { i, amp in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i < filled ? colors.primary : colors.borderHover)
                        .frame(maxWidth: .infinity)
                        .frame(height: 4 + CGFloat(amp) * 18)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let ratio = max(0, min(1, value.location.x / geo.size.width))
                        onSeek?(ratio)
                    }
            )
        }
        .frame(height: 26)
    }

    private func speedButton(_ colors: FlareColors) -> some View {
        Button { onCycleSpeed?() } label: {
            Text(speedLabel)
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundColor(colors.textSecondary)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(colors.bgSecondary)
                    .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1)))
        }.buttonStyle(.plain)
    }

    @ViewBuilder
    private func transcriptSection(_ colors: FlareColors) -> some View {
        Button { onToggleTranscript?() } label: {
            HStack(spacing: 5) {
                Image(systemName: "doc.text").font(.system(size: 11))
                Text(transcriptOpen ? "Hide text" : "To text")
                    .font(.system(size: 12, weight: .medium))
            }.foregroundColor(colors.primary)
        }.buttonStyle(.plain)

        if let transcript, transcriptOpen {
            Divider().overlay(colors.borderPrimary)
            Text(transcript).font(.system(size: 13)).foregroundColor(colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

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
                TextField("Search emoji", text: $query)
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
            out.append(StickerPack(key: Self.recentKey, label: "Recent", coverEmoji: "🕘", stickers: recents))
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
