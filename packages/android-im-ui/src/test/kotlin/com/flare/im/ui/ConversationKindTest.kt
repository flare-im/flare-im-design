package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals

/** FR-056: one conversation-kind vocabulary for every kit and every component. */
class ConversationKindTest {
    private fun vocabularyFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/conversation-kind.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/conversation-kind.json not found")
    }

    @Test fun theKitEnumIsTheSharedVocabulary() {
        val kinds = (FlareJson.parse(vocabularyFile().readText()) as Map<*, *>)["kinds"]
        assertEquals(kinds, FlareConversationKind.entries.map { it.name.replaceFirstChar { c -> c.lowercase() } })
    }
}
