package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals

/** FR-100: moments privacy in words, not SDK codes. */
class MomentsPrivacyTest {
    private fun vocabularyFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/moments-privacy.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/moments-privacy.json not found")
    }

    private fun names(values: List<Enum<*>>) = values.map { it.name.replaceFirstChar { c -> c.lowercase() } }

    @Test fun theKitEnumsAreTheSharedVocabulary() {
        val vocabulary = FlareJson.parse(vocabularyFile().readText()) as Map<*, *>
        assertEquals(vocabulary["visibility"], names(FlareMomentVisibility.entries))
        assertEquals(vocabulary["audienceMode"], names(FlareMomentAudienceMode.entries))
        assertEquals(vocabulary["historyRange"], names(FlareMomentHistoryRange.entries))
        assertEquals(
            listOf("friends", "public"),
            names(FlareMomentVisibility.entries.filter { flareMomentAudienceApplies(it) }),
        )
    }
}
