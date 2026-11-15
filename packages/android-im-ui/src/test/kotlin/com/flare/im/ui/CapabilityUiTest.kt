package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The capability components, the location input and protected media against spec/capability-ui-vectors.json. */
class CapabilityUiTest {
    private val vectors = FlareJson.parse(File("../../spec/capability-ui-vectors.json").readText()) as Map<*, *>
    private fun cases(section: String): List<Map<*, *>> =
        ((vectors[section] as Map<*, *>)["cases"] as List<*>).map { it as Map<*, *> }
    private fun hex(text: String): ByteArray = text.chunked(2).filter { it.length == 2 }.map { it.toInt(16).toByte() }.toByteArray()
    private val en = flareStringsEnglish()

    @Test fun consentDecisionsAndLabels() {
        for (c in cases("consentDecision")) {
            val d = FlareCapabilityConsentDecision.entries.first { it.wire == c["decision"] }
            assertEquals(c["answer"], d.answer)
        }
        for (c in cases("capabilityLabel")) {
            @Suppress("UNCHECKED_CAST") val params = c["params"] as Map<String, Any?>?
            assertEquals(c["key"], FlareCapabilityRules.labelKey(c["capability"] as String, params))
            assertNotEquals(c["capability"], FlareCapabilityRules.label(en, c["capability"] as String, params))
        }
        for (c in cases("consentAllowsAlways")) assertEquals(c["always"], FlareCapabilityRules.allowsAlways(c["capability"] as String))
    }

    @Test fun paymentAmountsAndCountdown() {
        for (c in cases("paymentAmount")) {
            assertEquals(c["text"], FlarePaymentRules.amountText(c["amount"] as String, c["currency"] as String), "$c")
        }
        for (c in cases("paymentCountdown")) {
            val (text, expired) = FlarePaymentRules.countdown((c["remainingMs"] as Number).toLong())
            assertEquals(c["text"], text)
            assertEquals(c["expired"], expired)
        }
        val order = FlarePaymentOrder("o", "1234.50", "CNY", "Wallet", "T", 10_000)
        assertTrue(FlarePaymentRules.confirmEnabled(order, 5_000, busy = false, confirmDisabled = false))
        assertFalse(FlarePaymentRules.confirmEnabled(order, 10_000, busy = false, confirmDisabled = false))
        assertFalse(FlarePaymentRules.confirmEnabled(order.copy(amount = "1e5"), 0, busy = false, confirmDisabled = false))
        assertEquals(order.copy(operation = "pay"), FlarePaymentOrder.fromJson(mapOf("orderId" to "o", "amount" to "1234.50",
            "currency" to "CNY", "payee" to "Wallet", "title" to "T", "expiresAtMs" to 10_000, "operation" to "pay")))
        assertNull(FlarePaymentOrder.fromJson(mapOf("orderId" to "o")))
    }

    @Test fun documentRules() {
        for (c in cases("documentFrame")) {
            assertEquals((c["aspect"] as Number).toFloat(), FlareDocumentSide.of(c["side"] as String)!!.frameAspect, 0.001f)
        }
        val compression = vectors["documentCompression"] as Map<*, *>
        val plan = (compression["plan"] as List<*>).map { step -> (step as List<*>).let { (it[0] as Number).toInt() to Math.round((it[1] as Number).toDouble() * 100).toInt() } }
        assertEquals(plan, FlareDocumentRules.compressionPlan)
        for (c in compression["fileName"] as List<*>) {
            val m = c as Map<*, *>
            assertEquals(m["name"], FlareDocumentSide.of(m["side"] as String)!!.fileName)
        }
        for (c in cases("documentAccept")) assertEquals(c["ok"], FlareDocumentRules.acceptsJpeg((c["accept"] as List<*>).map { it as String }))
        for (c in cases("jpegStripped")) assertEquals(c["stripped"], FlareDocumentRules.jpegIsStripped(hex(c["hex"] as String)), "$c")
        val strip = ((vectors["jpegStripped"] as Map<*, *>)["strip"] as List<*>).map { it as Map<*, *> }
        for (c in strip) {
            assertEquals(
                (c["out"] as String).lowercase(),
                FlareDocumentRules.jpegStrippingMetadata(hex(c["hex"] as String)).joinToString("") { "%02x".format(it) },
                "$c",
            )
        }
        for (c in cases("jpegStripped").filter { it["stripped"] == true }) {
            assertTrue(FlareDocumentRules.jpegIsStripped(FlareDocumentRules.jpegStrippingMetadata(hex(c["hex"] as String))))
        }
        val file = FlareCapturedDocument("document-front.jpg", byteArrayOf(-1, -40))
        assertEquals(listOf(255, 216), file.toJson()["bytes"])
    }

