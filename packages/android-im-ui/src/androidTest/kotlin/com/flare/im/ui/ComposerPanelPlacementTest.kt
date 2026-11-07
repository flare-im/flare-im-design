package com.flare.im.ui

import android.content.res.Configuration
import android.provider.Settings
import android.view.View
import android.widget.EditText
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotFocused
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.click
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.Density
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalTestApi::class)
class ComposerPanelPlacementTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()
    private val member = MentionCandidate("member-1", "Aster")
    private val otherMember = MentionCandidate("member-2", "Blossom")
    private val action = FlareComposerAction("test-attachment", label = "Test attachment", icon = "file")

    @Test fun phonePanelsStayBelowTheEditorAndToolsAndAreMutuallyExclusive() {
        compose.setContent { MaterialTheme { subject() } }
        val editor = compose.onNode(hasSetTextAction(), useUnmergedTree = true)
        val emoji = compose.onNodeWithContentDescription(strings.composerEmoji)
        val mention = compose.onNodeWithContentDescription(strings.composerMention)
        val more = compose.onNodeWithContentDescription(strings.composerMore)
        val picker = compose.onNode(hasText(strings.emojiStickerPickerEmoji) or hasContentDescription(strings.emojiStickerPickerLoading))
        val candidate = compose.onNodeWithText(member.name)
        val tile = compose.onNodeWithText(action.label!!)

        editor.performSemanticsAction(SemanticsActions.RequestFocus).assertIsFocused()
        emoji.performClick()
        editor.assertIsNotFocused()
        emoji.assertIsOn()
        assertBelow(editor, emoji)
        assertBelow(emoji, picker)

        mention.performClick()
        emoji.assertIsOff()
        picker.assertDoesNotExist()
        mention.assertIsOn()
        assertBelow(mention, candidate)
        compose.onNodeWithContentDescription(strings.searchMembers).assertIsNotFocused()

        more.performClick()
        mention.assertIsOff()
        candidate.assertDoesNotExist()
        more.assertIsOn()
        assertBelow(editor, more)
        assertBelow(more, tile)

        editor.performSemanticsAction(SemanticsActions.RequestFocus).assertIsFocused()
        more.assertIsOff()
        tile.assertDoesNotExist()
    }

    @Test fun typedAtFiltersFromTheEditorAndReplacesTheCompleteTokenWhenPicked() {
        val roster = mutableStateOf(listOf(member, otherMember))
        lateinit var host: View
        compose.setContent {
            host = LocalView.current
            MaterialTheme { subject(roster.value) }
        }
        val editor = compose.onNode(hasSetTextAction(), useUnmergedTree = true)
        editor.performSemanticsAction(SemanticsActions.RequestFocus)
        typeInNativeEditor(host, "@")
        compose.onNode(hasSetTextAction() and hasText("@"), useUnmergedTree = true).assertIsFocused()
        compose.onNodeWithContentDescription(strings.searchMembers).assertDoesNotExist()
        compose.onNodeWithText(otherMember.name).assertExists()
        typeInNativeEditor(host, "As")
        compose.onNode(hasSetTextAction() and hasText("@As"), useUnmergedTree = true).assertIsFocused()
        compose.onNodeWithText(otherMember.name).assertDoesNotExist()
        val candidate = compose.onNodeWithText(member.name)
        val stalePick = requireNotNull(candidate.fetchSemanticsNode().config[SemanticsActions.OnClick].action)
        compose.runOnIdle { roster.value = listOf(otherMember) }
        candidate.assertDoesNotExist()
        compose.runOnIdle { stalePick() }
        compose.onNode(hasSetTextAction() and hasText("@As"), useUnmergedTree = true).assertIsFocused()
        compose.runOnIdle { roster.value = listOf(member, otherMember) }
        candidate.performClick()
        compose.onNode(hasSetTextAction() and hasText("@Aster "), useUnmergedTree = true)
            .assertIsFocused()
        typeInNativeEditor(host, "hello")
        compose.onNode(hasSetTextAction() and hasText("@Aster hello"), useUnmergedTree = true).assertIsFocused()
        compose.onNodeWithText(member.name).assertDoesNotExist()
    }

    @Test fun wideAndroidComposerKeepsTheActivePanelBelowTheEditorAndTools() {
        compose.setContent {
            val density = LocalDensity.current
            // Use the device's viewport as a wide logical layout without requiring a tablet emulator.
            CompositionLocalProvider(LocalDensity provides Density(density.density / 2, density.fontScale)) {
                MaterialTheme { subject() }
            }
        }
        val more = compose.onNodeWithContentDescription(strings.composerMore)
        more.performClick()
        val tile = compose.onNodeWithText(action.label!!)
        val editor = compose.onNode(hasSetTextAction(), useUnmergedTree = true)
        assertBelow(editor, more)
        assertBelow(more, tile)
    }

    @Test fun tappingAToolReplacesTheImeWhileATypedMentionLeavesItOpen() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        assumeTrue(
            context.resources.configuration.keyboard == Configuration.KEYBOARD_NOKEYS ||
                Settings.Secure.getInt(context.contentResolver, "show_ime_with_hard_keyboard", 0) == 1,
        )
        lateinit var host: View
        compose.setContent {
            host = LocalView.current
            MaterialTheme { subject() }
        }
        fun imeVisible() = ViewCompat.getRootWindowInsets(host)?.isVisible(WindowInsetsCompat.Type.ime()) == true
        val editor = compose.onNode(hasSetTextAction(), useUnmergedTree = true)

        editor.performTouchInput { click() }
        // A cold system keyboard may start slowly on a shared emulator.
        compose.waitUntil(timeoutMillis = 30_000) { imeVisible() }
        typeInNativeEditor(host, "@")
        typeInNativeEditor(host, "As")
        compose.onNodeWithText(member.name).assertExists()
        compose.onNode(hasSetTextAction() and hasText("@As"), useUnmergedTree = true).assertIsFocused()
        assertTrue(imeVisible())

        compose.onNodeWithContentDescription(strings.composerEmoji).performClick().assertIsOn()
        compose.waitUntil(timeoutMillis = 10_000) { !imeVisible() }
    }

    @Composable
    private fun subject(roster: List<MentionCandidate> = listOf(member, otherMember)) = Composer(
        onSend = {},
        mentionCandidates = roster,
        actions = listOf(action),
        onAction = {},
    )

    /** Apply an editor commit so Android's TextWatcher and real selection drive the composer. */
    private fun typeInNativeEditor(host: View, text: String) {
        compose.runOnIdle {
            val editor = host.findFocus() as EditText
            val caret = editor.selectionStart
            editor.text.insert(caret, text)
            editor.setSelection(caret + text.length)
        }
    }

    private fun assertBelow(above: SemanticsNodeInteraction, below: SemanticsNodeInteraction) {
        assertTrue(below.fetchSemanticsNode().boundsInRoot.top >= above.fetchSemanticsNode().boundsInRoot.bottom)
    }
}
