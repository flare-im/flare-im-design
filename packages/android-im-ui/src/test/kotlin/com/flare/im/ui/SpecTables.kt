package com.flare.im.ui

import java.io.File

/**
 * The shared tables the four kits run (`spec/<name>`) and the shared copy source (`strings/en.json`), found by walking
 * up from the test's working directory. Gradle declares `spec/` as a test input, so a changed table reruns the tests.
 */
internal object SpecTables {
    private fun find(relative: String): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, relative)
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("$relative not found above ${File(".").absolutePath}")
    }

    fun table(name: String): Map<*, *> = FlareJson.parse(find("spec/$name").readText()) as Map<*, *>

    /** A table of the shared copy source (`strings/<name>`), such as the function fields' `en-formats.json`. */
    fun strings(name: String): Map<*, *> = FlareJson.parse(find("strings/$name").readText()) as Map<*, *>

    private val shared: Map<*, *> by lazy { FlareJson.parse(find("strings/en.json").readText()) as Map<*, *> }

    /** One field of the shared copy source in [language] ("zh" or "en"). */
    fun copy(key: String, language: String): String =
        ((shared[key] as? Map<*, *>)?.get(language) as? String) ?: error("strings/en.json has no $language for $key")
}

internal fun Map<*, *>.str(key: String): String? = this[key] as? String
internal fun Map<*, *>.bool(key: String): Boolean? = this[key] as? Boolean
internal fun Map<*, *>.int(key: String): Int? = (this[key] as? Number)?.toInt()
internal fun Map<*, *>.long(key: String): Long? = (this[key] as? Number)?.toLong()
internal fun Map<*, *>.obj(key: String): Map<*, *>? = this[key] as? Map<*, *>
internal fun Map<*, *>.items(key: String): List<Map<*, *>> = (this[key] as? List<*>).orEmpty().map { it as Map<*, *> }
