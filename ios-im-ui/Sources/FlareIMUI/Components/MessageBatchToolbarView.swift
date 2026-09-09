import SwiftUI

// MARK: - MessageBatchToolbar

/// Multi-select batch toolbar — select-all / forward / delete / exit.
/// Spec: Message/MessageBatchToolbar (`MessageBatchToolbarView`).
public struct MessageBatchToolbarView: View {
    private let count: Int
    private let total: Int
    private let busy: Bool
    private let onSelectAll: (() -> Void)?
    private let onForwardEach: (() -> Void)?
    private let onForwardMerged: (() -> Void)?
    private let onDelete: (() -> Void)?
    private let onExit: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareStrings) private var strings

    public init(count: Int, total: Int, busy: Bool = false,
                onSelectAll: (() -> Void)? = nil, onForwardEach: (() -> Void)? = nil,
                onForwardMerged: (() -> Void)? = nil, onDelete: (() -> Void)? = nil,
                onExit: (() -> Void)? = nil) {
        self.count = count; self.total = total; self.busy = busy
        self.onSelectAll = onSelectAll; self.onForwardEach = onForwardEach
        self.onForwardMerged = onForwardMerged; self.onDelete = onDelete; self.onExit = onExit
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingSm) {
            HStack(spacing: 4) {
                Text("\(count)").font(.system(size: FlareSizes.fontSizeLg, weight: .bold)).foregroundColor(colors.primary)
                Text("/ \(total) · \(strings.selectedSuffix)").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
            Spacer(minLength: FlareSizes.spacingMd)
            button(colors, "checkmark.circle", strings.selectAll, onSelectAll, disabled: total == 0 || busy)
            button(colors, "arrowshape.turn.up.right", strings.forwardEach, onForwardEach, disabled: count == 0 || busy)
            button(colors, "square.stack", strings.forwardMerged, onForwardMerged, disabled: count < 2 || busy)
            button(colors, "trash", strings.delete, onDelete, disabled: count == 0 || busy, tint: colors.error)
            iconButton(colors, "xmark", onExit)
        }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)
    }

    private func button(_ colors: FlareColors, _ icon: String, _ label: String, _ onTap: (() -> Void)?,
                        disabled: Bool, tint: Color? = nil) -> some View {
        Button { onTap?() } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 14))
                Text(label).font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
            }
            .foregroundColor(tint ?? colors.textPrimary)
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(height: 32)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }

    private func iconButton(_ colors: FlareColors, _ icon: String, _ onTap: (() -> Void)?) -> some View {
        Button { onTap?() } label: {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
        }
        .buttonStyle(.plain)
    }
}
