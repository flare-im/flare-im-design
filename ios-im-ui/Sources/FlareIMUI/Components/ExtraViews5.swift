import SwiftUI

// MARK: - Color(hex:)

extension Color {
    /// Parse a `#RRGGBB` / `#RGB` / `#RRGGBBAA` hex string. Returns nil on failure
    /// (e.g. CSS gradients or malformed values) so callers can fall back.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 3 || s.count == 6 || s.count == 8,
              s.allSatisfy({ $0.isHexDigit }) else { return nil }
        if s.count == 3 {
            s = s.map { "\($0)\($0)" }.joined()
        }
        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else { return nil }
        let r, g, b, a: Double
        if s.count == 8 {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - ImageGrid

/// Image grid — up to `max` thumbnails with a "+N" overflow scrim on the last cell.
/// Spec: Message/ImageGrid (`ImageGridView`).
public struct ImageGridView: View {
    private let images: [GridImage]
    private let max: Int
    private let onOpen: ((Int) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(images: [GridImage], max: Int = 9, onOpen: ((Int) -> Void)? = nil) {
        self.images = images; self.max = max; self.onOpen = onOpen
    }

    private var visible: [GridImage] { Array(images.prefix(max)) }
    private var overflow: Int { images.count - visible.count }

    private var cols: Int {
        let n = visible.count
        if n <= 1 { return 1 }
        if n == 4 { return 2 }
        if n <= 3 { return n }
        return 3
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let single = visible.count <= 1
        let side: CGFloat = single ? 220 : 84
        let columns = Array(repeating: GridItem(.fixed(single ? side : 84), spacing: 4),
                            count: single ? 1 : cols)
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, image in
                cell(colors, image, side: side,
                     showOverflow: overflow > 0 && index == visible.count - 1)
                    .onTapGesture { onOpen?(index) }
            }
        }
        .frame(width: single ? side : CGFloat(cols) * 84 + CGFloat(cols - 1) * 4)
    }

    private func cell(_ colors: FlareColors, _ image: GridImage, side: CGFloat, showOverflow: Bool) -> some View {
        ZStack {
            if let urlStr = image.url, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    colors.bgSecondary
                }
            } else {
                colors.bgSecondary
            }
            if showOverflow {
                Color.black.opacity(0.42)
                Text("+\(overflow)")
                    .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}

// MARK: - VoiceRecordingBar

/// Voice recording bar — live capsule with waveform, duration and cancel / send.
/// Spec: Composer/VoiceRecordingBar (`VoiceRecordingBarView`).
public struct VoiceRecordingBarView: View {
    private let durationLabel: String
    private let amplitudes: [Double]
    private let cancelling: Bool
    private let onCancel: (() -> Void)?
    private let onSend: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var blink = false

    public init(durationLabel: String, amplitudes: [Double] = [], cancelling: Bool = false,
                onCancel: (() -> Void)? = nil, onSend: (() -> Void)? = nil) {
        self.durationLabel = durationLabel; self.amplitudes = amplitudes; self.cancelling = cancelling
        self.onCancel = onCancel; self.onSend = onSend
    }

    private static let barCount = 28

    private var bars: [Double] {
        if amplitudes.isEmpty {
            return (0..<Self.barCount).map { 0.35 + 0.35 * (sin(Double($0) * 0.6) * 0.5 + 0.5) }
        }
        var out = [Double]()
        for i in 0..<Self.barCount { out.append(amplitudes[i % amplitudes.count]) }
        return out
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingMd) {
            cancelButton(colors)
            center(colors)
            right(colors)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(
            Capsule().fill(cancelling ? colors.error.opacity(0.08) : colors.bgPrimary)
                .overlay(Capsule().stroke(cancelling ? colors.error.opacity(0.4) : colors.borderPrimary, lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 14, y: 6)
    }

    private func cancelButton(_ colors: FlareColors) -> some View {
        Button { onCancel?() } label: {
            ZStack {
                Circle().fill(cancelling ? colors.error : colors.bgSecondary)
                Image(systemName: "trash").font(.system(size: 14))
                    .foregroundColor(cancelling ? .white : colors.textSecondary)
            }
            .frame(width: 36, height: 36)
        }.buttonStyle(.plain)
    }

    private func center(_ colors: FlareColors) -> some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 9, height: 9)
                .opacity(blink ? 0.25 : 1)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: blink)
                .onAppear { blink = true }
            Text(durationLabel).font(.system(size: 13).monospacedDigit())
                .foregroundColor(colors.textPrimary)
            HStack(spacing: 2) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, amp in
                    Capsule()
                        .fill(cancelling ? colors.error : colors.primary.opacity(0.7))
                        .frame(width: 2, height: 4 + CGFloat(amp) * 20)
                }
            }
            .frame(height: 24)
        }
    }

    @ViewBuilder
    private func right(_ colors: FlareColors) -> some View {
        if cancelling {
            Text("松开取消").font(.system(size: 12, weight: .medium))
                .foregroundColor(colors.error)
                .padding(.trailing, 6)
        } else {
            Button { onSend?() } label: {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "paperplane.fill").font(.system(size: 14)).foregroundColor(.white)
                }
                .frame(width: 36, height: 36)
            }.buttonStyle(.plain)
        }
    }
}

