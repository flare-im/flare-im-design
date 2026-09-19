package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class GroupPermissionMatrixTest {
    private val settings = FlareGroupPermissionSettings(
        muteAll = false,
        onlyAdminCanAtAll = true,
        onlyAdminCanPin = false,
        shareCardPermission = true,
        joinPolicy = FlareGroupJoinPolicy.Approval,
    )

    private fun row(rows: List<FlareGroupPermissionRow>, key: FlareGroupPermissionKey) =
        rows.first { it.key == key }

    @Test fun canonicalOrderOfRealBackendKeys() {
        assertEquals(
            listOf(
                FlareGroupPermissionKey.JoinPolicy,
                FlareGroupPermissionKey.MuteAll,
                FlareGroupPermissionKey.OnlyAdminCanAtAll,
                FlareGroupPermissionKey.OnlyAdminCanPin,
                FlareGroupPermissionKey.ShareCardPermission,
            ),
            groupPermissionRows(settings, true).map { it.key },
        )
    }

    @Test fun joinPolicyIsTheOnlyChoiceRowAndValuesCarryThrough() {
        val rows = groupPermissionRows(settings, true)
        assertEquals(
            listOf(FlareGroupPermissionKey.JoinPolicy),
            rows.filter { it.kind == FlareGroupPermissionRowKind.Choice }.map { it.key },
        )
        assertEquals(FlareGroupJoinPolicy.Approval, row(rows, FlareGroupPermissionKey.JoinPolicy).joinPolicyValue)
        assertFalse(row(rows, FlareGroupPermissionKey.MuteAll).boolValue)
        assertTrue(row(rows, FlareGroupPermissionKey.OnlyAdminCanAtAll).boolValue)
        assertTrue(row(rows, FlareGroupPermissionKey.ShareCardPermission).boolValue)
    }

    @Test fun editableFollowsCanManageOnly() {
        assertTrue(groupPermissionRows(settings, false).none { it.editable })
        assertTrue(
            groupPermissionRows(settings, true, listOf("muteAll"), mapOf("muteAll" to "网络错误"))
                .all { it.editable },
        )
    }

    @Test fun busyAndErrorArePerKey() {
        val rows = groupPermissionRows(settings, true, listOf("muteAll"), mapOf("onlyAdminCanPin" to "权限不足"))
        assertEquals(listOf(FlareGroupPermissionKey.MuteAll), rows.filter { it.busy }.map { it.key })
        assertEquals(
            listOf(FlareGroupPermissionKey.OnlyAdminCanPin),
            rows.filter { it.error != null }.map { it.key },
        )
        assertEquals("权限不足", row(rows, FlareGroupPermissionKey.OnlyAdminCanPin).error)
    }

    @Test fun ignoresUnknownBusyKeysAndEmptyInputs() {
        val rows = groupPermissionRows(settings, true, listOf("nope", "muteAll", "muteAll"))
        assertEquals(listOf(FlareGroupPermissionKey.MuteAll), rows.filter { it.busy }.map { it.key })
        assertTrue(groupPermissionRows(settings, true).all { !it.busy && it.error == null })
    }

    @Test fun keepsErrorVisibleOnReadOnlyPanel() {
        val row = row(
            groupPermissionRows(settings, false, emptyList(), mapOf("muteAll" to "你已不是管理员")),
            FlareGroupPermissionKey.MuteAll,
        )
        assertFalse(row.editable)
        assertEquals("你已不是管理员", row.error)
    }

    @Test fun anUnknownJoinPolicyStaysUnknownAndIsNeverGuessed() {
        val join = row(groupPermissionRows(settings.copy(joinPolicy = null), true), FlareGroupPermissionKey.JoinPolicy)
        assertEquals(FlareGroupPermissionRowKind.Choice, join.kind)
        assertNull(join.value)
        assertNull(join.joinPolicyValue)
        assertNull(FlareGroupPermissionSettings().joinPolicy)
    }

    @Test fun eachJoinPolicyPassesThroughAndChoicesReadOpenApprovalInvite() {
        assertEquals(
            listOf(FlareGroupJoinPolicy.Open, FlareGroupJoinPolicy.Approval, FlareGroupJoinPolicy.Invite),
            FlareGroupJoinPolicy.entries,
        )
        for (policy in FlareGroupJoinPolicy.entries) {
            val join = row(groupPermissionRows(settings.copy(joinPolicy = policy), false), FlareGroupPermissionKey.JoinPolicy)
            assertEquals(policy, join.joinPolicyValue)
            assertFalse(join.boolValue)
        }
        // A toggle row carries no policy.
        assertNull(row(groupPermissionRows(settings, true), FlareGroupPermissionKey.MuteAll).joinPolicyValue)
    }

    @Test fun wireKeysMatchTheCrossPlatformContract() {
        assertEquals(
            listOf("joinPolicy", "muteAll", "onlyAdminCanAtAll", "onlyAdminCanPin", "shareCardPermission"),
            FlareGroupPermissionKey.entries.map { it.wire },
        )
        assertNull(groupPermissionRows(settings, true).first { it.key == FlareGroupPermissionKey.JoinPolicy }.error)
    }

    @Test fun muteAllIsSilenceAndEveryRowDrawsARegistryGlyph() {
        assertEquals(
            listOf("lock", "silence", "mention", "pin", "share"),
            FlareGroupPermissionKey.entries.map(::groupPermissionIconName),
        )
        for (key in FlareGroupPermissionKey.entries) assertTrue(groupPermissionIconName(key) in flareIconNames)
    }
}
