package com.flare.im.ui

import java.io.File
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The shared server clock table (spec/server-clock-vectors.json): server now from the device clock and the host's
 * offset, and the plugin countdown and invite cooldown rules run at that now. Every table's size is asserted, so a
 * section the test stops reading is a failure, not silence.
 */
class ServerClockVectorsTest {
    private val zh = FlareStrings()
    private val en = flareStringsEnglish()

    private fun specFile(name: String): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/$name")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/$name not found above ${File(".").absolutePath}")
    }

    @Suppress("UNCHECKED_CAST")
    private fun table(name: String): List<Map<String, Any?>> {
        val root = FlareJson.parse(specFile("server-clock-vectors.json").readText()) as Map<String, Any?>
        return root.getValue(name) as List<Map<String, Any?>>
    }

    private fun Map<String, Any?>.long(key: String): Long = (this[key] as Number).toLong()
    private fun Map<String, Any?>.offset(): Long? = (this["offsetMs"] as? Number)?.toLong()

    @AfterTest fun resetClock() = FlareServerClock.setOffsetMs(null)

    @Test fun serverNowIsTheDeviceClockPlusTheOffset() {
        val rows = table("now")
        assertEquals(5, rows.size)
        for (v in rows) assertEquals(v.long("expected"), FlareServerClock.now(v.long("deviceNowMs"), v.offset()), v["id"].toString())
    }

    @Test fun countdownsRunOnTheServerClock() {
        val rows = table("countdown")
        assertEquals(5, rows.size)
        for (v in rows) {
            val id = v["id"].toString()
            val now = FlareServerClock.now(v.long("deviceNowMs"), v.offset())
            val shown = PluginViewFormat.countdown(v.long("atMs"), now, zh)
            assertEquals(v["zh"], shown.text, id)
            assertEquals((v["refreshMs"] as? Number)?.toInt(), shown.refreshMs, "$id refresh")
            assertEquals(v["en"], PluginViewFormat.countdown(v.long("atMs"), now, en).text, "$id en")
            assertEquals(v["deviceClockZh"], PluginViewFormat.countdown(v.long("atMs"), v.long("deviceNowMs"), zh).text, "$id device")
        }
    }

    @Suppress("UNCHECKED_CAST")
    @Test fun cooldownsRunOnTheServerClock() {
        val rows = table("regenerate")
        assertEquals(2, rows.size)
        for (v in rows) {
            val id = v["id"].toString()
            val expected = v["expected"] as Map<String, Any?>
            val remaining = expected["remaining"] as? Map<String, Any?>
            val now = FlareServerClock.now(v.long("deviceNowMs"), v.offset())
            val a = regenerateAvailability(v["canRegenerate"] as Boolean, v.long("availableAt"), now)
            assertEquals(expected["enabled"], a.enabled, id)
            assertEquals(remaining?.get("count")?.let { (it as Number).toInt() }, a.remaining?.count, "$id count")
            assertEquals(remaining?.get("unit"), a.remaining?.unit?.name?.lowercase(), "$id unit")
            assertEquals(v["deviceClockEnabled"], regenerateAvailability(true, v.long("availableAt"), v.long("deviceNowMs")).enabled, "$id device")
        }
    }

    @Test fun theKitReadsTheOffsetTheHostHandedIn() {
        val device = System.currentTimeMillis()
        FlareServerClock.setOffsetMs(-300_000)
        assertEquals(-300_000, FlareServerClock.offsetMs)
        val now = FlareServerClock.nowMs()
        assertTrue(now in (device - 300_000)..(System.currentTimeMillis() - 300_000), "$now")
        FlareServerClock.setOffsetMs(null)
        assertEquals(0, FlareServerClock.offsetMs)
    }

    /**
     * The composables that judge server-issued instants read the server clock. They are drawn on a device only, so the
     * source says which clock they read.
     */
    @Test fun serverInstantsAreNeverJudgedOnTheDeviceClock() {
        for (name in listOf("PluginView.kt", "MyInvitePanel.kt", "RedPacketDetail.kt")) {
            val source = File(specFile("server-clock-vectors.json").parentFile.parentFile,
                "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/$name").readText()
            assertFalse("System.currentTimeMillis()" in source, "$name reads the device clock")
            assertTrue("FlareServerClock.nowMs()" in source, "$name reads the server clock")
        }
    }
}
