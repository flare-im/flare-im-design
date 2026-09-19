package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test

/**
 * FR-045: the masked field owns its unmask key. The key is named by the kit, says whether the value is
 * showing, and unmasks the value for real — before it is pressed the field draws dots, not the password.
 */
class InputRevealInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()

    @Test fun theKeyUnmasksTheValueAndRenamesItself() {
        compose.setContent {
            MaterialTheme {
                var value by remember { mutableStateOf("hunter2") }
                Input(value = value, onValueChange = { value = it }, secure = true, revealable = true)
            }
        }

        compose.onNodeWithText("hunter2").assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.inputReveal).assertIsOff().performClick()
        compose.waitForIdle()

        compose.onNodeWithText("hunter2").assertExists()
        compose.onNodeWithContentDescription(strings.inputHide).assertIsOn().performClick()
        compose.waitForIdle()

        compose.onNodeWithText("hunter2").assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.inputReveal).assertIsOff()
    }
}
