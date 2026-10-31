import 'package:flutter/foundation.dart';

import 'directory_data.dart';

/// Group management contracts — pure logic shared by the four platforms and by
/// three components:
///
///  - [FlareGroupDetail]        → [groupManagementEntries], [groupDetailMemberActions]
///  - FlareGroupPermissionMatrix → `groupPermissionRows`
///  - FlareMemberRoleSheet      → [memberRoleActions]
///
/// Who may do what is not decided here. The host passes what its permission
/// source answered — the viewer's [FlareGroupCapabilities] and, per member, the
/// [FlareMemberActions] — and the kit only maps each answer to the entry it
/// names. No role, owner or permission-bit rule lives in the kit: a host that
/// says nothing gets no management entry. The shared cases are in
/// `spec/group-management-vectors.json`; all four platforms run them (Vue
/// `shared/contracts/group-permissions.ts`).

/// What the viewer may manage in the group, as the host's permission source
/// answers it (the social SDK's `memberCapabilities` carries these fields under
/// the same names). False hides the entries the field names.
@immutable
class FlareGroupCapabilities {
  const FlareGroupCapabilities({
    this.canManageInfo = false,
    this.canManageJoinSettings = false,
    this.canManageJoinRequests = false,
    this.canInvite = false,
    this.canDissolve = false,
  });

  /// No management at all: what a host passes when it could not read the
  /// viewer's capabilities.
  static const none = FlareGroupCapabilities();

  /// Group name, announcement, mute-all and the three group permission switches.
  final bool canManageInfo;

  /// Join policy and whether the group can be found by search.
  final bool canManageJoinSettings;

  /// List and answer join requests.
  final bool canManageJoinRequests;

  /// Invite friends into the group and read its invite link.
  final bool canInvite;

  /// Dissolve the group; without it the viewer's way out is leaving.
  final bool canDissolve;

  @override
  bool operator ==(Object other) =>
      other is FlareGroupCapabilities &&
      other.canManageInfo == canManageInfo &&
      other.canManageJoinSettings == canManageJoinSettings &&
      other.canManageJoinRequests == canManageJoinRequests &&
      other.canInvite == canInvite &&
      other.canDissolve == canDissolve;

  @override
  int get hashCode => Object.hash(
    canManageInfo,
    canManageJoinSettings,
    canManageJoinRequests,
    canInvite,
    canDissolve,
  );
}

/// What the viewer may do to one member, as the host's permission source
/// answers it (the social SDK's `memberActions`, one entry per member, carries
/// these fields). False hides the action.
@immutable
class FlareMemberActions {
  const FlareMemberActions({
    this.canRemove = false,
    this.canMute = false,
    this.canChangeRole = false,
    this.canTransferOwner = false,
  });

  /// Nothing may be done to the member.
  static const none = FlareMemberActions();

  /// Remove the member from the group.
  final bool canRemove;

  /// Mute or unmute the member; the label follows the member's muted state.
  final bool canMute;

  /// Make the member an admin or revoke it; the label follows the member's role.
  final bool canChangeRole;

  /// Hand ownership over to the member.
  final bool canTransferOwner;

  @override
  bool operator ==(Object other) =>
      other is FlareMemberActions &&
      other.canRemove == canRemove &&
      other.canMute == canMute &&
      other.canChangeRole == canChangeRole &&
      other.canTransferOwner == canTransferOwner;

  @override
  int get hashCode =>
      Object.hash(canRemove, canMute, canChangeRole, canTransferOwner);
}

/// The management entries of a group page, in display order; identical on all
/// four platforms ([id] is the shared table's name).
enum FlareGroupManagementEntry {
  editName('editName'),
  editAnnouncement('editAnnouncement'),
  discoverable('discoverable'),
  joinPolicy('joinPolicy'),
  joinRequests('joinRequests'),
  muteAll('muteAll'),
  inviteLink('inviteLink'),
  onlyAdminCanAtAll('onlyAdminCanAtAll'),
  onlyAdminCanPin('onlyAdminCanPin'),
  shareCardPermission('shareCardPermission'),
  inviteMembers('inviteMembers'),
  dissolve('dissolve');

  const FlareGroupManagementEntry(this.id);
  final String id;

