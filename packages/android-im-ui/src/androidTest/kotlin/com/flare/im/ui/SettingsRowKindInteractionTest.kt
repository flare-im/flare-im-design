package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertHasNoClickAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.SemanticsMatcher
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * Settings row kinds on the device (FR-084 / X23): read-only information is not a button, an in-place action
 * is a button without a chevron, and a navigation row still opens something.
 */
class SettingsRowKindInteractionTest {
    @get:Rule val compose = createComposeRule()

    private fun hasRole(role: androidx.compose.ui.semantics.Role) =
        SemanticsMatcher.expectValue(SemanticsProperties.Role, role)

    @Test fun aValueRowIsNotAControlAndIgnoresTaps() {
        val selected = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            SettingsList(
                sections = listOf(SettingsSection(items = listOf(
                    SettingsItem("flareId", "Flare ID", kind = FlareSettingKind.Value, detail = "alice"),
                    SettingsItem("devices", "多设备登录", kind = FlareSettingKind.Navigation),
                ))),
                onSelect = { selected += it.key },
            )
        } }
        compose.onNodeWithText("Flare ID").assertHasNoClickAction()
        compose.onNodeWithText("Flare ID").performClick()
        compose.onNodeWithText("多设备登录").assertHasClickAction().assert(hasRole(androidx.compose.ui.semantics.Role.Button))
        compose.onNodeWithText("多设备登录").performClick()
        // Only the navigation row acted; the value row swallowed its tap.
        compose.runOnIdle { assertEquals(listOf("devices"), selected) }
    }

    @Test fun anActionRowIsAButtonThatRunsInPlace() {
        val selected = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            SettingsList(
                sections = listOf(SettingsSection(items = listOf(
                    SettingsItem("logout", "退出登录", kind = FlareSettingKind.Action, danger = true),
                ))),
                onSelect = { selected += it.key },
            )
        } }
        compose.onNodeWithText("退出登录").assertHasClickAction().assert(hasRole(androidx.compose.ui.semantics.Role.Button))
        compose.onNodeWithText("退出登录").performClick()
        compose.runOnIdle { assertEquals(listOf("logout"), selected) }
    }

    @Test fun aLongValueStillStacksUnderItsLabel() {
        val announcement = "本周五下午三点在三楼会议室开例会，请大家准时参加"
        compose.setContent { MaterialTheme {
            SettingsList(
                sections = listOf(SettingsSection(items = listOf(
                    SettingsItem("announcement", "群公告", kind = FlareSettingKind.Value, detail = announcement),
                ))),
            )
        } }
        // Both the label and the whole value are on screen: the value is not truncated to one end-aligned line.
        compose.onNodeWithText("群公告").assertExists()
        compose.onNodeWithText(announcement).assertExists()
        assertTrue(settingsRowStacked(SettingsItem("announcement", "群公告", kind = FlareSettingKind.Value, detail = announcement)))
    }

    @Test fun anUnknownIconNameRendersTheFallbackInsteadOfCrashing() {
        compose.setContent { MaterialTheme {
            SettingsList(
                sections = listOf(SettingsSection(items = listOf(
                    SettingsItem("mystery", "未知图标", icon = "not-a-registry-name", kind = FlareSettingKind.Navigation),
                ))),
            )
        } }
        // The row still renders, and the name is never drawn as text.
        compose.onNodeWithText("未知图标").assertExists()
        compose.onNodeWithText("not-a-registry-name").assertDoesNotExist()
    }
}
