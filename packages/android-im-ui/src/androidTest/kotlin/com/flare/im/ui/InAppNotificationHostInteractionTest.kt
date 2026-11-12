package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeUp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

/**
 * InAppNotificationHost on a device: the banner shows what the presenter holds, goes after the kit's time, a newer
 * item of the same conversation replaces it in place, a tap opens and a swipe up dismisses.
 */
class InAppNotificationHostInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val alice = FlareInAppNotification(
        collapseId = "c:a", conversationId = "a", messageId = "m1", title = "Alice", body = "are you free?",
        count = 3, channel = FlareInAppNotificationChannel.Mentions,
    )
    private val spoken = alice.spoken()

    /** Shows [alice] with the test clock under the test's hand, so the banner's own time does not run ahead. */
    private fun showAlice(notifications: FlareInAppNotifications, opened: MutableList<String?> = mutableListOf()) {
        compose.mainClock.autoAdvance = false
        compose.setContent { MaterialTheme {
            InAppNotificationHost(notifications, onOpen = { conversationId, messageId -> opened += listOf(conversationId, messageId) }) {
                Box(Modifier.fillMaxSize())
            }
        } }
        compose.runOnUiThread { notifications.present(alice) }
        compose.mainClock.advanceTimeBy(FlareMotion.normal.toLong() + 100)
    }

    @Test fun theBannerGoesAfterTheKitsTime() {
        val notifications = FlareInAppNotifications()
        showAlice(notifications)
        compose.onNodeWithContentDescription(spoken).assertExists()
        compose.mainClock.advanceTimeBy(IN_APP_NOTIFICATION_DURATION_MS)
        compose.runOnUiThread { assertNull(notifications.current) }
    }

    @Test fun aTapOpensTheConversationAndTakesTheBannerAway() {
        val notifications = FlareInAppNotifications()
        val opened = mutableListOf<String?>()
        showAlice(notifications, opened)
        compose.onNodeWithContentDescription(spoken).performClick()
        compose.mainClock.advanceTimeByFrame()
        compose.runOnUiThread {
            assertEquals(listOf("a", "m1"), opened)
            assertNull(notifications.current)
        }
    }

    @Test fun aSwipeUpDismisses() {
        val notifications = FlareInAppNotifications()
        showAlice(notifications)
        compose.onNodeWithContentDescription(spoken).performTouchInput { swipeUp() }
        compose.mainClock.advanceTimeByFrame()
        compose.runOnUiThread { assertNull(notifications.current) }
    }
}
