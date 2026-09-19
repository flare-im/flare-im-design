package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared markdown table (`spec/markdown-preview-vectors.json`): what a markdown message reads as in a
 * conversation row, a reply strip or a quote. Vue is the reference implementation; this kit answers to the
 * same file.
 */
class MarkdownPreviewVectorsTest {
    @Test fun everyCaseReadsTheSameHere() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = table["cases"] as List<*>
        assertTrue(cases.size >= 20, "the shared table lost cases: ${cases.size}")
        val strings = mapOf(
            "zh-CN" to FlareStrings(),
            "en-US" to FlareStrings {
                previewImage = "[Image]"
                previewImageNamed = { "[Image] $it" }
            },
        )
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val markdown = case["markdown"] as String
            val expected = case["expected"] as Map<*, *>
            for ((locale, table2) in strings) {
                assertEquals(expected[locale], flareMarkdownToPlainText(markdown, table2), "$id in $locale")
            }
        }
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun vectorsFile(): File {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/markdown-preview-vectors.json")
        if (candidate.isFile) return candidate
        dir = dir.parentFile
    }
    error("spec/markdown-preview-vectors.json not found above ${File(".").absolutePath}")
}
