import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Models

/// The full data model for ``FlareGroupDetail`` — a group's settings / management page.
/// Mirrors the Vue kit's `FlareGroupDetailModel`. Purely a view input: the host resolves it
/// from the SDK and refreshes it after each emitted intent.
public struct FlareGroupDetailModel: Sendable {
    public var groupId: String
    public var name: String
    public var avatarURL: String?
    public var memberCount: Int
    public var announcement: String
    public var members: [Contact]
    public var ownerId: String
    public var adminIds: [String]
    /// Muted member ids — drives the per-member mute action label.
    public var mutedIds: [String]
    /// Viewer owns or administers the group (gates the 群管理 / 群权限 sections).
    public var canManage: Bool
    public var isOwner: Bool
    /// Viewer's own nickname in this group ("" = not set).
    public var myNickname: String
    /// Viewer's per-group notification / pin preference.
    public var myMuted: Bool
    public var myPinned: Bool
    /// Join policy: 1 = invite-only, 2 = approval, 3 = open.
    public var joinPolicy: Int
    public var muteAll: Bool
    public var onlyAdminCanAtAll: Bool
    public var onlyAdminCanPin: Bool
    public var shareCardPermission: Bool

    public init(groupId: String, name: String, avatarURL: String? = nil, memberCount: Int = 0,
                announcement: String = "", members: [Contact] = [], ownerId: String = "",
                adminIds: [String] = [], mutedIds: [String] = [], canManage: Bool = false,
                isOwner: Bool = false, myNickname: String = "", myMuted: Bool = false,
                myPinned: Bool = false, joinPolicy: Int = 3, muteAll: Bool = false,
                onlyAdminCanAtAll: Bool = false, onlyAdminCanPin: Bool = false,
                shareCardPermission: Bool = false) {
        self.groupId = groupId; self.name = name; self.avatarURL = avatarURL
        self.memberCount = memberCount; self.announcement = announcement; self.members = members
        self.ownerId = ownerId; self.adminIds = adminIds; self.mutedIds = mutedIds
        self.canManage = canManage; self.isOwner = isOwner; self.myNickname = myNickname
        self.myMuted = myMuted; self.myPinned = myPinned; self.joinPolicy = joinPolicy
        self.muteAll = muteAll; self.onlyAdminCanAtAll = onlyAdminCanAtAll
        self.onlyAdminCanPin = onlyAdminCanPin; self.shareCardPermission = shareCardPermission
    }
}

/// A pending group join request, resolved for display.
public struct FlareGroupJoinRequestView: Identifiable, Sendable {
    public var id: String { requestId }
    public var requestId: String
    public var applicantId: String
    public var applicantName: String
    public var avatarURL: String?
    public var message: String?
    public init(requestId: String, applicantId: String, applicantName: String,
                avatarURL: String? = nil, message: String? = nil) {
        self.requestId = requestId; self.applicantId = applicantId
        self.applicantName = applicantName; self.avatarURL = avatarURL; self.message = message
    }
}

/// Permission-flag keys emitted by ``FlareGroupDetail``'s `onSetFlag`. The host maps these to
/// its own SDK field names (e.g. snake_case `only_admin_can_at_all`).
public enum FlareGroupFlag: String, Sendable {
    case onlyAdminCanAtAll
    case onlyAdminCanPin
    case shareCardPermission
}

