import SwiftUI

/// 发动态时的「谁可以看」。
///
/// 两层正交：`visibility` 圈定人群（朋友 / 公开 / 私密，`spec/moments-privacy.json`），`audienceMode` 在其上
/// 做加减（1=部分可见 2=不给谁看）。
///
/// **两个方向的出错后果不对称**：把「部分可见」设成「不给谁看」，动态会发给你本想
/// 避开的所有人；反过来只是少给几个人看。所以两项不共用措辞，也不共用强调色。
/// Spec: Moments/MomentAudienceSheet (`MomentAudienceSheetView`).
public struct MomentAudienceSheetView: View {
    private let visibility: FlareMomentVisibility
    private let audienceMode: FlareMomentAudienceMode
    private let audienceUserIds: [String]
    private let contacts: [ContactBrief]
    private let labels: MomentAudienceLabels
    private let onVisibilityChanged: ((FlareMomentVisibility) -> Void)?
    private let onAudienceChanged: ((FlareMomentAudienceMode, [String]) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(visibility: FlareMomentVisibility,
                audienceMode: FlareMomentAudienceMode,
                audienceUserIds: [String],
                contacts: [ContactBrief],
                labels: MomentAudienceLabels = MomentAudienceLabels(),
                onVisibilityChanged: ((FlareMomentVisibility) -> Void)? = nil,
                onAudienceChanged: ((FlareMomentAudienceMode, [String]) -> Void)? = nil,
                onClose: (() -> Void)? = nil) {
        self.visibility = visibility; self.audienceMode = audienceMode
        self.audienceUserIds = audienceUserIds; self.contacts = contacts; self.labels = labels
        self.onVisibilityChanged = onVisibilityChanged
        self.onAudienceChanged = onAudienceChanged
        self.onClose = onClose
    }

    /// 私密时名单没有意义：没人看得到，加减谁都不改变结果。
    private var audienceApplies: Bool { flareMomentAudienceApplies(visibility) }

    private func pickMode(_ mode: FlareMomentAudienceMode) {
        // 再点一次当前模式即取消，并清空名单 —— 留着名单而把 mode 归零，
        // 下次切回来会突然冒出一份用户以为已经删掉的名单。
        let next: FlareMomentAudienceMode = audienceMode == mode ? .everyone : mode
        onAudienceChanged?(next, next == .everyone ? [] : audienceUserIds)
    }

    private func toggle(_ c: ContactBrief) {
        var ids = audienceUserIds
        if let i = ids.firstIndex(of: c.userId) { ids.remove(at: i) } else { ids.append(c.userId) }
        onAudienceChanged?(audienceMode, ids)
    }

    private var copy: MomentAudienceLabels.Resolved { labels.resolve(strings) }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let picked = Set(audienceUserIds)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(copy.title)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textPrimary)
                    .padding(FlareSizes.spacingMd)

                row("person.2", copy.friends, copy.friendsHint, visibility == .friends, colors) {
                    onVisibilityChanged?(.friends)
                }
                row("globe", copy.public, copy.publicHint, visibility == .public, colors) {
                    onVisibilityChanged?(.public)
                }
                row("lock", copy.private, copy.privateHint, visibility == .private, colors) {
                    onVisibilityChanged?(.private)
                }

                if audienceApplies {
                    Divider()
                    row("person.badge.plus", copy.include, copy.includeHint,
                        audienceMode == .include, colors, accent: colors.primary,
                        trailing: audienceMode == .include ? copy.selected(audienceUserIds.count) : nil) {
                        pickMode(.include)
                    }
                    row("eye.slash", copy.exclude, copy.excludeHint,
                        audienceMode == .exclude, colors, accent: colors.warning,
                        trailing: audienceMode == .exclude ? copy.selected(audienceUserIds.count) : nil) {
                        pickMode(.exclude)
                    }

                    if audienceMode != .everyone {
                        Divider()
                        Text(copy.pick)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary)
                            .padding(.horizontal, FlareSizes.spacingMd)
                            .padding(.vertical, FlareSizes.spacingSm)
                        ForEach(contacts) { c in
                            Button { toggle(c) } label: {
                            HStack(spacing: FlareSizes.spacingSm) {
                                AvatarView(userId: c.userId, displayName: c.displayName,
                                           avatarURL: c.avatarURL, size: 32)
                                Text(c.displayName)
                                    .font(.system(size: FlareSizes.fontSizeLg))
                                    .foregroundColor(colors.textPrimary)
                                Spacer()
                                if picked.contains(c.userId) {
                                    Image(systemName: "checkmark").foregroundColor(colors.primaryText)
                                }
                            }
                            .padding(.horizontal, FlareSizes.spacingMd)
                            .padding(.vertical, FlareSizes.spacingXs)
                            .background(picked.contains(c.userId) ? colors.bgHover : Color.clear)
                            .contentShape(Rectangle())
                            .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(picked.contains(c.userId) ? .isSelected : [])
                        }
                    }
                }

