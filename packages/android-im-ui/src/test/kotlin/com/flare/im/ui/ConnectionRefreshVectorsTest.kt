package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared reconnect table (`spec/reconnect-refresh-vectors.json`): connection phases in, the work the
 * transition creates out. The Vue, Flutter and SwiftUI kits run the same file.
 */
class ConnectionRefreshVectorsTest {
    @Test fun everyTransitionAsksForTheSameThingHere() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = table["cases"] as List<*>
        assertTrue(cases.size >= 17, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val name = case["name"] as String
            val refresh = FlareConnectionRefresh()
            val seen = (case["phases"] as List<*>).map { phase ->
                refresh.observe(
                    FlareConnectionPhase.entries.first { it.name.equals(phase as String, ignoreCase = true) },
                )
            }
            val expected = (case["expect"] as List<*>).map {
                val e = it as Map<*, *>
                FlareReconnectWork(
                    dropStaleBeliefs = e["dropStaleBeliefs"] as Boolean,
                    resubscribe = e["resubscribe"] as Boolean,
                    reread = e["reread"] as Boolean,
                )
            }
            assertEquals(expected, seen, name)
        }
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/reconnect-refresh-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/reconnect-refresh-vectors.json not found above ${File(".").absolutePath}")
}
