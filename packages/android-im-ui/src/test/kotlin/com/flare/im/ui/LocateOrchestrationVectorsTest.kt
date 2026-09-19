package com.flare.im.ui

import java.io.File
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared locate table (`spec/locate-orchestration-vectors.json`) is the one trip four kits make when a
 * quote names a message that is not loaded. Each case scripts a run; the expectations count the whole trip,
 * so a kit that asks or pages a different number of times fails even when it lands on the same answer.
 */
class LocateOrchestrationVectorsTest {
    @Test fun theTableIsTheBudgetThisKitWasBuiltWith() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        assertEquals(FLARE_LOCATE_MAX_PAGES, (table["maxPages"] as Number).toInt())
        assertEquals(FLARE_LOCATE_SETTLE_ATTEMPTS, (table["settleAttempts"] as Number).toInt())
    }

    @Test fun everyRunEndsTheSameWayHere() = runBlocking {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = table["cases"] as List<*>
        assertTrue(cases.size >= 13, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val historyPages = (case["historyPages"] as Number).toInt()
            val foundAfterPages = (case["foundAfterPages"] as Number?)?.toInt()
            val failAtPage = (case["failAtPage"] as Number?)?.toInt()
            val cancelAfterShows = (case["cancelAfterShows"] as Number?)?.toInt()
            val visibleFrom = (case["visibleFromShow"] as Number?)?.toInt() ?: 1
            var pages = 0
            var shows = 0
            val outcome = flareLocateMessage(
                showInList = {
                    shows += 1
                    foundAfterPages != null && pages >= foundAfterPages && shows >= visibleFrom
                },
                hasOlder = { pages < historyPages },
                readOlder = {
                    pages += 1
                    failAtPage == null || pages != failAtPage
                },
                settle = {},
                isCurrent = { cancelAfterShows == null || shows < cancelAfterShows },
            )
            val expected = case["expected"] as Map<*, *>
            assertEquals(expected["outcome"], outcome.name.replaceFirstChar { it.lowercase() }, "$id outcome")
            assertEquals((expected["pagesRead"] as Number).toInt(), pages, "$id pages read")
            assertEquals((expected["showCalls"] as Number).toInt(), shows, "$id asks")
        }
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/locate-orchestration-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/locate-orchestration-vectors.json not found above ${File(".").absolutePath}")
}
