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
        joinPolicy = FLARE_GROUP_JOIN_APPROVAL,
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
        assertEquals(FLARE_GROUP_JOIN_APPROVAL, row(rows, FlareGroupPermissionKey.JoinPolicy).intValue)
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

    @Test fun unknownJoinPolicyPassesThrough() {
        val rows = groupPermissionRows(settings.copy(joinPolicy = 9), true)
        assertEquals(9, row(rows, FlareGroupPermissionKey.JoinPolicy).intValue)
        assertFalse(isGroupJoinPolicy(9))
        assertTrue(
            listOf(FLARE_GROUP_JOIN_INVITE, FLARE_GROUP_JOIN_APPROVAL, FLARE_GROUP_JOIN_OPEN)
                .all { isGroupJoinPolicy(it) },
        )
    }

    @Test fun wireKeysMatchTheCrossPlatformContract() {
        assertEquals(
            listOf("joinPolicy", "muteAll", "onlyAdminCanAtAll", "onlyAdminCanPin", "shareCardPermission"),
            FlareGroupPermissionKey.entries.map { it.wire },
        )
        assertNull(groupPermissionRows(settings, true).first { it.key == FlareGroupPermissionKey.JoinPolicy }.error)
    }
}
