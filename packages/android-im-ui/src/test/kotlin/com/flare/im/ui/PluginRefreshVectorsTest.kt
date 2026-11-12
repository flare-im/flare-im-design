package com.flare.im.ui

import java.io.File
import kotlin.test.*

class PluginRefreshVectorsTest {
    private fun table(name: String): Map<*, *> {
        var directory: File? = File(".").absoluteFile
        while (directory != null) {
            val candidate = File(directory, "spec/$name.json")
            if (candidate.isFile) return FlareJson.parse(candidate.readText()) as Map<*, *>
            directory = directory.parentFile
        }
        error("Missing shared plugin refresh vector table: $name")
    }

    @Test fun silentRefreshUsesThePagePredicate() {
        for (raw in table("plugin-refresh-vectors")["pluginRefresh"] as List<*>) {
            val case = raw as Map<*, *>
            assertEquals(case["expect"], flarePluginMayRefresh(case["visible"] == true, case["foreground"] == true,
                case["loading"] == true, case["refreshing"] == true, case["busy"] == true, case["interaction"] == true), case["name"] as String)
        }
    }
}
