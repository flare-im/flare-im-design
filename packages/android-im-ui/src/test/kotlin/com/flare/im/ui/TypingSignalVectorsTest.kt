package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared typing table (`spec/typing-vectors.json`), `signal` half: the composer's edits in, the
 * reports this client owes the conversation out. The Vue, Flutter and SwiftUI kits run the same file
 * through the same driver, so a rule that is right here is right there or the difference is a failure.
 */
class TypingSignalVectorsTest {
    @Test fun usesTheTablesConstantsSoTheFourKitsCannotDriftApartQuietly() {
        val rules = (FlareJson.parse(vectorsFile().readText()) as Map<*, *>)["rules"] as Map<*, *>
        assertEquals(FLARE_TYPING_IDLE_STOP_MS, (rules["idleStopMs"] as Number).toInt())
        assertEquals(FLARE_TYPING_REFRESH_MS, (rules["refreshMs"] as Number).toInt())
        assertEquals(FLARE_TYPING_PEER_TTL_MS, (rules["peerTtlMs"] as Number).toInt())
    }

    @Test fun refreshesBeforeThePeersBeliefExpires() {
        // The invariant the table states. Two apps shipped without it and went silent mid-sentence.
        assertTrue(FLARE_TYPING_REFRESH_MS < FLARE_TYPING_PEER_TTL_MS)
    }

    @Test fun everyScriptReportsTheSameThingHere() = runEveryScript(0L)

    /**
     * The same scripts again with the clock where a real one is. A table whose times start at zero is
     * comfortably inside a 32-bit int; `System.currentTimeMillis()` is not, and a rule that stored "now"
     * in one would wrap to a negative instant and never stop typing — a defect no zero-based script can see.
     */
    @Test fun everyScriptReportsTheSameThingWithARealClock() = runEveryScript(1_767_000_000_000L)

    private fun runEveryScript(base: Long) {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = (table["signal"] as Map<*, *>)["cases"] as List<*>
        assertTrue(cases.size >= 22, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val name = case["name"] as String
            val signal = FlareTypingSignal()
            val reports = mutableListOf<FlareTypingReport>()
            for (rawStep in case["steps"] as List<*>) {
                val step = rawStep as Map<*, *>
                val at = base + (step["at"] as Number).toLong()
                // Time first, then the step: an idle stop that fell due in between must be reported before it.
                reports += signal.tick(at)
                when (step["op"] as String) {
                    "edit" -> reports += signal.edit(step["conversationId"] as? String ?: "", step["text"] as? String ?: "", at)
                    "send" -> reports += signal.send(step["conversationId"] as? String ?: "", at)
                    "close" -> reports += signal.close(at)
                }
            }
            reports += signal.tick(base + (case["endAt"] as Number).toLong())
            val expected = (case["expect"] as List<*>).map {
                val e = it as Map<*, *>
                FlareTypingReport(e["conversationId"] as String, e["typing"] as Boolean, base + (e["at"] as Number).toLong())
            }
            assertEquals(expected, reports, "$name @ base=$base")
        }
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/typing-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/typing-vectors.json not found above ${File(".").absolutePath}")
}
