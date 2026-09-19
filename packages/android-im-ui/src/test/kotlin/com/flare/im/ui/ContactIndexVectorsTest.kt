package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

/**
 * FR-044: one index letter per character, on all four kits. Vue and SwiftUI read the platform's pinyin
 * collation; Flutter and Compose read the table generated from it. A kit that disagrees here has a defect,
 * not a dialect — 曾 was Z on Flutter and C everywhere else for three rounds because nothing compared them.
 */
class ContactIndexVectorsTest {
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/contact-index-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/contact-index-vectors.json not found above ${File(".").absolutePath}")
    }

    /** The table is flat strings; a full JSON parser is not worth a dependency for two maps. */
    private fun section(text: String, name: String): Map<String, String> {
        val start = text.indexOf("\"$name\"").let { text.indexOf('{', it) + 1 }
        val end = text.indexOf('}', start)
        return text.substring(start, end).split(",").mapNotNull { entry ->
            val pair = entry.split(":").map { it.trim().trim('"') }
            if (pair.size == 2 && pair[0].isNotEmpty()) pair[0] to pair[1] else null
        }.toMap()
    }

    @Test fun readsEveryCharacterTheWayTheSharedTableSays() {
        val text = vectorsFile().readText()
        val letters = section(text, "letters")
        assertEquals(55, letters.size, "the table lost characters")
        val wrong = letters.entries.mapNotNull { (character, letter) ->
            val actual = contactIndexLetter(character, null)
            if (actual == letter) null else "$character: $actual (table says $letter)"
        }
        assertEquals(emptyList(), wrong)
    }

    @Test fun stillReadsTheCharactersIcuUsedToMissBelowApi29() {
        val groups = section(vectorsFile().readText(), "groups")
        for (character in groups.getValue("formerlyMissing")) {
            assertNotEquals(CONTACT_INDEX_OTHER, contactIndexLetter(character.toString(), null), character.toString())
        }
    }
}
