package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared haptics table (`spec/haptic-vectors.json`) is the one rule three kits follow for the tick a
 * gesture gives when it crosses the line where letting go starts to mean something else: one tick per change
 * of state, in both directions, never per frame. The tick itself is a device's to feel — this counts the asks.
 */
class HapticVectorsTest {
    @Test fun everyRunTicksTheSameNumberOfTimesHere() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = table["cases"] as List<*>
        assertTrue(cases.size >= 8, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val states = (case["states"] as List<*>).map { it as Boolean }
            var ticks = 0
            for (index in 1 until states.size) {
                if (flareHapticCrossed(states[index - 1], states[index])) ticks += 1
            }
            val expected = ((case["expected"] as Map<*, *>)["ticks"] as Number).toInt()
            assertEquals(expected, ticks, "$id: ${case["why"]}")
        }
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/haptic-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/haptic-vectors.json not found above ${File(".").absolutePath}")
}
