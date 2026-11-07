package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/**
 * `spec/connection-notice-vectors.json`, the table the four kits run: statuses over time in, what the connection
 * notice shows at each moment out ([FlareConnectionNoticeTracker]), and the banner's words in both languages.
 */
class ConnectionNoticeTest {
    private val table = SpecTables.table("connection-notice-vectors.json")

    private inline fun <reified E : Enum<E>> named(name: String): E =
        enumValues<E>().first { it.name.equals(name, ignoreCase = true) }

    private fun status(raw: Map<*, *>) = FlareConnectionStatus(
        phase = named(raw.str("phase")!!),
        quality = raw.str("quality")?.let { named<FlareConnectionQuality>(it) },
        progress = (raw["progress"] as? Number)?.toDouble(),
        nextRetryAt = raw.long("nextRetryAt"),
        attempt = raw.int("attempt"),
        reason = raw.str("reason"),
        developmentMode = raw.bool("developmentMode") ?: false,
    )

    @Test fun theThresholdsAreTheSharedOnes() {
        val thresholds = table.obj("thresholds")!!
        assertEquals(thresholds.long("syncingDelayMs"), FlareConnectionNoticeTracker.SYNCING_DELAY_MS)
        assertEquals(thresholds.long("switchingDelayMs"), FlareConnectionNoticeTracker.SWITCHING_DELAY_MS)
        assertEquals(thresholds.long("reconnectingMinShownMs"), FlareConnectionNoticeTracker.RECONNECTING_MIN_SHOWN_MS)
        assertTrue(table.items("cases").size >= 23, "the shared table lost cases")
    }

    /** The reason is the SDK's text: only the four actionRequired reasons are read, by their wire value. */
    @Test fun theReasonIsTheSdksTextAndOnlyTheActionReasonsAreRead() {
        assertEquals(FlareConnectionActionReason.UpgradeRequired, FlareConnectionStatus(FlareConnectionPhase.ActionRequired, reason = "upgradeRequired").actionReason)
        assertEquals("tenantUnavailable", FlareConnectionActionReason.TenantUnavailable.wire)
        for (reason in FlareConnectionActionReason.entries) assertEquals(reason, FlareConnectionActionReason.parse(reason.wire))
        assertEquals(null, FlareConnectionStatus(FlareConnectionPhase.Switching, reason = "drain").actionReason)
        assertEquals(null, FlareConnectionStatus(FlareConnectionPhase.ActionRequired, reason = "accountSuspended").actionReason)
        assertEquals(null, FlareConnectionActionReason.parse("Kicked"))
        assertEquals(null, FlareConnectionActionReason.parse(null))
    }

    @Test fun everyMomentShowsWhatTheSharedTableSays() {
        for (case in table.items("cases")) {
            val name = case.str("name")!!
            val tracker = FlareConnectionNoticeTracker()
            case.items("steps").forEachIndexed { index, step ->
                val at = step.long("at")!!
                step.obj("status")?.let { tracker.observe(status(it), at) }
                val model = tracker.present(at)
                val expect = step.obj("expect")!!
                val label = "$name — step $index at $at"
                assertEquals(expect.bool("visible"), model.visible, label)
                assertEquals(expect.str("text"), model.text?.name?.replaceFirstChar { it.lowercase() }, "$label text")
                assertEquals(expect.str("tone"), model.tone?.name?.lowercase(), "$label tone")
                assertEquals(expect.bool("pulse") ?: false, model.pulse, "$label pulse")
                assertEquals(expect.int("countdown"), model.countdown, "$label countdown")
                assertEquals((expect["progress"] as? Number)?.toDouble(), model.progress, "$label progress")
                assertEquals(expect.str("action"), model.action?.name?.replaceFirstChar { it.lowercase() }, "$label action")
                assertEquals(expect.bool("badge") ?: false, model.badge, "$label badge")
                assertEquals(expect.long("next"), tracker.nextChangeAt(at), "$label next")
            }
        }
    }

    @Test fun theBannerSaysTheMessageThenTheCountdownOrTheProgress() {
        val zh = FlareStrings()
        assertEquals(
            "连接已断开，正在重连… 5 秒后重试",
            FlareConnectionNoticeModel(true, FlareConnectionNoticeText.Reconnecting, countdown = 5).bannerText(zh),
        )
        assertEquals("正在同步消息… 43%", FlareConnectionNoticeModel(true, FlareConnectionNoticeText.Syncing, progress = 0.426).bannerText(zh))
        assertEquals("已在其他设备登录", FlareConnectionNoticeModel(true, FlareConnectionNoticeText.Kicked).bannerText(zh))
        // What a screen reader is told leaves the countdown out.
        assertEquals("连接已断开，正在重连…", FlareConnectionNoticeModel(true, FlareConnectionNoticeText.Reconnecting, countdown = 5).message(zh))
        assertEquals("", FlareConnectionNoticeModel.Hidden.bannerText(zh))
        assertEquals("立即重试", FlareConnectionNoticeAction.Retry.label(zh))
        assertEquals("立即更新", FlareConnectionNoticeAction.Update.label(zh))
        val en = flareStringsEnglish()
        assertEquals(
            "Connection lost. Reconnecting… Retrying in 1s",
            FlareConnectionNoticeModel(true, FlareConnectionNoticeText.Reconnecting, countdown = 1).bannerText(en),
        )
        assertEquals("Sign in again", FlareConnectionNoticeAction.SignIn.label(en))
    }

    @Test fun everyMessageAndActionHasChineseAndEnglishCopy() {
        val han = Regex("\\p{IsHan}")
        for (text in FlareConnectionNoticeText.entries) {
            val model = FlareConnectionNoticeModel(true, text)
            assertTrue(han.containsMatchIn(model.bannerText(FlareStrings())), "$text zh")
            assertFalse(han.containsMatchIn(model.bannerText(flareStringsEnglish())), "$text en")
        }
        for (action in FlareConnectionNoticeAction.entries) {
            assertNotEquals(action.label(FlareStrings()), action.label(flareStringsEnglish()), "$action")
        }
    }
}
