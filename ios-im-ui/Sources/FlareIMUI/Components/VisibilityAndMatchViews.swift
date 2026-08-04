import SwiftUI

// MARK: - MomentsVisibilityRuleList

/// Moments visibility list — the members under one rule, with add / remove.
///
/// The two rule kinds point in **opposite** directions: hide-from controls who
/// cannot see me, mute controls whose posts I do not see. Getting them backwards
/// leaks moments to someone the user meant to hide from, so title, hint, empty
/// copy and accent colour are all keyed off `kind` rather than shared.
/// Spec: Moments/MomentsVisibilityRuleList (`MomentsVisibilityRuleListView`).
public struct MomentsVisibilityRuleListView: View {
    private let kind: MomentsVisibilityRuleKind
    private let members: [ContactBrief]
    private let loading: Bool
    private let labels: MomentsVisibilityLabels
    private let onAdd: (() -> Void)?
    private let onRemove: ((ContactBrief) -> Void)?
    private let onSelectMember: ((ContactBrief) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(kind: MomentsVisibilityRuleKind,
                members: [ContactBrief],
                loading: Bool = false,
                labels: MomentsVisibilityLabels = MomentsVisibilityLabels(),
                onAdd: (() -> Void)? = nil,
                onRemove: ((ContactBrief) -> Void)? = nil,
                onSelectMember: ((ContactBrief) -> Void)? = nil) {
        self.kind = kind; self.members = members; self.loading = loading; self.labels = labels
        self.onAdd = onAdd; self.onRemove = onRemove; self.onSelectMember = onSelectMember
    }

    private var isHideFrom: Bool { kind == .hideFrom }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: FlareSizes.spacingSm) {
                Image(systemName: isHideFrom ? "eye.slash" : "speaker.slash")
                    .font(.system(size: 14))
                    // Distinct accents so both rules on one screen stay tellable apart.
                    .foregroundColor(isHideFrom ? colors.warning : colors.textTertiary)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isHideFrom ? labels.hideFromTitle : labels.muteTitle)
                        .font(.system(size: FlareSizes.fontSizeLg))
                        .foregroundColor(colors.textPrimary)
                    Text(isHideFrom ? labels.hideFromHint : labels.muteHint)
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textTertiary)
                }
                Spacer()
                Button { onAdd?() } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(FlareSizes.spacingMd)

            if loading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FlareSizes.spacingLg)
            } else if members.isEmpty {
                Text(labels.empty)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textTertiary)
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .padding(.bottom, FlareSizes.spacingLg)
            } else {
                ForEach(members) { m in
                    HStack(spacing: FlareSizes.spacingSm) {
                        AvatarView(userId: m.userId, displayName: m.displayName,
                                   avatarURL: m.avatarURL, size: 32)
                        Text(m.displayName)
                            .font(.system(size: FlareSizes.fontSizeLg))
                            .foregroundColor(colors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Button { onRemove?(m) } label: {
                            Text(labels.remove)
                                .font(.system(size: FlareSizes.fontSizeMd))
                                .foregroundColor(colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .padding(.vertical, FlareSizes.spacingXs)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelectMember?(m) }
                }
            }
        }
    }
}

/// Copy for `MomentsVisibilityRuleListView`. Kept per-kind on purpose.
public struct MomentsVisibilityLabels: Sendable {
    public let hideFromTitle: String
    public let hideFromHint: String
    public let muteTitle: String
    public let muteHint: String
    public let empty: String
    public let remove: String

    public init(hideFromTitle: String = "不让他看我的朋友圈",
                hideFromHint: String = "名单中的人看不到你发的内容",
                muteTitle: String = "不看他的朋友圈",
                muteHint: String = "你不会看到名单中的人发的内容",
                empty: String = "名单为空",
                remove: String = "移出") {
        self.hideFromTitle = hideFromTitle; self.hideFromHint = hideFromHint
        self.muteTitle = muteTitle; self.muteHint = muteHint
        self.empty = empty; self.remove = remove
    }
}

// MARK: - ContactMatchList

