package com.flare.im.ui

import org.junit.Assert.*
import org.junit.Test

class ScanHitGateLifecycleTest {
    @Test fun interruptedCollectionCannotSubmitAnOldCodeAndStartsANewWindow() {
        val gate = FlareScanHitGate()
        assertEquals(FlareScanHit.Lock(FlareScanCode("old"), false), gate.observe(listOf(FlareScanCode("old")), 0))
        assertTrue(gate.interruptObservations())
        assertFalse(gate.interruptObservations())
        assertEquals(FlareScanHit.Ignore, gate.observe(emptyList(), 1000))
        assertEquals(FlareScanHit.Lock(FlareScanCode("new"), false), gate.observe(listOf(FlareScanCode("new")), 1001))
        assertEquals(FlareScanHit.Ignore, gate.observe(emptyList(), 1150))
        assertEquals(FlareScanHit.Lock(FlareScanCode("new"), true), gate.observe(emptyList(), 1151))
    }

    @Test fun interruptionPreservesAnExplicitChoiceAndAnAlreadyLockedCode() {
        val gate = FlareScanHitGate()
        val codes = listOf(FlareScanCode("first"), FlareScanCode("chosen"))
        gate.observe(codes, 0)
        assertEquals(FlareScanHit.Choose(codes), gate.observe(emptyList(), 150))
        assertFalse(gate.interruptObservations())
        assertEquals(FlareScanHit.Ignore, gate.observe(emptyList(), 1000))
        assertEquals(FlareScanHit.Lock(codes[1], true), gate.select("chosen"))
        assertFalse(gate.interruptObservations())
        assertEquals(FlareScanHit.Ignore, gate.observe(listOf(FlareScanCode("new")), 2000))
    }
}
