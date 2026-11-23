import SwiftUI

/// The red packet arch: the solid red full-width band under the header of the red packet pages (composer, review,
/// details). Spec: RedPacketArch (`RedPacketArchView`); Vue `RedPacketArch`, Flutter `FlareRedPacketArch`.
///
/// It spans its container's width — place it straight under the header, never inside a clipped card — and is
/// hidden from VoiceOver. `compact` is the composer's and review's 32pt arch; the details page uses the full
/// ``FlareSizes/componentRedPacketDetailHeaderHeight``.
public struct RedPacketArchView: View {
    private let compact: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(compact: Bool = false) { self.compact = compact }

    /// The arch's height: compact (composer, review) or the details header's.
    static func height(compact: Bool) -> CGFloat {
        compact ? FlareSizes.componentRedPacketArchCompactHeight : FlareSizes.componentRedPacketDetailHeaderHeight
    }

    public var body: some View {
        RedPacketArchShape()
            .fill(FlareColors.of(scheme, brand: flareBrandTheme).redPacketEnd)
            .frame(maxWidth: .infinity)
            .frame(height: Self.height(compact: compact))
            .clipped()
            .accessibilityHidden(true)
    }
}

/// A full-width band: straight sides 60% of the height, the bottom bowed across the whole width by the other 40%
/// (the lower half of an ellipse as wide as the frame) — CSS `border-radius: 0 0 50% 50% / 0 0 40% 40%`.
struct RedPacketArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let bow = rect.height * 0.4, side = rect.maxY - bow, k: CGFloat = 0.5522847498  // cubic quarter-ellipse
        let rx = rect.width / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: side))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.maxX, y: side + bow * k),
                      control2: CGPoint(x: rect.midX + rx * k, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX, y: side), control1: CGPoint(x: rect.midX - rx * k, y: rect.maxY),
                      control2: CGPoint(x: rect.minX, y: side + bow * k))
        path.closeSubpath()
        return path
    }
}
