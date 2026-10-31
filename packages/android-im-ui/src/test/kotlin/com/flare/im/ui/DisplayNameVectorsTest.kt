package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * `spec/display-name-vectors.json`, the table the four kits run: the id tail ([flareIdTail], which the plugin view's
 * unresolved user name reads too) and the text of every projected name in Chinese (the defaults) and English
 * ([flareStringsEnglish]).
 */
class DisplayNameVectorsTest {
    private val table = SpecTables.table("display-name-vectors.json")

    @Test fun idTailsFollowTheSharedTable() {
        val rows = table.items("idTail")
        assertTrue(rows.size >= 12, "the shared table lost cases: ${rows.size}")
        for (row in rows) {
            val id = row.str("id")!!
            assertEquals(row.str("output"), flareIdTail(row.str("input")!!), id)
            assertEquals(row.str("output"), PluginViewFormat.fallbackName(row.str("input")!!), "$id fallback name")
        }
    }

    @Test fun namesReadAsTheSharedTableSaysInBothLanguages() {
        val rows = table.items("text")
        assertTrue(rows.size >= 24, "the shared table lost cases: ${rows.size}")
        for (row in rows) {
            val id = row.str("id")!!
            val name = FlareDisplayName.fromMap(row["name"] as Map<*, *>) ?: error("$id: not a display name")
            val text = row["text"] as Map<*, *>
            assertEquals(text["zh-CN"], flareDisplayNameText(name, FlareStrings()), "$id zh-CN")
            assertEquals(text["en-US"], flareDisplayNameText(name, flareStringsEnglish()), "$id en-US")
        }
    }

    @Test fun readsTheWireAndRefusesWhatIsNotAName() {
        assertEquals(
            FlareDisplayName.Named("Alice", FlareDisplayNameSource.Alias),
            FlareDisplayName.fromJson("""{"kind":"named","text":"Alice","source":"alias"}"""),
        )
        assertEquals(
            FlareDisplayName.Members(listOf("张三", "李四"), 12),
            FlareDisplayName.fromJson("""{"kind":"members","names":["张三","李四"],"total":12}"""),
        )
        assertEquals(
            FlareDisplayName.Unnamed(FlareDisplayNameEntity.Person, "9876"),
            FlareDisplayName.fromJson("""{"kind":"unnamed","entity":"person","idTail":"9876"}"""),
        )
        assertNull(FlareDisplayName.fromJson("""{"kind":"unnamed","entity":"robot","idTail":""}"""))
        assertNull(FlareDisplayName.fromJson("""{"kind":"nickname","text":"x"}"""))
        assertNull(FlareDisplayName.fromJson("not json"))
    }

    @Test fun aHostsOwnWordsWin() {
        val strings = FlareStrings { displayNameUser = { "访客 $it" } }
        assertEquals("访客 9876", flareDisplayNameText(FlareDisplayName.Unnamed(FlareDisplayNameEntity.Person, "9876"), strings))
    }
}
