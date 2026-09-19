package com.flare.im.ui

import java.io.File
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared locate-mark table (`spec/locate-highlight-vectors.json`) is the one rule four kits follow: how
 * long the mark lasts, how it fades, and what a reader who asked for less motion gets instead — which is the
 * same mark, held still, never nothing. Vue's stylesheet holds the same numbers and its own test checks them;
 * the Flutter and SwiftUI tests read this same file.
 */
class LocateHighlightVectorsTest {
    @Test fun theTableIsTheWindowThisKitWasBuiltWith() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        assertEquals(LOCATE_HIGHLIGHT_DURATION_MS.toDouble(), (table["durationMs"] as Number).toDouble())
    }

    @Test fun everyCaseResolvesTheSameWayHere() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = table["cases"] as List<*>
        assertTrue(cases.size >= 12, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val expected = case["expected"] as Map<*, *>
            val mark = locateHighlight(
                (case["elapsedMs"] as Number).toFloat(),
                case["reducedMotion"] as Boolean,
            )
            assertEquals(expected["marked"], mark.marked, "$id marked")
            for ((field, actual) in listOf("alpha" to mark.alpha, "spread" to mark.spread)) {
                val want = (expected[field] as Number).toDouble()
                assertTrue(abs(actual - want) <= 0.001, "$id $field: expected $want, got $actual")
            }
        }
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/locate-highlight-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/locate-highlight-vectors.json not found above ${File(".").absolutePath}")
}
