package com.flare.im.ui

import java.io.File
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared swipe-to-reply table (`spec/swipe-reply-vectors.json`) is the one rule three kits follow:
 * which direction counts, when the list's own scrolling wins instead, how far the row follows the finger,
 * and where the gesture arms. The same file is read by the Flutter and SwiftUI tests, so a number that
 * drifts on this platform fails on this platform alone.
 */
class SwipeReplyVectorsTest {
    @Test fun theTableIsTheGeometryThisKitWasBuiltWith() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        assertEquals(SWIPE_REPLY_ARM_DISTANCE.toDouble(), (table["armDistance"] as Number).toDouble())
        assertEquals(SWIPE_REPLY_MAX_TRAVEL.toDouble(), (table["maxTravel"] as Number).toDouble())
    }

    @Test fun everyCaseResolvesTheSameWayHere() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = table["cases"] as List<*>
        assertTrue(cases.size >= 19, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val expected = case["expected"] as Map<*, *>
            val gesture = swipeReplyGesture(
                (case["dx"] as Number).toFloat(),
                (case["dy"] as Number).toFloat(),
                case["rtl"] as Boolean,
            )
            val travel = (expected["travel"] as Number).toDouble()
            assertTrue(
                abs(gesture.travel - travel) <= 0.001,
                "$id travel: expected $travel, got ${gesture.travel}",
            )
            assertEquals(expected["armed"], gesture.armed, "$id armed")
        }
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/swipe-reply-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/swipe-reply-vectors.json not found above ${File(".").absolutePath}")
}
