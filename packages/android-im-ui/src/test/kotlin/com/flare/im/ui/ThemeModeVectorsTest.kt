package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared theme table (`spec/theme-mode-vectors.json`): the host holds the person's choice and the kit
 * resolves it. The same file is read by the Vue, Flutter and SwiftUI tests.
 */
class ThemeModeVectorsTest {
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/theme-mode-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/theme-mode-vectors.json not found")
    }

    @Test fun everyCaseResolvesTheSameWayHere() {
        val cases = (FlareJson.parse(vectorsFile().readText()) as Map<*, *>)["cases"] as List<*>
        assertEquals(FlareThemeMode.entries.size * 2, cases.size, "the shared table lost cases")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val mode = FlareThemeMode.entries.first { it.name.equals(case["mode"] as String, ignoreCase = true) }
            assertEquals(case["dark"], flareThemeIsDark(mode, case["systemDark"] as Boolean), id)
        }
    }

    @Test fun theStringsCarryTheThreeLabels() {
        val strings = FlareStrings()
        assertTrue(listOf(strings.themeSystem, strings.themeLight, strings.themeDark).none { it.isBlank() })
        assertEquals(listOf("跟随系统", "浅色", "深色"), listOf(strings.themeSystem, strings.themeLight, strings.themeDark))
    }
}
