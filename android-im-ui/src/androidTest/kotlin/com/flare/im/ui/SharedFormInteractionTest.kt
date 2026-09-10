package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** Runs on an Android emulator; local state only, no account or SDK mutations. */
class SharedFormInteractionTest {
    @get:Rule val compose = createComposeRule()

    @Test fun formValidationAndBusyActions() {
        val text = mutableStateOf("")
        val busy = mutableStateOf(false)
        var confirmed = 0
        var dismissed = 0
        compose.setContent { MaterialTheme {
            FormDialog(title = "Edit note", confirmLabel = "Save", cancelLabel = "Cancel",
                onDismiss = { dismissed++ }, onConfirm = { confirmed++ },
                confirmEnabled = text.value.isNotBlank(), busy = busy.value) {
                Input(value = text.value, onValueChange = { text.value = it }, placeholder = "Note")
            }
        } }
        compose.onNodeWithText("Save").assertIsNotEnabled()
        compose.onNode(hasSetTextAction()).performTextInput("A local preview")
        compose.onNodeWithText("Save").assertIsEnabled().performClick()
        compose.runOnIdle { assertEquals(1, confirmed); busy.value = true }
        compose.onNodeWithText("Cancel").assertIsNotEnabled()
        compose.onNodeWithText("Save").assertIsNotEnabled()
        compose.runOnIdle { busy.value = false }
        compose.onNodeWithText("Cancel").performClick()
        compose.runOnIdle { assertEquals(1, dismissed) }
    }

    @Test fun settingsWholeRowTogglesAndDisabledBlocks() {
        val enabled = mutableStateOf(true)
        val value = mutableStateOf(false)
        var calls = 0
        compose.setContent { MaterialTheme {
            SettingsRow(SettingsItem("mute", "Mute", kind = FlareSettingKind.Toggle,
                value = value.value, disabled = !enabled.value),
                onToggle = { _, next -> value.value = next; calls++ })
        } }
        compose.onNodeWithText("Mute").performClick()
        compose.onNodeWithText("Mute").assertIsOn()
        compose.runOnIdle { assertEquals(1, calls); enabled.value = false }
        compose.onNodeWithText("Mute").assertIsNotEnabled()
    }
}
