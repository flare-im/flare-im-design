package com.flare.im.ui

import java.io.File
import kotlin.test.*

class ScanVectorsTest {
    private fun table(name: String): Map<*, *> {
        var directory: File? = File(".").absoluteFile
        while (directory != null) {
            val candidate = File(directory, "spec/$name.json")
            if (candidate.isFile) return FlareJson.parse(candidate.readText()) as Map<*, *>
            directory = directory.parentFile
        }
        error("Missing shared scan vector table: $name")
    }

    @Test fun sharedGateVectorsExerciseCollectionSelectionSuppressionAndClockRegression() {
        val cases = table("scan-gate-vectors")["cases"] as List<*>
        assertTrue(cases.size >= 7)
        for (raw in cases) {
            val case = raw as Map<*, *>
            val gate = FlareScanHitGate()
            for ((index, item) in (case["steps"] as List<*>).withIndex()) {
                val step = item as Map<*, *>
                if (step["dismiss"] == true) { gate.dismiss(); continue }
                val result = if (step["select"] is String) gate.select(step["select"] as String)
                    else gate.observe((step["codes"] as List<*>).map { FlareScanCode(it as String) }, (step["tsMs"] as Number).toLong())
                val expected = step["expect"] as Map<*, *>
                val label = "${case["name"]}: step $index"
                when (expected["kind"]) {
                    "ignore" -> assertEquals(FlareScanHit.Ignore, result, label)
                    "lock" -> {
                        assertIs<FlareScanHit.Lock>(result, label)
                        assertEquals(expected["raw"], result.code.raw, label)
                        assertEquals(expected["ready"], result.ready, label)
                    }
                    "choose" -> {
                        assertIs<FlareScanHit.Choose>(result, label)
                        assertEquals(expected["raws"], result.codes.map { it.raw }, label)
                    }
                    else -> error("Unknown scan-gate vector")
                }
            }
        }
    }

    @Test fun sharedMarkerVectorsUseTheViewfinderBoundsAndSilentRefreshUsesThePagePredicate() {
        val views = table("scan-view-vectors")
        for (raw in views["markerBounds"] as List<*>) {
            val case = raw as Map<*, *>
            val bounds = flareScanMarkerBounds((case["corners"] as List<*>).map {
                val point = it as Map<*, *>; FlareScanPoint((point["x"] as Number).toDouble(), (point["y"] as Number).toDouble())
            })
            val expected = case["expect"] as Map<*, *>
            listOf("left" to bounds.left, "top" to bounds.top, "width" to bounds.width, "height" to bounds.height).forEach { (key, value) ->
                assertEquals((expected[key] as Number).toDouble(), value, 0.000001, "${case["name"]}: $key")
            }
        }
        for (raw in views["pluginRefresh"] as List<*>) {
            val case = raw as Map<*, *>
            assertEquals(case["expect"], flarePluginMayRefresh(case["visible"] == true, case["foreground"] == true,
                case["loading"] == true, case["refreshing"] == true, case["busy"] == true, case["interaction"] == true), case["name"] as String)
        }
    }
}
