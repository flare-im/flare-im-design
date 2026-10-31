import Foundation

// Group management contracts shared by ``FlareGroupDetail``, ``GroupPermissionMatrixView`` and
// ``MemberRoleSheetView`` — the Swift spelling of the Vue kit's `shared/contracts/group-permissions.ts`.
//
// Who may do what is not decided here. The host passes what its permission source answered — the
// viewer's ``FlareGroupCapabilities`` and, per member, the ``FlareMemberActions`` — and the kit only
// maps each answer to the entry it names. No role, owner or permission-bit rule lives in the kit: a host
// that says nothing gets no management entry. The shared cases are in `spec/group-management-vectors.json`;
// all four platforms run them.

/// What the viewer may manage in the group, as the host's permission source answers it (the social SDK's
/// `memberCapabilities` carries these fields under the same names). False hides the entries the field names.
public struct FlareGroupCapabilities: Equatable, Sendable {
    /// Group name, announcement, mute-all and the three group permission switches.
    public var canManageInfo: Bool
    /// Join policy and whether the group can be found by search.
    public var canManageJoinSettings: Bool
    /// List and answer join requests.
    public var canManageJoinRequests: Bool
    /// Invite friends into the group and read its invite link.
    public var canInvite: Bool
    /// Dissolve the group; without it the viewer's way out is leaving.
    public var canDissolve: Bool

    public init(canManageInfo: Bool = false, canManageJoinSettings: Bool = false,
                canManageJoinRequests: Bool = false, canInvite: Bool = false, canDissolve: Bool = false) {
        self.canManageInfo = canManageInfo
        self.canManageJoinSettings = canManageJoinSettings
        self.canManageJoinRequests = canManageJoinRequests
        self.canInvite = canInvite
        self.canDissolve = canDissolve
    }

    /// No management at all: what a host passes when it could not read the viewer's capabilities.
    public static let none = FlareGroupCapabilities()
}

/// What the viewer may do to one member, as the host's permission source answers it (the social SDK's
/// `memberActions`, one entry per member, carries these fields). False hides the action.
public struct FlareMemberActions: Equatable, Sendable {
    /// Remove the member from the group.
    public var canRemove: Bool
    /// Mute or unmute the member; the label follows the member's muted state.
    public var canMute: Bool
    /// Make the member an admin or revoke it; the label follows the member's role.
    public var canChangeRole: Bool
    /// Hand ownership over to the member.
    public var canTransferOwner: Bool

    public init(canRemove: Bool = false, canMute: Bool = false,
                canChangeRole: Bool = false, canTransferOwner: Bool = false) {
        self.canRemove = canRemove
        self.canMute = canMute
        self.canChangeRole = canChangeRole
        self.canTransferOwner = canTransferOwner
    }

    /// Nothing may be done to the member.
    public static let none = FlareMemberActions()
}

/// The management entries of a group page, in display order; identical on all four platforms.
public enum FlareGroupManagementEntry: String, CaseIterable, Sendable {
    case editName, editAnnouncement, discoverable, joinPolicy, joinRequests, muteAll, inviteLink
    case onlyAdminCanAtAll, onlyAdminCanPin, shareCardPermission, inviteMembers, dissolve

    /// The one capability field this entry reads; nothing is combined.
    func isOffered(by capabilities: FlareGroupCapabilities) -> Bool {
        switch self {
        case .editName, .editAnnouncement, .muteAll, .onlyAdminCanAtAll, .onlyAdminCanPin, .shareCardPermission:
            return capabilities.canManageInfo
        case .discoverable, .joinPolicy: return capabilities.canManageJoinSettings
        case .joinRequests: return capabilities.canManageJoinRequests
        case .inviteLink, .inviteMembers: return capabilities.canInvite
        case .dissolve: return capabilities.canDissolve
        }
    }
}

/// The management entries the viewer gets, in display order. Without `.dissolve` the page offers leaving instead.
public func groupManagementEntries(_ capabilities: FlareGroupCapabilities?) -> [FlareGroupManagementEntry] {
    let caps = capabilities ?? .none
    return FlareGroupManagementEntry.allCases.filter { $0.isOffered(by: caps) }
}

/// A member's role on the group page: the owner by `ownerId`, an admin by `adminIds`, otherwise a member.
public func groupDetailMemberRole(model: FlareGroupDetailModel, memberId: String) -> FlareGroupMemberRole {
    if memberId == model.ownerId { return .owner }
    return model.adminIds.contains(memberId) ? .admin : .member
}

/// The actions ``FlareGroupDetail``'s member sheet offers for `memberId`: ``memberRoleActions(role:muted:actions:)``
/// over the member's state on the page and the host's `memberActions` entry for that id. A member the host gave
/// no entry gets nothing, and the sheet does not open for an empty list.
public func groupDetailMemberActions(model: FlareGroupDetailModel, memberId: String) -> [FlareMemberRoleActionEntry] {
    memberRoleActions(role: groupDetailMemberRole(model: model, memberId: memberId),
                      muted: model.mutedIds.contains(memberId),
                      actions: model.memberActions[memberId])
}
