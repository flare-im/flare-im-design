import SwiftUI

/// Sticky bar above the thread showing pinned messages; tap to focus one, and
/// (when many) cycle. Spec: Message/PinnedMessageBar (`PinnedMessageBarView`).
public struct PinnedMessageBarView: View {
    private let items: [FlarePinnedMessage]
    private let onFocus: ((FlarePinnedMessage) -> Void)?

    @Environment(\.colorScheme) private var scheme
    @State private var index = 0

    public init(items: [FlarePinnedMessage], onFocus: ((FlarePinnedMessage) -> Void)? = nil) {
        self.items = items
        self.onFocus = onFocus
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if items.isEmpty {
            EmptyView()
        } else {
            let item = items[min(index, items.count - 1)]
            Button {
                onFocus?(item)
                if items.count > 1 { index = (index + 1) % items.count }
            } label: {
                HStack(spacing: FlareSizes.spacingSm) {
                    Image(systemName: "pin.fill").font(.system(size: 14)).foregroundColor(colors.pinned)
                    VStack(alignment: .leading, spacing: 1) {
                        if let name = item.senderName, !name.isEmpty {
                            Text(name).font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                                .foregroundColor(colors.pinned)
                        }
                        Text(item.summary).font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textSecondary).lineLimit(1)
                    }
                    Spacer()
                    if items.count > 1 {
                        Text("\(min(index, items.count - 1) + 1)/\(items.count)")
                            .font(.system(size: FlareSizes.fontSizeXs))
                            .foregroundColor(colors.textTertiary)
                    }
                }
                .padding(.horizontal, FlareSizes.spacingMd)
                .padding(.vertical, FlareSizes.spacingSm)
                .background(colors.bgSecondary)
                .overlay(Rectangle().fill(colors.pinned).frame(width: 3), alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }
}
