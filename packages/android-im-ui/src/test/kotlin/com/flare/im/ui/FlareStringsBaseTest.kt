package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/** [FlareStrings] built from a table the host already has: what it does not set stays the base's. */
class FlareStringsBaseTest {
    @Test
    fun `a key it sets is new and the rest stay the base's`() {
        val english = flareStringsEnglish()
        val derived = FlareStrings(english) { connectionUpdate = "Get it" }
        assertEquals("Get it", derived.connectionUpdate)
        assertEquals("Update now", english.connectionUpdate)
        assertEquals(english.updatePromptLater, derived.updatePromptLater)
        assertEquals(english.updatePromptTitleAvailable, derived.updatePromptTitleAvailable)
    }

    @Test
    fun `a function field carries over like the rest`() {
        val derived = FlareStrings(flareStringsEnglish()) { send = "Send it" }
        assertEquals("Read (3)", derived.readTab(3))
    }

    @Test
    fun `a key neither table sets keeps the default`() {
        val derived = FlareStrings(FlareStrings { send = "Send" }) { hangUp = "End" }
        assertEquals("Send", derived.send)
        assertEquals("End", derived.hangUp)
        assertEquals("麦克风", derived.microphone)
    }

    @Test
    fun `configure reads the base's value`() {
        val derived = FlareStrings(FlareStrings { send = "Send" }) { send = "$send it" }
        assertEquals("Send it", derived.send)
    }

    @Test
    fun `a table built without a base is as it was`() {
        val host = FlareStrings { send = "Send" }
        assertEquals("Send", host.send)
        assertEquals("挂断", host.hangUp)
    }
}
