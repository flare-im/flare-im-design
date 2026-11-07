package com.flare.im.ui

import androidx.compose.ui.graphics.Color
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotSame
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

/**
 * `spec/resource-overlay-vectors.json`, the table the four kits run: what a resource pack may change. Below it, the
 * same rules on the real word list, colours and catalog.
 */
class ResourceOverlayTest {
    private val table = SpecTables.table("resource-overlay-vectors.json")

    private fun Map<*, *>.texts(key: String): Map<String, String> {
        val map = this[key] as? Map<*, *> ?: return emptyMap()
        return map.entries.associate { it.key as String to it.value as String }
    }

    private fun Map<*, *>.words(key: String): List<String> = (this[key] as List<*>).map { it as String }

    private fun stickerJson(item: FlareResourceSticker): Map<String, Any?> = buildMap {
        put("stickerId", item.stickerId)
        put("url", item.url)
        item.previewUrl?.let { put("previewUrl", it) }
        item.alt?.let { put("alt", it) }
    }

    private fun emojiJson(item: FlareResourceEmoji): Map<String, Any?> = buildMap {
        put("key", item.key)
        put("url", item.url)
        item.previewUrl?.let { put("previewUrl", it) }
        if (item.labels.isNotEmpty()) put("labels", item.labels)
    }

    private fun packJson(pack: FlareResourceStickerPack): Map<String, Any?> = buildMap {
        put("id", pack.id)
        put("title", pack.title)
        pack.iconUrl?.let { put("iconUrl", it) }
        put("stickers", pack.stickers.map(::stickerJson))
    }

    @Test
    fun `a pack is read when it is what the manifest promised`() {
        table.items("content").forEach { row ->
            val content = flareResourceContent(row.str("kind")!!, row.str("contentJson")!!)
            assertEquals(row.bool("accepted"), content != null, row.str("name"))
        }
    }

    @Test
    fun `placeholders read as a set`() {
        table.items("placeholders").forEach { row ->
            assertEquals(row.words("expect"), flareResourcePlaceholders(row.str("text")!!), row.str("text"))
        }
    }

    @Test
    fun `an entry stands or falls on its own`() {
        table.items("strings").forEach { row ->
            val builtIn = row.texts("builtIn")
            assertEquals(row.texts("expect"), flareResourceStrings({ builtIn[it] }, row["entries"]), row.str("name"))
        }
    }

    @Test
    fun `a language answers only for itself`() {
        table.items("locales").forEach { row ->
            assertEquals(row.str("expect"), flareResourceLocale(row.str("requested")!!, row.words("available")), row.str("requested"))
        }
    }

    @Test
    fun `only known colours in the two forms are kept`() {
        table.items("colors").forEach { row ->
            assertEquals(row.texts("expect"), flareResourceColors(row.words("known").toSet(), row["group"]), row.str("name"))
        }
    }

    @Test
    fun `a colour reads with its alpha first`() {
        table.items("argb").forEach { row ->
            assertEquals(row.long("argb"), flareResourceColorArgb(row.str("value")!!), row.str("value"))
        }
    }

    @Test
    fun `emoji only add`() {
        table.items("emoji").forEach { row ->
            val result = flareResourceEmoji(row.words("builtInEmoji"), row.words("builtInPacks"), row["packs"])
            val want = row.obj("expect")!!
            assertEquals(want["emoji"], result.emoji.map(::emojiJson), row.str("name"))
            assertEquals(want["stickerPacks"], result.stickerPacks.map(::packJson), row.str("name"))
        }
    }

    @Test
    fun `packs fold in order`() {
        table.items("fold").forEach { row ->
            val overlay = FlareResourceOverlay(
                row.items("packs").map {
                    FlareResourcePack(it.str("id")!!, it.str("kind")!!, it.long("packVersion")!!, it.str("contentJson")!!)
                },
            )
            val builtIn = row.texts("builtIn")
            val known = row.words("known").toSet()
            val want = row.obj("expect")!!
            assertEquals(want.texts("strings"), overlay.stringValues(row.str("locale")!!) { builtIn[it] }, row.str("name"))
            assertEquals(want.texts("light"), overlay.colorValues(false, known), row.str("name"))
            assertEquals(want.texts("dark"), overlay.colorValues(true, known), row.str("name"))
        }
    }

    private fun stringsPack(locales: String) = FlareResourcePack(
        id = "strings",
        kind = "strings",
        contentJson = """{"schema":"$FLARE_RESOURCE_SCHEMA","kind":"strings","locales":$locales}""",
    )