/// Localizable copy for ``FlareGroupDetail``. Defaults are Chinese (Feishu-style), matching the
/// social example app; the kit passes labels as params rather than reading a string catalog.
public struct FlareGroupDetailLabels: Sendable {
    public var title: String
    public var unavailable: String
    public var unavailableHint: String
    public var memberCountSuffix: String     // "位成员"
    public var notSet: String
    // Sections
    public var sectionInfo: String
    public var sectionMyInGroup: String
    public var sectionManage: String
    public var sectionPerms: String
    // 群信息
    public var groupName: String
    public var announcement: String
    public var announcementEmpty: String
    public var members: String
    // 我在本群
    public var myNickname: String
    public var muteNotif: String
    public var pinGroup: String
    // 群管理
    public var joinMode: String
    public var joinRequests: String
    public var muteAll: String
    public var inviteLink: String
    // 群权限
    public var onlyAdminAtAll: String
    public var onlyAdminPin: String
    public var shareCard: String
    // Join policy labels
    public var joinOpen: String
    public var joinApproval: String
    public var joinInvite: String
    // Edit sheets
    public var editName: String
    public var editAnnouncement: String
    public var nicknamePlaceholder: String
    // Member management
    public var memberManage: String
    public var setAdmin: String
    public var unsetAdmin: String
    public var mute: String
    public var unmute: String
    public var transferOwner: String
    public var transferConfirm: String   // "确定把群主转让给「%@」吗？"
    public var removeMember: String
    // Join requests
    public var noRequests: String
    public var requestDefaultMessage: String
    public var approve: String
    public var reject: String
    // Invite
    public var invite: String
    public var inviteEmpty: String
    public var inviteLinkHint: String
    public var inviteCodeTitle: String
    public var copyCode: String
    public var copied: String
    public var cannotGenerate: String
    // Bottom actions
    public var message: String
    public var leave: String
    public var dissolve: String
    public var leaveConfirmTitle: String
    public var leaveConfirmHint: String
    public var dissolveConfirmTitle: String
    public var dissolveConfirmHint: String
    // Generic
    public var cancel: String
    public var save: String
    public var done: String

    public init(
        title: String = "群资料",
        unavailable: String = "无法加载群资料",
        unavailableHint: String = "请检查网络连接后重试。",
        memberCountSuffix: String = "位成员",
        notSet: String = "未设置",
        sectionInfo: String = "群信息",
        sectionMyInGroup: String = "我在本群",
        sectionManage: String = "群管理",
        sectionPerms: String = "群权限",
        groupName: String = "群名称",
        announcement: String = "群公告",
        announcementEmpty: String = "暂无群公告",
        members: String = "群成员",
        myNickname: String = "我的群昵称",
        muteNotif: String = "消息免打扰",
        pinGroup: String = "置顶该群",
        joinMode: String = "进群方式",
        joinRequests: String = "入群申请",
        muteAll: String = "全员禁言",
        inviteLink: String = "群邀请链接",
        onlyAdminAtAll: String = "仅管理员可@全体成员",
        onlyAdminPin: String = "仅管理员可置顶消息",
        shareCard: String = "允许分享群名片",
        joinOpen: String = "允许任何人加入",
        joinApproval: String = "需管理员审批",
        joinInvite: String = "仅邀请加入",
        editName: String = "修改群名称",
        editAnnouncement: String = "编辑群公告",
        nicknamePlaceholder: String = "群内显示名",
        memberManage: String = "成员管理",
        setAdmin: String = "设为管理员",
        unsetAdmin: String = "取消管理员",
        mute: String = "禁言",
        unmute: String = "取消禁言",
        transferOwner: String = "转让群主",
        transferConfirm: String = "确定把群主转让给「%@」吗？转让后你将变为普通成员，此操作不可撤销。",
        removeMember: String = "移出群聊",
        noRequests: String = "暂无入群申请",
        requestDefaultMessage: String = "申请加入群聊",
        approve: String = "通过",
        reject: String = "拒绝",
        invite: String = "邀请成员",
        inviteEmpty: String = "暂无可邀请的联系人",
        inviteLinkHint: String = "将邀请码分享给好友，即可加入本群。",
        inviteCodeTitle: String = "邀请码",
        copyCode: String = "复制邀请码",
        copied: String = "已复制",
        cannotGenerate: String = "无法生成邀请链接",
        message: String = "发消息",
        leave: String = "退出群聊",
        dissolve: String = "解散群聊",
        leaveConfirmTitle: String = "退出群聊",
        leaveConfirmHint: String = "退出后将不再接收该群消息。",
        dissolveConfirmTitle: String = "解散群聊",
        dissolveConfirmHint: String = "解散后群聊将被永久删除，无法恢复。",
        cancel: String = "取消",
        save: String = "保存",
        done: String = "完成"
    ) {
        self.title = title; self.unavailable = unavailable; self.unavailableHint = unavailableHint
        self.memberCountSuffix = memberCountSuffix; self.notSet = notSet
        self.sectionInfo = sectionInfo; self.sectionMyInGroup = sectionMyInGroup
        self.sectionManage = sectionManage; self.sectionPerms = sectionPerms
        self.groupName = groupName; self.announcement = announcement
        self.announcementEmpty = announcementEmpty; self.members = members
        self.myNickname = myNickname; self.muteNotif = muteNotif; self.pinGroup = pinGroup
        self.joinMode = joinMode; self.joinRequests = joinRequests; self.muteAll = muteAll
        self.inviteLink = inviteLink; self.onlyAdminAtAll = onlyAdminAtAll
        self.onlyAdminPin = onlyAdminPin; self.shareCard = shareCard
        self.joinOpen = joinOpen; self.joinApproval = joinApproval; self.joinInvite = joinInvite
        self.editName = editName; self.editAnnouncement = editAnnouncement
        self.nicknamePlaceholder = nicknamePlaceholder; self.memberManage = memberManage
        self.setAdmin = setAdmin; self.unsetAdmin = unsetAdmin; self.mute = mute; self.unmute = unmute
        self.transferOwner = transferOwner; self.transferConfirm = transferConfirm
        self.removeMember = removeMember; self.noRequests = noRequests
        self.requestDefaultMessage = requestDefaultMessage; self.approve = approve; self.reject = reject
        self.invite = invite; self.inviteEmpty = inviteEmpty; self.inviteLinkHint = inviteLinkHint
        self.inviteCodeTitle = inviteCodeTitle; self.copyCode = copyCode; self.copied = copied
        self.cannotGenerate = cannotGenerate; self.message = message; self.leave = leave
        self.dissolve = dissolve; self.leaveConfirmTitle = leaveConfirmTitle
        self.leaveConfirmHint = leaveConfirmHint; self.dissolveConfirmTitle = dissolveConfirmTitle
        self.dissolveConfirmHint = dissolveConfirmHint; self.cancel = cancel; self.save = save
        self.done = done
    }
}

