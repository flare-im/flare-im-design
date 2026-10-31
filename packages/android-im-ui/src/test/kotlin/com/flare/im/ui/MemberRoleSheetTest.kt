package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MemberRoleSheetTest {
    private val every = FlareMemberActions(canRemove = true, canMute = true, canChangeRole = true, canTransferOwner = true)

    private fun member(role: FlareGroupMemberRole, muted: Boolean = false) =
        FlareGroupMemberSnapshot(id = "u-$role", name = role.name, role = role, muted = muted)

    private fun ids(m: FlareGroupMemberSnapshot, actions: FlareMemberActions? = every) =
        memberRoleActions(m, actions).map { it.action }

    @Test fun nothingTheHostDidNotAnswerForThisMember() {
        assertEquals(emptyList(), ids(member(FlareGroupMemberRole.Member), null))
        assertEquals(emptyList(), ids(member(FlareGroupMemberRole.Member), FlareMemberActions()))
    }

    @Test fun noRankRuleOfItsOwnWhatTheHostAllowsIsWhatTheSheetOffers() {
        // The owner's protection and admins not managing each other come from the host's answer.
        assertEquals(
            listOf(
                FlareMemberRoleAction.Demote, FlareMemberRoleAction.Mute,
                FlareMemberRoleAction.TransferOwner, FlareMemberRoleAction.Remove,
            ),
            ids(member(FlareGroupMemberRole.Admin)),
        )
        assertEquals(
            listOf(
                FlareMemberRoleAction.Promote, FlareMemberRoleAction.Mute,
                FlareMemberRoleAction.TransferOwner, FlareMemberRoleAction.Remove,
            ),
            ids(member(FlareGroupMemberRole.Member)),
        )
    }

    @Test fun promoteForMemberDemoteForAdminNeitherForTheOwner() {
        val role = FlareMemberActions(canChangeRole = true)
        assertEquals(listOf(FlareMemberRoleAction.Promote), ids(member(FlareGroupMemberRole.Member), role))
        assertEquals(listOf(FlareMemberRoleAction.Demote), ids(member(FlareGroupMemberRole.Admin), role))
        assertEquals(emptyList(), ids(member(FlareGroupMemberRole.Owner), role))
    }

    @Test fun muteAndUnmuteAreExclusive() {
        val mute = FlareMemberActions(canMute = true)
        assertEquals(listOf(FlareMemberRoleAction.Mute), ids(member(FlareGroupMemberRole.Member), mute))
        assertEquals(listOf(FlareMemberRoleAction.Unmute), ids(member(FlareGroupMemberRole.Member, muted = true), mute))
    }

    @Test fun eachAnswerRevealsExactlyItsAction() {
        assertEquals(listOf(FlareMemberRoleAction.Remove), ids(member(FlareGroupMemberRole.Member), FlareMemberActions(canRemove = true)))
        assertEquals(
            listOf(FlareMemberRoleAction.TransferOwner),
            ids(member(FlareGroupMemberRole.Member), FlareMemberActions(canTransferOwner = true)),
        )
    }

    @Test fun dangerGroupIsTransferThenRemoveAtTheEnd() {
        val entries = memberRoleActions(member(FlareGroupMemberRole.Member), every)
        assertEquals(
            listOf(FlareMemberRoleAction.TransferOwner, FlareMemberRoleAction.Remove),
            entries.filter { it.danger }.map { it.action },
        )
        assertEquals(FlareMemberRoleAction.Remove, entries.last().action)
        assertTrue(entries.last().danger)
    }

    @Test fun adminActionsUseTheirOwnGlyphsNotBorrowedOnes() {
        assertEquals(
            listOf("admin", "admin", "silence", "silence", "transfer-owner", "remove-member"),
            FlareMemberRoleAction.entries.map(::memberRoleIconName),
        )
        // Removal is not sign-out, ownership is not a favourite, unmute is not the notification bell.
        assertTrue(memberRoleIconName(FlareMemberRoleAction.Remove) != "logout")
        assertTrue(memberRoleIconName(FlareMemberRoleAction.TransferOwner) != "star")
        assertTrue(memberRoleIconName(FlareMemberRoleAction.Unmute) != "notification")
        for (action in FlareMemberRoleAction.entries) assertTrue(memberRoleIconName(action) in flareIconNames)
    }
}