/// Contact-book match results — who from the user's address book is already here.
///
/// Every row echoes `matchedBy`: the display name is whatever nickname the other
/// person chose, which often does not match the address-book name. Without the
/// matched number the user cannot tell who this is.
/// Spec: Contacts/ContactMatchList (`ContactMatchListView`).
public struct ContactMatchListView: View {
    private let matches: [MatchedContact]
    private let loading: Bool
    private let labels: ContactMatchLabels
    private let onAddFriend: ((MatchedContact) -> Void)?
    private let onOpenConversation: ((MatchedContact) -> Void)?
    private let onSelectContact: ((MatchedContact) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(matches: [MatchedContact],
                loading: Bool = false,
                labels: ContactMatchLabels = ContactMatchLabels(),
                onAddFriend: ((MatchedContact) -> Void)? = nil,
                onOpenConversation: ((MatchedContact) -> Void)? = nil,
                onSelectContact: ((MatchedContact) -> Void)? = nil) {
        self.matches = matches; self.loading = loading; self.labels = labels
        self.onAddFriend = onAddFriend; self.onOpenConversation = onOpenConversation
        self.onSelectContact = onSelectContact
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if loading {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, FlareSizes.spacing2xl)
        } else if matches.isEmpty {
            Text(labels.empty)
                .font(.system(size: FlareSizes.fontSizeMd))
                .foregroundColor(colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FlareSizes.spacing2xl)
        } else {
            VStack(spacing: 0) {
                ForEach(matches) { c in
                    HStack(spacing: FlareSizes.spacingMd) {
                        AvatarView(userId: c.userId, displayName: c.displayName,
                                   avatarURL: c.avatarURL, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.displayName)
                                .font(.system(size: FlareSizes.fontSizeLg))
                                .foregroundColor(colors.textPrimary)
                                .lineLimit(1)
                            // Weaker than the name: it identifies, it does not label.
                            Text(c.matchedBy)
                                .font(.system(size: FlareSizes.fontSizeSm))
                                .foregroundColor(colors.textTertiary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if c.alreadyFriend {
                            Button { onOpenConversation?(c) } label: {
                                Text(labels.message)
                                    .font(.system(size: FlareSizes.fontSizeMd))
                                    .foregroundColor(colors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button { onAddFriend?(c) } label: {
                                Text(labels.add)
                                    .font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                                    .foregroundColor(colors.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .padding(.vertical, FlareSizes.spacingSm)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelectContact?(c) }
                }
            }
        }
    }
}

/// Copy for `ContactMatchListView`.
public struct ContactMatchLabels: Sendable {
    public let add: String
    public let message: String
    public let empty: String

    public init(add: String = "添加",
                message: String = "发消息",
                empty: String = "通讯录里还没有已注册的联系人") {
        self.add = add; self.message = message; self.empty = empty
    }
}

// MARK: - AnnouncementReadBar

/// Group-announcement read bar — confirm while unread, x/y read once confirmed.
///
/// `readCount` / `memberCount` must be the server's own counts. The unread member
/// list that ships alongside them is truncated by the server, so deriving a count
/// from its length silently under-reports in large groups — a wrong number that
/// never raises an error.
/// Spec: General/AnnouncementReadBar (`AnnouncementReadBarView`).
public struct AnnouncementReadBarView: View {
    private let readCount: Int
    private let memberCount: Int
    private let selfRead: Bool
    private let canViewUnread: Bool
    private let labels: AnnouncementReadLabels
    private let onConfirm: (() -> Void)?
    private let onViewUnread: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(readCount: Int,
                memberCount: Int,
                selfRead: Bool,
                canViewUnread: Bool = false,
                labels: AnnouncementReadLabels = AnnouncementReadLabels(),
                onConfirm: (() -> Void)? = nil,
                onViewUnread: (() -> Void)? = nil) {
        self.readCount = readCount; self.memberCount = memberCount; self.selfRead = selfRead
        self.canViewUnread = canViewUnread; self.labels = labels
        self.onConfirm = onConfirm; self.onViewUnread = onViewUnread
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        // Counts are hidden until the data lands, so "0/0" never flashes.
        let showCount = memberCount > 0
        let allRead = memberCount > 0 && readCount >= memberCount

        HStack(spacing: FlareSizes.spacingSm) {
            Image(systemName: selfRead ? "checkmark.circle.fill" : "megaphone")
                .font(.system(size: 14))
                .foregroundColor(selfRead ? colors.textTertiary : colors.textSecondary)
            if showCount {
                Text(labels.readCount(readCount, memberCount))
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(selfRead ? colors.textTertiary : colors.textSecondary)
            }
            Spacer()
            if !selfRead {
                Button { onConfirm?() } label: {
                    Text(labels.confirmRead)
                        .font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                        .foregroundColor(colors.primary)
                }
                .buttonStyle(.plain)
            }
            if canViewUnread && !allRead {
                Button { onViewUnread?() } label: {
                    Text(labels.viewUnread)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingSm)
        .background(colors.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd, style: .continuous))
    }
}

/// Copy for `AnnouncementReadBarView`.
public struct AnnouncementReadLabels: Sendable {
    public let confirmRead: String
    public let viewUnread: String
    /// Formats the x/y line. A closure rather than a template so locales that
    /// reorder or pluralise the counts can express it.
    public let readCount: @Sendable (Int, Int) -> String

    public init(confirmRead: String = "已读",
                viewUnread: String = "查看未读",
                readCount: @escaping @Sendable (Int, Int) -> String = { "\($0)/\($1) 人已读" }) {
        self.confirmRead = confirmRead; self.viewUnread = viewUnread; self.readCount = readCount
    }
}
