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
 * NotificationAlertSettings while the host starts saving: `disabled` stops the rows, and a picker already open stays
 * open and still reports its pick through onChange.
 */
class NotificationAlertSettingsInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()
    private val changes = mutableListOf<FlareNotificationAlertPreferences>()

    private fun show(value: FlareNotificationAlertPreferences): (Boolean) -> Unit {
        var disabled by mutableStateOf(false)
        compose.setContent { MaterialTheme {
            NotificationAlertSettings(value = value, disabled = disabled, onChange = { changes += it })
        } }
        return { disabled = it }
    }

    @Test fun aChoiceSheetAlreadyOpenAppliesItsPickWhileDisabled() {
        val disable = show(FlareNotificationAlertPreferences())
        compose.onNodeWithText(strings.notificationPreviewLabel).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertExists()

        compose.runOnIdle { disable(true) }
        compose.onNode(isDialog()).assertExists()
        compose.onNodeWithText(strings.notificationPreviewHidden).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        compose.runOnIdle { assertEquals(listOf(FlareNotificationPreview.Hidden), changes.map { it.preview }) }

        // The rows themselves take no input.
        compose.onNodeWithText(strings.multiDeviceLabel).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
    }

    @Test fun theRepeatSheetAlreadyOpenKeepsItsSwitchesWhileDisabled() {
        val disable = show(FlareNotificationAlertPreferences(quietHours = FlareQuietHours(enabled = true)))
        compose.onNodeWithText(strings.quietHoursRepeat).performClick()
        compose.waitForIdle()

        compose.runOnIdle { disable(true) }
        compose.onNode(isDialog()).assertExists()
        compose.onNodeWithText(strings.weekdaySunday).performClick()
        compose.runOnIdle { assertEquals(listOf(0x3f), changes.map { it.quietHours.weekdays }) }
        compose.onNode(isDialog()).assertExists()
    }
}
