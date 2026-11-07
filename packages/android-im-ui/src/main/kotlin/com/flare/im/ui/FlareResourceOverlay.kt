package com.flare.im.ui

import android.content.Context
import androidx.compose.ui.graphics.Color

// What a resource pack may change, the same on four kits (`spec/resource-overlay-vectors.json`). A pack is data read by
// code already in the build: it replaces copy and colours that exist and adds emoji, and nothing else.

internal const val FLARE_RESOURCE_SCHEMA = "flare.resource.v1"

private val PLACEHOLDER = Regex("\\{[A-Za-z0-9_]+\\}|%[sd@]")
private val COLOR = Regex("#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?")
private val SAFE_ID = Regex("[A-Za-z0-9_-]+")
private val EMOJI_KEY = Regex("[a-z][a-z0-9_]*")
private val HTTPS_URL = Regex("https://[A-Za-z0-9.-]+(?::[0-9]+)?(?:[/?#][!-~]*)?")

/** One entry of `update.get_resources`, as the SDK returns it. */
data class FlareResourcePack(
    val id: String,
    val kind: String,
    val packVersion: Long = 0,
    val contentJson: String,
)

internal data class FlareResourceEmoji(
    val key: String,
    val url: String,
    val previewUrl: String? = null,
    val labels: Map<String, String> = emptyMap(),
)

internal data class FlareResourceSticker(
    val stickerId: String,
    val url: String,
    val previewUrl: String? = null,
    val alt: String? = null,
)

internal data class FlareResourceStickerPack(
    val id: String,
    val title: String,
    val iconUrl: String? = null,
    val stickers: List<FlareResourceSticker>,
)

internal data class FlareResourceEmojiResult(
    val emoji: List<FlareResourceEmoji> = emptyList(),
    val stickerPacks: List<FlareResourceStickerPack> = emptyList(),
)

/** The pack's content when it is the object its manifest entry promised, else null. */
internal fun flareResourceContent(kind: String, contentJson: String): Map<*, *>? {
    val parsed = runCatching { FlareJson.parse(contentJson) }.getOrNull() as? Map<*, *> ?: return null
    return parsed.takeIf { it["schema"] == FLARE_RESOURCE_SCHEMA && it["kind"] == kind }
}

/** The placeholders [text] carries, as a sorted set. */
internal fun flareResourcePlaceholders(text: String): List<String> =
    PLACEHOLDER.findAll(text).map { it.value }.toSortedSet().toList()

/** The entries of one language that may replace the built-in text [builtIn] answers for each key. */
internal fun flareResourceStrings(builtIn: (String) -> String?, entries: Any?): Map<String, String> {
    val map = entries as? Map<*, *> ?: return emptyMap()
    return buildMap {
        for ((key, value) in map) {
            val name = key as? String ?: continue
            val current = builtIn(name) ?: continue
            val text = value as? String ?: continue
            if (text.isNotBlank() && flareResourcePlaceholders(current) == flareResourcePlaceholders(text)) put(name, text)
        }
    }
}

private fun normalizedTag(tag: String): String = tag.trim().lowercase().replace('_', '-')

/** The tag of [available] that speaks for [requested], or null: copy never crosses into another language. */
internal fun flareResourceLocale(requested: String, available: Collection<String>): String? {
    val wanted = normalizedTag(requested)
    if (wanted.isEmpty()) return null
    val tags = available.map { normalizedTag(it) to it }.sortedBy { it.first }
    var cut = wanted
    while (cut.isNotEmpty()) {
        tags.firstOrNull { it.first == cut }?.let { return it.second }
        cut = cut.substringBeforeLast('-', "")
    }
    return tags.firstOrNull { it.first.startsWith("$wanted-") }?.second
}

/** The colours of one group whose key is known and whose value is `#RRGGBB` or `#RRGGBBAA`. */
internal fun flareResourceColors(known: Set<String>, group: Any?): Map<String, String> {
    val map = group as? Map<*, *> ?: return emptyMap()
    return buildMap {
        for ((key, value) in map) {
            val name = key as? String ?: continue
            val text = value as? String ?: continue
            if (name in known && COLOR.matches(text)) put(name, text)
        }
    }
}

