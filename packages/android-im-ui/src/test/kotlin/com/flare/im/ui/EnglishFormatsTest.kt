package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The function fields of [FlareStrings] against `strings/en-formats.json`: the English preset says what the table says
 * in English (plural forms included), the defaults what it says in Chinese, and every function field the kit declares
 * has a case — so a new count, name or kind field cannot ship in Chinese only under the English preset.
 */
class EnglishFormatsTest {
    private val table = SpecTables.strings("en-formats.json")
    private val cases = table.items("cases").filter { (it["kits"] as List<*>).contains("android") }

    /** The kit's function fields, by name: every getter of [FlareStrings] that returns a function. */
    private val functionFields: Set<String> = FlareStrings::class.java.methods
        .filter { it.parameterCount == 0 && it.name.startsWith("get") && Function::class.java.isAssignableFrom(it.returnType) }
        .map { it.name.removePrefix("get").replaceFirstChar(Char::lowercaseChar) }
        .toSet()

    private fun argument(raw: Any?): Any? = when (raw) {
        is Number -> raw.toInt()
        is Map<*, *> -> when {
            raw["kind"] != null -> FlarePermissionKind.entries.first { it.name.equals(raw["kind"] as String, ignoreCase = true) }
            raw["state"] != null -> FlarePermissionState.entries.first { it.name.equals(raw["state"] as String, ignoreCase = true) }
            else -> error("unknown argument $raw")
        }
        else -> raw
    }

    @Suppress("UNCHECKED_CAST")
    private fun call(strings: FlareStrings, field: String, args: List<Any?>): String {
        val getter = FlareStrings::class.java.getMethod("get" + field.replaceFirstChar(Char::uppercaseChar))
        val fn = getter.invoke(strings)
        return when (args.size) {
            1 -> (fn as (Any?) -> Any?)(args[0])
            2 -> (fn as (Any?, Any?) -> Any?)(args[0], args[1])
            3 -> (fn as (Any?, Any?, Any?) -> Any?)(args[0], args[1], args[2])
            else -> error("$field: ${args.size} arguments")
        } as String
    }

    @Test fun everyCaseReadsAsTheTableSaysInBothLanguages() {
        assertTrue(cases.isNotEmpty())
        val english = flareStringsEnglish()
        val chinese = FlareStrings()
        for (case in cases) {
            val field = case.str("field")!!
            val args = (case["args"] as List<*>).map(::argument)
            assertEquals(case.str("en"), call(english, field, args), "$field $args en")
            assertEquals(case.str("zh"), call(chinese, field, args), "$field $args zh")
        }
    }

    @Test fun everyFunctionFieldHasAnEnglishCase() {
        assertTrue(functionFields.size >= 40, "found ${functionFields.size} function fields")
        val covered = cases.map { it.str("field")!! }.toSet()
        assertEquals(emptySet(), functionFields - covered, "function fields with no case in strings/en-formats.json")
        assertEquals(emptySet(), covered - functionFields, "cases naming a field the kit does not declare")
        for (field in covered) {
            assertTrue(cases.any { it.str("field") == field && it.str("en") != it.str("zh") }, "$field: no case shows its English")
        }
    }

    /** The conversation list under the English preset: a merged forward's count reads in English, singular at 1. */
    @Test fun aMergedForwardPreviewReadsInEnglish() {
        val record = { n: Int -> FlareForwardContent(List(n) { FlareForwardItem("A", plainText = "$it") }, mode = FlareForwardMode.Merged) }
        assertEquals("[Forward] 3 messages", flareMessagePreviewText(record(3), flareStringsEnglish()))
        assertEquals("[转发] 3 条消息", flareMessagePreviewText(record(3), FlareStrings()))
    }
}