  /// The one capability this entry reads; nothing is combined.
  bool _offeredBy(FlareGroupCapabilities c) => switch (this) {
    editName ||
    editAnnouncement ||
    muteAll ||
    onlyAdminCanAtAll ||
    onlyAdminCanPin ||
    shareCardPermission => c.canManageInfo,
    discoverable || joinPolicy => c.canManageJoinSettings,
    joinRequests => c.canManageJoinRequests,
    inviteLink || inviteMembers => c.canInvite,
    dissolve => c.canDissolve,
  };
}

/// The management entries the viewer gets, in display order. Without
/// [FlareGroupManagementEntry.dissolve] the page offers leaving instead.
List<FlareGroupManagementEntry> groupManagementEntries(
  FlareGroupCapabilities? capabilities,
) {
  final caps = capabilities ?? FlareGroupCapabilities.none;
  return [
    for (final entry in FlareGroupManagementEntry.values)
      if (entry._offeredBy(caps)) entry,
  ];
}

/// A member's role in the group.
enum FlareGroupMemberRole { owner, admin, member }

/// Management actions a member sheet can emit; names match the cross-platform
/// contract (Vue `action` payload / SwiftUI / Compose enums).
enum FlareMemberRoleAction {
  promote,
  demote,
  mute,
  unmute,
  transferOwner,
  remove,
}

/// One displayable action; [danger] entries render in the trailing danger group.
@immutable
class FlareMemberRoleActionEntry {
  const FlareMemberRoleActionEntry(this.action, {this.danger = false});
  final FlareMemberRoleAction action;
  final bool danger;

  @override
  bool operator ==(Object other) =>
      other is FlareMemberRoleActionEntry &&
      other.action == action &&
      other.danger == danger;

  @override
  int get hashCode => Object.hash(action, danger);

  @override
  String toString() =>
      'FlareMemberRoleActionEntry(${action.name}, danger: $danger)';
}

/// Ordered management actions for a member with [role] and [muted], from what
/// the host says the viewer may do to that member ([actions]). The kit decides
/// nothing about who may act on whom — the owner's protection, admins not
/// managing each other, the owner-only actions all come from the host's answer.
/// It only picks the label each answer needs:
///
///  - `canChangeRole` offers promote for a member and demote for an admin;
///  - `canMute` offers mute or unmute by [muted];
///  - `canTransferOwner` and `canRemove` form the trailing danger group.
///
/// `mute` still needs host-supplied durations in FlareMemberRoleSheet — a sheet
/// with none hides the row, since the kit never invents durations.
List<FlareMemberRoleActionEntry> memberRoleActions(
  FlareGroupMemberRole role,
  bool muted,
  FlareMemberActions? actions,
) {
  final can = actions ?? FlareMemberActions.none;
  return [
    if (can.canChangeRole && role == FlareGroupMemberRole.member)
      const FlareMemberRoleActionEntry(FlareMemberRoleAction.promote),
    if (can.canChangeRole && role == FlareGroupMemberRole.admin)
      const FlareMemberRoleActionEntry(FlareMemberRoleAction.demote),
    if (can.canMute && !muted)
      const FlareMemberRoleActionEntry(FlareMemberRoleAction.mute),
    if (can.canMute && muted)
      const FlareMemberRoleActionEntry(FlareMemberRoleAction.unmute),
    if (can.canTransferOwner)
      const FlareMemberRoleActionEntry(
        FlareMemberRoleAction.transferOwner,
        danger: true,
      ),
    if (can.canRemove)
      const FlareMemberRoleActionEntry(
        FlareMemberRoleAction.remove,
        danger: true,
      ),
  ];
}

/// A member's role on the group page: the owner by `ownerId`, an admin by
/// `adminIds`, otherwise a member.
FlareGroupMemberRole groupDetailMemberRole(
  FlareGroupDetailModel model,
  String memberId,
) {
  if (memberId == model.ownerId) return FlareGroupMemberRole.owner;
  return model.adminIds.contains(memberId)
      ? FlareGroupMemberRole.admin
      : FlareGroupMemberRole.member;
}

/// The actions [FlareGroupDetail]'s member sheet offers for [memberId]:
/// [memberRoleActions] over the member's state on the page and the host's
/// `memberActions` entry for that id. A member the host gave no entry gets
/// nothing, and the sheet does not open for an empty list.
List<FlareMemberRoleActionEntry> groupDetailMemberActions(
  FlareGroupDetailModel model,
  String memberId,
) => memberRoleActions(
  groupDetailMemberRole(model, memberId),
  model.mutedIds.contains(memberId),
  model.memberActions[memberId],
);
