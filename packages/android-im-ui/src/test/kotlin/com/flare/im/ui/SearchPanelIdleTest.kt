package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** `flareSearchIdle` keeps Vue `FlareSearchPanel.isIdle`: no words, the first type and no time range is not a search. */
class SearchPanelIdleTest {
    @Test fun onlyNoWordsTheFirstTypeAndNoRangeRestIdle() {
        assertTrue(flareSearchIdle(FlareSearchCriteria("  ", "all"), "all"))
        assertTrue(flareSearchIdle(FlareSearchCriteria("", ""), "all"))
        assertFalse(flareSearchIdle(FlareSearchCriteria("hi", "all"), "all"))
        assertFalse(flareSearchIdle(FlareSearchCriteria("", "image"), "all"))
        assertFalse(flareSearchIdle(FlareSearchCriteria("", "all", fromTime = 1L), "all"))
    }
}
