package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** A settings value longer than 16 characters goes under its label; toggles never stack. */
class SettingsRowTest {
    @Test fun aValueLongerThanSixteenCharactersStacks() {
        val announcement = "本周五下午三点在三楼会议室开例会，请大家准时参加"
        assertTrue(settingsRowStacked(SettingsItem("announcement", "群公告", kind = FlareSettingKind.Value, detail = announcement)))
        assertTrue(settingsRowStacked(SettingsItem("gateway", "网关", kind = FlareSettingKind.Navigation, detail = "ws://10.0.2.2:60051/ws")))
        // Exactly sixteen stays on one line, end-aligned.
        assertFalse(settingsRowStacked(SettingsItem("name", "群聊名称", kind = FlareSettingKind.Value, detail = "一二三四五六七八九十一二三四五六")))
        assertFalse(settingsRowStacked(SettingsItem("count", "群成员", kind = FlareSettingKind.Value, detail = "128")))
        assertFalse(settingsRowStacked(SettingsItem("empty", "昵称", kind = FlareSettingKind.Value)))
    }

    @Test fun charactersAreCountedAsCodePointsAndTogglesNeverStack() {
        // Sixteen emoji are thirty-two UTF-16 units but sixteen characters.
        assertFalse(settingsRowStacked(SettingsItem("mood", "心情", kind = FlareSettingKind.Value, detail = "😀".repeat(16))))
        assertTrue(settingsRowStacked(SettingsItem("mood", "心情", kind = FlareSettingKind.Value, detail = "😀".repeat(17))))
        assertFalse(settingsRowStacked(SettingsItem("mute", "消息免打扰", kind = FlareSettingKind.Toggle, detail = "开启后仍会收到提及你的消息通知提醒")))
    }

    @Test fun onlyARowThatOpensSomethingDrawsAChevron() {
        assertTrue(settingsRowHasChevron(FlareSettingKind.Navigation))
        // An action runs in place, a value is information, a toggle is a switch: none of them points anywhere.
        assertFalse(settingsRowHasChevron(FlareSettingKind.Action))
        assertFalse(settingsRowHasChevron(FlareSettingKind.Value))
        assertFalse(settingsRowHasChevron(FlareSettingKind.Toggle))
    }

    @Test fun anActionRowKeepsStackingAndTheDefaultKindStaysNavigation() {
        // The default kind did not change with the new one.
        assertEquals(FlareSettingKind.Navigation, SettingsItem("x", "标签").kind)
        // A long detail stacks under the label for an action too.
        assertTrue(settingsRowStacked(SettingsItem("clear", "清空聊天记录", kind = FlareSettingKind.Action, detail = "只清空本机上这个会话的聊天记录，其它设备不受影响")))
        assertFalse(settingsRowStacked(SettingsItem("logout", "退出登录", kind = FlareSettingKind.Action, danger = true)))
    }

    @Test fun aGroupSettingThatCouldNotBeReadIsAValueRowNotASwitch() {
        val labels = FlareGroupDetailLabels()
        val unreadable = FlareGroupDetailModel(groupId = "g1", name = "设计评审组", myMuted = null, myPinned = null)
        assertNull(unreadable.myMuted)
        assertNull(unreadable.myPinned)
        // The copy the row shows instead of a state it does not have.
        assertEquals("暂时无法读取", labels.settingUnavailable)
    }
}
