package com.flare.im.ui

import android.graphics.Bitmap
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.ui.Modifier
import androidx.compose.material3.Text
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertHasNoClickAction
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.Density
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * The call record card on a device: what it says, the one action it offers and who hears the tap; and the 1:1 call
 * view's minimize control. The rules themselves are the JVM CallRecordCardTest against spec/call-record-vectors.json.
 */
class CallRecordCardInteractionTest {
    @get:Rule val rule = createComposeRule()
    private val zh = FlareStrings()

    @Test fun joinReachesTheHostOnce() {
        var joins = 0
        rule.setContent {
            CallRecordCard(media = FlareCallMode.Video, scope = FlareCallRecordScope.Group, state = FlareCallRecordState.Ongoing,
                viewerIsInitiator = false, canJoin = true, canCallBack = false, joinedCount = 4, onJoin = { joins++ })
        }
        rule.onNodeWithText("群通话进行中 · 4 人", useUnmergedTree = true).assertExists()
        rule.onNodeWithText(zh.callRecordJoin).performClick()
        assertEquals(1, joins)
    }

    @Test fun busyCallBackTakesNoTap() {
        var callBacks = 0
        val busy = mutableStateOf(true)
        rule.setContent {
            CallRecordCard(media = FlareCallMode.Audio, scope = FlareCallRecordScope.Single, state = FlareCallRecordState.Ended,
                endReason = FlareCallEndReason.Missed, viewerIsInitiator = false, canJoin = false, canCallBack = true,
                busy = busy.value, onCallBack = { callBacks++ })
        }
        rule.onNodeWithTag(CALL_RECORD_ACTION_TAG).performClick()
        assertEquals(0, callBacks)
        busy.value = false
        rule.onNodeWithTag(CALL_RECORD_ACTION_TAG).performClick()
        assertEquals(0, callBacks)
        rule.onNodeWithText(zh.confirm).performClick()
        assertEquals(1, callBacks)
    }

    @Test fun compactCardConfirmsBeforeCallingBack() {
        var callBacks = 0
        rule.setContent {
            Box(Modifier.width(360.dp)) {
                CallRecordCard(media = FlareCallMode.Video, scope = FlareCallRecordScope.Single, state = FlareCallRecordState.Ended,
                    durationSeconds = 30, viewerIsInitiator = true, canJoin = false, canCallBack = true,
                    onCallBack = { callBacks++ })
            }
        }
        rule.onNodeWithText(zh.callRecordCallBack).assertDoesNotExist()
        val bounds = rule.onNodeWithTag(CALL_RECORD_ACTION_TAG).getUnclippedBoundsInRoot()
        assertTrue("short records follow their content", bounds.right - bounds.left < FlareSizes.componentRichCardWidth)
        assertTrue("the entire card remains touchable", bounds.bottom - bounds.top >= FlareSizes.touchTarget)
        rule.onNodeWithTag(CALL_RECORD_ACTION_TAG).performClick()
        assertEquals(0, callBacks)
        rule.onNodeWithText(zh.cancel).performClick()
        rule.onNodeWithTag(CALL_RECORD_ACTION_TAG).performClick()
        rule.onNodeWithText(zh.confirm).performClick()
        assertEquals(1, callBacks)
    }

    @Test fun unavailableCallBackInvalidatesAnOpenConfirmation() {
        var callBacks = 0
        val available = mutableStateOf(true)
        rule.setContent {
            CallRecordCard(media = FlareCallMode.Audio, scope = FlareCallRecordScope.Single, state = FlareCallRecordState.Ended,
                viewerIsInitiator = false, canJoin = false, canCallBack = available.value,
                onCallBack = { callBacks++ })
        }
        rule.onNodeWithTag(CALL_RECORD_ACTION_TAG).performClick()
        available.value = false
        rule.onNodeWithText(zh.confirm).assertDoesNotExist()
        available.value = true
        rule.onNodeWithText(zh.confirm).assertDoesNotExist()
        assertEquals(0, callBacks)
    }

    @Test fun callbackWithoutHandlerHasNoTapAction() {
        rule.setContent {
            CallRecordCard(media = FlareCallMode.Audio, scope = FlareCallRecordScope.Single, state = FlareCallRecordState.Ended,
                viewerIsInitiator = false, canJoin = false, canCallBack = true)
        }
        rule.onNodeWithText(zh.callRecordCallBack).assertDoesNotExist()
        rule.onNodeWithTag(CALL_RECORD_ACTION_TAG).assertHasNoClickAction()
        rule.onNodeWithText(zh.confirm).assertDoesNotExist()
    }

