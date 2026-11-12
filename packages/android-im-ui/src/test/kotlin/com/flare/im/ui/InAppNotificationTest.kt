package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * `spec/in-app-notification-vectors.json`, the table the four kits run: items fed into [FlareInAppNotifications],
 * what shows and waits, and when the visible banner's time starts over.
 */
class InAppNotificationTest {
    private val table = SpecTables.table("in-app-notification-vectors.json")

    private fun item(text: String): FlareInAppNotification {
        val (collapseId, body) = text.split("/")
        return FlareInAppNotification(collapseId = collapseId, conversationId = collapseId.drop(2), title = collapseId, body = body)
    }

    private fun written(entry: FlareInAppNotification?): String? = entry?.let { "${it.collapseId}/${it.body}" }

    @Test fun theLimitsAreTheSharedOnes() {
        val limits = table.obj("limits")!!
        assertEquals(limits.long("durationMs"), IN_APP_NOTIFICATION_DURATION_MS)
        assertEquals(limits.int("pendingLimit"), IN_APP_NOTIFICATION_PENDING_LIMIT)
    }

    @Test fun everyCaseQueuesAsTheTableSays() {
        val cases = table.items("cases")
        check(cases.isNotEmpty())
        for (case in cases) {
            val presenter = FlareInAppNotifications()
            case.items("steps").forEachIndexed { index, step ->
                val before = presenter.revision
                when (step.str("op")) {
                    "present" -> presenter.present(item(step.str("item")!!))
                    "dismiss" -> presenter.dismiss()
                    "clear" -> presenter.clear((step["collapseIds"] as List<*>).map { it as String })
                    "clearAll" -> presenter.clearAll()
                    else -> error("unknown op ${step.str("op")}")
                }
                val where = "${case.str("name")} step ${index + 1}"
                assertEquals(step.str("current"), written(presenter.current), where)
                assertEquals((step["pending"] as List<*>).map { it as String }, presenter.pending.map { written(it) }, where)
                assertEquals(step.bool("restart"), presenter.revision != before, where)
            }
        }
    }

    @Test fun aReaderHearsTheLabelTitleTagCountAndBody() {
        val alice = FlareInAppNotification(
            collapseId = "c:a", conversationId = "a", messageId = "m1", title = "Alice", body = "are you free?",
            count = 3, channel = FlareInAppNotificationChannel.Mentions,
        )
        assertEquals("New message, Alice, [Mention], [3 messages], are you free?", alice.spoken(flareStringsEnglish()))
        assertEquals("新消息, Alice, [有人@我], [3条], are you free?", alice.spoken())
        val bob = FlareInAppNotification(collapseId = "c:b", conversationId = "b", title = "Bob", body = "lunch", channel = FlareInAppNotificationChannel.Urgent)
        assertEquals("[Urgent]", bob.tag(flareStringsEnglish()))
        assertEquals("New message, Bob, [Urgent], lunch", bob.spoken(flareStringsEnglish()))
        assertEquals(null, bob.copy(channel = FlareInAppNotificationChannel.Quiet).tag())
    }
}
