package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared draft table (`spec/draft-vectors.json`): the composer's edits in, the writes this client owes
 * the core out. The Vue, Flutter and SwiftUI kits run the same file through the same driver.
 */
class DraftAutosaveVectorsTest {
    @Test fun usesTheTablesDelay() {
        val rules = (FlareJson.parse(vectorsFile().readText()) as Map<*, *>)["rules"] as Map<*, *>
        assertEquals(FLARE_DRAFT_SAVE_DELAY_MS, (rules["saveDelayMs"] as Number).toInt())
    }

    @Test fun everyScriptWritesTheSameThingHere() = runEveryScript(0L)

    /** The same scripts with the clock where a real one is — see [TypingSignalVectorsTest]. */
    @Test fun everyScriptWritesTheSameThingWithARealClock() = runEveryScript(1_767_000_000_000L)

    private fun runEveryScript(base: Long) {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = table["cases"] as List<*>
        assertTrue(cases.size >= 23, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val name = case["name"] as String
            val drafts = FlareDraftAutosave()
            val saves = mutableListOf<FlareDraftSave>()
            for (rawStep in case["steps"] as List<*>) {
                val step = rawStep as Map<*, *>
                val at = base + (step["at"] as Number).toLong()
                saves += drafts.tick(at)
                val cid = step["conversationId"] as? String ?: ""
                val text = step["text"] as? String ?: ""
                when (step["op"] as String) {
                    "seed" -> drafts.seed(cid, text)
                    "edit" -> saves += drafts.edit(cid, text, at)
                    "send" -> saves += drafts.send(cid, at)
                    "restore" -> saves += drafts.restore(cid, text, at)
                    "leave" -> saves += drafts.leave(at)
                }
            }
            saves += drafts.tick(base + (case["endAt"] as Number).toLong())
            val expected = (case["expect"] as List<*>).map {
                val e = it as Map<*, *>
                FlareDraftSave(e["conversationId"] as String, e["text"] as String, base + (e["at"] as Number).toLong())
            }
            assertEquals(expected, saves, "$name @ base=$base")
        }
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/draft-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/draft-vectors.json not found above ${File(".").absolutePath}")
}
