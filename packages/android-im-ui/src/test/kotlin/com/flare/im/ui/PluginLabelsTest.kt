package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

class PluginLabelsTest {
    @Test fun packetEnglishCopyIncludesFunctionLabelsAndUnavailableStates() {
        val labels = flareStringsEnglish()
        assertEquals("Processing…", labels.packetBusy)
        assertEquals("Unavailable", labels.packetUnavailable)
        assertEquals("Opened · 1.00 CNY", labels.packetClaimed("1.00 CNY"))
    }
}
