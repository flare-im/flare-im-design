package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared group management table (`spec/group-management-vectors.json`): which entries the host's capabilities
 * name, how a member's actions are labelled, and what GroupDetail's member sheet offers. The Vue, SwiftUI and
 * Flutter kits run the same table.
 */
class GroupManagementVectorsTest {
    private val table = FlareJson.parse(File(repositoryRoot(), "spec/group-management-vectors.json").readText()) as Map<*, *>

    private fun cases(list: String): List<Map<*, *>> = (table[list] as List<*>).map { it as Map<*, *> }

    private fun Map<*, *>?.flag(key: String) = this?.get(key) == true

    private fun capabilities(raw: Map<*, *>?) = FlareGroupCapabilities(
        canManageInfo = raw.flag("canManageInfo"),
        canManageJoinSettings = raw.flag("canManageJoinSettings"),
        canManageJoinRequests = raw.flag("canManageJoinRequests"),
        canInvite = raw.flag("canInvite"),
        canDissolve = raw.flag("canDissolve"),
    )

    private fun actions(raw: Map<*, *>?): FlareMemberActions? = raw?.let {
        FlareMemberActions(
            canRemove = it.flag("canRemove"),
            canMute = it.flag("canMute"),
            canChangeRole = it.flag("canChangeRole"),
            canTransferOwner = it.flag("canTransferOwner"),
        )
    }

    private fun role(wire: Any?) = when (wire) {
        "owner" -> FlareGroupMemberRole.Owner
        "admin" -> FlareGroupMemberRole.Admin
        else -> FlareGroupMemberRole.Member
    }

    private fun wire(action: FlareMemberRoleAction) = when (action) {
        FlareMemberRoleAction.Promote -> "promote"
        FlareMemberRoleAction.Demote -> "demote"
        FlareMemberRoleAction.Mute -> "mute"
        FlareMemberRoleAction.Unmute -> "unmute"
        FlareMemberRoleAction.TransferOwner -> "transferOwner"
        FlareMemberRoleAction.Remove -> "remove"
    }

    private fun entries(raw: Any?) = (raw as List<*>).map { e -> (e as Map<*, *>).let { it["action"] to (it["danger"] == true) } }

    private fun shown(got: List<FlareMemberRoleActionEntry>) = got.map { wire(it.action) to it.danger }

    @Test fun theDisplayOrderIsTheSharedOne() {
        assertEquals(table["entryOrder"], FlareGroupManagementEntry.entries.map { it.wire })
    }

    @Test fun eachCapabilityShowsTheEntriesItNamesAndNothingElse() {
        val list = cases("entries")
        assertTrue(list.size >= 8, "the shared table lost cases: ${list.size}")
        for (case in list) {
            val got = groupManagementEntries(capabilities(case["capabilities"] as Map<*, *>?)).map { it.wire }
            assertEquals(case["expected"], got, case["id"] as String)
        }
    }

    @Test fun eachMemberActionIsLabelledFromTheHostsAnswerAndTheMembersState() {
        for (case in cases("memberActions")) {
            val member = case["member"] as Map<*, *>
            val got = memberRoleActions(role(member["role"]), member["muted"] == true, actions(case["actions"] as Map<*, *>?))
            assertEquals(entries(case["expected"]), shown(got), case["id"] as String)
        }
    }

    @Test fun theMemberSheetOffersOnlyWhatTheHostAllowsForThatMember() {
        for (case in cases("detailSheet")) {
            val raw = case["model"] as Map<*, *>
            val model = FlareGroupDetailModel(
                groupId = "g",
                name = "g",
                ownerId = raw["ownerId"] as String,
                adminIds = (raw["adminIds"] as List<*>).map { it as String },
                mutedIds = (raw["mutedIds"] as List<*>).map { it as String },
                memberActions = (raw["memberActions"] as Map<*, *>).entries
                    .associate { (id, value) -> id as String to actions(value as Map<*, *>)!! },
            )
            val got = groupDetailMemberActions(model, case["memberId"] as String)
            assertEquals(entries(case["expected"]), shown(got), case["id"] as String)
        }
    }

    @Test fun aPermissionMatrixRowIsEditableExactlyWhenItsEntryIsOffered() {
        val settings = FlareGroupPermissionSettings(joinPolicy = FlareGroupJoinPolicy.Approval)
        for (case in cases("entries")) {
            val rows = groupPermissionRows(settings, capabilities(case["capabilities"] as Map<*, *>?))
            val expected = FlareGroupPermissionKey.entries.map { it.wire }.filter { it in (case["expected"] as List<*>) }
            assertEquals(expected, rows.filter { it.editable }.map { it.key.wire }, case["id"] as String)
        }
    }

    /** An admin who may only mute: mute for the plain member, nothing for the peer admin or the owner. */
    @Test fun anAdminWhoMayOnlyMuteGetsOnlyMuteAndNothingOnAPeerAdmin() {
        val model = FlareGroupDetailModel(
            groupId = "g",
            name = "g",
            ownerId = "own",
            adminIds = listOf("me", "peer"),
            memberActions = mapOf("kim" to FlareMemberActions(canMute = true), "peer" to FlareMemberActions()),
        )
        assertEquals(listOf(FlareMemberRoleAction.Mute), groupDetailMemberActions(model, "kim").map { it.action })
        assertEquals(emptyList(), groupDetailMemberActions(model, "peer"))
        assertEquals(emptyList(), groupDetailMemberActions(model, "own"))
        // The kit's own entries say nothing either: an admin without capabilities gets no management row.
        assertEquals(emptyList(), groupManagementEntries(model.capabilities))
    }

    private fun repositoryRoot(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            if (File(dir, "spec/group-management-vectors.json").isFile) return dir
            dir = dir.parentFile
        }
        error("spec/group-management-vectors.json not found above ${File(".").absolutePath}")
    }
}
