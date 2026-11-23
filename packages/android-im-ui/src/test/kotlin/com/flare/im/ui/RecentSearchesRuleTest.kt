package com.flare.im.ui

import kotlin.test.assertEquals
import kotlin.test.Test

/** `flareRememberSearch` keeps the Vue kit's rule: trimmed, newest first, no repeats, capped. */
class RecentSearchesRuleTest {
    @Test fun aUsedTermGoesFirstOnceAndTheOldestFallOff() {
        assertEquals(listOf("b", "a"), flareRememberSearch(listOf("a"), "  b "))
        assertEquals(listOf("a", "b"), flareRememberSearch(listOf("b", "a"), "a"))
        assertEquals(listOf("c", "b"), flareRememberSearch(listOf("b", "a"), "c", max = 2))
        assertEquals(listOf("a"), flareRememberSearch(listOf("a"), "   "))
    }
}
