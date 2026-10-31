package com.flare.im.ui

/**
 * What the viewer may manage in a group, as the host's permission source answers it (the social
 * SDK's `memberCapabilities` carries these fields under the same names). False hides the entries
 * the field names; the kit reads no role, owner or permission-bit rule of its own.
 *
 * Mirrors the Vue kit's `FlareGroupCapabilities` (shared/contracts/group-permissions.ts).
 */
data class FlareGroupCapabilities(
    /** Group name, announcement, mute-all and the three group permission switches. */
    val canManageInfo: Boolean = false,
    /** Join policy and whether the group can be found by search. */
    val canManageJoinSettings: Boolean = false,
    /** List and answer join requests. */
    val canManageJoinRequests: Boolean = false,
    /** Invite friends into the group and read its invite link. */
    val canInvite: Boolean = false,
    /** Dissolve the group; without it the viewer's way out is leaving. */
    val canDissolve: Boolean = false,
) {
    companion object {
        /** No management at all: what a host passes when it could not read the viewer's capabilities. */
        val none = FlareGroupCapabilities()
    }
}

/**
 * What the viewer may do to one member, as the host's permission source answers it (the social
 * SDK's `memberActions`, one entry per member, carries these fields). False hides the action.
 */
data class FlareMemberActions(
    /** Remove the member from the group. */
    val canRemove: Boolean = false,
    /** Mute or unmute the member; the label follows the member's muted state. */
    val canMute: Boolean = false,
    /** Make the member an admin or revoke it; the label follows the member's role. */
    val canChangeRole: Boolean = false,
    /** Hand ownership over to the member. */
    val canTransferOwner: Boolean = false,
)

/**
 * The management entries of a group page. Declaration order is the display order, identical on
 * all four platforms; [wire] is the id in `spec/group-management-vectors.json`.
 */
enum class FlareGroupManagementEntry(val wire: String) {
    EditName("editName"),
    EditAnnouncement("editAnnouncement"),
    Discoverable("discoverable"),
    JoinPolicy("joinPolicy"),
    JoinRequests("joinRequests"),
    MuteAll("muteAll"),
    InviteLink("inviteLink"),
    OnlyAdminCanAtAll("onlyAdminCanAtAll"),
    OnlyAdminCanPin("onlyAdminCanPin"),
    ShareCardPermission("shareCardPermission"),
    InviteMembers("inviteMembers"),
    Dissolve("dissolve"),
}

/** Which capability each entry reads; one field per entry, nothing combined. */
private fun FlareGroupCapabilities.allows(entry: FlareGroupManagementEntry): Boolean = when (entry) {
    FlareGroupManagementEntry.EditName,
    FlareGroupManagementEntry.EditAnnouncement,
    FlareGroupManagementEntry.MuteAll,
    FlareGroupManagementEntry.OnlyAdminCanAtAll,
    FlareGroupManagementEntry.OnlyAdminCanPin,
    FlareGroupManagementEntry.ShareCardPermission,
    -> canManageInfo
    FlareGroupManagementEntry.Discoverable, FlareGroupManagementEntry.JoinPolicy -> canManageJoinSettings
    FlareGroupManagementEntry.JoinRequests -> canManageJoinRequests
    FlareGroupManagementEntry.InviteLink, FlareGroupManagementEntry.InviteMembers -> canInvite
    FlareGroupManagementEntry.Dissolve -> canDissolve
}

/**
 * The management entries the viewer gets, in display order (Vue `groupManagementEntries`).
 * Without [FlareGroupManagementEntry.Dissolve] the page offers leaving instead.
 */
fun groupManagementEntries(capabilities: FlareGroupCapabilities?): List<FlareGroupManagementEntry> {
    val caps = capabilities ?: FlareGroupCapabilities.none
    return FlareGroupManagementEntry.entries.filter { caps.allows(it) }
}

/** A member's role on the group page: the owner by `ownerId`, an admin by `adminIds`, otherwise a member. */
fun groupDetailMemberRole(model: FlareGroupDetailModel, memberId: String): FlareGroupMemberRole = when {
    memberId == model.ownerId -> FlareGroupMemberRole.Owner
    memberId in model.adminIds -> FlareGroupMemberRole.Admin
    else -> FlareGroupMemberRole.Member
}

/**
 * The actions [FlareGroupDetail]'s member sheet offers for [memberId] (Vue `groupDetailMemberActions`):
 * [memberRoleActions] over the member's state on the page and the host's [FlareGroupDetailModel.memberActions]
 * entry for that id. A member the host gave no entry gets nothing, and the sheet does not open for an empty list.
 */
fun groupDetailMemberActions(model: FlareGroupDetailModel, memberId: String): List<FlareMemberRoleActionEntry> =
    memberRoleActions(
        role = groupDetailMemberRole(model, memberId),
        muted = memberId in model.mutedIds,
        actions = model.memberActions[memberId],
    )