/** A colour the rules accepted as `0xAARRGGBB`: `#RRGGBB` is opaque, `#RRGGBBAA` puts its alpha first. */
internal fun flareResourceColorArgb(value: String): Long {
    val rgb = value.substring(1, 7).toLong(16)
    val alpha = if (value.length == 9) value.substring(7).toLong(16) else 0xFFL
    return (alpha shl 24) or rgb
}

private fun isHttps(value: Any?): Boolean = value is String && HTTPS_URL.matches(value)

/** An image address an entry can keep: absent, or https. */
private fun optionalUrlOk(value: Any?): Boolean = value == null || isHttps(value)

private fun filled(value: Any?): String? = (value as? String)?.trim()?.takeIf(String::isNotEmpty)

private fun stickerOf(raw: Any?, seen: MutableSet<String>): FlareResourceSticker? {
    val map = raw as? Map<*, *> ?: return null
    val id = map["stickerId"] as? String ?: return null
    if (!SAFE_ID.matches(id) || id in seen) return null
    if (!isHttps(map["url"]) || !optionalUrlOk(map["previewUrl"])) return null
    seen += id
    return FlareResourceSticker(id, map["url"] as String, map["previewUrl"] as String?, filled(map["alt"]))
}

private fun emojiOf(raw: Any?, seen: MutableSet<String>): FlareResourceEmoji? {
    val map = raw as? Map<*, *> ?: return null
    val key = map["key"] as? String ?: return null
    if (!EMOJI_KEY.matches(key) || key in seen) return null
    if (!isHttps(map["url"]) || !optionalUrlOk(map["previewUrl"])) return null
    seen += key
    val labels = buildMap<String, String> {
        (map["labels"] as? Map<*, *>)?.forEach { (tag, label) ->
            val text = filled(label)
            if (tag is String && text != null) put(tag, text)
        }
    }
    return FlareResourceEmoji(key, map["url"] as String, map["previewUrl"] as String?, labels)
}

/** The emoji and sticker packs that add to the catalog. Nothing here replaces what ships with the kit. */
internal fun flareResourceEmoji(
    builtInEmoji: Collection<String>,
    builtInPacks: Collection<String>,
    packs: Any?,
): FlareResourceEmojiResult {
    val list = packs as? List<*> ?: return FlareResourceEmojiResult()
    val emoji = mutableListOf<FlareResourceEmoji>()
    val stickerPacks = mutableListOf<FlareResourceStickerPack>()
    val seenKeys = builtInEmoji.toMutableSet()
    val seenPacks = builtInPacks.toMutableSet()
    for (raw in list) {
        val map = raw as? Map<*, *> ?: continue
        val id = map["id"] as? String ?: continue
        val title = filled(map["title"]) ?: continue
        if (!SAFE_ID.matches(id) || id in seenPacks || !optionalUrlOk(map["iconUrl"])) continue
        val seenStickers = mutableSetOf<String>()
        val stickers = (map["stickers"] as? List<*>).orEmpty().mapNotNull { stickerOf(it, seenStickers) }
        val entries = (map["emoji"] as? List<*>).orEmpty().mapNotNull { emojiOf(it, seenKeys) }
        if (stickers.isEmpty() && entries.isEmpty()) continue
        seenPacks += id
        emoji += entries
        if (stickers.isNotEmpty()) {
            stickerPacks += FlareResourceStickerPack(id, title, map["iconUrl"] as String?, stickers)
        }
    }
    return FlareResourceEmojiResult(emoji, stickerPacks)
}

/**
 * The resource packs of this run, folded over what ships with the kit. Build it from `update.get_resources`, keep it in
 * the root's state, and pass what it returns to the existing locals:
 *
 * ```kotlin
 * val strings = remember(overlay, language) { overlay.strings(base, locale = language) }
 * CompositionLocalProvider(LocalFlareStrings provides strings) {
 *     FlareThemeProvider(mode, brand, colors = overlay.colors(FlareColors.resolve(brand, dark), dark)) { App() }
 * }
 * ```
 *
 * An entry or a pack the rules refuse is left out and the rest stands; this never throws. A help pack is the host's.
 * With nothing to apply [strings] and [colors] hand back what they were given.
 */
