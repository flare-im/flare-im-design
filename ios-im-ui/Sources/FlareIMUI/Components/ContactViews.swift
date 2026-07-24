import SwiftUI

/// Directory row. Spec: Contacts/ContactItem (`ContactItemView`).
public struct ContactItemView: View {
    private let item: Contact
    private let showPresence: Bool
    private let onSelect: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(item: Contact, showPresence: Bool = true, onSelect: (() -> Void)? = nil) {
        self.item = item; self.showPresence = showPresence; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Button { onSelect?() } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: item.id, displayName: item.name, avatarURL: item.avatarURL,
                           size: 40, presence: showPresence ? item.presence : nil)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.system(size: FlareSizes.fontSizeXl, weight: .medium)).foregroundColor(colors.textPrimary)
                    if let s = item.signature, !s.isEmpty {
                        Text(s).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Directory grouped A-Z with a side index. Spec: Contacts/ContactList (`ContactListView`).
public struct ContactListView: View {
    private let items: [Contact]
    private let indexed: Bool
    private let loading: Bool
    private let onSelect: ((Contact) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(items: [Contact], indexed: Bool = true, loading: Bool = false, onSelect: ((Contact) -> Void)? = nil) {
        self.items = items; self.indexed = indexed; self.loading = loading; self.onSelect = onSelect
    }

    private static func letter(_ c: Contact) -> String {
        let k = (c.indexKey ?? c.name.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "#").uppercased()
        if let ch = k.first, ch >= "A", ch <= "Z" { return String(ch) }
        return "#"
    }

    private var groups: [(letter: String, people: [Contact])] {
        Dictionary(grouping: items, by: { Self.letter($0) })
            .map { (letter: $0.key, people: $0.value) }
            .sorted { $0.letter < $1.letter }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if items.isEmpty {
            if loading { ProgressView() } else { EmptyStateView(title: "还没有联系人", systemImage: "person.2") }
        } else {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groups, id: \.letter) { g in
                                Section {
                                    ForEach(g.people) { c in
                                        ContactItemView(item: c) { onSelect?(c) }
                                            .padding(.horizontal, FlareSizes.spacingMd)
                                            .padding(.vertical, FlareSizes.spacingXs)
                                    }
                                } header: {
                                    Text(g.letter)
                                        .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                                        .foregroundColor(colors.textTertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, 4)
                                        .background(colors.bgSecondary)
                                        .id(g.letter)
                                }
                            }
                        }
                    }
                    if indexed && groups.count > 1 {
                        VStack(spacing: 2) {
                            ForEach(groups, id: \.letter) { g in
                                Text(g.letter)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(colors.primary)
                                    .onTapGesture { withAnimation { proxy.scrollTo(g.letter, anchor: .top) } }
                            }
                        }
                        .padding(.trailing, 2)
                    }
                }
            }
        }
    }
}

/// Contact name card. Spec: Contacts/ContactDetail (`ContactDetailView`).
public struct ContactDetailView: View {
    private let contact: Contact
    private let onMessage: (() -> Void)?
    private let onCall: (() -> Void)?
    private let onVideo: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(contact: Contact, onMessage: (() -> Void)? = nil, onCall: (() -> Void)? = nil, onVideo: (() -> Void)? = nil) {
        self.contact = contact; self.onMessage = onMessage; self.onCall = onCall; self.onVideo = onVideo
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: FlareSizes.spacingSm) {
            AvatarView(userId: contact.id, displayName: contact.name, avatarURL: contact.avatarURL, size: 88, presence: contact.presence)
            Text(contact.name).font(.system(size: FlareSizes.fontSize4xl, weight: .semibold)).foregroundColor(colors.textPrimary)
            if let s = contact.signature, !s.isEmpty {
                Text(s).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
            }
            HStack(spacing: FlareSizes.spacingMd) {
                actionButton("发消息", "message", onMessage, colors, primary: true)
                actionButton("语音", "phone", onCall, colors)
                actionButton("视频", "video", onVideo, colors)
            }
            .padding(.top, FlareSizes.spacingLg)
        }
        .padding(FlareSizes.spacingLg)
    }

    private func actionButton(_ label: String, _ icon: String, _ action: (() -> Void)?, _ colors: FlareColors, primary: Bool = false) -> some View {
        Button { action?() } label: {
            Label(label, systemImage: icon).font(.system(size: FlareSizes.fontSizeMd))
                .frame(maxWidth: .infinity).padding(.vertical, FlareSizes.spacingSm)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(primary ? colors.primary : colors.bgSecondary))
                .foregroundColor(primary ? .white : colors.textPrimary)
        }
        .buttonStyle(.plain)
    }
}

/// New friends — incoming requests. Spec: Contacts/NewFriendRequests (`NewFriendRequestsView`).
public struct NewFriendRequestsView: View {
    private let items: [FriendRequest]
    private let onAccept: ((FriendRequest) -> Void)?
    private let onReject: ((FriendRequest) -> Void)?
    private let emptyText: String
    private let acceptLabel: String
    private let declineLabel: String
    @Environment(\.colorScheme) private var scheme

    public init(items: [FriendRequest], emptyText: String = "没有新的好友请求",
                acceptLabel: String = "接受", declineLabel: String = "拒绝",
                onAccept: ((FriendRequest) -> Void)? = nil, onReject: ((FriendRequest) -> Void)? = nil) {
        self.items = items; self.emptyText = emptyText
        self.acceptLabel = acceptLabel; self.declineLabel = declineLabel
        self.onAccept = onAccept; self.onReject = onReject
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if items.isEmpty {
            EmptyStateView(title: emptyText, systemImage: "person.badge.plus")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { req in
                        HStack(spacing: FlareSizes.spacingMd) {
                            AvatarView(userId: req.id, displayName: req.name, avatarURL: req.avatarURL, size: 44)
                            VStack(alignment: .leading) {
                                Text(req.name).font(.system(size: FlareSizes.fontSizeXl, weight: .medium)).foregroundColor(colors.textPrimary)
                                if let m = req.message, !m.isEmpty {
                                    Text(m).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                                }
                            }
                            Spacer()
                            Button(declineLabel) { onReject?(req) }.buttonStyle(.bordered).controlSize(.small)
                            Button(acceptLabel) { onAccept?(req) }.buttonStyle(.borderedProminent).controlSize(.small).tint(colors.primary)
                        }
                        .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
                    }
                }
            }
        }
    }
}

/// My groups. Spec: Contacts/GroupList (`GroupListView`).
public struct GroupListView: View {
    private let items: [GroupSummary]
    private let onSelect: ((GroupSummary) -> Void)?
    private let emptyText: String
    @Environment(\.colorScheme) private var scheme

    public init(items: [GroupSummary], emptyText: String = "还没有群组", onSelect: ((GroupSummary) -> Void)? = nil) {
        self.items = items; self.emptyText = emptyText; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if items.isEmpty {
            EmptyStateView(title: emptyText, systemImage: "person.3")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { g in
                        Button { onSelect?(g) } label: {
                            HStack(spacing: FlareSizes.spacingMd) {
                                AvatarView(userId: g.id, displayName: g.name, avatarURL: g.avatarURL, size: 44)
                                VStack(alignment: .leading) {
                                    Text(g.name).font(.system(size: FlareSizes.fontSizeXl, weight: .medium)).foregroundColor(colors.textPrimary)
                                    Text("\(g.memberCount) 名成员").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
