package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * `onUserInput` means "the person edited the text", not "the text changed" — the difference [onValueChange]
 * does not draw. It is invisible until a host drives a typing signal ([FlareTypingSignal]) from it: the
 * composer's own clear after a send would then read as someone typing, and so would every text the host
 * puts back, such as the original of a send that failed.
 */
@OptIn(ExperimentalTestApi::class)
class ComposerUserInputInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()

    @Test fun theClearAfterASendIsNotAnEditByThePerson() {
        val edits = mutableListOf<String>()
        val changes = mutableListOf<String>()
        compose.setContent {
            MaterialTheme {
                Composer(onValueChange = changes::add, onUserInput = edits::add, onSend = {})
            }
        }
        compose.onNode(hasSetTextAction()).performTextInput("hello")
        compose.waitForIdle()
        assertEquals(listOf("hello"), edits)

        compose.onNodeWithContentDescription(strings.send).performClick()
        compose.waitForIdle()
        // Both saw the clear; only one of them called it an edit.
        assertEquals(listOf("hello", ""), changes)
        assertEquals(listOf("hello"), edits)
    }
}
