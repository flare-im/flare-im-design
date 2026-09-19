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
    /// The viewer's own notification and pin settings; nil when they could not be read, so the row
    /// claims no state instead of drawing a switch that says "off" (Vue `myMuted: boolean | null`).
    public var myMuted: Bool?
    public var myPinned: Bool?
    /// How people join the group; nil when the host does not know (the row reads "not set").
    public var joinPolicy: FlareGroupJoinPolicy?
    public var muteAll: Bool
    public var onlyAdminCanAtAll: Bool
    public var onlyAdminCanPin: Bool
    public var shareCardPermission: Bool

    public init(groupId: String, name: String, avatarURL: String? = nil, memberCount: Int = 0,
                announcement: String = "", members: [Contact] = [], ownerId: String = "",
                adminIds: [String] = [], mutedIds: [String] = [], canManage: Bool = false,
                isOwner: Bool = false, myNickname: String = "", myMuted: Bool? = nil,
                myPinned: Bool? = nil, joinPolicy: FlareGroupJoinPolicy? = nil, muteAll: Bool = false,
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

/// How people join a group — open to anyone, approved by an admin, or by invitation only — in
/// display order. The kit never encodes the SDK's numbers: the host maps its own values, and a
/// value it does not know is `nil` wherever a model holds a policy.
public enum FlareGroupJoinPolicy: String, CaseIterable, Sendable {
    case open, approval, invite
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
    public var title: String?
    public var unavailable: String?
    public var unavailableHint: String?
    public var memberCountSuffix: String?     // "位成员"
    public var notSet: String?
    public var settingUnavailable: String?
    // Sections
    public var sectionInfo: String?
    public var sectionMyInGroup: String?
    public var sectionManage: String?
    public var sectionPerms: String?
    // 群信息
    public var groupName: String?
    public var announcement: String?
    public var announcementEmpty: String?
    public var members: String?
    // 我在本群
    public var myNickname: String?
    public var muteNotif: String?
    public var pinGroup: String?
    // 群管理
    public var joinMode: String?
    public var joinRequests: String?
    public var muteAll: String?
    public var inviteLink: String?
    // 群权限
    public var onlyAdminAtAll: String?
    public var onlyAdminPin: String?
    public var shareCard: String?
    // Join policy labels
    public var joinOpen: String?
    public var joinApproval: String?
    public var joinInvite: String?
    // Edit sheets
    public var editName: String?
    public var editAnnouncement: String?
    public var nicknamePlaceholder: String?
    // Member management
    public var memberManage: String?
    public var setAdmin: String?
    public var unsetAdmin: String?
    public var mute: String?
    public var unmute: String?
    public var transferOwner: String?
    public var transferConfirm: String?   // "确定把群主转让给「%@」吗？"
    public var removeMember: String?
    // Join requests
    public var noRequests: String?
    public var requestDefaultMessage: String?
    public var approve: String?
    public var reject: String?
    // Invite
    public var invite: String?
    public var inviteEmpty: String?
    public var inviteLinkHint: String?
    public var inviteCodeTitle: String?
    public var copyCode: String?
    public var copied: String?
    public var cannotGenerate: String?
    // Bottom actions
    public var message: String?
    public var leave: String?
    public var dissolve: String?
    // Generic
    public var cancel: String?
    public var save: String?
    public var done: String?

    public init(
        title: String? = nil,
        unavailable: String? = nil,
        unavailableHint: String? = nil,
        memberCountSuffix: String? = nil,
        notSet: String? = nil,
        sectionInfo: String? = nil,
        sectionMyInGroup: String? = nil,
        sectionManage: String? = nil,
        sectionPerms: String? = nil,
        groupName: String? = nil,
        announcement: String? = nil,
        announcementEmpty: String? = nil,
        members: String? = nil,
        myNickname: String? = nil,
        muteNotif: String? = nil,
        pinGroup: String? = nil,
        joinMode: String? = nil,
        joinRequests: String? = nil,
        muteAll: String? = nil,
        inviteLink: String? = nil,
        onlyAdminAtAll: String? = nil,
        onlyAdminPin: String? = nil,
        shareCard: String? = nil,
        joinOpen: String? = nil,
        joinApproval: String? = nil,
        joinInvite: String? = nil,
        editName: String? = nil,
        editAnnouncement: String? = nil,
        nicknamePlaceholder: String? = nil,
        memberManage: String? = nil,
        setAdmin: String? = nil,
        unsetAdmin: String? = nil,
        mute: String? = nil,
        unmute: String? = nil,
        transferOwner: String? = nil,
        transferConfirm: String? = nil,
        removeMember: String? = nil,
        noRequests: String? = nil,
        requestDefaultMessage: String? = nil,
        approve: String? = nil,
        reject: String? = nil,
        invite: String? = nil,
        inviteEmpty: String? = nil,
        inviteLinkHint: String? = nil,
        inviteCodeTitle: String? = nil,
        copyCode: String? = nil,
        copied: String? = nil,
        cannotGenerate: String? = nil,
        message: String? = nil,
        leave: String? = nil,
        dissolve: String? = nil,
        cancel: String? = nil,
        save: String? = nil,
        done: String? = nil
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
        self.removeMember = removeMember
        self.noRequests = noRequests
        self.requestDefaultMessage = requestDefaultMessage; self.approve = approve; self.reject = reject
        self.invite = invite; self.inviteEmpty = inviteEmpty; self.inviteLinkHint = inviteLinkHint
        self.inviteCodeTitle = inviteCodeTitle; self.copyCode = copyCode; self.copied = copied
        self.cannotGenerate = cannotGenerate; self.message = message; self.leave = leave
        self.dissolve = dissolve; self.cancel = cancel; self.save = save
        self.done = done
    }
}

public extension FlareGroupDetailLabels {
    /// Every label filled in: an explicit label wins, otherwise the `flareStrings` provider.
    struct Resolved: Sendable {
        public let title: String
        public let unavailable: String
        public let unavailableHint: String
        public let memberCountSuffix: String
        public let notSet: String
        public let settingUnavailable: String
        public let sectionInfo: String
        public let sectionMyInGroup: String
        public let sectionManage: String
        public let sectionPerms: String
        public let groupName: String
        public let announcement: String
        public let announcementEmpty: String
        public let members: String
        public let myNickname: String
        public let muteNotif: String
        public let pinGroup: String
        public let joinMode: String
        public let joinRequests: String
        public let muteAll: String
        public let inviteLink: String
        public let onlyAdminAtAll: String
        public let onlyAdminPin: String
        public let shareCard: String
        public let joinOpen: String
        public let joinApproval: String
        public let joinInvite: String
        public let editName: String
        public let editAnnouncement: String
        public let nicknamePlaceholder: String
        public let memberManage: String
        public let setAdmin: String
        public let unsetAdmin: String
        public let mute: String
        public let unmute: String
        public let transferOwner: String
        public let transferConfirm: String
        public let removeMember: String
        public let noRequests: String
        public let requestDefaultMessage: String
        public let approve: String
        public let reject: String
        public let invite: String
        public let inviteEmpty: String
        public let inviteLinkHint: String
        public let inviteCodeTitle: String
        public let copyCode: String
        public let copied: String
        public let cannotGenerate: String
        public let message: String
        public let leave: String
        public let dissolve: String
        public let cancel: String
        public let save: String
        public let done: String
    }
    func resolve(_ strings: FlareStrings) -> Resolved {
        Resolved(
            title: title ?? strings.groupDetailTitle,
            unavailable: unavailable ?? strings.groupDetailUnavailable,
            unavailableHint: unavailableHint ?? strings.groupDetailUnavailableHint,
            memberCountSuffix: memberCountSuffix ?? strings.groupDetailMemberCountSuffix,
            notSet: notSet ?? strings.groupDetailNotSet,
            settingUnavailable: settingUnavailable ?? strings.groupDetailSettingUnavailable,
            sectionInfo: sectionInfo ?? strings.groupDetailSectionInfo,
            sectionMyInGroup: sectionMyInGroup ?? strings.groupDetailSectionMyInGroup,
            sectionManage: sectionManage ?? strings.groupDetailSectionManage,
            sectionPerms: sectionPerms ?? strings.groupDetailSectionPerms,
            groupName: groupName ?? strings.groupDetailGroupName,
            announcement: announcement ?? strings.groupAnnouncement,
            announcementEmpty: announcementEmpty ?? strings.groupDetailAnnouncementEmpty,
            members: members ?? strings.groupMembers,
            myNickname: myNickname ?? strings.groupDetailMyNickname,
            muteNotif: muteNotif ?? strings.groupDetailMuteNotif,
            pinGroup: pinGroup ?? strings.groupDetailPinGroup,
            joinMode: joinMode ?? strings.groupDetailJoinMode,
            joinRequests: joinRequests ?? strings.groupDetailJoinRequests,
            muteAll: muteAll ?? strings.groupDetailMuteAll,
            inviteLink: inviteLink ?? strings.groupDetailInviteLink,
            onlyAdminAtAll: onlyAdminAtAll ?? strings.groupDetailOnlyAdminAtAll,
            onlyAdminPin: onlyAdminPin ?? strings.groupDetailOnlyAdminPin,
            shareCard: shareCard ?? strings.groupDetailShareCard,
            joinOpen: joinOpen ?? strings.groupDetailJoinOpen,
            joinApproval: joinApproval ?? strings.groupDetailJoinApproval,
            joinInvite: joinInvite ?? strings.groupDetailJoinInvite,
            editName: editName ?? strings.groupDetailEditName,
            editAnnouncement: editAnnouncement ?? strings.groupDetailEditAnnouncement,
            nicknamePlaceholder: nicknamePlaceholder ?? strings.groupDetailNicknamePlaceholder,
            memberManage: memberManage ?? strings.groupDetailMemberManage,
            setAdmin: setAdmin ?? strings.groupDetailSetAdmin,
            unsetAdmin: unsetAdmin ?? strings.groupDetailUnsetAdmin,
            mute: mute ?? strings.groupDetailMute,
            unmute: unmute ?? strings.groupDetailUnmute,
            transferOwner: transferOwner ?? strings.groupDetailTransferOwner,
            transferConfirm: transferConfirm ?? strings.groupDetailTransferConfirm,
            removeMember: removeMember ?? strings.groupDetailRemoveMember,
            noRequests: noRequests ?? strings.groupDetailNoRequests,
            requestDefaultMessage: requestDefaultMessage ?? strings.groupDetailRequestDefaultMessage,
            approve: approve ?? strings.groupDetailApprove,
            reject: reject ?? strings.reject,
            invite: invite ?? strings.groupDetailInvite,
            inviteEmpty: inviteEmpty ?? strings.groupDetailInviteEmpty,
            inviteLinkHint: inviteLinkHint ?? strings.groupDetailInviteLinkHint,
            inviteCodeTitle: inviteCodeTitle ?? strings.groupDetailInviteCodeTitle,
            copyCode: copyCode ?? strings.groupDetailCopyCode,
            copied: copied ?? strings.groupDetailCopied,
            cannotGenerate: cannotGenerate ?? strings.groupDetailCannotGenerate,
            message: message ?? strings.sendMessage,
            leave: leave ?? strings.groupDetailLeave,
            dissolve: dissolve ?? strings.groupDetailDissolve,
            cancel: cancel ?? strings.cancel,
            save: save ?? strings.groupDetailSave,
            done: done ?? strings.groupDetailDone
        )
    }
}

// MARK: - FlareGroupDetail

/// Group detail / management — hero, member grid, and Feishu-style settings sections
/// (群信息 / 我在本群 / 群管理 / 群权限, the latter two owner-admin gated), plus member actions,
/// join-request approval, invite picker and invite link, with the 发消息 / 退群 footer.
///
/// Hosts place their own content in two slots that scroll with the page at its horizontal inset:
/// `afterInfo` after the group information section and `footer` after the message and leave
/// buttons; an absent slot draws nothing. The message button is drawn only when `onOpenChat` is set.
///
/// Purely presentational: it renders ``FlareGroupDetailModel`` and emits intents through its
/// closures; the host persists changes and refreshes the model. Mirrors the Vue kit's
/// `FlareGroupDetail`. Owns its editing sheets / alerts and reuses ``GroupMemberGridView``.
/// Transferring ownership confirms first, inside the member dialog it starts from — through the
/// app's ``FlareFeedback`` when a ``SwiftUI/View/flareFeedbackHost(_:)`` is installed, else with a
/// system alert — and only then emits. Removing a member and leaving / dissolving are emitted as
/// tapped: the host confirms them (e.g. `feedback.confirm(FlareConfirmOptions(action:))`) because
/// it owns the busy and error states of the write.
public struct FlareGroupDetail: View {
    private let model: FlareGroupDetailModel?
    private let loading: Bool
    private let joinRequests: [FlareGroupJoinRequestView]
    private let loadingJoinRequests: Bool
    private let inviteCode: String?
    private let loadingInviteLink: Bool
    private let invitableContacts: [Contact]
    private let labels: FlareGroupDetailLabels
    private let afterInfo: AnyView?
    private let footer: AnyView?

    private let onBack: (() -> Void)?
    private let onOpenChat: (([String], String) -> Void)?
    private let onUpdateName: ((String) -> Void)?
    private let onUpdateAnnouncement: ((String) -> Void)?
    private let onUpdateMyNickname: ((String) -> Void)?
    private let onSetJoinPolicy: ((FlareGroupJoinPolicy) -> Void)?
    private let onToggleMuteAll: ((Bool) -> Void)?
    private let onSetFlag: ((FlareGroupFlag, Bool) -> Void)?
    private let onToggleMyMuted: ((Bool) -> Void)?
    private let onToggleMyPinned: ((Bool) -> Void)?
    private let onLoadJoinRequests: (() -> Void)?
    private let onRespondRequest: ((String, Bool) -> Void)?
    private let onEnsureInviteLink: (() -> Void)?
    private let onPromoteMember: ((_ userId: String, _ admin: Bool) -> Void)?
    private let onMuteMember: ((_ userId: String, _ muted: Bool) -> Void)?
    private let onTransferOwner: ((String) -> Void)?
    private let onRemoveMember: ((String) -> Void)?
    private let onLoadContacts: (() -> Void)?
    private let onInviteMembers: (([String]) -> Void)?
    private let onSearchMembers: ((String) async throws -> [Contact])?
    private let onLeave: (() -> Void)?
    /// Host actions the kit cannot know about, drawn above leaving the group (FR-046).
    private let extraActions: [FlareDetailExtraAction]
    private let onExtraAction: ((String) -> Void)?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareFeedback) private var feedback

    // Edit sheets (name / announcement / nickname)
    @State private var editKind: EditKind?
    @State private var editDraft = ""
    // Join policy / requests / invite link / invite members
    @State private var joinPolicyPicker: JoinPolicyPicking?
    @State private var showJoinRequests = false
    @State private var showInviteLink = false
    @State private var showInvite = false
    // Member management
    @State private var memberAction: Contact?
    @State private var transferTarget: Contact?
    // All members (the 群成员 row)
    @State private var showMembers = false
    @State private var memberQuery = ""
    @State private var searchedMembers: [Contact]?
    @State private var memberSearchLoading = false
    @State private var memberSearchError: String?
    @State private var memberSearchGeneration = 0
    /// A member chosen in the members sheet; their dialog opens once the sheet is gone.
    @State private var pendingMemberAction: Contact?

    private enum EditKind: Identifiable { case name, announcement, nickname; var id: Int { hashValue } }
    /// The join-policy sheet, while it is shown.
    private enum JoinPolicyPicking: Identifiable { case shown; var id: Int { 0 } }

    public init(model: FlareGroupDetailModel?, loading: Bool = false,
                joinRequests: [FlareGroupJoinRequestView] = [], loadingJoinRequests: Bool = false,
                inviteCode: String? = nil, loadingInviteLink: Bool = false,
                invitableContacts: [Contact] = [], labels: FlareGroupDetailLabels = FlareGroupDetailLabels(),
                afterInfo: AnyView? = nil, footer: AnyView? = nil,
                onBack: (() -> Void)? = nil, onOpenChat: (([String], String) -> Void)? = nil,
                onUpdateName: ((String) -> Void)? = nil, onUpdateAnnouncement: ((String) -> Void)? = nil,
                onUpdateMyNickname: ((String) -> Void)? = nil, onSetJoinPolicy: ((FlareGroupJoinPolicy) -> Void)? = nil,
                onToggleMuteAll: ((Bool) -> Void)? = nil, onSetFlag: ((FlareGroupFlag, Bool) -> Void)? = nil,
                onToggleMyMuted: ((Bool) -> Void)? = nil, onToggleMyPinned: ((Bool) -> Void)? = nil,
                onLoadJoinRequests: (() -> Void)? = nil, onRespondRequest: ((String, Bool) -> Void)? = nil,
                onEnsureInviteLink: (() -> Void)? = nil,
                onPromoteMember: ((_ userId: String, _ admin: Bool) -> Void)? = nil,
                onMuteMember: ((_ userId: String, _ muted: Bool) -> Void)? = nil,
                onTransferOwner: ((String) -> Void)? = nil,
                onRemoveMember: ((String) -> Void)? = nil, onLoadContacts: (() -> Void)? = nil,
                onInviteMembers: (([String]) -> Void)? = nil,
                onSearchMembers: ((String) async throws -> [Contact])? = nil,
                onLeave: (() -> Void)? = nil,
                extraActions: [FlareDetailExtraAction] = [], onExtraAction: ((String) -> Void)? = nil) {
        self.model = model; self.loading = loading; self.joinRequests = joinRequests
        self.loadingJoinRequests = loadingJoinRequests; self.inviteCode = inviteCode
        self.loadingInviteLink = loadingInviteLink; self.invitableContacts = invitableContacts
        self.labels = labels; self.afterInfo = afterInfo; self.footer = footer
        self.onBack = onBack; self.onOpenChat = onOpenChat; self.onUpdateName = onUpdateName
        self.onUpdateAnnouncement = onUpdateAnnouncement; self.onUpdateMyNickname = onUpdateMyNickname
        self.onSetJoinPolicy = onSetJoinPolicy; self.onToggleMuteAll = onToggleMuteAll
        self.onSetFlag = onSetFlag; self.onToggleMyMuted = onToggleMyMuted
        self.onToggleMyPinned = onToggleMyPinned; self.onLoadJoinRequests = onLoadJoinRequests
        self.onRespondRequest = onRespondRequest; self.onEnsureInviteLink = onEnsureInviteLink
        self.onPromoteMember = onPromoteMember; self.onMuteMember = onMuteMember
        self.onTransferOwner = onTransferOwner; self.onRemoveMember = onRemoveMember
        self.onLoadContacts = onLoadContacts; self.onInviteMembers = onInviteMembers
        self.onSearchMembers = onSearchMembers; self.onLeave = onLeave
        self.extraActions = extraActions; self.onExtraAction = onExtraAction
    }

    /// Cells in the member preview, the add tile included: four rows of five (Vue `MEMBER_PREVIEW_CELLS`).
    static let memberPreviewCells = 20

    /// The members the grid previews: the first 19 with the add tile when the viewer manages the group,
    /// else the first 20. The 群成员 row lists everyone.
    static func previewMembers(_ members: [Contact], canManage: Bool) -> [Contact] {
        Array(members.prefix(canManage ? memberPreviewCells - 1 : memberPreviewCells))
    }

    /// The members whose name contains `query` (trimmed, any case); everyone for an empty query.
    static func matchingMembers(_ members: [Contact], query: String) -> [Contact] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return members }
        return members.filter { $0.name.lowercased().contains(needle) }
    }

    /// Chooses sheet members while preserving the old local path when no host-backed search is supplied.
    static func visibleMembers(_ members: [Contact], query: String, searched: [Contact]?, remoteEnabled: Bool) -> [Contact] {
        remoteEnabled ? (searched ?? matchingMembers(members, query: query)) : matchingMembers(members, query: query)
    }

    private var canManage: Bool { model?.canManage ?? false }

    /// The states a member's admin and mute buttons offer, read from the model at tap time: the
    /// opposite of what the member has now (the button reads "unset admin" for an admin).
    static func memberIntentTargets(_ memberId: String, in model: FlareGroupDetailModel) -> (admin: Bool, muted: Bool) {
        (admin: !model.adminIds.contains(memberId), muted: !model.mutedIds.contains(memberId))
    }

    /// The join policy's name; an unknown policy reads "not set" — the kit never guesses one.
    static func joinPolicyLabel(_ policy: FlareGroupJoinPolicy?, copy: FlareGroupDetailLabels.Resolved) -> String {
        switch policy {
        case .open: return copy.joinOpen
        case .approval: return copy.joinApproval
        case .invite: return copy.joinInvite
        case nil: return copy.notSet
        }
    }

    /// The picker's choices in display order (open, approval, invite).
    static func joinPolicyOptions(_ copy: FlareGroupDetailLabels.Resolved) -> [FlareSelectOption] {
        FlareGroupJoinPolicy.allCases.map { FlareSelectOption(value: $0.rawValue, label: joinPolicyLabel($0, copy: copy)) }
    }

    private var copy: FlareGroupDetailLabels.Resolved { labels.resolve(strings) }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Group {
            if let m = model {
                content(colors, m)
            } else if loading {
                ProgressView().frame(maxWidth: .infinity).padding(FlareSizes.spacing2xl)
            } else {
                EmptyStateView(title: copy.unavailable, description: copy.unavailableHint, icon: "group")
                    .frame(maxWidth: .infinity, minHeight: 240)
            }
        }
        .background(colors.bgSecondary.ignoresSafeArea())
        // ── Edit name / announcement / nickname ──
        .sheet(item: $editKind) { kind in
            FormSheetView(title: editAlertTitle, confirmLabel: copy.save, cancelLabel: copy.cancel,
                          confirmEnabled: kind != .name || !editDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          onConfirm: saveEdit, onClose: { editKind = nil }) {
                InputView(text: $editDraft, multiline: kind == .announcement)
            }
        }
        // ── Join policy: the current one selected (none when unknown); a pick closes and emits ──
        .flareBottomSheet(item: $joinPolicyPicker, title: copy.joinMode) { _ in
            FlareGroupJoinPolicyPicker(policy: model?.joinPolicy, options: Self.joinPolicyOptions(copy)) { policy in
                joinPolicyPicker = nil
                onSetJoinPolicy?(policy)
            }
        }
        // ── Member management ──
        .confirmationDialog(memberAction?.name ?? "", isPresented: Binding(
            get: { memberAction != nil }, set: { if !$0 { memberAction = nil } }
        ), titleVisibility: .visible) { memberActionButtons(for: memberAction) }
        // ── Transfer owner confirm (without a feedback host) ──
        .alert(copy.transferOwner, isPresented: Binding(
            get: { transferTarget != nil }, set: { if !$0 { transferTarget = nil } }
        )) {
            Button(copy.transferOwner, role: .destructive) {
                if let t = transferTarget { onTransferOwner?(t.id) }
            }
            Button(copy.cancel, role: .cancel) { transferTarget = nil }
        } message: {
            Text(String(format: copy.transferConfirm, transferTarget?.name ?? ""))
        }
        // ── Sheets ──
        .sheet(isPresented: $showJoinRequests) { joinRequestsSheet }
        .sheet(isPresented: $showInviteLink) { inviteLinkSheet }
        .sheet(isPresented: $showInvite) { inviteMembersSheet }
        .sheet(isPresented: $showMembers, onDismiss: {
            // The member dialog belongs to the page: open it once the members sheet is gone.
            if let member = pendingMemberAction { pendingMemberAction = nil; memberAction = member }
        }) { membersSheet }
    }

    private var editAlertTitle: String {
        switch editKind {
        case .announcement: return copy.editAnnouncement
        case .nickname: return copy.myNickname
        default: return copy.editName
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
                    members: Self.previewMembers(m.members, canManage: canManage), ownerId: m.ownerId,
                    adminIds: m.adminIds, showAdd: canManage,
                    onSelect: { uid in
                        guard canManage, uid != m.ownerId else { return }
                        memberAction = m.members.first { $0.id == uid }
                    },
                    onAddMember: { onLoadContacts?(); showInvite = true },
                    total: m.memberCount
                )
                infoCard(colors, m)
                if let afterInfo { afterInfo.padding(.horizontal, FlareSizes.spacingMd) }
                myInGroupCard(colors, m)
                if canManage { manageCard(colors, m) }
                if canManage { permsCard(colors, m) }
                bottomActions(colors, m)
                if let footer { footer.padding(.horizontal, FlareSizes.spacingLg) }
            }
            .padding(.vertical, FlareSizes.spacingLg)
        }
    }

    private func hero(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            AvatarView(userId: m.groupId, displayName: m.name, avatarURL: m.avatarURL, size: 72)
            Text(m.name.isEmpty ? copy.title : m.name)
                .font(.system(size: FlareSizes.fontSize3xl, weight: .semibold)).foregroundColor(colors.textPrimary)
            Text("\(m.memberCount) \(copy.memberCountSuffix)")
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
        card(copy.sectionInfo, [
            FlareSettingsItem(key: "name", label: copy.groupName, icon: "tag",
                              kind: canManage ? .navigation : .value, detail: m.name.isEmpty ? "-" : m.name),
            FlareSettingsItem(key: "announcement", label: copy.announcement, icon: "announcement",
                              kind: canManage ? .navigation : .value,
                              detail: m.announcement.isEmpty ? copy.notSet : m.announcement),
            // Everyone, with search, in the members sheet.
            FlareSettingsItem(key: "members", label: copy.members, icon: "people",
                              kind: .navigation, detail: "\(m.memberCount)"),
        ], colors)
    }

    private func myInGroupCard(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        card(copy.sectionMyInGroup, [
            FlareSettingsItem(key: "myNickname", label: copy.myNickname, icon: "edit",
                              kind: .navigation, detail: m.myNickname.isEmpty ? copy.notSet : m.myNickname),
            // A setting that could not be read claims neither state: an information row, not a switch.
            m.myMuted.map { FlareSettingsItem(key: "myMuted", label: copy.muteNotif, icon: "mute",
                                              kind: .toggle, value: $0) }
                ?? FlareSettingsItem(key: "myMuted", label: copy.muteNotif, icon: "mute",
                                     kind: .value, detail: copy.settingUnavailable),
            m.myPinned.map { FlareSettingsItem(key: "myPinned", label: copy.pinGroup, icon: "pin",
                                               kind: .toggle, value: $0) }
                ?? FlareSettingsItem(key: "myPinned", label: copy.pinGroup, icon: "pin",
                                     kind: .value, detail: copy.settingUnavailable),
        ], colors)
    }

    private func manageCard(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        card(copy.sectionManage, [
            FlareSettingsItem(key: "joinPolicy", label: copy.joinMode, icon: "lock",
                              kind: .navigation, detail: Self.joinPolicyLabel(m.joinPolicy, copy: copy)),
            FlareSettingsItem(key: "joinRequests", label: copy.joinRequests, icon: "join-request",
                              kind: .navigation, detail: joinRequests.isEmpty ? "" : "\(joinRequests.count)"),
            FlareSettingsItem(key: "muteAll", label: copy.muteAll, icon: "silence",
                              kind: .toggle, value: m.muteAll),
            FlareSettingsItem(key: "inviteLink", label: copy.inviteLink, icon: "link", kind: .navigation),
        ], colors)
    }

    private func permsCard(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        card(copy.sectionPerms, [
            FlareSettingsItem(key: "atAll", label: copy.onlyAdminAtAll, icon: "mention",
                              kind: .toggle, value: m.onlyAdminCanAtAll),
            FlareSettingsItem(key: "pinPerm", label: copy.onlyAdminPin, icon: "pin",
                              kind: .toggle, value: m.onlyAdminCanPin),
            FlareSettingsItem(key: "shareCard", label: copy.shareCard, icon: "share",
                              kind: .toggle, value: m.shareCardPermission),
        ], colors)
    }

    private func onRowSelect(_ item: FlareSettingsItem) {
        switch item.key {
        case "members":
            memberQuery = ""; showMembers = true
        case "myNickname":
            editDraft = model?.myNickname ?? ""; editKind = .nickname
        case "name" where canManage:
            editDraft = model?.name ?? ""; editKind = .name
        case "announcement" where canManage:
            editDraft = model?.announcement ?? ""; editKind = .announcement
        case "joinPolicy" where canManage:
            joinPolicyPicker = .shown
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

    // MARK: - Message / leave

    private func bottomActions(_ colors: FlareColors, _ m: FlareGroupDetailModel) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            // Drawn only when the host opens the chat: no handler, no dead button.
            if let onOpenChat {
                ButtonView(label: copy.message, variant: .primary, block: true) {
                    // Contract parity with Vue `openChat({ userIds, name })` / Flutter `(userIds, name)`.
                    onOpenChat(m.members.map(\.id), m.name.isEmpty ? copy.title : m.name)
                }
            }
            ForEach(extraActions) { action in
                ButtonView(label: action.label, variant: action.danger ? .danger : .secondary, block: true) {
                    onExtraAction?(action.id)
                }
            }
            // Leaving is the host's to confirm: the tap is the intent.
            ButtonView(label: m.isOwner ? copy.dissolve : copy.leave, variant: .danger, block: true) {
                onLeave?()
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.top, FlareSizes.spacingSm)
    }

    // MARK: - Member action buttons

    /// The member dialog's buttons for `member` (the one whose dialog is open).
    @ViewBuilder func memberActionButtons(for member: Contact?) -> some View {
        if let mem = member, let m = model, canManage, mem.id != m.ownerId {
            // Each intent carries the state its label offers.
            let target = Self.memberIntentTargets(mem.id, in: m)
            Button(target.admin ? copy.setAdmin : copy.unsetAdmin) { onPromoteMember?(mem.id, target.admin); memberAction = nil }
            Button(target.muted ? copy.mute : copy.unmute) { onMuteMember?(mem.id, target.muted); memberAction = nil }
            if m.isOwner {
                Button(copy.transferOwner) { memberAction = nil; confirmTransfer(mem) }
            }
            // Removing is the host's to confirm: the tap is the intent.
            Button(copy.removeMember, role: .destructive) { memberAction = nil; onRemoveMember?(mem.id) }
            Button(copy.cancel, role: .cancel) {}
        } else {
            Button(copy.cancel, role: .cancel) {}
        }
    }

    // MARK: - Transfer confirmation

    // Member-dialog buttons run once the dialog is gone, so a confirmation can present right away.

    private func confirmTransfer(_ member: Contact) {
        if !Self.confirm(Self.transferOptions(member, copy: copy, onTransferOwner: onTransferOwner), through: feedback) {
            transferTarget = member
        }
    }

    /// Asks through the app's feedback host when one is installed — the step runs once confirmed —
    /// and returns true; false leaves the confirmation to the system alert.
    @MainActor
    static func confirm(_ options: FlareConfirmOptions, through feedback: FlareFeedback?) -> Bool {
        guard let feedback else { return false }
        Task { _ = await feedback.confirm(options) }
        return true
    }

    static func transferOptions(_ member: Contact, copy: FlareGroupDetailLabels.Resolved,
                                onTransferOwner: ((String) -> Void)?) -> FlareConfirmOptions {
        FlareConfirmOptions(title: copy.transferOwner, description: String(format: copy.transferConfirm, member.name),
                            confirmText: copy.transferOwner, cancelText: copy.cancel,
                            action: { onTransferOwner?(member.id) })
    }

    // MARK: - Sheets

    private var joinRequestsSheet: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return VStack(spacing: 0) {
            sheetHeader(copy.joinRequests) { showJoinRequests = false }
            Group {
                if loadingJoinRequests {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if joinRequests.isEmpty {
                    EmptyStateView(title: copy.noRequests, icon: "join-request")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(joinRequests) { r in
                        HStack(spacing: FlareSizes.spacingMd) {
                            AvatarView(userId: r.applicantId, displayName: r.applicantName, avatarURL: r.avatarURL, size: 42)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.applicantName).foregroundColor(colors.textPrimary)
                                Text((r.message?.isEmpty == false ? r.message! : copy.requestDefaultMessage))
                                    .font(.footnote).foregroundColor(colors.textTertiary).lineLimit(1)
                            }
                            Spacer()
                            ButtonView(label: copy.reject, variant: .secondary, size: .sm) { onRespondRequest?(r.requestId, false) }
                            ButtonView(label: copy.approve, variant: .primary, size: .sm) { onRespondRequest?(r.requestId, true) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .background(colors.bgPrimary.ignoresSafeArea())
    }

    /// Every member with a search field; choosing one who can be managed closes the sheet and opens the
    /// same member dialog as the grid.
    private var membersSheet: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let members = model?.members ?? []
        let matching = Self.visibleMembers(members, query: memberQuery, searched: searchedMembers, remoteEnabled: onSearchMembers != nil)
        return VStack(spacing: 0) {
            sheetHeader(strings.groupDetailMembersTitle(model?.memberCount ?? members.count)) { showMembers = false }
            SearchBarView(text: $memberQuery, placeholder: strings.groupDetailSearchMembers, loading: memberSearchLoading)
                .padding(.horizontal, FlareSizes.spacingLg)
                .padding(.bottom, FlareSizes.spacingSm)
            if let memberSearchError {
                Text(memberSearchError)
                    .font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, FlareSizes.spacing2xl)
                Spacer(minLength: 0)
            } else if matching.isEmpty {
                Text(strings.groupDetailNoMatchingMembers)
                    .font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, FlareSizes.spacing2xl)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(matching) { member in
                            ContactItemView(item: member, showPresence: false,
                                            onSelect: memberSelectable(member) ? { chooseListedMember(member) } : nil)
                                .padding(.horizontal, FlareSizes.spacingMd)
                                .padding(.vertical, FlareSizes.spacingSm)
                        }
                    }
                }
            }
        }
        .background(colors.bgPrimary.ignoresSafeArea())
        .onChange(of: memberQuery) { _ in runMemberSearch() }
    }

    private func runMemberSearch() {
        memberSearchGeneration += 1
        let generation = memberSearchGeneration
        let query = memberQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        memberSearchError = nil
        guard let onSearchMembers, !query.isEmpty else {
            searchedMembers = nil
            memberSearchLoading = false
            return
        }
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            await MainActor.run {
                guard generation == memberSearchGeneration else { return }
                memberSearchLoading = true
            }
            do {
                let found = try await onSearchMembers(query)
                await MainActor.run {
                    guard generation == memberSearchGeneration else { return }
                    searchedMembers = found
                    memberSearchLoading = false
                }
            } catch {
                await MainActor.run {
                    guard generation == memberSearchGeneration else { return }
                    searchedMembers = []
                    memberSearchError = error.localizedDescription.isEmpty ? strings.groupDetailNoMatchingMembers : error.localizedDescription
                    memberSearchLoading = false
                }
            }
        }
    }

    /// Whether choosing `member` offers anything: the viewer manages the group and the member is not its owner.
    private func memberSelectable(_ member: Contact) -> Bool {
        canManage && member.id != model?.ownerId
    }

    private func chooseListedMember(_ member: Contact) {
        pendingMemberAction = member
        showMembers = false
    }

    private var inviteLinkSheet: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return VStack(spacing: 0) {
            sheetHeader(copy.inviteLink) { showInviteLink = false }
            VStack(spacing: FlareSizes.spacingLg) {
                if loadingInviteLink {
                    ProgressView().padding(FlareSizes.spacing2xl)
                } else if let code = inviteCode, !code.isEmpty {
                    Text(copy.inviteCodeTitle).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                    InviteCodeCopyView(code: code, copyLabel: copy.copyCode, copiedLabel: copy.copied)
                    Text(copy.inviteLinkHint)
                        .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                        .multilineTextAlignment(.center)
                } else {
                    EmptyStateView(title: copy.cannotGenerate, description: copy.unavailableHint, icon: "link")
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
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let memberIds = Set(model?.members.map { $0.id } ?? [])
        let invitable = invitableContacts.filter { !memberIds.contains($0.id) }
        return VStack(spacing: 0) {
            sheetHeader(copy.invite) { showInvite = false }
            InviteMemberPicker(contacts: invitable, emptyText: copy.inviteEmpty,
                               inviteLabel: copy.invite, cancelLabel: copy.cancel,
                               onCancel: { showInvite = false },
                               onConfirm: { ids in showInvite = false; onInviteMembers?(ids) })
        }
        .background(colors.bgPrimary.ignoresSafeArea())
    }

    /// Cross-platform sheet header (the kit also builds on macOS, where iOS navigation-bar
    /// toolbars are unavailable): a centered title with a trailing Done button.
    private func sheetHeader(_ title: String, _ onDone: @escaping () -> Void) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return ZStack {
            Text(title).font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
            HStack {
                Spacer()
                Button(copy.done) { onDone() }.foregroundColor(colors.primaryText)
            }
        }
        .padding(FlareSizes.spacingLg)
    }
}

// MARK: - Supporting views

/// The join-policy sheet's body: the choices as a kit radio group with the current policy selected —
/// none when it is unknown — and picking one reports it.
struct FlareGroupJoinPolicyPicker: View {
    let policy: FlareGroupJoinPolicy?
    let options: [FlareSelectOption]
    let onPick: (FlareGroupJoinPolicy) -> Void

    var body: some View {
        RadioGroupView(options: options, selection: Binding(
            get: { policy?.rawValue ?? "" },
            set: { value in if let picked = FlareGroupJoinPolicy(rawValue: value) { onPick(picked) } }
        ), vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.bottom, FlareSizes.spacingLg)
    }
}

/// Invite-code display + copy button (used by ``FlareGroupDetail``'s invite-link sheet).
private struct InviteCodeCopyView: View {
    let code: String
    let copyLabel: String
    let copiedLabel: String
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @State private var copied = false

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
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
                       block: true, icon: copied ? "check" : "copy") {
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
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @State private var picked: Set<String> = []

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 0) {
            if contacts.isEmpty {
                EmptyStateView(title: emptyText, icon: "people")
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
