package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Where a located row lands. Vue, Flutter and SwiftUI centre it; this kit used to leave it at the top of
 * the viewport, so the same tap read differently on Android (FR-113). The arithmetic is here; the row
 * actually arriving in the middle is asserted on a device (`androidTest/MessageQuoteInteractionTest`).
 */
class LocatedRowPlacementTest {

    @Test fun aRowIsOffsetByHalfTheSpaceAroundIt() {
        // A 200 px row in a 1000 px viewport leaves 800 px: 400 above it, 400 below.
        assertEquals(-400, centeredRowOffset(viewportSize = 1000, rowSize = 200))
        assertEquals(-450, centeredRowOffset(viewportSize = 1000, rowSize = 100))
    }

    @Test fun aRowThatFillsTheViewportStartsAtTheTop() {
        // Pushing it down would only hide its beginning, which is the part the reader came back for.
        assertEquals(0, centeredRowOffset(viewportSize = 800, rowSize = 800))
        assertEquals(0, centeredRowOffset(viewportSize = 800, rowSize = 1600))
    }

    @Test fun anUnmeasurableRowIsNotOffset() {
        assertEquals(0, centeredRowOffset(viewportSize = 1000, rowSize = 0))
        assertEquals(0, centeredRowOffset(viewportSize = 0, rowSize = 0))
    }

    @Test fun theRowsOwnHeightWinsOverTheAverage() {
        assertEquals(240, estimatedRowSize(visibleSizes = listOf(100, 120, 140), exact = 240))
    }

    @Test fun aRowNotOnScreenIsEstimatedFromTheRowsThatAre() {
        assertEquals(120, estimatedRowSize(visibleSizes = listOf(100, 120, 140), exact = null))
        // Nothing drawn yet: aim at the top and let the correction pass do the centring.
        assertEquals(0, estimatedRowSize(visibleSizes = emptyList(), exact = null))
        assertEquals(0, estimatedRowSize(visibleSizes = emptyList(), exact = 0))
    }
}
