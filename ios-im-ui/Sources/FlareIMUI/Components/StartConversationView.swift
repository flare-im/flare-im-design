import SwiftUI

/// New-conversation entry — pick a contact (single) or several (group). Spec:
/// Conversation/StartConversationDialog (`StartConversationView`). Contacts come
/// from the product; `onConfirm` returns the selected ids.
public struct StartConversationView: View {
    private let contacts: [FlareContactOption]
    private let allowGroup: Bool
    private let busy: Bool
    private let onConfirm: (([String]) -> Void)?

    @Environment(\.colorScheme) private var scheme
    @State private var selected: Set<String> = []
    @State private var query: String = ""

    public init(
        contacts: [FlareContactOption],
        allowGroup: Bool = true,
        busy: Bool = false,
        onConfirm: (([String]) -> Void)? = nil
    ) {
        self.contacts = contacts
        self.allowGroup = allowGroup
        self.busy = busy
        self.onConfirm = onConfirm
    }

    private var filtered: [FlareContactOption] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return contacts }
        let q = query.lowercased()
        return contacts.filter {
            $0.name.lowercased().contains(q) || ($0.subtitle?.lowercased().contains(q) ?? false)
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "magnifyingglass").foregroundColor(colors.textTertiary)
                TextField("搜索联系人", text: $query)
            }
            .padding(FlareSizes.spacingSm)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .padding(FlareSizes.spacingMd)

            List(filtered) { c in
                Button {
                    if allowGroup { toggle(c.id) } else { onConfirm?([c.id]) }
                } label: {
                    HStack {
                        AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 40)
                        VStack(alignment: .leading) {
                            Text(c.name).foregroundColor(colors.textPrimary)
                            if let sub = c.subtitle {
                                Text(sub).font(.system(size: FlareSizes.fontSizeSm))
                                    .foregroundColor(colors.textTertiary).lineLimit(1)
                            }
                        }
                        Spacer()
                        if allowGroup {
                            Image(systemName: selected.contains(c.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selected.contains(c.id) ? colors.primary : colors.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)

            if allowGroup {
                Button {
                    onConfirm?(Array(selected))
                } label: {
                    Group {
                        if busy {
                            ProgressView().tint(.white)
                        } else {
                            Text(selected.isEmpty ? "确定" : "确定 (\(selected.count))")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FlareSizes.spacingMd)
                    .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                        .fill(selected.isEmpty || busy ? colors.bgDisabled : colors.primary))
                    .foregroundColor(selected.isEmpty || busy ? colors.textDisabled : .white)
                }
                .disabled(selected.isEmpty || busy)
                .padding(FlareSizes.spacingMd)
            }
        }
    }

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }
}
