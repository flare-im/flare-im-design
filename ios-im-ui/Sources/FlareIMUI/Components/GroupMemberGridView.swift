import SwiftUI

// MARK: - GroupMemberGrid

/// Group member grid — avatars + owner / admin badges + add-member tile.
/// Spec: Contacts/GroupMemberGrid (`GroupMemberGridView`).
public struct GroupMemberGridView: View {
    private let members: [Contact]
    private let ownerId: String?
    private let adminIds: [String]
    private let showAdd: Bool
    private let columns: Int
    private let onSelect: ((String) -> Void)?
    private let onAddMember: (() -> Void)?
    private let title: String
    private let ownerLabel: String
    private let adminLabel: String
    private let addLabel: String
    private let memberCountText: (Int) -> String
    @Environment(\.colorScheme) private var scheme

    public init(members: [Contact], ownerId: String? = nil, adminIds: [String] = [], showAdd: Bool = true,
                columns: Int = 5, onSelect: ((String) -> Void)? = nil, onAddMember: (() -> Void)? = nil,
                title: String = "群成员", ownerLabel: String = "群主", adminLabel: String = "管理员",
                addLabel: String = "加成员", memberCountText: @escaping (Int) -> String = { "\($0) 名成员" }) {
        self.members = members; self.ownerId = ownerId; self.adminIds = adminIds; self.showAdd = showAdd
        self.columns = columns; self.onSelect = onSelect; self.onAddMember = onAddMember
        self.title = title; self.ownerLabel = ownerLabel; self.adminLabel = adminLabel
        self.addLabel = addLabel; self.memberCountText = memberCountText
    }

    private func role(_ m: Contact) -> String? {
        if m.id == ownerId { return ownerLabel }
        if adminIds.contains(m.id) { return adminLabel }
        return nil
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                Text(memberCountText(members.count)).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
            }
            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(members) { m in cell(colors, m) }
                if showAdd { addCell(colors) }
            }
        }
        .padding(FlareSizes.spacingLg)
    }

    private func cell(_ colors: FlareColors, _ m: Contact) -> some View {
        Button { onSelect?(m.id) } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottom) {
                    AvatarView(userId: m.id, displayName: m.name, avatarURL: m.avatarURL, size: 48)
                    if let r = role(m) {
                        Text(r).font(.system(size: 10)).foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(m.id == ownerId ? colors.warning : colors.textTertiary))
                            .offset(y: 6)
                    }
                }
                Text(m.name).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func addCell(_ colors: FlareColors) -> some View {
        Button { onAddMember?() } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 22)).foregroundColor(colors.textTertiary)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(colors.borderHover, style: StrokeStyle(lineWidth: 1, dash: [4])))
                Text(addLabel).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