// MARK: - FlareGroupDetail

/// Group detail / management — hero, member grid, and Feishu-style settings sections
/// (群信息 / 我在本群 / 群管理 / 群权限, the latter two owner-admin gated), plus member actions,
/// join-request approval, invite picker and invite link, with the 发消息 / 退群 footer.
///
/// Purely presentational: it renders ``FlareGroupDetailModel`` and emits intents through its
/// closures; the host performs the SDK writes and refreshes the model. Mirrors the Vue kit's
/// `FlareGroupDetail`. Owns all of its own sheets / alerts and reuses ``GroupMemberGridView``.
public struct FlareGroupDetail: View {
    private let model: FlareGroupDetailModel?
    private let loading: Bool
    private let joinRequests: [FlareGroupJoinRequestView]
    private let loadingJoinRequests: Bool
    private let inviteCode: String?
    private let loadingInviteLink: Bool
    private let invitableContacts: [Contact]
    private let labels: FlareGroupDetailLabels

    private let onBack: (() -> Void)?
    private let onOpenChat: (() -> Void)?
    private let onUpdateName: ((String) -> Void)?
    private let onUpdateAnnouncement: ((String) -> Void)?
    private let onUpdateMyNickname: ((String) -> Void)?
    private let onSetJoinPolicy: ((Int) -> Void)?
    private let onToggleMuteAll: ((Bool) -> Void)?
    private let onSetFlag: ((FlareGroupFlag, Bool) -> Void)?
    private let onToggleMyMuted: ((Bool) -> Void)?
    private let onToggleMyPinned: ((Bool) -> Void)?
    private let onLoadJoinRequests: (() -> Void)?
    private let onRespondRequest: ((String, Bool) -> Void)?
    private let onEnsureInviteLink: (() -> Void)?
    private let onPromoteMember: ((String) -> Void)?
    private let onMuteMember: ((String) -> Void)?
    private let onTransferOwner: ((String) -> Void)?
    private let onRemoveMember: ((String) -> Void)?
    private let onLoadContacts: (() -> Void)?
    private let onInviteMembers: (([String]) -> Void)?
    private let onLeave: (() -> Void)?

