package com.flare.im.ui

import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The merged-forward record against spec/message-forward-vectors.json, mapped from the core's forward content as a host maps it. */
class ForwardRecordVectorsTest {
    private val table = SpecTables.table("message-forward-vectors.json")

    private fun itemContent(raw: Map<*, *>?): FlareMessageContent? = when (raw?.str("contentType")) {
        "text" -> FlareTextContent(raw.obj("text")?.str("text").orEmpty())
        "image" -> FlareImageContent(url = raw.obj("image")?.str("url").orEmpty())
        else -> null
    }

    private fun content(input: Map<*, *>): FlareForwardContent {
        val forward = input.obj("forward")!!
        return FlareForwardContent(
            items = forward.items("items").map { item ->
                FlareForwardItem(
                    senderName = item.str("sourceSenderName").orEmpty(),
                    sentAtMs = item.long("sourceMessageTimeMs") ?: 0,
                    plainText = item.str("plainText").orEmpty(),
                    content = itemContent(item.obj("content")),
                )
            },
            title = forward.str("title").orEmpty(),
            mode = when (forward.int("mode")) { 1 -> FlareForwardMode.Single; 2 -> FlareForwardMode.Merged; else -> FlareForwardMode.Unspecified },
        )
    }

    @Test fun everyCaseShowsWhatTheVectorSays() {
        val cases = table.items("cases").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(cases.isNotEmpty())
        for (case in cases) for ((language, strings, locale) in listOf(
            Triple("zh", FlareStrings(), Locale.SIMPLIFIED_CHINESE),
            Triple("en", flareStringsEnglish(), Locale.US),
        )) {
            val id = "${case.str("id")} $language"
            val expect = case.obj("expect")!!
            val view = flareForwardRecordView(content(case.obj("input")!!), strings, locale)
            assertEquals(expect.str("layout"), view.layout.name.lowercase(), id)
            val facts = expect.obj(language) ?: continue
            assertEquals(facts.str("title"), view.title, id)
            assertEquals(facts.str("subtitle"), view.subtitle, id)
            assertEquals(facts.items("previews").map { it.str("sender") to it.str("text") }, view.previews, id)
            assertEquals(facts.str("more"), view.more, id)
            assertEquals(facts.str("hint"), view.hint, id)
            assertEquals(facts.str("label"), view.label, id)
            assertEquals(facts.str("drawerTitle"), view.drawerTitle, id)
        }
    }

    @Test fun theDrawerAvatarReadsTheSenderNameNeverTheUnknownSenderWord() {
        val initials = table.obj("senderInitials")!!
        assertTrue((initials["platforms"] as List<*>).contains("compose"))
        for (case in initials.items("cases")) {
            val name = case.str("senderName").orEmpty()
            assertEquals(case.str("initial"), flareForwardSenderInitial(FlareForwardItem(senderName = name)), name)
        }
    }

    @Test fun aRecordIsACardAndReadsAsItsCount() {
        val record = FlareForwardContent(listOf(FlareForwardItem("A", plainText = "1"), FlareForwardItem("B", plainText = "2")), mode = FlareForwardMode.Merged)
        assertEquals(FlareMessageSurface.Card, flareMessageSurface(FlareMessageSurfaceInput(contentType = flareMessageContentType(record).first)))
        assertEquals("[转发] 2 条消息", flareMessagePreviewText(record, FlareStrings()))
    }
}