    @Test fun aQuotedReplyKeepsItsOwnAction() {
        var quoteOpens = 0
        var callBacks = 0
        rule.setContent {
            CompositionLocalProvider(LocalFlareCardQuote provides {
                Text("Quoted message", Modifier.clickable { quoteOpens++ })
            }) {
                CallRecordCard(media = FlareCallMode.Audio, scope = FlareCallRecordScope.Single,
                    state = FlareCallRecordState.Ended, viewerIsInitiator = false,
                    canJoin = false, canCallBack = true, onCallBack = { callBacks++ })
            }
        }
        rule.onNodeWithText("Quoted message").performClick()
        assertEquals(1, quoteOpens)
        rule.onNodeWithText(zh.confirm).assertDoesNotExist()
        assertEquals(0, callBacks)
        rule.onNodeWithTag(CALL_RECORD_ACTION_TAG).performClick()
        rule.onNodeWithText(zh.confirm).performClick()
        assertEquals(1, callBacks)
    }

    @Test fun callRecordsRemainCompactInBothThemesAndLargeText() {
        val mode = mutableStateOf(FlareThemeMode.Light)
        val fontScale = mutableStateOf(1f)
        rule.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density, fontScale.value)) {
                FlareThemeProvider(mode = mode.value) {
                    Column(Modifier.width(360.dp).background(flareColors().bgSecondary).padding(FlareSizes.spacingMd),
                        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
                        CallRecordCard(media = FlareCallMode.Video, scope = FlareCallRecordScope.Single,
                            state = FlareCallRecordState.Ended, durationSeconds = 30, viewerIsInitiator = true,
                            canJoin = false, canCallBack = true, onCallBack = {})
                        CallRecordCard(media = FlareCallMode.Audio, scope = FlareCallRecordScope.Single,
                            state = FlareCallRecordState.Ended, endReason = FlareCallEndReason.Declined,
                            viewerIsInitiator = true, canJoin = false, canCallBack = true, onCallBack = {})
                        CallRecordCard(media = FlareCallMode.Audio, scope = FlareCallRecordScope.Single,
                            state = FlareCallRecordState.Ended, endReason = FlareCallEndReason.Missed,
                            viewerIsInitiator = false, canJoin = false, canCallBack = true, onCallBack = {})
                        CallRecordCard(media = FlareCallMode.Video, scope = FlareCallRecordScope.Group,
                            state = FlareCallRecordState.Ongoing, joinedCount = 4, viewerIsInitiator = false,
                            canJoin = true, canCallBack = false, onJoin = {})
                    }
                }
            }
        }
        capture("call-record-android-light.png")
        rule.runOnIdle { mode.value = FlareThemeMode.Dark }
        capture("call-record-android-dark.png")
        rule.runOnIdle { mode.value = FlareThemeMode.Light; fontScale.value = 2f }
        capture("call-record-android-large-text.png")
    }

    private fun capture(name: String) {
        val file = File(InstrumentationRegistry.getInstrumentation().targetContext.getExternalFilesDir(null), name)
        file.outputStream().use { rule.onRoot().captureToImage().asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, it) }
        assertTrue(file.length() > 0)
    }

    @Test fun namesTheMediaAndTheStatus() {
        rule.setContent {
            CallRecordCard(media = FlareCallMode.Audio, scope = FlareCallRecordScope.Single, state = FlareCallRecordState.Ended,
                endReason = FlareCallEndReason.Missed, viewerIsInitiator = false, canJoin = false, canCallBack = false)
        }
        rule.onNodeWithContentDescription(zh.callRecordVoice)
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, zh.callRecordMissed))
    }

    @Test fun anUnavailablePluginDropsTheAction() {
        rule.setContent {
            CallRecordCard(media = FlareCallMode.Audio, scope = FlareCallRecordScope.Group, state = FlareCallRecordState.Ongoing,
                viewerIsInitiator = false, canJoin = true, canCallBack = true, joinedCount = 2, disabled = true)
        }
        rule.onAllNodesWithTag(CALL_RECORD_ACTION_TAG).assertCountEquals(0)
    }

    @Test fun theCallViewMinimizesOnlyWhenTheHostCan() {
        var minimized = 0
        val canMinimize = mutableStateOf(false)
        rule.setContent {
            CallView(peerName = "Ada", mode = FlareCallMode.Audio, state = FlareCallState.Connected,
                onMinimize = if (canMinimize.value) ({ minimized++ }) else null)
        }
        rule.onNodeWithContentDescription(zh.callMinimize).assertDoesNotExist()
        canMinimize.value = true
        rule.onNodeWithContentDescription(zh.callMinimize).performClick()
        assertEquals(1, minimized)
    }
}