    @Environment(\.colorScheme) private var scheme

    // Edit sheets (name / announcement / nickname)
    @State private var editKind: EditKind?
    @State private var editDraft = ""
    // Join policy / requests / invite link / invite members
    @State private var pickJoinPolicy = false
    @State private var showJoinRequests = false
    @State private var showInviteLink = false
    @State private var showInvite = false
    // Member management
    @State private var memberAction: Contact?
    @State private var transferTarget: Contact?
    // Bottom danger
    @State private var confirmLeave = false

    private enum EditKind: Identifiable { case name, announcement, nickname; var id: Int { hashValue } }

    private static let JOIN_INVITE = 1
    private static let JOIN_APPROVAL = 2
    private static let JOIN_OPEN = 3

    public init(model: FlareGroupDetailModel?, loading: Bool = false,
                joinRequests: [FlareGroupJoinRequestView] = [], loadingJoinRequests: Bool = false,
                inviteCode: String? = nil, loadingInviteLink: Bool = false,
                invitableContacts: [Contact] = [], labels: FlareGroupDetailLabels = FlareGroupDetailLabels(),
                onBack: (() -> Void)? = nil, onOpenChat: (() -> Void)? = nil,
                onUpdateName: ((String) -> Void)? = nil, onUpdateAnnouncement: ((String) -> Void)? = nil,
                onUpdateMyNickname: ((String) -> Void)? = nil, onSetJoinPolicy: ((Int) -> Void)? = nil,
                onToggleMuteAll: ((Bool) -> Void)? = nil, onSetFlag: ((FlareGroupFlag, Bool) -> Void)? = nil,
                onToggleMyMuted: ((Bool) -> Void)? = nil, onToggleMyPinned: ((Bool) -> Void)? = nil,
                onLoadJoinRequests: (() -> Void)? = nil, onRespondRequest: ((String, Bool) -> Void)? = nil,
                onEnsureInviteLink: (() -> Void)? = nil, onPromoteMember: ((String) -> Void)? = nil,
                onMuteMember: ((String) -> Void)? = nil, onTransferOwner: ((String) -> Void)? = nil,
                onRemoveMember: ((String) -> Void)? = nil, onLoadContacts: (() -> Void)? = nil,
                onInviteMembers: (([String]) -> Void)? = nil, onLeave: (() -> Void)? = nil) {
        self.model = model; self.loading = loading; self.joinRequests = joinRequests
        self.loadingJoinRequests = loadingJoinRequests; self.inviteCode = inviteCode
        self.loadingInviteLink = loadingInviteLink; self.invitableContacts = invitableContacts
        self.labels = labels
        self.onBack = onBack; self.onOpenChat = onOpenChat; self.onUpdateName = onUpdateName
        self.onUpdateAnnouncement = onUpdateAnnouncement; self.onUpdateMyNickname = onUpdateMyNickname
        self.onSetJoinPolicy = onSetJoinPolicy; self.onToggleMuteAll = onToggleMuteAll
        self.onSetFlag = onSetFlag; self.onToggleMyMuted = onToggleMyMuted
        self.onToggleMyPinned = onToggleMyPinned; self.onLoadJoinRequests = onLoadJoinRequests
        self.onRespondRequest = onRespondRequest; self.onEnsureInviteLink = onEnsureInviteLink
        self.onPromoteMember = onPromoteMember; self.onMuteMember = onMuteMember
        self.onTransferOwner = onTransferOwner; self.onRemoveMember = onRemoveMember
        self.onLoadContacts = onLoadContacts; self.onInviteMembers = onInviteMembers; self.onLeave = onLeave
    }

    private var canManage: Bool { model?.canManage ?? false }

