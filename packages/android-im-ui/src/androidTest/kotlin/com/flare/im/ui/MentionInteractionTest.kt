package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.pressKey
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** The mention picker as a combobox, and the composer opening it for "@" and writing the pick. */
@OptIn(ExperimentalTestApi::class)
class MentionInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()
    private val candidates = listOf(
        MentionCandidate("u_xu", "徐知远"),
        MentionCandidate("u_chen", "陈默"),
        MentionCandidate("u_chenxi", "陈曦"),
    )

    private fun showPicker(onSelect: (MentionCandidate) -> Unit, onClose: () -> Unit = {}) {
        compose.setContent { MaterialTheme { MentionPicker(candidates, allowEveryone = true, onSelect = onSelect, onClose = onClose, autofocus = true) } }
        compose.waitForIdle()
    }

    @Test fun enterPicksTheFirstMatchWhileFocusStaysInTheSearchField() {
        var picked: MentionCandidate? = null
        showPicker(onSelect = { picked = it })
        val search = compose.onNodeWithContentDescription(strings.searchMembers)
        search.assertIsFocused().performTextInput("陈")
        // The row is one node to a screen reader — its name and whether it is the highlighted one read together.
        compose.onNode(hasText("陈默") and SemanticsMatcher.expectValue(SemanticsProperties.Selected, true)).assertExists()
        search.assertIsFocused().performKeyInput { pressKey(Key.Enter) }
        assertEquals("u_chen", picked?.id)
    }

    @Test fun theArrowsMoveTheHighlightAndWrap() {
        var picked: MentionCandidate? = null
        showPicker(onSelect = { picked = it })
        val search = compose.onNodeWithContentDescription(strings.searchMembers)
        search.performTextInput("陈")
        search.performKeyInput { pressKey(Key.DirectionDown); pressKey(Key.DirectionDown); pressKey(Key.DirectionUp) }
        search.performKeyInput { pressKey(Key.Enter) }
        assertEquals("u_chenxi", picked?.id)
    }

    @Test fun escapeCloses() {
        var closes = 0
        showPicker(onSelect = {}, onClose = { closes++ })
        compose.onNodeWithContentDescription(strings.searchMembers).performKeyInput { pressKey(Key.Escape) }
        assertEquals(1, closes)
    }

    @Test fun typingAtInTheComposerOpensThePickerAndThePickIsWrittenAsTheLabel() {
        var text = ""
        var sent: String? = null
        compose.setContent { MaterialTheme {
            var value by remember { mutableStateOf("") }
            Composer(
                value = value,
                onValueChange = { value = it; text = it },
                onSend = { sent = it },
                mentionCandidates = candidates,
                mentionEveryone = true,
            )
        } }
        compose.onNode(hasSetTextAction()).performTextInput("@")
        compose.waitForIdle()
        compose.onNodeWithContentDescription(strings.searchMembers).assertIsFocused()
        compose.onNodeWithText("陈默").performClick()
        compose.waitForIdle()
        assertEquals("@陈默 ", text)
        // The send carries the text only; the core resolves the mention from it.
        compose.onNodeWithContentDescription(strings.send).performClick()
        assertEquals("@陈默", sent)
    }
}
