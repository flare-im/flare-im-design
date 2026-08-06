import SwiftUI

// MARK: - QRCard

/// QR card — personal add-me card with avatar + decorative QR matrix.
/// Spec: Profile/QRCard (`QRCardView`).
public struct QRCardView: View {
    private let name: String
    private let subtitle: String?
    private let avatarURL: String?
    private let qrImageURL: String?
    @Environment(\.colorScheme) private var scheme

    public init(name: String, subtitle: String? = nil, avatarURL: String? = nil, qrImageURL: String? = nil) {
        self.name = name; self.subtitle = subtitle; self.avatarURL = avatarURL; self.qrImageURL = qrImageURL
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: FlareSizes.spacingMd) {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: name, displayName: name, avatarURL: avatarURL, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 16, weight: .semibold)).foregroundColor(colors.textPrimary).lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle).font(.system(size: 12)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            qrPanel(colors)

            Text("扫一扫加我").font(.system(size: 12)).foregroundColor(colors.textTertiary)
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(width: 240)
        .background(RoundedRectangle(cornerRadius: 16).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.14), radius: 24, y: 10)
    }

    private func qrPanel(_ colors: FlareColors) -> some View {
        Group {
            if let qrImageURL, let url = URL(string: qrImageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    matrix(colors)
                }
            } else {
                matrix(colors)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
    }

    private func matrix(_ colors: FlareColors) -> some View {
        let seed = name.unicodeScalars.reduce(7) { $0 + Int($1.value) }
        let color = colors.textPrimary
        return Canvas { ctx, size in
            let n = 11
            let cell = size.width / CGFloat(n)
            let inset = cell * 0.14
            for y in 0..<n {
                for x in 0..<n {
                    // skip finder-pattern corners
                    if (x < 3 && y < 3) || (x > 7 && y < 3) || (x < 3 && y > 7) { continue }
                    if ((x * 31 + y * 17 + seed) % 5) == 0 {
                        let rect = CGRect(x: CGFloat(x) * cell + inset, y: CGFloat(y) * cell + inset,
                                          width: cell - inset * 2, height: cell - inset * 2)
                        ctx.fill(Path(roundedRect: rect, cornerRadius: cell * 0.22), with: .color(color))
                    }
                }
            }
            // finder patterns at three corners
            let finderOrigins: [(Int, Int)] = [(0, 0), (8, 0), (0, 8)]
            for (fx, fy) in finderOrigins {
                let outer = CGRect(x: CGFloat(fx) * cell + inset, y: CGFloat(fy) * cell + inset,
                                   width: cell * 3 - inset * 2, height: cell * 3 - inset * 2)
                ctx.stroke(Path(roundedRect: outer, cornerRadius: cell * 0.5),
                           with: .color(color), lineWidth: cell * 0.34)
                let dot = outer.insetBy(dx: cell * 0.75, dy: cell * 0.75)
                ctx.fill(Path(roundedRect: dot, cornerRadius: cell * 0.3), with: .color(color))
            }
        }
    }
}
