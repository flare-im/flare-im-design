package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTouchInput
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * The tick a swipe gives when it crosses the arming distance. The counting rule is the shared table
 * (`test/HapticVectorsTest`); what needs a device is the gesture actually reaching the platform — once on
 * the way in, once on the way back out, and never while the finger rests past the line.
 */
class SwipeReplyHapticInteractionTest {
    @get:Rule val compose = createComposeRule()

    private class RecordingHaptics : HapticFeedback {
        val ticks = mutableListOf<HapticFeedbackType>()
        override fun performHapticFeedback(hapticFeedbackType: HapticFeedbackType) {
            ticks += hapticFeedbackType
        }
    }

    @Test fun armingAndDisarmingEachAskForOneTick() {
        val haptics = RecordingHaptics()
        compose.setContent {
            CompositionLocalProvider(LocalHapticFeedback provides haptics) {
                MaterialTheme {
                    MessageList(
                        messages = listOf(
                            FlareMessageData(
                                id = "m1", senderId = "ann", senderName = "Ann",
                                content = FlareTextContent("第一条"),
                            ),
                        ),
                        currentUserId = "me",
                        onSwipeReply = {},
                    )
                }
            }
        }
        compose.onNodeWithText("第一条").performTouchInput {
            down(center)
            moveBy(Offset(30f, 0f))
            moveBy(Offset(30f, 0f))
        }
        compose.runOnIdle { assertEquals(0, haptics.ticks.size) }

        compose.onNodeWithText("第一条").performTouchInput { moveBy(Offset(200f, 0f)) }
        compose.runOnIdle { assertEquals(1, haptics.ticks.size) }

        // Held past the line, not a drum.
        compose.onNodeWithText("第一条").performTouchInput { moveBy(Offset(60f, 0f)) }
        compose.runOnIdle { assertEquals(1, haptics.ticks.size) }

        // Back out of the armed zone: letting go means something else again.
        compose.onNodeWithText("第一条").performTouchInput {
            moveBy(Offset(-260f, 0f))
            up()
        }
        compose.runOnIdle { assertEquals(2, haptics.ticks.size) }
    }
}
