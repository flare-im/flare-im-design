package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared table's `stored` list (`spec/message-preview-vectors.json`): each token exactly as the core writes it
 * for a conversation's last message, a quote or a search hit, and the line it reads as. Vue
 * (`displayTextFromStoredPreview`) and the SwiftUI and Flutter kits read the same list.
 */
class StoredPreviewVectorsTest {
    /** The emoji token reads the pack names the kit ships; a JVM test has no assets, so the file is read here. */
    init {
        val raw = FlareJson.parse(File(repositoryRoot(), "packages/android-im-ui/src/main/assets/emoji-sticker/emoji-locales.json").readText()) as Map<*, *>
        FlareEmojiStickerCatalog.loadLocales(
            raw.entries.associate { (column, labels) ->
                column as String to (labels as Map<*, *>).entries.associate { (k, v) -> k as String to v as String }
            },
        )
    }

    @Test fun everyStoredTokenReadsTheSameInBothLocales() {
        val vectors = FlareJson.parse(File(repositoryRoot(), "spec/message-preview-vectors.json").readText()) as Map<*, *>
        val stored = vectors["stored"] as List<*>
        assertTrue(stored.size >= 40, "the shared table lost tokens: ${stored.size}")
        for (raw in stored) {
            val case = raw as Map<*, *>
            val expected = case["expected"] as Map<*, *>
            for ((locale, strings) in listOf("zh-CN" to FlareStrings(), "en-US" to flareStringsEnglish())) {
                assertEquals(expected[locale], flareStoredPreviewText(case["token"] as String, strings, locale), "${case["id"]} in $locale")
            }
        }
    }

    /** A host names the events it owns; the kit names the rest, and the server's own words beat both. */
    @Test fun aHostNamesItsOwnEventsFirst() {
        val s = FlareStrings()
        val host: (String) -> String = { if (it == "shop.order_paid") "订单已支付" else "" }
        assertEquals("订单已支付", flareStoredPreviewText("""{"k":"im.preview.system","a":{"ek":"shop.order_paid"}}""", s, "zh-CN", host))
        assertEquals(s.systemEventGroupMemberLeft, flareStoredPreviewText("""{"k":"im.preview.system","a":{"ek":"group.member_left"}}""", s, "zh-CN", host))
        assertEquals("已付款", flareStoredPreviewText("""{"k":"im.preview.system","a":{"ek":"shop.order_paid","fb":"已付款"}}""", s, "zh-CN", host))
        assertEquals("", flareStoredPreviewText(null, s))
        assertEquals("", flareStoredPreviewText("   ", s))
    }

    /** The table lives beside the four kits, so find the repository root from the module's directory. */
    private fun repositoryRoot(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            if (File(dir, "spec/message-preview-vectors.json").isFile) return dir
            dir = dir.parentFile
        }
        error("spec/message-preview-vectors.json not found above ${File(".").absolutePath}")
    }
}
