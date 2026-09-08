import SwiftUI

// Flare 品牌 Logo(通用件,归属 kit)。前倾几何 F,取自品牌色阶。
// 两种呈现:
//  - .gradient(默认):品牌渐变 squircle + 白色 F —— 用于中性/浅底、app 图标、启动图。
//  - .plate:白色 squircle + 品牌渐变 F —— 用于品牌色背景(如登录头的紫色渐变)上,保证对比。
// Spec: Brand/BrandLogo。四端共用同一几何(前倾 skewX -9°)与同一 token。

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

/// Flare 品牌 Logo 视图。
public struct FlareBrandLogo: View {
    private let size: CGFloat
    private let variant: FlareBrandLogoVariant
    @Environment(\.colorScheme) private var scheme

    public init(size: CGFloat = 64, variant: FlareBrandLogoVariant = .gradient) {
        self.size = size
        self.variant = variant
    }

    private func brandGradient(_ c: FlareColors) -> LinearGradient {
        LinearGradient(colors: [c.primaryActive, c.primary, c.info],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    public var body: some View {
        let c = FlareColors.of(scheme)
        ZStack {
            switch variant {
            case .gradient:
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).fill(brandGradient(c))
                FlareBrandFShape().fill(Color.white).frame(width: size, height: size)
            case .plate:
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).fill(.white)
                FlareBrandFShape().fill(brandGradient(c)).frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.12), radius: size * 0.25, y: size * 0.12)
        .accessibilityLabel("flare IM")
    }
}