    private fun tokensPack(groups: String) = FlareResourcePack(
        id = "tokens",
        kind = "tokens",
        contentJson = """{"schema":"$FLARE_RESOURCE_SCHEMA","kind":"tokens",$groups}""",
    )

    @Test
    fun `strings replace a field by its name and keep the word list they fold over`() {
        val base = flareStringsEnglish()
        val folded = FlareResourceOverlay(listOf(stringsPack("""{"en":{"send":"Post"}}"""))).strings(base, "en-US")
        assertEquals("Post", folded.send)
        assertEquals(base.cancelReply, folded.cancelReply)
        assertEquals(base.readTab(3), folded.readTab(3))
        // A new object: the static local only passes the new copy down if the value changes.
        assertNotSame(base, folded)
    }

    @Test
    fun `a function field is not a key`() {
        assertFalse("readTab" in flareStringKeys)
        assertNull(FlareStrings().stringValue("readTab"))
        val base = flareStringsEnglish()
        assertSame(base, FlareResourceOverlay(listOf(stringsPack("""{"en":{"readTab":"Seen"}}"""))).strings(base, "en"))
    }

    @Test
    fun `every key reads the field it names`() {
        val strings = FlareStrings()
        flareStringKeys.forEach { assertTrue(strings.stringValue(it) != null, it) }
        assertEquals(strings.send, strings.stringValue("send"))
    }

    @Test
    fun `colours keep light and dark apart`() {
        val overlay = FlareResourceOverlay(listOf(tokensPack(""""colors":{"primary":"#112233"},"dark":{"bgPrimary":"#44556677"}""")))
        val light = overlay.colors(FlareColors.Light, dark = false)
        assertEquals(Color(0xFF112233), light.primary)
        assertEquals(FlareColors.Light.bgPrimary, light.bgPrimary)
        assertNotEquals(FlareColors.Light, light)
        val dark = overlay.colors(FlareColors.Dark, dark = true)
        assertEquals(FlareColors.Dark.primary, dark.primary)
        assertEquals(Color(0x77445566), dark.bgPrimary)
    }

    @Test
    fun `nothing to apply hands back what it was given`() {
        val base = flareStringsEnglish()
        assertTrue(FlareResourceOverlay.Empty.isEmpty)
        assertSame(base, FlareResourceOverlay.Empty.strings(base, "en"))
        assertSame(FlareColors.Light, FlareResourceOverlay.Empty.colors(FlareColors.Light, dark = false))
    }

    @AfterTest
    fun clearRuntimeCatalog() {
        FlareEmojiStickerCatalog.clearRegisteredEmojiAssets()
        FlareEmojiStickerCatalog.clearRegisteredStickerPacks()
    }

    @Test
    fun `a pack's emoji reach the catalog without preview bytes`() {
        val overlay = FlareResourceOverlay(
            listOf(
                FlareResourcePack(
                    id = "emoji",
                    kind = "emoji",
                    contentJson = """{"schema":"$FLARE_RESOURCE_SCHEMA","kind":"emoji","packs":[{"id":"acme","title":"Acme",
                        "stickers":[{"stickerId":"wave","url":"https://cdn.example/w.webp"}],
                        "emoji":[{"key":"acme_wave","url":"https://cdn.example/e.webp"}]}]}""",
                ),
            ),
        )

        overlay.registerLoadedEmoji()

        val catalog = FlareEmojiStickerCatalog
        assertTrue(catalog.hasEmojiKey("acme_wave"))
        assertNull(catalog.emojiStaticPreviewBytes("acme_wave"))
        assertEquals("https://cdn.example/e.webp", catalog.emojiRuntimeUri("acme_wave"))
        assertEquals(listOf("wave"), catalog.stickerPacks.single { it.id == "acme" }.stickerIds)
        assertEquals("https://cdn.example/w.webp", catalog.stickerRuntimeUri("wave", "acme"))
        assertNull(catalog.stickerStaticPreviewBytes("wave", "acme"))
    }

    @Test
    fun `an empty preview is still refused`() {
        FlareEmojiStickerCatalog.registerEmojiAssets(
            listOf(FlareEmojiAssetRegistration(key = "empty_preview", animatedUri = "https://cdn.example/e.webp", staticPreviewBytes = byteArrayOf())),
        )
        assertFalse(FlareEmojiStickerCatalog.hasEmojiKey("empty_preview"))
    }
}
