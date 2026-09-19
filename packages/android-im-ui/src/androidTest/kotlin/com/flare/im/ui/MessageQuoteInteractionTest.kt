package com.flare.im.ui

import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityManager
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.test.platform.app.InstrumentationRegistry
import java.util.concurrent.CopyOnWriteArrayList
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import kotlin.math.abs

/**
 * Reply quotes in the thread: a loaded original is scrolled to, an unloaded one goes to the host.
 *
 * A thread opens at its newest message, so the quote is the newest row and the original sits far above it,
 * out of the rows the lazy list has composed — the jump is only proven when the original was not there before.
 */
class MessageQuoteInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()

    private fun message(id: String, text: String, replyTo: FlareReplyTarget? = null, serverId: String? = null) =
        FlareMessageData(id = id, senderId = "ann", senderName = "Ann", content = FlareTextContent(text), replyTo = replyTo, serverId = serverId)

    /** [count] plain rows, then the newest row quoting [quotedId]. */
    private fun threadQuoting(quotedId: String, count: Int = 39) =
        (1..count).map { message("m$it", "第 $it 条") } +
            message("reply", "回复", FlareReplyTarget("Ann", "被引用的原文", messageId = quotedId))

    @Test fun aLoadedQuoteScrollsToTheOriginalWithoutAskingTheHost() {
        val located = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            MessageList(messages = threadQuoting("m1"), currentUserId = "me", onLocateMessage = { located += it })
        } }
        assertTrue(compose.onAllNodesWithText("第 1 条").fetchSemanticsNodes().isEmpty())
        compose.onNodeWithContentDescription(strings.messageQuoteLabel("Ann", "被引用的原文"))
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button))
            .assertHasClickAction()
            .performClick()
        compose.onNodeWithText("第 1 条").assertIsDisplayed()
        compose.runOnIdle { assertTrue(located.isEmpty()) }
    }

    /**
     * Where the row lands once it is found: in the middle of the viewport, which is where Vue, Flutter and
     * SwiftUI put it. This kit left it against the top edge, so the same tap read differently on Android and
     * the rows that give the message its context stayed off screen above it (FR-113). The arithmetic is unit
     * tested (`test/LocatedRowPlacementTest`); only a device can say the row actually arrives there, so this
     * assertion is the one that has to run on one.
     */
    @Test fun aLocatedRowArrivesInTheMiddleOfTheViewport() {
        // Room above and below the target, otherwise the list has nothing to centre it with.
        compose.setContent { MaterialTheme {
            MessageList(messages = threadQuoting("m30", count = 60), currentUserId = "me", onLocateMessage = {})
        } }
        assertTrue(compose.onAllNodesWithText("第 30 条").fetchSemanticsNodes().isEmpty())
        compose.onNodeWithContentDescription(strings.messageQuoteLabel("Ann", "被引用的原文")).performClick()
        compose.waitForIdle()
        // The list fills the rule's root, so the root's middle is the viewport's middle.
        val row = compose.onNodeWithText("第 30 条").assertIsDisplayed().getUnclippedBoundsInRoot()
        val viewport = compose.onRoot().getUnclippedBoundsInRoot()
        val offCentre = (row.top + row.bottom) / 2f - (viewport.top + viewport.bottom) / 2f
        // A row's own height is the margin; the old top-anchored placement missed by half a screen.
        assertTrue("located row sits $offCentre from the middle of the viewport", abs(offCentre.value) <= 24f)
    }

    /**
     * A jump that lands says so out loud as well: the ring is for the people who can see it, and a reader
     * who cannot gets the same fact — which row, and what it says. Only a device has an accessibility
     * service to receive it, which is why this assertion lives here.
     *
     * The listener is the instrumentation's own accessibility connection: an app only sends announcements
     * while some accessibility client is connected, and this is one — the same event TalkBack would receive.
     */
    @Test fun aLandedJumpIsAnnounced() {
        val announced = CopyOnWriteArrayList<String>()
        val automation = InstrumentationRegistry.getInstrumentation().uiAutomation
        automation.setOnAccessibilityEventListener { event ->
            if (event.eventType == AccessibilityEvent.TYPE_ANNOUNCEMENT) announced += event.text.joinToString("")
        }
        try {
            val messages = threadQuoting("m1")
            compose.setContent { MaterialTheme {
                MessageList(messages = messages, currentUserId = "me", onLocateMessage = {})
            } }
            val manager = InstrumentationRegistry.getInstrumentation().targetContext
                .getSystemService(AccessibilityManager::class.java)
            compose.waitUntil(timeoutMillis = 5_000) { manager.isEnabled }
            compose.onNodeWithContentDescription(strings.messageQuoteLabel("Ann", "被引用的原文")).performClick()
            compose.waitUntil(timeoutMillis = 5_000) { announced.isNotEmpty() }
            compose.waitForIdle()
            assertEquals(listOf(flareLocatedAnnouncement(messages.first(), strings)), announced.toList())
        } finally {
            automation.setOnAccessibilityEventListener(null)
        }
    }

    /**
     * The bug this batch removes: a quote names its original by the core id, and a message this device sent
     * is drawn on a row keyed by its client id. The quote must still recognise it and scroll — the reader is
     * looking at the message, so nothing may go to the host and nothing may say it is gone.
     */
    @Test fun aQuoteOfASelfSentMessageIsLocatedByItsCoreIdWithoutAskingTheHost() {
        val located = mutableListOf<String>()
        val messages = listOf(message("cli-1", "第 1 条", serverId = "srv-1")) + threadQuoting("srv-1").drop(1)
        compose.setContent { MaterialTheme {
            MessageList(messages = messages, currentUserId = "me", onLocateMessage = { located += it })
        } }
        assertTrue(compose.onAllNodesWithText("第 1 条").fetchSemanticsNodes().isEmpty())
        compose.onNodeWithContentDescription(strings.messageQuoteLabel("Ann", "被引用的原文")).performClick()
        compose.onNodeWithText("第 1 条").assertIsDisplayed()
        compose.runOnIdle { assertTrue(located.isEmpty()) }
    }

    @Test fun anUnloadedQuoteAsksTheHost() {
        val located = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            MessageList(
                messages = listOf(message("m1", "回复你", FlareReplyTarget("", "很早以前的消息", messageId = "old"))),
                currentUserId = "me",
                onLocateMessage = { located += it },
            )
        } }
        compose.onNodeWithContentDescription(strings.messageQuoteLabel("", "很早以前的消息")).performClick()
        compose.runOnIdle { assertEquals(listOf("old"), located) }
    }

    @Test fun aQuoteThatCannotLocateIsPlainText() {
        compose.setContent { MaterialTheme {
            MessageList(
                messages = listOf(message("m1", "回复你", FlareReplyTarget("Ann", "很早以前的消息", messageId = "old"))),
                currentUserId = "me",
            )
        } }
        compose.onNodeWithText("很早以前的消息").assertIsDisplayed()
        compose.onAllNodes(hasClickAction()).assertCountEquals(0)
    }

    @Test fun multiSelectAndMissingIdsLeaveTheQuoteAsText() {
        val located = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            androidx.compose.foundation.layout.Column {
                MessageBubble(
                    message = message("a", "选中模式", FlareReplyTarget("Ann", "原文一", messageId = "m0")),
                    currentUserId = "me",
                    multiSelectMode = true,
                    onLocateMessage = { located += it },
                )
                MessageBubble(
                    message = message("b", "没有原文编号", FlareReplyTarget("Ann", "原文二")),
                    currentUserId = "me",
                    onLocateMessage = { located += it },
                )
            }
        } }
        compose.onNodeWithText("原文一").assertIsDisplayed()
        compose.onNodeWithText("原文二").assertIsDisplayed()
        compose.onAllNodes(hasClickAction()).assertCountEquals(0)
        compose.runOnIdle { assertTrue(located.isEmpty()) }
    }
}
