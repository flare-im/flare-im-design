package com.flare.im.ui

import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
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
        rule.onNodeWithText(zh.callRecordCallBack).performClick()
        assertEquals(1, callBacks)
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
