import SwiftUI

// MARK: - MentionPicker

/// @mention picker — search field + optional "Everyone" + member list.
/// Spec: Composer/MentionPicker (`MentionPickerView`).
public struct MentionPickerView: View {
    private let candidates: [MentionCandidate]
    private let allowEveryone: Bool
    private let onSelect: ((MentionCandidate) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var query: String = ""

    public init(candidates: [MentionCandidate], allowEveryone: Bool = false,
                onSelect: ((MentionCandidate) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.candidates = candidates; self.allowEveryone = allowEveryone
        self.onSelect = onSelect; self.onClose = onClose
    }

    private var filtered: [MentionCandidate] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return candidates }
        return candidates.filter {
            $0.name.lowercased().contains(q) || ($0.detail?.lowercased().contains(q) ?? false)
        }
    }

    private var showEveryone: Bool {
        guard allowEveryone else { return false }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty || "everyone".contains(q)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                TextField("搜索成员", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)

            Divider().overlay(colors.borderPrimary)

            if !showEveryone && filtered.isEmpty {
                Text("没有匹配的成员")
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if showEveryone { everyoneRow(colors) }
                        ForEach(filtered) { c in personRow(colors, c) }
                    }
                }
                .frame(maxHeight: 264)
            }
        }
        .frame(width: 280)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func everyoneRow(_ colors: FlareColors) -> some View {
        Button {
            onSelect?(MentionCandidate(id: "__all__", name: "所有人", isEveryone: true))
        } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                Image(systemName: "person.2").font(.system(size: 15)).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Circle().fill(colors.primary))
                VStack(alignment: .leading, spacing: 1) {
                    Text("所有人").font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
                    Text("通知全体成员").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }

    private func personRow(_ colors: FlareColors, _ c: MentionCandidate) -> some View {
        Button { onSelect?(c) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(c.name).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary).lineLimit(1)
                    if let d = c.detail, !d.isEmpty {
                        Text(d).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }
}
