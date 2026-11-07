import SwiftUI

// Flare IM brand mark. All platform kits share the italic IM geometry.
// The gradient and plate variants adapt the same mark to neutral or branded surfaces.

public enum FlareBrandLogoVariant: Sendable {
    case gradient
    case plate
}

/// 品牌 F 字形(归一化 100×100 盒,前倾 italic)。公开以便复用。
public struct FlareBrandFShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 100
        var p = Path()
        let rects: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (28, 22, 15, 58, 7),   // 竖干
            (28, 22, 44, 15, 7),   // 上横
            (28, 45, 34, 13, 6),   // 中横
        ]
        for (x, y, w, h, r) in rects {
            p.addRoundedRect(in: CGRect(x: x * s, y: y * s, width: w * s, height: h * s),
                             cornerSize: CGSize(width: r * s, height: r * s))
        }
        let k = CGFloat(tan(-9.0 * .pi / 180))
        let skew = CGAffineTransform(a: 1, b: 0, c: k, d: 1, tx: 0, ty: 0)
        let recenter = CGAffineTransform(translationX: -k * (rect.height / 2), y: 0)
        return p.applying(skew).applying(recenter)
    }
}

private struct FlareBrandIMShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: 22, y: 27, width: 10, height: 48))
        path.move(to: CGPoint(x: 40, y: 75))
        for point in [CGPoint(x: 40, y: 27), CGPoint(x: 50, y: 27), CGPoint(x: 60, y: 48),
                      CGPoint(x: 70, y: 27), CGPoint(x: 80, y: 27), CGPoint(x: 80, y: 75),
                      CGPoint(x: 70, y: 75), CGPoint(x: 70, y: 48), CGPoint(x: 60, y: 65),
                      CGPoint(x: 50, y: 48), CGPoint(x: 50, y: 75)] {
            path.addLine(to: point)
        }
        path.closeSubpath()
        let skew = CGFloat(tan(-9.0 * .pi / 180))
        return path
            .applying(CGAffineTransform(a: 1, b: 0, c: skew, d: 1, tx: -skew * 51, ty: 0))
            .applying(CGAffineTransform(scaleX: rect.width / 100, y: rect.height / 100))
            .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY))
    }
}

/// Shared Flare IM brand logo.
public struct FlareBrandLogo: View {
    private let size: CGFloat
    private let variant: FlareBrandLogoVariant
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(size: CGFloat = 64, variant: FlareBrandLogoVariant = .gradient) {
        self.size = size
        self.variant = variant
    }

    private func brandGradient(_ c: FlareColors) -> LinearGradient {
        LinearGradient(colors: [c.primaryActive, c.primary, c.info],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    public var body: some View {
        let c = FlareColors.of(scheme, brand: flareBrandTheme)
        ZStack {
            switch variant {
            case .gradient:
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).fill(brandGradient(c))
                FlareBrandIMShape().fill(Color.white).frame(width: size, height: size)
            case .plate:
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).fill(.white)
                FlareBrandIMShape().fill(brandGradient(c)).frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.12), radius: size * 0.25, y: size * 0.12)
        .accessibilityLabel("Flare IM")
    }
}
