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
                        block(colors, width: 120, height: 11)
                        block(colors, width: 190, height: 11)
                    }
                    Spacer()
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
                HStack(alignment: .bottom, spacing: FlareSizes.spacingSm) {
                    if isSelf { Spacer() }
                    if !isSelf { circle(colors, 32) }
                    block(colors, width: isSelf ? 160 : 200, height: 40, radius: FlareSizes.radiusLg)
                    if !isSelf { Spacer() }
                }
            }
        }
        .padding(FlareSizes.spacingLg)
    }

    private func profile(_ colors: FlareColors) -> some View {
        VStack(spacing: 12) {
            circle(colors, 72)
            block(colors, width: 120, height: 15)
            block(colors, width: 180, height: 11)
        }
        .frame(maxWidth: .infinity)
        .padding(FlareSizes.spacingLg)
    }

    private func text(_ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<rows, id: \.self) { i in
                block(colors, width: i == rows - 1 ? 160 : nil, height: 11)
            }
        }
        .padding(FlareSizes.spacingLg)
    }
}
