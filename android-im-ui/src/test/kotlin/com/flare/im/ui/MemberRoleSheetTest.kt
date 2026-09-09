package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MemberRoleSheetTest {
    private val all = FlareMemberRoleCapabilities(
        promote = true, demote = true, mute = true, unmute = true, remove = true, transferOwner = true,
    )

    private fun member(role: FlareGroupMemberRole, muted: Boolean = false) =
        FlareGroupMemberSnapshot(id = "u-$role", name = role.name, role = role, muted = muted)

    private fun ids(
        m: FlareGroupMemberSnapshot,
        viewer: FlareGroupMemberRole,
        caps: FlareMemberRoleCapabilities = all,
    ) = memberRoleActions(m, viewer, caps).map { it.action }

    @Test fun ownerIsUntouchableForEveryViewer() {
        FlareGroupMemberRole.entries.forEach { viewer ->
            assertEquals(emptyList(), ids(member(FlareGroupMemberRole.Owner), viewer))
            assertEquals(emptyList(), ids(member(FlareGroupMemberRole.Owner, muted = true), viewer))
        }
    }

    @Test fun plainMemberSeesNothing() {
        assertEquals(emptyList(), ids(member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Member))
        assertEquals(emptyList(), ids(member(FlareGroupMemberRole.Admin), FlareGroupMemberRole.Member))
    }

    @Test fun adminStopsAtPeerAdminAndCannotTransfer() {
        assertEquals(emptyList(), ids(member(FlareGroupMemberRole.Admin), FlareGroupMemberRole.Admin))
        assertEquals(
            listOf(FlareMemberRoleAction.Promote, FlareMemberRoleAction.Mute, FlareMemberRoleAction.Remove),
            ids(member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Admin),
        )
        assertFalse(
            ids(member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Admin)
                .contains(FlareMemberRoleAction.TransferOwner),
        )
    }

    @Test fun ownerManagesMembersAndAdmins() {
        assertEquals(
            listOf(
                FlareMemberRoleAction.Promote, FlareMemberRoleAction.Mute,
                FlareMemberRoleAction.TransferOwner, FlareMemberRoleAction.Remove,
            ),
            ids(member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Owner),
        )
        assertEquals(
            listOf(
                FlareMemberRoleAction.Demote, FlareMemberRoleAction.Mute,
                FlareMemberRoleAction.TransferOwner, FlareMemberRoleAction.Remove,
            ),
            ids(member(FlareGroupMemberRole.Admin), FlareGroupMemberRole.Owner),
        )
    }

    @Test fun promoteForMemberDemoteForAdmin() {
        val caps = FlareMemberRoleCapabilities(promote = true, demote = true)
        assertEquals(
            listOf(FlareMemberRoleAction.Promote),
            ids(member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Owner, caps),
        )
        assertEquals(
            listOf(FlareMemberRoleAction.Demote),
            ids(member(FlareGroupMemberRole.Admin), FlareGroupMemberRole.Owner, caps),
        )
    }

    @Test fun muteAndUnmuteAreExclusive() {
        val caps = FlareMemberRoleCapabilities(mute = true, unmute = true)
        assertEquals(
            listOf(FlareMemberRoleAction.Mute),
            ids(member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Owner, caps),
        )
        assertEquals(
            listOf(FlareMemberRoleAction.Unmute),
            ids(member(FlareGroupMemberRole.Member, muted = true), FlareGroupMemberRole.Owner, caps),
        )
    }

    @Test fun nothingWithoutCapabilities() {
        assertEquals(
            emptyList(),
            ids(member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Owner, FlareMemberRoleCapabilities()),
        )
        assertEquals(
            listOf(FlareMemberRoleAction.Remove),
            ids(
                member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Owner,
                FlareMemberRoleCapabilities(remove = true),
            ),
        )
        assertEquals(
            listOf(FlareMemberRoleAction.TransferOwner),
            ids(
                member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Owner,
                FlareMemberRoleCapabilities(transferOwner = true),
            ),
        )
    }

    @Test fun dangerGroupIsTransferThenRemoveAtTheEnd() {
        val entries = memberRoleActions(member(FlareGroupMemberRole.Member), FlareGroupMemberRole.Owner, all)
        assertEquals(
            listOf(FlareMemberRoleAction.TransferOwner, FlareMemberRoleAction.Remove),
            entries.filter { it.danger }.map { it.action },
        )
        assertEquals(FlareMemberRoleAction.Remove, entries.last().action)
        assertTrue(entries.last().danger)
    }
}
