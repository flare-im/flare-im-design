package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.TouchInjectionScope
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * Swiping a message to reply to it. The arithmetic is the shared table (`test/SwipeReplyVectorsTest`);
 * this is the gesture reaching it on a real touch screen — which is why it needs a device.
 *
 * The rule works in dp and a finger moves in pixels, so every drag here is written in dp: a drag written in
 * pixels is a different distance on every screen density and only armed where a pixel happened to be a dp.
 */
class MessageSwipeReplyInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()

    private fun message(id: String, text: String, lifecycle: FlareMessageLifecycle? = null) =
        FlareMessageData(
            id = id, senderId = "ann", senderName = "Ann",
            content = FlareTextContent(text), lifecycle = lifecycle,
        )

    private fun list(replied: MutableList<String>, multiSelectMode: Boolean = false, message: FlareMessageData) {
        compose.setContent { MaterialTheme {
            MessageList(
                messages = listOf(message),
                currentUserId = "me",
                multiSelectMode = multiSelectMode,
                onSwipeReply = { replied += it.id },
            )
        } }
    }

    /** A finger down in the middle of the row, dragged sideways by [first] and then [second], then lifted. */
    private fun TouchInjectionScope.drag(first: Dp, second: Dp) {
        down(center)
        moveBy(Offset(first.toPx(), 0f))
        moveBy(Offset(second.toPx(), 0f))
        up()
    }

    /** Past the arming distance, so the affordance was fully drawn before the finger came up. */
    @Test fun aRowDraggedPastTheArmingDistanceReplies() {
        val replied = mutableListOf<String>()
        list(replied, message = message("m1", "第一条"))
        compose.onNodeWithText("第一条").performTouchInput { drag(40.dp, 120.dp) }
        compose.runOnIdle { assertEquals(listOf("m1"), replied) }
    }

    @Test fun aRowLetGoBeforeItArmsSaysNothing() {
        val replied = mutableListOf<String>()
        list(replied, message = message("m1", "第一条"))
        compose.onNodeWithText("第一条").performTouchInput { drag(20.dp, 10.dp) }
        compose.runOnIdle { assertTrue(replied.isEmpty()) }
    }

    @Test fun draggingTowardsTheOtherEdgeNeverReplies() {
        val replied = mutableListOf<String>()
        list(replied, message = message("m1", "第一条"))
        compose.onNodeWithText("第一条").performTouchInput { drag((-40).dp, (-160).dp) }
        compose.runOnIdle { assertTrue(replied.isEmpty()) }
    }

    /** Selecting messages owns the row; a swipe there would fight the selection. */
    @Test fun multiSelectCarriesNoSwipe() {
        val replied = mutableListOf<String>()
        list(replied, multiSelectMode = true, message = message("m1", "第一条"))
        compose.onNodeWithText("第一条").performTouchInput { drag(40.dp, 120.dp) }
        compose.runOnIdle { assertTrue(replied.isEmpty()) }
    }

    /** A notice has no message actions, and replying is one of them. */
    @Test fun aNoticeCarriesNoSwipe() {
        val replied = mutableListOf<String>()
        list(replied, message = message("m2", "撤回的", FlareMessageLifecycle(mutation = FlareMessageMutationState.Recalled)))
        compose.onNodeWithText(strings.messageRecalledPeer).performTouchInput { drag(40.dp, 120.dp) }
        compose.runOnIdle { assertTrue(replied.isEmpty()) }
    }
}
