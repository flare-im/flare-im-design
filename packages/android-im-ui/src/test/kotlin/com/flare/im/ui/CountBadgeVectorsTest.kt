package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * `spec/count-badge-vectors.json`, the table the four kits run: what a navigation item's count badge and a filter tab's
 * badge read ([flareCountBadgeText]), and when a filter tab draws one ([flareCountBadgeDrawn]).
 */
class CountBadgeVectorsTest {
    private val table = SpecTables.table("count-badge-vectors.json")

    @Test fun badgesReadAsTheSharedTableSays() {
        val rows = table.items("cases")
        assertTrue(rows.size >= 14, "the shared table lost cases: ${rows.size}")
        assertEquals(99, table.int("cap"))
        assertEquals("99+", table.str("overflow"))
        for (row in rows) {
            val id = row.str("id")!!
            val count = row.int("count")
            val more = row.bool("more") ?: false
            assertEquals(row.str("text"), flareCountBadgeText(count, more), "$id text")
            assertEquals(row.bool("drawn"), flareCountBadgeDrawn(count, more), "$id drawn")
            if (row["more"] == null) {
                // A host that passes no `more` gets the default.
                assertEquals(row.str("text"), flareCountBadgeText(count), "$id text by default")
                assertEquals(row.bool("drawn"), flareCountBadgeDrawn(count), "$id drawn by default")
            }
        }
    }

    @Test fun aNavigationBadgeAndAFilterTabTakeMoreWithoutAnyHostChange() {
        // The new field has a default: a host that writes neither still builds and reads the same.
        assertEquals(false, FlareApplicationNavigationBadge(count = 3).more)
        assertEquals(false, FlareFilterTabOption("requests", "申请", badge = 3).badgeMore)
        val more = FlareApplicationNavigationBadge(count = 5, more = true)
        assertEquals("99+", flareCountBadgeText(more.count, more.more))
    }
}
