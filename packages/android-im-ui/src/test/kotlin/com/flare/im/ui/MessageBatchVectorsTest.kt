package com.flare.im.ui

import java.io.File
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

    @Test fun availabilityMatchesTheSharedTable() {
        val cases = table()["cases"] as List<*>
        assertTrue(cases.size >= 8, "the shared table lost cases")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val available = messageBatchActionsAvailable(
                ids((case["selected"] as Number).toInt()),
                capabilities((case["capabilities"] as List<*>).map { it as String }),
                case["busy"] as Boolean,
            )
            assertEquals(case["available"], available.map { it.wireName() }, case["id"] as String)
        }
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
