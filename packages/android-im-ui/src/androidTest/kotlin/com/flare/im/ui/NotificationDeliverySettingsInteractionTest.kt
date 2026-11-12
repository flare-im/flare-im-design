package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.isDialog
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * The section form of NotificationDeliverySettings as a settings page uses it: the group sits in the host's own
 * SettingsList, its rows run the kit's actions and the guide, the host's rows stay the host's, and a maker's page
 * the host did not name reads the kit's auto-start label.
 */
class NotificationDeliverySettingsInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()

    @Test fun theGroupJoinsTheHostsListAndRunsItsOwnRows() {
        val log = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            NotificationDeliverySettings(
                status = FlareNotificationStatus.Off,
                background = FlareBackgroundDelivery.Restricted,
                vendorActions = listOf(FlareNotificationGuideAction { log += "autoStart" }),
                onStatusAction = { log += "status" },
                onOpenBatterySettings = { log += "battery" },
            ) { notifications, select ->
                SettingsList(
                    sections = listOf(SettingsSection(items = listOf(SettingsItem("language", "语言"))), notifications),
                    onSelect = { if (!select(it)) log += it.key },
                    scrollable = false,
                )
            }
        } }
        compose.onNodeWithText("语言").performClick()
        compose.onNodeWithText(strings.notificationDeliveryNewMessages).performClick()
        compose.runOnIdle { assertEquals(listOf("language", "status"), log) }

        compose.onNodeWithText(strings.backgroundDeliveryLabel).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertExists()
        compose.onNodeWithText(strings.backgroundDeliveryAutoStart).performClick()
        compose.onNodeWithText(strings.backgroundDeliveryBattery).performClick()
        compose.runOnIdle { assertEquals(listOf("language", "status", "autoStart", "battery"), log) }
    }

    /** Android's resident connection switch: the host's onToggle hands it to select, which flips it; the battery row follows. */
    @Test fun theResidentSwitchFlipsThroughSelectAndBringsTheBatteryRow() {
        val changes = mutableListOf<Boolean>()
        val log = mutableListOf<String>()
        var resident by mutableStateOf(false)
        compose.setContent { MaterialTheme {
            NotificationDeliverySettings(
                status = FlareNotificationStatus.On,
                background = FlareBackgroundDelivery.Optimized,
                onOpenBatterySettings = { log += "battery" },
                residentMode = resident,
                onResidentModeChange = { on -> changes += on; resident = on },
            ) { notifications, select ->
                SettingsList(
                    sections = listOf(notifications),
                    onToggle = { item, _ -> if (!select(item)) log += item.key },
                    onSelect = { if (!select(it)) log += it.key },
                    scrollable = false,
                )
            }
        } }
        compose.onNodeWithText(strings.residentConnectionDescription).assertExists()
        compose.onNodeWithText(strings.residentConnectionBattery).assertDoesNotExist()

        compose.onNodeWithText(strings.residentConnectionLabel).performClick()
        compose.runOnIdle { assertEquals(listOf(true), changes) }
        compose.onNodeWithText(strings.residentConnectionBattery).performClick()
        compose.runOnIdle { assertEquals(listOf("battery"), log) }

        compose.onNodeWithText(strings.residentConnectionLabel).performClick()
        compose.runOnIdle { assertEquals(listOf(true, false), changes) }
        compose.onNodeWithText(strings.residentConnectionBattery).assertDoesNotExist()
    }
}
