package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * FR-097: the emoji and sticker panel belonged to every app instead of the composer. The composer owns
 * it when the host does not, and a host that handles the key still gets its own.
 */
class ComposerEmojiPanelInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()

    @Test fun theComposerOpensItsOwnPanel() {
        compose.setContent { MaterialTheme { Composer(onSend = {}) } }

        // The key reports the composer's own panel state: closed, then open, then closed again.
        compose.onNodeWithContentDescription(strings.composerEmoji).assertIsOff().performClick()
        compose.waitForIdle()
        compose.onNodeWithContentDescription(strings.composerEmoji).assertIsOn().performClick()
        compose.waitForIdle()
        compose.onNodeWithContentDescription(strings.composerEmoji).assertIsOff()
    }

    @Test fun aHostThatHandlesTheKeyKeepsItsOwnPanel() {
        var pressed = 0
        compose.setContent { MaterialTheme { Composer(onSend = {}, onEmoji = { pressed++ }) } }

        compose.onNodeWithContentDescription(strings.composerEmoji).assertHasClickAction().performClick()
        compose.waitForIdle()
        assertEquals(1, pressed)
        // The composer's own panel never opened — the key carries no open state at all, the host's panel does.
        compose.onNodeWithContentDescription(strings.composerEmoji)
            .assert(SemanticsMatcher.keyNotDefined(SemanticsProperties.ToggleableState))
    }
}
