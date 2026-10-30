package com.flare.im.ui

import java.io.File
import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * FR-034: the message batch toolbar answers the same question the conversation one does — what may a host
 * do with this selection right now. `spec/message-batch-vectors.json` is the answer, on four kits.
 */
class MessageBatchVectorsTest {
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/message-batch-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/message-batch-vectors.json not found")
    }

    private fun table(): Map<*, *> = FlareJson.parse(vectorsFile().readText()) as Map<*, *>

    private fun capabilities(names: List<String>) = MessageBatchCapabilities(
        forwardEach = "forwardEach" in names,
        forwardMerged = "forwardMerged" in names,
        pin = "pin" in names,
        pinSelf = "pinSelf" in names,
        delete = "delete" in names,
    )

    private fun ids(count: Int) = List(count) { "m$it" }

    /** The table writes the actions as the contract's wire names; Kotlin spells its enum in PascalCase. */
    private fun MessageBatchAction.wireName() = name.replaceFirstChar { it.lowercase() }

    private fun selection(case: Map<*, *>): List<String> =
        (case["selectedIds"] as List<*>?)?.map { it as String } ?: ids((case["selected"] as Number).toInt())

    private fun unforwardable(case: Map<*, *>): Set<String> =
        (case["unforwardable"] as List<*>?)?.map { it as String }?.toSet() ?: emptySet()

    @Test fun availabilityMatchesTheSharedTable() {
        val cases = table()["cases"] as List<*>
        assertTrue(cases.size >= 14, "the shared table lost cases")
        for (raw in cases) {
            val case = raw as Map<*, *>
            assertEquals((case["selected"] as Number).toInt(), selection(case).size, case["id"] as String)
            val available = messageBatchActionsAvailable(
                selection(case),
                capabilities((case["capabilities"] as List<*>).map { it as String }),
                case["busy"] as Boolean,
                unforwardable(case),
            )
            assertEquals(case["available"], available.map { it.wireName() }, case["id"] as String)
        }
    }

    @Test fun theReportedIdsAndTheUnforwardableCountAreTheTables() {
        val cases = (table()["cases"] as List<*>).map { it as Map<*, *> }.filter { it["reports"] != null }
        assertTrue(cases.size >= 6, "the shared table lost the forward cases")
        for (case in cases) {
            for ((name, reported) in case["reports"] as Map<*, *>) {
                val action = MessageBatchAction.entries.first { it.wireName() == name }
                assertEquals(reported, messageBatchActionIds(action, selection(case), unforwardable(case)), "${case["id"]} $name")
            }
            assertEquals((case["unforwardableCount"] as Number).toInt(), messageBatchUnforwardableCount(selection(case), unforwardable(case)),
                case["id"] as String)
        }
        val forward = table()["forward"] as Map<*, *>
        assertEquals(forward["actions"], MessageBatchAction.entries.filter { it.forwards }.map { it.wireName() })
    }

    @Test fun theForwardKeysTurnOffWhenTooFewForwardableIdsAreLeft() {
        val everything = MessageBatchCapabilities(forwardEach = true, forwardMerged = true, delete = true)
        val controls = messageBatchToolbarControls(FlareStrings(), listOf("a", "b"), 4, everything, busy = false, unforwardableIds = setOf("a"))
            .associate { it.id to it.enabled }
        assertEquals(true, controls[MessageBatchAction.ForwardEach.name])
        assertEquals(false, controls[MessageBatchAction.ForwardMerged.name], "one forwardable id cannot merge")
        assertEquals(true, controls[MessageBatchAction.Delete.name])
        assertEquals("1 条不支持转发", messageBatchUnforwardableText(1, FlareStrings(), Locale.SIMPLIFIED_CHINESE))
        val english = flareStringsEnglish()
        assertEquals("1 message can't be forwarded", messageBatchUnforwardableText(1, english, Locale.US))
        assertEquals("2 messages can't be forwarded", messageBatchUnforwardableText(2, english, Locale.US))
    }

    @Test fun theDeclaredOrderAndMinimumsAreTheTables() {
        assertEquals(table()["order"], MessageBatchAction.entries.map { it.wireName() })
        assertEquals(
            table()["minimumSelection"],
            flareMessageBatchMinimumSelection.entries.associate { (action, minimum) -> action.wireName() to minimum.toDouble() },
        )
    }

    @Test fun nothingIsAllowedWithoutCapabilities() {
        assertEquals(emptyList(), messageBatchActionsAvailable(ids(3), null, busy = false))
    }

    @Test fun theStringsCarryTheNewKeys() {
        val strings = FlareStrings()
        assertEquals(listOf("置顶", "仅自己置顶", "清除选择"), listOf(strings.messageBatchPin, strings.messageBatchPinSelf, strings.messageBatchClear))
    }
}
