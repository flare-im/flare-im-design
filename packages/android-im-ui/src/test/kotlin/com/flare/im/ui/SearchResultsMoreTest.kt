package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A search that takes a limit and returns no count can say a group is truncated ([SearchResultGroup.hasMore])
 * but not by how much. The row is then the plain "更多"; the counted "查看全部 N" is kept for a known total,
 * which wins when both are given. A count is never made up to get the row.
 */
class SearchResultsMoreTest {
    private val strings = FlareStrings()
    private val item = SearchResultItem(id = "u1", kind = SearchResultKind.Contact, title = "周屿")

    @Test fun aKnownTotalIsCountedAndAnUnknownOneIsNot() {
        assertEquals(strings.viewAll(9), flareSearchMoreText(SearchResultGroup(SearchResultKind.Contact, "联系人", listOf(item), total = 9, hasMore = true), strings))
        assertEquals(strings.more, flareSearchMoreText(SearchResultGroup(SearchResultKind.Contact, "联系人", listOf(item), hasMore = true), strings))
        // A total that is not more than what is shown counts nothing.
        assertEquals(strings.more, flareSearchMoreText(SearchResultGroup(SearchResultKind.Contact, "联系人", listOf(item), total = 1, hasMore = true), strings))
    }
}
