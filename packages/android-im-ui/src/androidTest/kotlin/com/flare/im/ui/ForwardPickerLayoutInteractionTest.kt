package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsNotDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * The picker under the heights its hosts give it. A sheet or modal caps it at a share of the window (less on a
 * small phone, in landscape, or with the keyboard up), and the Send footer must survive every cap: the list is
 * the part that yields.
 */
class ForwardPickerLayoutInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()
    private val targets = (1..10).map { ForwardTarget(id = "t$it", name = "会话 $it") }

    private fun heightDp(text: String): Dp = with(compose.density) {
        compose.onNodeWithText(text).fetchSemanticsNode().boundsInRoot.height.toDp()
    }

    private fun bottomDp(text: String): Dp = with(compose.density) {
        compose.onNodeWithText(text).fetchSemanticsNode().boundsInRoot.bottom.toDp()
    }

    private fun host(height: Dp, content: @Composable () -> Unit) {
        compose.setContent { MaterialTheme { Box(Modifier.width(400.dp).height(height)) { content() } } }
    }

    @Test fun aShortBoundedHostKeepsSendOnScreenAndTappable() {
        var confirmed: List<String>? = null
        host(300.dp) { ForwardPicker(targets = targets, onConfirm = { confirmed = it }) }

        compose.onNodeWithText(strings.send).assertIsDisplayed()
        assertTrue("Send has no height under a 300 dp host", heightDp(strings.send) > 0.dp)
        assertTrue("the picker overflows its 300 dp host", bottomDp(strings.send) <= 300.dp)

        compose.onNodeWithText("会话 1").performClick()
        compose.onNodeWithText(strings.send).performClick()
        compose.runOnIdle { assertEquals(listOf("t1"), confirmed) }
    }

    @Test fun aTallHostStillCapsTheListAt300AndDoesNotStretch() {
        host(640.dp) { ForwardPicker(targets = targets) }

        compose.onNodeWithText(strings.send).assertIsDisplayed()
        assertTrue(heightDp(strings.send) > 0.dp)
        // Header + search + a 300 dp list + footer is well under 640: the list wraps, it does not fill the host.
        assertTrue("the list stretched to the host", bottomDp(strings.send) < 520.dp)
        // Ten rows of 52 dp do not fit the 300 dp list, so the last one is scrolled out of view.
        compose.onNodeWithText("会话 1").assertIsDisplayed()
        compose.onNodeWithText("会话 10").assertIsNotDisplayed()
    }

    @Test fun anUnboundedHostKeepsTheListRatherThanCollapsingIt() {
        host(640.dp) {
            Column(Modifier.verticalScroll(rememberScrollState())) { ForwardPicker(targets = targets) }
        }

        compose.onNodeWithText("会话 1").assertIsDisplayed()
        assertTrue("the list collapsed under an unbounded host", heightDp("会话 1") > 0.dp)
        compose.onNodeWithText(strings.send).assertIsDisplayed()
    }

    @Test fun onAnOverlayThePickerDropsItsCardAndCloseControl() {
        host(300.dp) {
            CompositionLocalProvider(LocalFlareOverlaySurface provides FlareOverlaySurfaceKind.Sheet) {
                ForwardPicker(targets = targets, onClose = {})
            }
        }
        compose.onNodeWithContentDescription(strings.close).assertDoesNotExist()
        compose.onNodeWithText(strings.send).assertIsDisplayed()
        // The overlay supplies the surface, so the picker spans the 400 dp host instead of sitting in a 340 dp
        // card: the end-aligned Send reaches past where the card would have ended.
        val sendEnd = with(compose.density) {
            compose.onNodeWithText(strings.send).fetchSemanticsNode().boundsInRoot.right.toDp()
        }
        assertTrue("the picker kept its 340 dp card on an overlay", sendEnd > 340.dp)
    }

    @Test fun standaloneThePickerKeepsItsCloseControl() {
        var closed = false
        host(640.dp) { ForwardPicker(targets = targets, onClose = { closed = true }) }
        compose.onNodeWithContentDescription(strings.close).performClick()
        compose.runOnIdle { assertTrue(closed) }
    }
}
