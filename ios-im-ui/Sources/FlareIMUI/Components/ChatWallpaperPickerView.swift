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
