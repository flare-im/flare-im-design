import SwiftUI

// MARK: - ForwardPicker

/// Forward picker — searchable chat list with single / multi-select + send.
/// Spec: Message/ForwardPicker (`ForwardPickerView`).
public struct ForwardPickerView: View {
    private let targets: [ForwardTarget]
    private let multiple: Bool
    private let dismissible: Bool
    private let onConfirm: (([String]) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var query: String = ""
    @State private var selected: Set<String> = []

    public init(targets: [ForwardTarget], multiple: Bool = true, dismissible: Bool = true,
                onConfirm: (([String]) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.targets = targets; self.multiple = multiple; self.dismissible = dismissible
        self.onConfirm = onConfirm; self.onClose = onClose
    }

    private var filtered: [ForwardTarget] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return targets }
        return targets.filter {
            $0.name.lowercased().contains(q) || ($0.subtitle?.lowercased().contains(q) ?? false)
        }
    }

    private func toggle(_ id: String) {
        if multiple {
            if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        } else {
            selected = selected.contains(id) ? [] : [id]
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingSm) {
                Text("转发给").font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                if dismissible {
                    Button { onClose?() } label: {
                        Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.top, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingMd)

            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                TextField("搜索会话", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
            }
            .padding(.horizontal, FlareSizes.spacingMd).frame(height: 38)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .padding(.horizontal, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingMd)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filtered) { t in row(colors, t) }
                }
            }
            .frame(maxHeight: 300)

            Divider().overlay(colors.borderPrimary)

            HStack(spacing: FlareSizes.spacingMd) {
                Text("已选 \(selected.count)").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                Spacer()
                Button { onConfirm?(Array(selected)) } label: {
                    Text("发送").font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, FlareSizes.spacingLg).frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(
                                LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                }
                .buttonStyle(.plain)
                .disabled(selected.isEmpty)
                .opacity(selected.isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)
        }
        .frame(width: 340)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func row(_ colors: FlareColors, _ t: ForwardTarget) -> some View {
        let isSel = selected.contains(t.id)
        return Button { toggle(t.id) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                ZStack {
                    Circle().stroke(colors.borderHover, lineWidth: 1).frame(width: 20, height: 20)
                    if isSel {
                        Circle().fill(colors.primary).frame(width: 20, height: 20)
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                    }
                }
                AvatarView(userId: t.id, displayName: t.name, avatarURL: t.avatarURL, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary).lineLimit(1)
                    if let sub = t.subtitle, !sub.isEmpty {
                        Text(sub).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
            .background(isSel ? colors.bgSelected : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
