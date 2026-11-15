package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.click
import androidx.compose.ui.test.isDialog
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * The sheet form of PermissionPrompt as a host uses it: a key closes the sheet and its callback runs only once the
 * sheet is gone (so the system permission dialog the host opens has the screen to itself), even with no dismiss to
 * close it otherwise; the scrim closes it as a dismiss; and an answered prompt stays closed while it stays composed.
 */
class PermissionPromptSheetInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()
    private val overlays = FlareOverlayStack(FlareToastState())
    private val log = mutableListOf<String>()

    /** Each entry says what the host heard and whether a kit overlay was still open when it heard it. */
    private fun heard(what: String) {
        log += if (overlays.isEmpty) what else "$what while open"
    }

    private fun ask(dismissible: Boolean = true) {
        compose.setContent { MaterialTheme {
            CompositionLocalProvider(LocalFlareOverlayStack provides overlays) {
                PermissionPrompt(
                    kind = FlarePermissionKind.Notifications,
                    state = FlarePermissionState.Undetermined,
                    softAsk = true,
                    presentation = FlarePermissionPresentation.Sheet,
                    onRequest = { heard("request") },
                    onDismiss = if (dismissible) ({ heard("dismiss") }) else null,
                )
            }
        } }
        compose.waitForIdle()
        compose.onNode(isDialog()).assertExists()
    }

    @Test fun aKeyClosesTheSheetBeforeItsCallbackRuns() {
        ask()
        compose.onNodeWithText(strings.permissionSoftAskNotificationsAction).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        compose.runOnIdle { assertEquals(listOf("request"), log) }
    }

    @Test fun aKeyClosesTheSheetEvenWithoutADismiss() {
        ask(dismissible = false)
        // Nothing but a key closes it: the scrim is locked.
        compose.onNode(isDialog()).performTouchInput { click(Offset(10f, 10f)) }
        compose.waitForIdle()
        compose.onNode(isDialog()).assertExists()
        compose.onNodeWithText(strings.permissionSoftAskNotificationsAction).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        compose.runOnIdle { assertEquals(listOf("request"), log) }
    }

    @Test fun theScrimClosesItAsADismissAndItStaysClosed() {
        ask()
        compose.onNode(isDialog()).performTouchInput { click(Offset(10f, 10f)) }
        compose.waitForIdle()
        // Still composed by the host, yet it does not come back.
        compose.onNode(isDialog()).assertDoesNotExist()
        compose.runOnIdle { assertEquals(listOf("dismiss"), log) }
    }

    @Test fun notNowIsADismissThatAlsoWaitsForTheSheet() {
        ask()
        compose.onNodeWithText(strings.permissionNotNow).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        compose.runOnIdle { assertEquals(listOf("dismiss"), log) }
    }
}
