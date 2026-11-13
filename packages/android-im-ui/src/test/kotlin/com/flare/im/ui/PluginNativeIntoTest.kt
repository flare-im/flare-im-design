package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNull

/** A page action's native target writing into a form input, against spec/plugin-native-into-vectors.json. */
class PluginNativeIntoTest {
    private val cases = ((FlareJson.parse(File("../../spec/plugin-native-into-vectors.json").readText()) as Map<*, *>)["cases"]
        as List<*>).map { it as Map<*, *> }

    @Test fun aNativeTargetRunsThroughTheInputItNames() {
        for (c in cases) {
            val raw = c["input"] as Map<*, *>
            val input = PluginInput(raw["id"] as String, PluginInputKind.fromWire(raw["kind"] as String)!!, "")
            val target = (c["target"] as? Map<*, *>)?.let { pluginActionOf(mapOf("id" to "a", "label" to "A", "target" to it))?.target }
            assertEquals(c["key"], pluginNativeIntoKey(target, input), "$c")
        }
    }

    @Test fun actionsCarryTheirTarget() {
        val action = pluginActionOf(mapOf("id" to "scan", "label" to "Scan", "target" to mapOf("kind" to "native",
            "capability" to "documentCapture", "params" to mapOf("side" to "front"), "into" to "front")))!!
        assertEquals(PluginActionTarget("native", "documentCapture", mapOf("side" to "front"), "front"), action.target)
        assertNull(pluginActionOf(mapOf("id" to "a", "label" to "A", "target" to 7))!!.target)
    }

    @Test fun aNativeRequestHasANewTokenEachTime() {
        val target = PluginActionTarget("native", "locationOnce", mapOf("precision" to "coarse"), "area")
        assertNotEquals(PluginNativeIntoRequest(target), PluginNativeIntoRequest(target))
    }
}
