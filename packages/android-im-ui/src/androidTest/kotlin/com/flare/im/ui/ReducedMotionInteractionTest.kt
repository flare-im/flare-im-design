package com.flare.im.ui

import android.provider.Settings
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test

/**
 * Reduced motion on Android (`A11Y-REDUCED-MOTION`).
 *
 * "The user removed animations" is a real system setting — the animator duration scale — and the kit
 * reads it (`flareReducedMotion`). What it changes is observable: a sheet that is asked to close
 * calls its host back at once instead of playing its way out, so a person who has turned animations
 * off does not sit through one.
 *
 * The ledger had this requirement marked AUTOMATION_REQUIRED with no evidence on any platform. Vue,
 * Flutter and SwiftUI had tests; Android was the one that did not, so the requirement could not be
 * closed. The setting is written through the instrumentation shell and restored afterwards — a test
 * that changes a device setting puts it back.
 */
class ReducedMotionInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private var previousScale = 1f

    private fun animatorScale(): Float =
        Settings.Global.getFloat(instrumentation.targetContext.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)

    private fun setAnimatorScale(value: Float) {
        instrumentation.uiAutomation.executeShellCommand("settings put global animator_duration_scale $value").close()
        // The write goes through the shell, so wait for the value the kit will read to be the one we set.
        val deadline = System.currentTimeMillis() + 5_000
        while (animatorScale() != value && System.currentTimeMillis() < deadline) Thread.sleep(50)
    }

    @Before fun rememberSetting() {
        previousScale = animatorScale()
    }

    @After fun restoreSetting() {
        setAnimatorScale(previousScale)
    }

    @Test fun theKitReadsTheSystemSettingItself() {
        // The claim under test is that the kit asks the system, not that the system can be asked.
        // Breaking `flareReducedMotion` turns this red; asserting the setting alone would not.
        setAnimatorScale(0f)
        val offReading = mutableStateOf<Boolean?>(null)
        compose.setContent { MaterialTheme { offReading.value = flareReducedMotion() } }
        compose.waitForIdle()
        assertEquals(true, offReading.value)
    }

    @Test fun theKitSeesAnimationsComeBack() {
        setAnimatorScale(1f)
        val onReading = mutableStateOf<Boolean?>(null)
        compose.setContent { MaterialTheme { onReading.value = flareReducedMotion() } }
        compose.waitForIdle()
        assertEquals(false, onReading.value)
    }

    /**
     * And the surface that uses it still works with animations off — the sheet closes and the host
     * is told. This does not distinguish the two code paths: with the scale at 0 the animated path
     * also finishes instantly, so only the reading above can tell them apart.
     */
    @Test fun aSheetStillClosesWhenAnimationsAreOff() {
        setAnimatorScale(0f)
        val closed = mutableStateOf(false)
        compose.setContent {
            MaterialTheme {
                if (!closed.value) BottomSheet(onClose = { closed.value = true }, title = "分享到") { Text("内容") }
            }
        }
        compose.onNodeWithText("内容").assertIsDisplayed()

        compose.onNodeWithContentDescription(FlareStrings().close).performClick()
        compose.waitUntil(5_000) { closed.value }
        compose.onNodeWithText("内容").assertDoesNotExist()
    }

    @Test fun aSheetStillClosesWhenAnimationsAreOn() {
        setAnimatorScale(1f)
        val closed = mutableStateOf(false)
        compose.setContent {
            MaterialTheme {
                if (!closed.value) BottomSheet(onClose = { closed.value = true }, title = "分享到") { Text("内容") }
            }
        }
        compose.onNodeWithText("内容").assertIsDisplayed()

        compose.onNodeWithContentDescription(FlareStrings().close).performClick()
        compose.waitUntil(5_000) { closed.value }
        compose.onNodeWithText("内容").assertDoesNotExist()
    }
}
