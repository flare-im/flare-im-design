package com.flare.im.ui
import org.junit.Assert.*
import org.junit.Test
class SearchTimeRangeTest {
    @Test fun inclusiveBoundsAndSnapshotIdentity() {
        assertTrue(FlareSearchRangeOption("r", "range", 0, 100).isValid)
        assertFalse(FlareSearchRangeOption("r", "range", 2, 1).isValid)
        assertFalse(FlareSearchRangeOption("r", "range", -1).isValid)
        assertNotEquals(FlareSearchCriteria("x", "file", toTime = 100), FlareSearchCriteria("x", "file", toTime = 101))
    }
}
