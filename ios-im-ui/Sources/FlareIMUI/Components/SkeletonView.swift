import SwiftUI

// MARK: - Skeleton

/// Skeleton placeholder — shimmering loading blocks for common layouts.
/// Spec: General/Skeleton (`SkeletonView`).
public enum SkeletonVariant: Sendable { case conversation, message, profile, text }

public struct SkeletonView: View {
    private let variant: SkeletonVariant
    private let rows: Int
    private let still: Bool
    @Environment(\.colorScheme) private var scheme
    @State private var animating = false

    public init(variant: SkeletonVariant = .conversation, rows: Int = 4, still: Bool = false) {
        self.variant = variant; self.rows = rows; self.still = still
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Group {
            switch variant {
            case .conversation: conversation(colors)
            case .message: message(colors)
            case .profile: profile(colors)
            case .text: text(colors)
            }
        }
        .onAppear { if !still { animating = true } }
    }

    private func block(_ colors: FlareColors, width: CGFloat? = nil, height: CGFloat, radius: CGFloat = 6) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(colors.bgSecondary)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .overlay(shimmer(radius: radius))
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    /// A line sized as a fraction of the available width (Android / Flutter
    /// parity — fixed pixel widths don't scale across screen sizes).
    private func line(_ colors: FlareColors, fraction: CGFloat, height: CGFloat, radius: CGFloat = 6) -> some View {
        GeometryReader { geo in
            block(colors, width: geo.size.width * fraction, height: height, radius: radius)
        }
        .frame(height: height)
    }

    @ViewBuilder
    private func shimmer(radius: CGFloat) -> some View {
        if still {
            EmptyView()
        } else {
            GeometryReader { geo in
                LinearGradient(colors: [.clear, Color.white.opacity(0.18), .clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: animating ? geo.size.width : -geo.size.width * 0.6)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false), value: animating)
            }
        }
    }

    private func circle(_ colors: FlareColors, _ size: CGFloat) -> some View {
        Circle().fill(colors.bgSecondary).frame(width: size, height: size)
            .overlay(shimmer(radius: size / 2)).clipShape(Circle())
    }

    private func conversation(_ colors: FlareColors) -> some View {
        VStack(spacing: 14) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: FlareSizes.spacingMd) {
                    circle(colors, 44)
                    VStack(alignment: .leading, spacing: 8) {
                        line(colors, fraction: 0.42, height: 11)
                        line(colors, fraction: 0.68, height: 11)
                    }
                    block(colors, width: 34, height: 11)
                }
            }
        }
        .padding(FlareSizes.spacingLg)
    }

    private func message(_ colors: FlareColors) -> some View {
        VStack(spacing: 16) {
            ForEach(0..<rows, id: \.self) { i in
                let isSelf = i % 2 == 1
                let fractions: [CGFloat] = [0.6, 0.45, 0.7, 0.5, 0.65]
                let fraction = fractions[i % fractions.count]
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: FlareSizes.spacingSm) {
                        if isSelf { Spacer(minLength: 0) }
                        if !isSelf { circle(colors, 32) }
                        block(colors, width: geo.size.width * fraction, height: 40, radius: FlareSizes.radiusLg)
                        if !isSelf { Spacer(minLength: 0) }
                    }
                }
                .frame(height: 40)
            }
        }
        .padding(FlareSizes.spacingLg)
    }

    private func profile(_ colors: FlareColors) -> some View {
        VStack(spacing: 12) {
            circle(colors, 72)
            centeredLine(colors, fraction: 0.4, height: 15)
            centeredLine(colors, fraction: 0.6, height: 11)
        }
        .frame(maxWidth: .infinity)
        .padding(FlareSizes.spacingLg)
    }

    private func centeredLine(_ colors: FlareColors, fraction: CGFloat, height: CGFloat) -> some View {
        GeometryReader { geo in
            block(colors, width: geo.size.width * fraction, height: height)
                .frame(maxWidth: .infinity)
        }
        .frame(height: height)
    }

    private func text(_ colors: FlareColors) -> some View {
        let fractions: [CGFloat] = [0.9, 0.75, 0.85, 0.6, 0.8]
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<rows, id: \.self) { i in
                line(colors, fraction: fractions[i % fractions.count], height: 11)
            }
        }
        .padding(FlareSizes.spacingLg)
    }
}
