import SwiftUI

// MARK: - ReadReceiptSheet

/// Read receipt sheet — read / unread tabs with member lists.
/// Spec: Message/ReadReceiptSheet (`ReadReceiptSheetView`).
public struct ReadReceiptSheetView: View {
    private let readers: [Contact]
    private let unread: [Contact]
    private let dismissible: Bool
    private let onSelect: ((String) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var activeTab: Int = 0

    public init(readers: [Contact], unread: [Contact], dismissible: Bool = false,
                onSelect: ((String) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.readers = readers; self.unread = unread; self.dismissible = dismissible
        self.onSelect = onSelect; self.onClose = onClose
    }

    private var activeList: [Contact] { activeTab == 0 ? readers : unread }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "checkmark.circle").font(.system(size: 16)).foregroundColor(colors.primary)
                Text("已读回执").font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                if dismissible {
                    Button { onClose?() } label: {
                        Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.top, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingMd)

            HStack(spacing: 0) {
                tab(colors, 0, "已读 (\(readers.count))")
                tab(colors, 1, "未读 (\(unread.count))")
            }
            .padding(.horizontal, FlareSizes.spacingLg)

            Divider().overlay(colors.borderPrimary)

            if activeList.isEmpty {
                Text(activeTab == 0 ? "还没有人已读" : "所有人都已读")
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 28)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(activeList) { c in row(colors, c) }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func tab(_ colors: FlareColors, _ index: Int, _ label: String) -> some View {
        let active = activeTab == index
        return Button { activeTab = index } label: {
            VStack(spacing: 6) {
                Text(label).font(.system(size: FlareSizes.fontSizeLg, weight: active ? .semibold : .regular))
                    .foregroundColor(active ? colors.primary : colors.textSecondary)
                Rectangle().fill(active ? colors.primary : Color.clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }

    private func row(_ colors: FlareColors, _ c: Contact) -> some View {
        Button { onSelect?(c.id) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 36, presence: c.presence)
                Text(c.name).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }
}
