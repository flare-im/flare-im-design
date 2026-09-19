package com.flare.im.ui
import kotlin.test.*
class SearchHighlightTest {
    @Test fun unicodeOffsetsAndLiteralQueries() {
        listOf("İX" to "x", "a.b[a.b" to "a.b", "👋HELLO" to "hello", "abc" to "  ").forEach { (text, query) ->
            assertEquals(text, highlightQuery(text, query, FlareColors.Light).text)
        }
        val result = highlightQuery("İX", "x", FlareColors.Light)
        assertEquals(1, result.spanStyles.single().start)
        assertEquals(2, result.spanStyles.single().end)
    }
}
