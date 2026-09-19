package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/**
 * The shared typing table (`spec/typing-vectors.json`), `roster` half: facts about peers in, the people
 * typing out. The Vue, Flutter and SwiftUI kits run the same file through the same driver.
 */
class TypingRosterVectorsTest {
    @Test fun expiresABeliefOnTheTablesTtl() {
        val rules = (FlareJson.parse(vectorsFile().readText()) as Map<*, *>)["rules"] as Map<*, *>
        assertEquals(FLARE_TYPING_PEER_TTL_MS, (rules["peerTtlMs"] as Number).toInt())
    }

    @Test fun everyScriptBelievesTheSameThingHere() = runEveryScript(0L)

    /** The same scripts with the clock where a real one is — see [TypingSignalVectorsTest]. */
    @Test fun everyScriptBelievesTheSameThingWithARealClock() = runEveryScript(1_767_000_000_000L)

    private fun runEveryScript(base: Long) {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val roster = table["roster"] as Map<*, *>
        val selfId = roster["selfId"] as String
        val cases = roster["cases"] as List<*>
        assertTrue(cases.size >= 22, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val name = case["name"] as String
            val watch = case["watch"] as String
            val steps = (case["steps"] as List<*>).map { it as Map<*, *> }
            val state = FlareTypingRoster(selfId)
            val seen = mutableListOf<Pair<Long, List<String>>>()
            var last: List<String> = emptyList()
            val ids = steps.map { it["conversationId"] as? String ?: "" }.toSet()

            fun record(at: Long) {
                val typers = state.typers(watch)
                if (typers == last) return
                last = typers
                seen += (at - base) to typers
            }
            fun snapshot(): List<List<String>> = ids.sorted().map { state.typers(it) }
            fun advance(to: Long) {
                // Beliefs expire at their own deadline, so the record carries that instant, not the step's.
                // The bound is not decoration: this loop asks the rule when to prune next, so a rule that
                // stops making progress would spin here forever, and a harness that hangs is worse than one
                // that fails.
                var guard = 0
                while (true) {
                    guard += 1
                    assertTrue(guard < steps.size + 64, "$name: prune made no progress")
                    val next = state.nextExpiry ?: return
                    if (next > to) return
                    val before = snapshot()
                    state.prune(next)
                    assertNotEquals(before, snapshot(), "$name: prune at $next dropped nothing")
                    record(next)
                }
            }

            for (step in steps) {
                val at = base + (step["at"] as Number).toLong()
                advance(at)
                when (step["op"] as String) {
                    "started" -> state.started(step["conversationId"] as? String ?: "", step["userId"] as? String ?: "", at)
                    "stopped" -> state.stopped(step["conversationId"] as? String ?: "", step["userId"] as? String ?: "")
                    "replaced" -> state.replaced(
                        step["conversationId"] as? String ?: "",
                        (step["userIds"] as List<*>).map { it as String },
                        at,
                    )
                    "sent" -> state.sent(step["conversationId"] as? String ?: "", step["senderId"] as? String ?: "")
                }
                record(at)
            }
            advance(base + (case["endAt"] as Number).toLong())

            val expected = (case["expect"] as List<*>).map {
                val e = it as Map<*, *>
                (e["at"] as Number).toLong() to (e["typers"] as List<*>).map { id -> id as String }
            }
            assertEquals(expected, seen, "$name @ base=$base")
            if (case.containsKey("nextExpiryAtEnd")) {
                val declared = (case["nextExpiryAtEnd"] as Number?)?.toLong()
                assertEquals(declared, state.nextExpiry?.minus(base), "$name next expiry")
            }
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