    private func joinPolicyLabel(_ p: Int) -> String {
        switch p {
        case Self.JOIN_INVITE: return labels.joinInvite
        case Self.JOIN_APPROVAL: return labels.joinApproval
        default: return labels.joinOpen
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Group {
            if let m = model {
                content(colors, m)
            } else if loading {
                ProgressView().frame(maxWidth: .infinity).padding(FlareSizes.spacing2xl)
            } else {
                EmptyStateView(title: labels.unavailable, description: labels.unavailableHint, systemImage: "person.3")
                    .frame(maxWidth: .infinity, minHeight: 240)
            }
        }
        .background(colors.bgSecondary.ignoresSafeArea())
        // ── Edit name / announcement / nickname ──
        .alert(editAlertTitle, isPresented: Binding(get: { editKind != nil }, set: { if !$0 { editKind = nil } })) {
            TextField("", text: $editDraft)
            Button(labels.save) { saveEdit() }
            Button(labels.cancel, role: .cancel) { editKind = nil }
        }
        // ── Join policy ──
        .confirmationDialog(labels.joinMode, isPresented: $pickJoinPolicy, titleVisibility: .visible) {
            Button(labels.joinOpen) { onSetJoinPolicy?(Self.JOIN_OPEN) }
            Button(labels.joinApproval) { onSetJoinPolicy?(Self.JOIN_APPROVAL) }
            Button(labels.joinInvite) { onSetJoinPolicy?(Self.JOIN_INVITE) }
            Button(labels.cancel, role: .cancel) {}
        }
        // ── Member management ──
        .confirmationDialog(memberAction?.name ?? "", isPresented: Binding(
            get: { memberAction != nil }, set: { if !$0 { memberAction = nil } }
        ), titleVisibility: .visible) { memberActionButtons() }
        // ── Transfer owner confirm ──
        .alert(labels.transferOwner, isPresented: Binding(
            get: { transferTarget != nil }, set: { if !$0 { transferTarget = nil } }
        )) {
            Button(labels.transferOwner, role: .destructive) {
                if let t = transferTarget { onTransferOwner?(t.id) }
            }
            Button(labels.cancel, role: .cancel) { transferTarget = nil }
        } message: {
            Text(String(format: labels.transferConfirm, transferTarget?.name ?? ""))
        }
        // ── Leave / dissolve ──
        .alert(model?.isOwner == true ? labels.dissolveConfirmTitle : labels.leaveConfirmTitle,
               isPresented: $confirmLeave) {
            Button(model?.isOwner == true ? labels.dissolve : labels.leave, role: .destructive) { onLeave?() }
            Button(labels.cancel, role: .cancel) {}
        } message: {
            Text(model?.isOwner == true ? labels.dissolveConfirmHint : labels.leaveConfirmHint)
        }
        // ── Sheets ──
        .sheet(isPresented: $showJoinRequests) { joinRequestsSheet }
        .sheet(isPresented: $showInviteLink) { inviteLinkSheet }
        .sheet(isPresented: $showInvite) { inviteMembersSheet }
    }

    private var editAlertTitle: String {
        switch editKind {
        case .announcement: return labels.editAnnouncement
        case .nickname: return labels.myNickname
        default: return labels.editName
        }
    }

    private func saveEdit() {
        let v = editDraft.trimmingCharacters(in: .whitespaces)
        switch editKind {
        case .name: onUpdateName?(v)
        case .announcement: onUpdateAnnouncement?(v)
        case .nickname: onUpdateMyNickname?(v)
        case .none: break
        }
        editKind = nil
    }

    // MARK: - Content

    private func content(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        ScrollView {
            VStack(spacing: FlareSizes.spacingLg) {
                hero(colors, m)
                GroupMemberGridView(
                    members: m.members, ownerId: m.ownerId, adminIds: m.adminIds, showAdd: canManage,
                    onSelect: { uid in
                        guard canManage, uid != m.ownerId else { return }
                        memberAction = m.members.first { $0.id == uid }
                    },
                    onAddMember: { onLoadContacts?(); showInvite = true }
                )
                infoCard(colors, m)
                myInGroupCard(colors, m)
                if canManage { manageCard(colors, m) }
                if canManage { permsCard(colors, m) }
                footer(colors, m)
            }
            .padding(.vertical, FlareSizes.spacingLg)
        }
    }

    private func hero(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            AvatarView(userId: m.groupId, displayName: m.name, avatarURL: m.avatarURL, size: 72)
            Text(m.name.isEmpty ? labels.title : m.name)
                .font(.system(size: FlareSizes.fontSize3xl, weight: .semibold)).foregroundColor(colors.textPrimary)
            Text("\(m.memberCount) \(labels.memberCountSuffix)")
                .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Settings cards

    /// A titled grouped card of ``FlareSettingsRow`` — rendered inline (not a nested List) so it
    /// composes inside the outer ScrollView, mirroring ``ProfilePanelView``'s card style.
    private func card(_ title: String, _ items: [FlareSettingsItem], _ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            Text(title).font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                .foregroundColor(colors.textTertiary).padding(.horizontal, FlareSizes.spacingLg)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    if i > 0 { Divider().padding(.leading, FlareSizes.spacingMd) }
                    FlareSettingsRow(item: item, onToggle: onRowToggle, onSelect: onRowSelect)
                        .padding(.horizontal, FlareSizes.spacingMd)
                        .frame(minHeight: 48)
                }
            }
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgElevated))
            .padding(.horizontal, FlareSizes.spacingMd)
        }
    }

    private func infoCard(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        card(labels.sectionInfo, [
            FlareSettingsItem(key: "name", label: labels.groupName, systemImage: "tag",
                              kind: canManage ? .navigation : .value, detail: m.name.isEmpty ? "-" : m.name),
            FlareSettingsItem(key: "announcement", label: labels.announcement, systemImage: "megaphone",
                              kind: canManage ? .navigation : .value,
                              detail: m.announcement.isEmpty ? labels.notSet : m.announcement),
            FlareSettingsItem(key: "members", label: labels.members, systemImage: "person.2",
                              kind: .value, detail: "\(m.memberCount)"),
        ], colors)
    }

    private func myInGroupCard(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        card(labels.sectionMyInGroup, [
            FlareSettingsItem(key: "myNickname", label: labels.myNickname, systemImage: "person.text.rectangle",
                              kind: .navigation, detail: m.myNickname.isEmpty ? labels.notSet : m.myNickname),
            FlareSettingsItem(key: "myMuted", label: labels.muteNotif, systemImage: "bell.slash",
                              kind: .toggle, value: m.myMuted),
            FlareSettingsItem(key: "myPinned", label: labels.pinGroup, systemImage: "pin",
                              kind: .toggle, value: m.myPinned),
        ], colors)
    }

    private func manageCard(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        card(labels.sectionManage, [
            FlareSettingsItem(key: "joinPolicy", label: labels.joinMode, systemImage: "person.badge.plus",
                              kind: .navigation, detail: joinPolicyLabel(m.joinPolicy)),
            FlareSettingsItem(key: "joinRequests", label: labels.joinRequests, systemImage: "envelope.open",
                              kind: .navigation, detail: joinRequests.isEmpty ? "" : "\(joinRequests.count)"),
            FlareSettingsItem(key: "muteAll", label: labels.muteAll, systemImage: "speaker.slash",
                              kind: .toggle, value: m.muteAll),
            FlareSettingsItem(key: "inviteLink", label: labels.inviteLink, systemImage: "link", kind: .navigation),
        ], colors)
    }

    private func permsCard(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        card(labels.sectionPerms, [
            FlareSettingsItem(key: "atAll", label: labels.onlyAdminAtAll, systemImage: "at",
                              kind: .toggle, value: m.onlyAdminCanAtAll),
            FlareSettingsItem(key: "pinPerm", label: labels.onlyAdminPin, systemImage: "pin.circle",
                              kind: .toggle, value: m.onlyAdminCanPin),
            FlareSettingsItem(key: "shareCard", label: labels.shareCard, systemImage: "square.and.arrow.up",
                              kind: .toggle, value: m.shareCardPermission),
        ], colors)
    }

    private func onRowSelect(_ item: FlareSettingsItem) {
        switch item.key {
        case "myNickname":
            editDraft = model?.myNickname ?? ""; editKind = .nickname
        case "name" where canManage:
            editDraft = model?.name ?? ""; editKind = .name
        case "announcement" where canManage:
            editDraft = model?.announcement ?? ""; editKind = .announcement
        case "joinPolicy" where canManage:
            pickJoinPolicy = true
        case "joinRequests" where canManage:
            onLoadJoinRequests?(); showJoinRequests = true
        case "inviteLink" where canManage:
            onEnsureInviteLink?(); showInviteLink = true
        default:
            break
        }
    }

    private func onRowToggle(_ item: FlareSettingsItem, _ on: Bool) {
        switch item.key {
        case "myMuted": onToggleMyMuted?(on)
        case "myPinned": onToggleMyPinned?(on)
        case "muteAll" where canManage: onToggleMuteAll?(on)
        case "atAll" where canManage: onSetFlag?(.onlyAdminCanAtAll, on)
        case "pinPerm" where canManage: onSetFlag?(.onlyAdminCanPin, on)
        case "shareCard" where canManage: onSetFlag?(.shareCardPermission, on)
        default: break
        }
    }

    // MARK: - Footer

    private func footer(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            ButtonView(label: labels.message, variant: .primary, block: true) { onOpenChat?() }
            ButtonView(label: m.isOwner ? labels.dissolve : labels.leave, variant: .danger, block: true) {
                confirmLeave = true
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.top, FlareSizes.spacingSm)
    }

    // MARK: - Member action buttons

    @ViewBuilder private func memberActionButtons() -> some View {
        if let mem = memberAction, let m = model, canManage, mem.id != m.ownerId {
            let isAdmin = m.adminIds.contains(mem.id)
            let isMuted = m.mutedIds.contains(mem.id)
            Button(isAdmin ? labels.unsetAdmin : labels.setAdmin) { onPromoteMember?(mem.id); memberAction = nil }
            Button(isMuted ? labels.unmute : labels.mute) { onMuteMember?(mem.id); memberAction = nil }
            if m.isOwner {
                Button(labels.transferOwner) { transferTarget = mem; memberAction = nil }
            }
            Button(labels.removeMember, role: .destructive) { onRemoveMember?(mem.id); memberAction = nil }
            Button(labels.cancel, role: .cancel) {}
        } else {
            Button(labels.cancel, role: .cancel) {}
        }
    }

    // MARK: - Sheets

    private var joinRequestsSheet: some View {
        let colors = FlareColors.of(scheme)
        return VStack(spacing: 0) {
            sheetHeader(labels.joinRequests) { showJoinRequests = false }
            Group {
                if loadingJoinRequests {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if joinRequests.isEmpty {
                    EmptyStateView(title: labels.noRequests, systemImage: "envelope.open")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(joinRequests) { r in
                        HStack(spacing: FlareSizes.spacingMd) {
                            AvatarView(userId: r.applicantId, displayName: r.applicantName, avatarURL: r.avatarURL, size: 42)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.applicantName).foregroundColor(colors.textPrimary)
                                Text((r.message?.isEmpty == false ? r.message! : labels.requestDefaultMessage))
                                    .font(.footnote).foregroundColor(colors.textTertiary).lineLimit(1)
                            }
                            Spacer()
                            ButtonView(label: labels.reject, variant: .secondary, size: .sm) { onRespondRequest?(r.requestId, false) }
                            ButtonView(label: labels.approve, variant: .primary, size: .sm) { onRespondRequest?(r.requestId, true) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .background(colors.bgPrimary.ignoresSafeArea())
    }

    private var inviteLinkSheet: some View {
        let colors = FlareColors.of(scheme)
        return VStack(spacing: 0) {
            sheetHeader(labels.inviteLink) { showInviteLink = false }
            VStack(spacing: FlareSizes.spacingLg) {
                if loadingInviteLink {
                    ProgressView().padding(FlareSizes.spacing2xl)
                } else if let code = inviteCode, !code.isEmpty {
                    Text(labels.inviteCodeTitle).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                    InviteCodeCopyView(code: code, copyLabel: labels.copyCode, copiedLabel: labels.copied)
                    Text(labels.inviteLinkHint)
                        .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                        .multilineTextAlignment(.center)
                } else {
                    EmptyStateView(title: labels.cannotGenerate, description: labels.unavailableHint, systemImage: "link.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                Spacer()
            }
            .padding(FlareSizes.spacingLg)
            .frame(maxWidth: .infinity)
        }
        .background(colors.bgPrimary.ignoresSafeArea())
    }

    private var inviteMembersSheet: some View {
        let colors = FlareColors.of(scheme)
        let memberIds = Set(model?.members.map { $0.id } ?? [])
        let invitable = invitableContacts.filter { !memberIds.contains($0.id) }
        return VStack(spacing: 0) {
            sheetHeader(labels.invite) { showInvite = false }
            InviteMemberPicker(contacts: invitable, emptyText: labels.inviteEmpty,
                               inviteLabel: labels.invite, cancelLabel: labels.cancel,
                               onCancel: { showInvite = false },
                               onConfirm: { ids in showInvite = false; onInviteMembers?(ids) })
        }
        .background(colors.bgPrimary.ignoresSafeArea())
    }

    /// Cross-platform sheet header (the kit also builds on macOS, where iOS navigation-bar
    /// toolbars are unavailable): a centered title with a trailing Done button.
    private func sheetHeader(_ title: String, _ onDone: @escaping () -> Void) -> some View {
        let colors = FlareColors.of(scheme)
        return ZStack {
            Text(title).font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
            HStack {
                Spacer()
                Button(labels.done) { onDone() }.foregroundColor(colors.primary)
            }
        }
        .padding(FlareSizes.spacingLg)
    }
}

// MARK: - Supporting views

/// Invite-code display + copy button (used by ``FlareGroupDetail``'s invite-link sheet).
private struct InviteCodeCopyView: View {
    let code: String
    let copyLabel: String
    let copiedLabel: String
    @Environment(\.colorScheme) private var scheme
    @State private var copied = false

    var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: FlareSizes.spacingLg) {
            Text(code)
                .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold, design: .monospaced))
                .foregroundColor(colors.textPrimary)
                .textSelection(.enabled)
                .padding(FlareSizes.spacingLg)
                .frame(maxWidth: .infinity)
                .background(colors.bgSecondary)
                .cornerRadius(FlareSizes.radiusMd)
            ButtonView(label: copied ? copiedLabel : copyLabel, variant: copied ? .secondary : .primary,
                       block: true, systemImage: copied ? "checkmark" : "doc.on.doc") {
                #if canImport(UIKit)
                UIPasteboard.general.string = code
                #endif
                copied = true
            }
        }
    }
}

/// Multi-select contact picker for group invites — checkbox rows + a confirm button.
private struct InviteMemberPicker: View {
    let contacts: [Contact]
    let emptyText: String
    let inviteLabel: String
    let cancelLabel: String
    let onCancel: () -> Void
    let onConfirm: ([String]) -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var picked: Set<String> = []

    var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            if contacts.isEmpty {
                EmptyStateView(title: emptyText, systemImage: "person.2")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(contacts) { c in
                    Button {
                        if picked.contains(c.id) { picked.remove(c.id) } else { picked.insert(c.id) }
                    } label: {
                        HStack(spacing: FlareSizes.spacingMd) {
                            AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 40)
                            Text(c.name).foregroundColor(colors.textPrimary)
                            Spacer()
                            CheckboxView(isOn: .constant(picked.contains(c.id)))
                                .allowsHitTesting(false)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
            HStack(spacing: FlareSizes.spacingMd) {
                ButtonView(label: cancelLabel, variant: .secondary, block: true) { onCancel() }
                ButtonView(label: inviteLabel, variant: .primary, block: true,
                           action: picked.isEmpty ? nil : { onConfirm(Array(picked)) })
            }
            .padding(FlareSizes.spacingLg)
        }
    }
}
