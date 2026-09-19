package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** FR-057: a failed refresh over rows worth keeping does not wipe what someone was reading. */
class ViewStateVectorsTest {
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/view-state-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/view-state-vectors.json not found")
    }

    @Test fun presentationMatchesTheSharedTable() {
        val cases = (FlareJson.parse(vectorsFile().readText()) as Map<*, *>)["cases"] as List<*>
        assertTrue(cases.size >= 10, "the shared table lost cases")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val status = FlareApplicationViewStatus.entries.first { it.name.equals(case["status"] as String, ignoreCase = true) }
            val presentation = flareViewPresentation(status, case["stale"] as Boolean)
            assertEquals(case["presentation"], presentation.name.replaceFirstChar { it.lowercase() }, case["id"] as String)
        }
    }
}
