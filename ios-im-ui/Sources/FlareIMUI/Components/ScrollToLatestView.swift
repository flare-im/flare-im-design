import SwiftUI

// MARK: - ScrollToLatest

/// Scroll-to-latest pill — floating back-to-bottom + unread badge.
public struct ScrollToLatestView: View {
    private let count: Int
    private let onTap: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    public init(count: Int = 0, onTap: (() -> Void)? = nil) { self.count = count; self.onTap = onTap }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Button { onTap?() } label: {
            HStack(spacing: 6) {
                if count > 0 {
                    Text(count > 99 ? "99+" : "\(count)")
                        .font(.system(size: FlareSizes.fontSizeMd, weight: .semibold)).foregroundColor(colors.primary)
                }
                Image(systemName: "arrow.down").font(.system(size: 20)).foregroundColor(.white)
                    .frame(width: 30, height: 30).background(Circle().fill(colors.primary))
            }
            .padding(.leading, count > 0 ? 12 : 8).padding(.trailing, 6).padding(.vertical, 6)
            .background(Capsule().fill(colors.bgPrimary))
            .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}