// MARK: - PollComposer

/// Poll composer — build a multi-option poll with optional multi-select.
/// Spec: Composer/PollComposer (`PollComposerView`).
public struct PollComposerView: View {
    private let maxOptions: Int
    private let onSubmit: ((String, [String], Bool) -> Void)?
    private let onCancel: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var question = ""
    @State private var options: [String] = ["", ""]
    @State private var multiple = false

    public init(maxOptions: Int = 10,
                onSubmit: ((String, [String], Bool) -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.maxOptions = maxOptions; self.onSubmit = onSubmit; self.onCancel = onCancel
    }

    private var filledOptions: [String] {
        options.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
    private var canSubmit: Bool {
        !question.trimmingCharacters(in: .whitespaces).isEmpty && filledOptions.count >= 2
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("发起投票").font(.system(size: 15, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer(minLength: 0)
                Button { onCancel?() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                        .foregroundColor(colors.textTertiary)
                }.buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("输入问题", text: $question)
                    .font(.system(size: 15, weight: .medium)).foregroundColor(colors.textPrimary)
                    .textFieldStyle(.plain)
                Rectangle().fill(colors.borderPrimary).frame(height: 1)
            }

            ForEach(options.indices, id: \.self) { i in
                optionRow(colors, i)
            }

            if options.count < maxOptions {
                Button { options.append("") } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                        Text("添加选项").font(.system(size: 13, weight: .medium))
                    }.foregroundColor(colors.primary)
                }.buttonStyle(.plain)
            }

            Button { multiple.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: multiple ? "checkmark.square" : "square")
                        .font(.system(size: 15)).foregroundColor(multiple ? colors.primary : colors.textTertiary)
                    Text("允许多选").font(.system(size: 13)).foregroundColor(colors.textSecondary)
                    Spacer(minLength: 0)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)

            Button {
                onSubmit?(question.trimmingCharacters(in: .whitespaces), filledOptions, multiple)
            } label: {
                Text("创建投票").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(
                            LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)
        }
        .padding(16)
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func optionRow(_ colors: FlareColors, _ i: Int) -> some View {
        HStack(spacing: 8) {
            TextField("选项 \(i + 1)", text: $options[i])
                .font(.system(size: 14)).foregroundColor(colors.textPrimary)
                .textFieldStyle(.plain)
            if options.count > 2 {
                Button { options.remove(at: i) } label: {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                        .foregroundColor(colors.textTertiary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
    }
}

// MARK: - ChatWallpaperPicker

/// Chat wallpaper picker — swatch grid of colours / images with a selected check.
/// Spec: Settings/ChatWallpaperPicker (`ChatWallpaperPickerView`).
public struct ChatWallpaperPickerView: View {
    private let options: [WallpaperOption]
    private let selectedId: String?
    private let onSelect: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(options: [WallpaperOption], selectedId: String? = nil, onSelect: ((String) -> Void)? = nil) {
        self.options = options; self.selectedId = selectedId; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 10) {
            Text("聊天背景").font(.system(size: 13, weight: .semibold)).foregroundColor(colors.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(options) { option in
                    swatch(colors, option)
                        .onTapGesture { onSelect?(option.id) }
                }
            }
        }
        .padding(14)
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func swatch(_ colors: FlareColors, _ option: WallpaperOption) -> some View {
        let selected = option.id == selectedId
        return ZStack(alignment: .bottomTrailing) {
            fill(colors, option)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
                .overlay(
                    RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                        .stroke(selected ? colors.primary : Color.clear, lineWidth: 2)
                )
            if selected {
                ZStack {
                    Circle().fill(colors.primary)
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                }
                .frame(width: 22, height: 22)
                .padding(4)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func fill(_ colors: FlareColors, _ option: WallpaperOption) -> some View {
        if let imageURLStr = option.imageURL, let url = URL(string: imageURLStr) {
            AsyncImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                colors.bgSecondary
            }
        } else if let hex = option.color, let parsed = Color(hex: hex) {
            parsed
        } else {
            colors.bgSecondary
        }
    }
}