    @Test fun protectedMedia() {
        for (c in cases("protectedMediaSource")) {
            assertEquals(c["native"], FlarePluginProtectedMedia.source(c["url"] as String) != null, "$c")
        }
        assertEquals("https://h/p?grant=g", FlarePluginProtectedMedia.url(mapOf("url" to "https://h/p?grant=g"), "/url"))
        val own = pluginBlockOf(FlareJson.parse("""{"kind":"protected-media","label":"My documents","items":[{"id":"m1","label":"Front","mediaType":"image/jpeg","input":{"applicationId":"a1"}}],"action":{"id":"viewDocument","label":"View"},"inputName":"materialId","urlPath":"/url"}""") as Map<*, *>)
        own as PluginProtectedMediaBlock
        assertFalse(own.asksReason)
        assertEquals(mapOf("materialId" to "m1"), own.read(own.items[0], "")?.formValues)
        val console = own.copy(reasonInput = "reason")
        assertEquals(mapOf("materialId" to "m1", "reason" to "audit"), console.read(console.items[0], "audit")?.formValues)
        for (c in cases("protectedMediaReason")) {
            assertEquals(c["asks"], own.copy(reasonInput = c["reasonInput"] as String?).asksReason)
        }
        val section = pluginBlockOf(FlareJson.parse("""{"kind":"section","label":"S","blocks":[{"kind":"protected-media","items":[],"inputName":"m","urlPath":"/u"}]}""") as Map<*, *>)
        assertTrue((section as PluginSectionBlock).blocks.isEmpty(), "never inside a section")
        assertNull(pluginBlockOf(FlareJson.parse("""{"kind":"protected-media","items":[]}""") as Map<*, *>))
    }

    @Test fun locationInput() {
        for (c in cases("locationInput")) {
            val fix = PluginLocationValue.read(c["value"], PluginLocationPrecision.fromWire(c["precision"] as String))
            assertEquals(c["ok"], fix != null, "$c")
            if (fix != null) assertEquals(c["text"], fix.text)
        }
        val view = PluginViewModel.fromMap(FlareJson.parse("""{"available":true,"title":"t","fields":[],"actions":[],
            "inputs":[{"id":"place","kind":"location","label":"Where","required":true,"precision":"coarse"},
                      {"id":"bad","kind":"location","label":"No precision"}]}""") as Map<*, *>)
        val input = view.inputs.single()
        assertEquals(PluginLocationPrecision.Coarse, input.precision)
        val fix = PluginLocationValue(31.23, 121.47, 1000, PluginLocationPrecision.Coarse)
        assertEquals(PluginFormIssue.Required, PluginFormRules.check(input, null))
        assertNull(PluginFormRules.check(input, fix.toMap()))
        assertEquals(PluginFormIssue.InvalidType, PluginFormRules.check(input, fix.toMap() + ("latitude" to 31.234)))
        assertEquals(fix.toMap(), PluginFormRules.values(listOf(input), mapOf("place" to fix.toMap()))["place"])
        assertNull(PluginFormRules.draftValue(input.copy(precision = PluginLocationPrecision.Fine), mapOf("place" to fix.toMap())))
        assertNotNull(PluginFormRules.draftValue(input, mapOf("place" to fix.toMap())))
    }
}