                Divider()
                HStack {
                    Spacer()
                    Button(copy.done) { onClose?() }
                        .font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                        .foregroundColor(colors.primaryText)
                }
                .padding(FlareSizes.spacingMd)
            }
        }
    }

    @ViewBuilder
    private func row(_ systemImage: String,
                     _ title: String,
                     _ hint: String,
                     _ active: Bool,
                     _ colors: FlareColors,
                     accent: Color? = nil,
                     trailing: String? = nil,
                     action: @escaping () -> Void) -> some View {
        let tone = active ? (accent ?? colors.textPrimary) : colors.textSecondary
        Button(action: action) {
        HStack(spacing: FlareSizes.spacingSm) {
            Image(systemName: systemImage).font(.system(size: 16)).foregroundColor(tone)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(tone)
                Text(hint).font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
            }
            Spacer()
            if let trailing {
                Text(trailing).font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
            } else if active {
                Image(systemName: "checkmark").foregroundColor(colors.primaryText)
            }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingSm)
        .contentShape(Rectangle())
        .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

/// Copy for `MomentAudienceSheetView`. 两个方向的措辞刻意分开。
public struct MomentAudienceLabels: Sendable {
    public let title: String?
    public let `public`: String?
    public let publicHint: String?
    public let friends: String?
    public let friendsHint: String?
    public let `private`: String?
    public let privateHint: String?
    public let include: String?
    public let includeHint: String?
    public let exclude: String?
    public let excludeHint: String?
    public let pick: String?
    public let done: String?
    /// 「已选 N 人」。闭包而非模板串，让复数形式不同的语言也能表达。
    public let selected: (@Sendable (Int) -> String)?

    public init(title: String? = nil,
                public publicLabel: String? = nil,
                publicHint: String? = nil,
                friends: String? = nil,
                friendsHint: String? = nil,
                private privateLabel: String? = nil,
                privateHint: String? = nil,
                include: String? = nil,
                includeHint: String? = nil,
                exclude: String? = nil,
                excludeHint: String? = nil,
                pick: String? = nil,
                done: String? = nil,
                selected: (@Sendable (Int) -> String)? = nil) {
        self.title = title; self.public = publicLabel; self.publicHint = publicHint
        self.friends = friends; self.friendsHint = friendsHint
        self.private = privateLabel; self.privateHint = privateHint
        self.include = include; self.includeHint = includeHint
        self.exclude = exclude; self.excludeHint = excludeHint
        self.pick = pick; self.done = done; self.selected = selected
    }
}

public extension MomentAudienceLabels {
    /// Every label filled in: an explicit label wins, otherwise the `flareStrings` provider.
    struct Resolved: Sendable {
        public let title: String
        public let `public`: String
        public let publicHint: String
        public let friends: String
        public let friendsHint: String
        public let `private`: String
        public let privateHint: String
        public let include: String
        public let includeHint: String
        public let exclude: String
        public let excludeHint: String
        public let pick: String
        public let done: String
        public let selected: @Sendable (Int) -> String
    }
    func resolve(_ strings: FlareStrings) -> Resolved {
        Resolved(
            title: title ?? strings.pickVisibility,
            public: `public` ?? strings.momentAudienceSheetPublic,
            publicHint: publicHint ?? strings.momentAudienceSheetPublicHint,
            friends: friends ?? strings.momentAudienceSheetFriends,
            friendsHint: friendsHint ?? strings.momentAudienceSheetFriendsHint,
            private: `private` ?? strings.momentAudienceSheetPrivate,
            privateHint: privateHint ?? strings.momentAudienceSheetPrivateHint,
            include: include ?? strings.momentAudienceSheetInclude,
            includeHint: includeHint ?? strings.momentAudienceSheetIncludeHint,
            exclude: exclude ?? strings.momentAudienceSheetExclude,
            excludeHint: excludeHint ?? strings.momentAudienceSheetExcludeHint,
            pick: pick ?? strings.momentAudienceSheetPick,
            done: done ?? strings.momentAudienceSheetDone,
            selected: selected ?? strings.momentAudienceSheetSelected
        )
    }
}