class FlareResourceOverlay(packs: List<FlareResourcePack>) {
    private val stringPacks = mutableListOf<Map<*, *>>()
    private val tokenPacks = mutableListOf<Map<*, *>>()
    private val emojiPacks = mutableListOf<Any?>()

    init {
        for (pack in packs) {
            val content = flareResourceContent(pack.kind, pack.contentJson) ?: continue
            when (pack.kind) {
                "strings" -> (content["locales"] as? Map<*, *>)?.let { stringPacks.add(it) }
                "tokens" -> tokenPacks.add(content)
                "emoji" -> (content["packs"] as? List<*>)?.let { emojiPacks.addAll(it) }
            }
        }
    }

    val isEmpty: Boolean get() = stringPacks.isEmpty() && tokenPacks.isEmpty() && emojiPacks.isEmpty()

    /**
     * What the strings packs say for [locale], in pack order: a later pack wins a key. [builtIn] answers for a table's
     * keys, so a host's own table takes its entries under the same rules: a known key, the same placeholders.
     */
    fun stringValues(locale: String, builtIn: (String) -> String?): Map<String, String> {
        val accepted = linkedMapOf<String, String>()
        for (locales in stringPacks) {
            val tag = flareResourceLocale(locale, locales.keys.filterIsInstance<String>()) ?: continue
            accepted += flareResourceStrings(builtIn, locales[tag])
        }
        return accepted
    }

    /** One mode's colours, in pack order: a later pack wins a key. `colors` is light and `dark` dark; neither reaches the other. */
    internal fun colorValues(dark: Boolean, known: Set<String>): Map<String, String> {
        val accepted = linkedMapOf<String, String>()
        for (pack in tokenPacks) accepted += flareResourceColors(known, pack[if (dark) "dark" else "colors"])
        return accepted
    }

    /** [base] with what the packs say for [locale], the language [base] is written in. */
    fun strings(base: FlareStrings, locale: String): FlareStrings {
        val accepted = stringValues(locale) { base.stringValue(it) }
        return if (accepted.isEmpty()) base else FlareStrings(base) { values.putAll(accepted) }
    }

    /** [base], a theme's colours for that mode, with what the packs set for it. */
    fun colors(base: FlareColors, dark: Boolean): FlareColors {
        val accepted = colorValues(dark, flareColorKeys)
        return if (accepted.isEmpty()) base else base.applying(accepted.mapValues { Color(flareResourceColorArgb(it.value)) })
    }

    /** Adds the packs' emoji and stickers to the catalog. Waits for the bundled manifest: it decides what may not be replaced. */
    suspend fun registerEmoji(context: Context) {
        if (emojiPacks.isEmpty()) return
        FlareEmojiStickerCatalog.ensureLoaded(context)
        registerLoadedEmoji()
    }

    internal fun registerLoadedEmoji() {
        val catalog = FlareEmojiStickerCatalog
        val result = flareResourceEmoji(catalog.bundledEmojiKeys(), catalog.bundledStickerPackIds(), emojiPacks)
        if (result.emoji.isNotEmpty()) {
            catalog.registerEmojiAssets(
                result.emoji.map { FlareEmojiAssetRegistration(key = it.key, animatedUri = it.url, labels = it.labels) },
            )
        }
        if (result.stickerPacks.isNotEmpty()) {
            catalog.registerStickerPacks(
                result.stickerPacks.map { pack ->
                    FlareStickerPackRegistration(
                        id = pack.id,
                        title = pack.title,
                        stickers = pack.stickers.map { FlareStickerAssetRegistration(stickerId = it.stickerId, uri = it.url) },
                    )
                },
            )
        }
    }

    companion object {
        /** No packs: what a root starts from, before the packs are read. */
        val Empty = FlareResourceOverlay(emptyList())
    }
}
