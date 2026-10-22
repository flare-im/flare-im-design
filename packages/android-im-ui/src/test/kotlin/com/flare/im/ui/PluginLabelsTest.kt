package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

class PluginLabelsTest {
    @Test fun packetEnglishCopyIncludesFunctionLabelsAndUnavailableStates() {
        val labels = flareStringsEnglish()
        assertEquals("Processing…", labels.packetBusy)
        assertEquals("Unavailable", labels.packetUnavailable)
        // Red packet v5: the card never shows an amount, so there is no "opened · amount" line any more.
        assertEquals("Opened", labels.packetStateClaimed)
    }
}
