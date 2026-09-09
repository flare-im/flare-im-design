package com.flare.im.ui
import kotlin.test.Test
import kotlin.test.assertEquals
class LayoutPolicyTest {
    @Test fun deviceBoundaries() {
        assertEquals(1, FlareLayoutPolicy.paneCount(320f, true, 1f))
        assertEquals(1, FlareLayoutPolicy.paneCount(719f, true, 1f))
        assertEquals(2, FlareLayoutPolicy.paneCount(720f, true, 1f))
        assertEquals(2, FlareLayoutPolicy.paneCount(1099f, true, 1f))
        assertEquals(3, FlareLayoutPolicy.paneCount(1100f, true, 1f))
        assertEquals(2, FlareLayoutPolicy.paneCount(1100f, false, 1f))
        assertEquals(1, FlareLayoutPolicy.paneCount(720f, true, 2f))
        assertEquals(1, FlareLayoutPolicy.paneCount(1040f, true, 2f))
        assertEquals(2, FlareLayoutPolicy.paneCount(1041f, true, 2f))
        assertEquals(2, FlareLayoutPolicy.paneCount(1100f, true, 2f))
        assertEquals(2, FlareLayoutPolicy.paneCount(1341f, true, 2f))
        assertEquals(3, FlareLayoutPolicy.paneCount(1342f, true, 2f))
        assertEquals(3, FlareLayoutPolicy.paneCount(1440f, true, 3f))
    }
    @Test fun customColumnsReserveChat() { assertEquals(2, FlareLayoutPolicy.paneCount(1100f, true, 1f, 600f, 400f)) }
}
