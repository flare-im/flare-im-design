import SwiftUI

// MARK: - UnreadDivider

/// Unread divider — the "N new messages" line. Spec: Message/UnreadDivider.
public struct UnreadDividerView: View {
    private let count: Int
    @Environment(\.colorScheme) private var scheme
    public init(count: Int = 0) { self.count = count }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let text = count > 0 ? "\(count) 条新消息" : "新消息"
        HStack(spacing: FlareSizes.spacingMd) {
            Rectangle().fill(colors.primary.opacity(0.24)).frame(height: 1)
            Text(text).font(.system(size: FlareSizes.fontSizeSm, weight: .medium)).foregroundColor(colors.primary)
            Rectangle().fill(colors.primary.opacity(0.24)).frame(height: 1)
        }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
    }
}
