import SwiftUI

/// 发动态时的「谁可以看」。
///
/// 两层正交：`visibility` 圈定人群（0=朋友 1=公开 2=私密），`audienceMode` 在其上
/// 做加减（1=部分可见 2=不给谁看）。
///
/// **两个方向的出错后果不对称**：把「部分可见」设成「不给谁看」，动态会发给你本想
/// 避开的所有人；反过来只是少给几个人看。所以两项不共用措辞，也不共用强调色。
/// Spec: Moments/MomentAudienceSheet (`MomentAudienceSheetView`).
public struct MomentAudienceSheetView: View {
    private let visibility: Int
    private let audienceMode: Int
    private let audienceUserIds: [String]
    private let contacts: [ContactBrief]
    private let labels: MomentAudienceLabels
    private let onVisibilityChanged: ((Int) -> Void)?
    private let onAudienceChanged: ((Int, [String]) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(visibility: Int,
                audienceMode: Int,
                audienceUserIds: [String],
                contacts: [ContactBrief],
                labels: MomentAudienceLabels = MomentAudienceLabels(),
                onVisibilityChanged: ((Int) -> Void)? = nil,
                onAudienceChanged: ((Int, [String]) -> Void)? = nil,
                onClose: (() -> Void)? = nil) {
        self.visibility = visibility; self.audienceMode = audienceMode
        self.audienceUserIds = audienceUserIds; self.contacts = contacts; self.labels = labels
        self.onVisibilityChanged = onVisibilityChanged
        self.onAudienceChanged = onAudienceChanged
        self.onClose = onClose
    }

    /// 私密时名单没有意义：没人看得到，加减谁都不改变结果。
    private var audienceApplies: Bool { visibility != 2 }

    private func pickMode(_ mode: Int) {
        // 再点一次当前模式即取消，并清空名单 —— 留着名单而把 mode 归零，
        // 下次切回来会突然冒出一份用户以为已经删掉的名单。
        let next = audienceMode == mode ? 0 : mode
        onAudienceChanged?(next, next == 0 ? [] : audienceUserIds)
    }

    private func toggle(_ c: ContactBrief) {
        var ids = audienceUserIds
        if let i = ids.firstIndex(of: c.userId) { ids.remove(at: i) } else { ids.append(c.userId) }
        onAudienceChanged?(audienceMode, ids)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let picked = Set(audienceUserIds)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(labels.title)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textPrimary)
                    .padding(FlareSizes.spacingMd)

                row("person.2", labels.friends, labels.friendsHint, visibility == 0, colors) {
                    onVisibilityChanged?(0)
                }
                row("globe", labels.public, labels.publicHint, visibility == 1, colors) {
                    onVisibilityChanged?(1)
                }
                row("lock", labels.private, labels.privateHint, visibility == 2, colors) {
                    onVisibilityChanged?(2)
                }

                if audienceApplies {
                    Divider()
                    row("person.badge.plus", labels.include, labels.includeHint,
                        audienceMode == 1, colors, accent: colors.primary,
                        trailing: audienceMode == 1 ? labels.selected(audienceUserIds.count) : nil) {
                        pickMode(1)
                    }
                    row("eye.slash", labels.exclude, labels.excludeHint,
                        audienceMode == 2, colors, accent: colors.warning,
                        trailing: audienceMode == 2 ? labels.selected(audienceUserIds.count) : nil) {
                        pickMode(2)
                    }

                    if audienceMode != 0 {
                        Divider()
                        Text(labels.pick)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary)
                            .padding(.horizontal, FlareSizes.spacingMd)
                            .padding(.vertical, FlareSizes.spacingSm)
                        ForEach(contacts) { c in
                            HStack(spacing: FlareSizes.spacingSm) {
                                AvatarView(userId: c.userId, displayName: c.displayName,
                                           avatarURL: c.avatarURL, size: 32)
                                Text(c.displayName)
                                    .font(.system(size: FlareSizes.fontSizeLg))
                                    .foregroundColor(colors.textPrimary)
                                Spacer()
                                if picked.contains(c.userId) {
                                    Image(systemName: "checkmark").foregroundColor(colors.primary)
                                }
                            }
                            .padding(.horizontal, FlareSizes.spacingMd)
                            .padding(.vertical, FlareSizes.spacingXs)
                            .background(picked.contains(c.userId) ? colors.bgHover : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { toggle(c) }
                        }
                    }
                }

                Divider()
                HStack {
                    Spacer()
                    Button(labels.done) { onClose?() }
                        .font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                        .foregroundColor(colors.primary)
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
        HStack(spacing: FlareSizes.spacingSm) {
            Image(systemName: systemImage).font(.system(size: 14)).foregroundColor(tone)
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
                Image(systemName: "checkmark").foregroundColor(colors.primary)
            }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingSm)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

/// Copy for `MomentAudienceSheetView`. 两个方向的措辞刻意分开。
public struct MomentAudienceLabels: Sendable {
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
    /// 「已选 N 人」。闭包而非模板串，让复数形式不同的语言也能表达。
    public let selected: @Sendable (Int) -> String

    public init(title: String = "谁可以看",
                public publicLabel: String = "公开",
                publicHint: String = "所有人可见",
                friends: String = "朋友可见",
                friendsHint: String = "你的好友可见",
                private privateLabel: String = "私密",
                privateHint: String = "仅自己可见",
                include: String = "部分可见",
                includeHint: String = "仅选中的朋友可见",
                exclude: String = "不给谁看",
                excludeHint: String = "选中的朋友看不到",
                pick: String = "选择朋友",
                done: String = "完成",
                selected: @escaping @Sendable (Int) -> String = { "已选 \($0) 人" }) {
        self.title = title; self.public = publicLabel; self.publicHint = publicHint
        self.friends = friends; self.friendsHint = friendsHint
        self.private = privateLabel; self.privateHint = privateHint
        self.include = include; self.includeHint = includeHint
        self.exclude = exclude; self.excludeHint = excludeHint
        self.pick = pick; self.done = done; self.selected = selected
    }
}
