import SwiftUI

/// The map area of a location card and of the location picker: the static map when there is one, otherwise — and
/// while it loads or when it fails — the drawn map ground (``FlareMapPlaceholder``), never a blank. Over the picture
/// only, `attribution` (OpenStreetMap's ODbL credit) sits in the bottom-right corner as a small line of secondary text
/// on a translucent ground, at most 60% of the width so it stays clear of the centre marker; the drawn ground is not
/// map data and carries none.
struct FlareMapSnapshot: View {
    let url: String?
    let attribution: String?
    var pin: Bool = true

    /// The credit a static map carries: OpenStreetMap's for the osm provider, none for amap.
    static func attribution(_ provider: FlareLocationProvider, _ strings: FlareStrings) -> String? {
        provider == .osm ? strings.locationOsmAttribution : nil
    }

    var body: some View {
        if let picture = flarePictureURL(url) {
            AsyncImage(url: picture) { phase in
                if case .success(let image) = phase {
                    Color.clear
                        .overlay(image.resizable().scaledToFill())
                        .clipped()
                        .overlay(alignment: .bottomTrailing) {
                            if let attribution, !attribution.isEmpty { FlareMapAttribution(text: attribution) }
                        }
                } else {
                    FlareMapPlaceholder(pin: pin)
                }
            }
        } else {
            FlareMapPlaceholder(pin: pin)
        }
    }
}

/// The map data's credit in the corner of a static map.
struct FlareMapAttribution: View {
    let text: String
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        GeometryReader { geo in
            Text(text)
                .font(.system(size: FlareSizes.fontSize2xs))
                .foregroundColor(colors.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, FlareSizes.spacingXs)
                .background(UnevenCornerGround(radius: FlareSizes.radiusXs).fill(colors.bgPrimary.opacity(0.72)))
                .frame(maxWidth: geo.size.width * 0.6, alignment: .trailing)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .allowsHitTesting(false)
    }
}

/// A rectangle with only its top-left corner rounded (the attribution's ground sits in the picture's corner).
private struct UnevenCornerGround: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.height / 2, rect.width / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r,
                    startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
