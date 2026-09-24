package com.flare.im.ui

import android.content.Context
import android.os.Build
import coil.ImageLoader
import coil.decode.GifDecoder
import coil.decode.ImageDecoderDecoder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import org.json.JSONObject

/** One sticker pack from the manifest. */
data class FlareStickerPack(
    /** Protocol packageId (e.g. `gifs`, `classic`). */
    val id: String,
    /** On-disk dir relative to the resource root, e.g. `stickers/default`. */
    val dir: String,
    val title: String,
    val stickerIds: List<String>,
)

/** User-installed emoji resource. [animatedUri] is used only by a standalone
 * sent emoji; every editing/picker/inline surface decodes [staticPreviewBytes]. */
data class FlareEmojiAssetRegistration(
    val key: String,
    val animatedUri: String,
    val staticPreviewBytes: ByteArray,
    val labels: Map<String, String> = emptyMap(),
)

data class FlareStickerAssetRegistration(
    val stickerId: String,
    val uri: String,
    val staticPreviewBytes: ByteArray,
)

data class FlareStickerPackRegistration(
    val id: String,
    val title: String,
    val stickers: List<FlareStickerAssetRegistration>,
)

/**
 * Cross-platform emoji-pack + sticker catalog, backed by the flare-im-design
 * manifest bundled with this library (a symlink mirror of the single source
 * `flare-im-design/assets/emoji-sticker`, packaged under `assets/emoji-sticker`).
 *
 * Message views resolve assets by path convention (Coil renders the webp, a
 * missing file triggers the fallback). The picker + localized labels use
 * [ensureLoaded] to read the manifest + locales from `assets`.
 */
private val PACK_KEY_TOKEN = Regex("\\[([a-z][a-z0-9_]*)]")
private val EMOJI_KEY = Regex("^[a-z][a-z0-9_]*$")
private const val STATIC_PREVIEW_BYTE_BUDGET = 8 * 1024 * 1024

object FlareEmojiStickerCatalog {
    const val ASSET_ROOT = "emoji-sticker"

    /** Protocol packageId whose on-disk dir is `default/`. */
    const val STICKER_PACKAGE_GIFS = "gifs"

    @Volatile
    private var loaded = false
    val isLoaded: Boolean get() = loaded

    private var bundledEmojiKeys: List<String> = emptyList()
    val emojiKeys: List<String>
        get() = bundledEmojiKeys.filterNot(runtimeEmoji::containsKey) + runtimeEmoji.keys
    private var emojiKeySet: Set<String> = emptySet()

    private var bundledStickerPacks: List<FlareStickerPack> = emptyList()
    val stickerPacks: List<FlareStickerPack>
        get() = bundledStickerPacks.filterNot { runtimeStickerPacks.containsKey(it.id) } +
            runtimeStickerPacks.values.map { pack ->
                FlareStickerPack(pack.id, "", pack.title, pack.stickers.map { it.stickerId })
            }

    private val runtimeEmoji = linkedMapOf<String, FlareEmojiAssetRegistration>()
    private val runtimeStickerPacks = linkedMapOf<String, FlareStickerPackRegistration>()
    private val _revision = MutableStateFlow(0)
    val revision: StateFlow<Int> = _revision.asStateFlow()

    // locale column -> (key -> label)
    private var locales: Map<String, Map<String, String>> = emptyMap()

    /** Loads the manifest + locale labels once. Safe to call repeatedly. */
    suspend fun ensureLoaded(context: Context) = withContext(Dispatchers.IO) {
        if (loaded) return@withContext
        val assets = context.applicationContext.assets

        val manifest = JSONObject(assets.open("$ASSET_ROOT/manifest.json").use { it.readBytes().decodeToString() })
        val emoji = manifest.optJSONObject("emoji")
        val keysJson = emoji?.optJSONArray("keys")
        val keys = buildList {
            if (keysJson != null) for (i in 0 until keysJson.length()) add(keysJson.getString(i))
        }
        bundledEmojiKeys = keys
        emojiKeySet = keys.toSet()

        val packsJson = manifest.optJSONArray("stickerPacks")
        bundledStickerPacks = buildList {
            if (packsJson != null) for (i in 0 until packsJson.length()) {
                val p = packsJson.getJSONObject(i)
                val itemsJson = p.optJSONArray("items")
                val ids = buildList {
                    if (itemsJson != null) for (j in 0 until itemsJson.length()) {
                        add(itemsJson.getJSONObject(j).getString("id"))
                    }
                }
                add(
                    FlareStickerPack(
                        id = p.optString("id"),
                        dir = p.optString("dir"),
                        title = p.optString("title"),
                        stickerIds = ids,
                    ),
                )
            }
        }

        loadLocales(
            runCatching {
                val raw = JSONObject(assets.open("$ASSET_ROOT/emoji-locales.json").use { it.readBytes().decodeToString() })
                buildMap {
                    for (col in raw.keys()) {
                        val map = raw.getJSONObject(col)
                        put(col, buildMap { for (k in map.keys()) put(k, map.getString(k)) })
                    }
                }
            }.getOrDefault(emptyMap()),
        )

        loaded = true
    }

    fun hasEmojiKey(key: String): Boolean {
        val normalized = key.trim()
        return runtimeEmoji.containsKey(normalized) || emojiKeySet.contains(normalized)
    }

    private fun safeComponent(value: String): Boolean = value.matches(Regex("^[A-Za-z0-9_-]+$"))

    /** Adds or replaces per-user emoji assets without changing `[key]` protocol values. */
    @Synchronized
    fun registerEmojiAssets(assets: Iterable<FlareEmojiAssetRegistration>) {
        assets.forEach { asset ->
            val key = asset.key.trim()
            if (!EMOJI_KEY.matches(key) || asset.animatedUri.isBlank() ||
                asset.staticPreviewBytes.isEmpty() || asset.staticPreviewBytes.size > STATIC_PREVIEW_BYTE_BUDGET
            ) return@forEach
            runtimeEmoji[key] = asset.copy(
                key = key,
                animatedUri = asset.animatedUri.trim(),
                staticPreviewBytes = asset.staticPreviewBytes.copyOf(),
                labels = asset.labels.toMap(),
            )
        }
        _revision.value += 1
    }

    @Synchronized
    fun unregisterEmojiAsset(key: String) {
        if (runtimeEmoji.remove(key.trim()) != null) _revision.value += 1
    }

    @Synchronized
    fun clearRegisteredEmojiAssets() {
        if (runtimeEmoji.isEmpty()) return
        runtimeEmoji.clear()
        _revision.value += 1
    }

    @Synchronized
    fun registerStickerPacks(packs: Iterable<FlareStickerPackRegistration>) {
        packs.forEach { pack ->
            val id = pack.id.trim()
            if (!safeComponent(id) || pack.title.isBlank()) return@forEach
            val stickers = pack.stickers.filter { sticker ->
                safeComponent(sticker.stickerId.trim()) && sticker.uri.isNotBlank() &&
                    sticker.staticPreviewBytes.isNotEmpty() &&
                    sticker.staticPreviewBytes.size <= STATIC_PREVIEW_BYTE_BUDGET
            }.map { sticker ->
                sticker.copy(
                    stickerId = sticker.stickerId.trim(),
                    uri = sticker.uri.trim(),
                    staticPreviewBytes = sticker.staticPreviewBytes.copyOf(),
                )
            }
            runtimeStickerPacks[id] = FlareStickerPackRegistration(id, pack.title.trim(), stickers)
        }
        _revision.value += 1
    }

    @Synchronized
    fun unregisterStickerPack(packageId: String) {
        if (runtimeStickerPacks.remove(packageId.trim()) != null) _revision.value += 1
    }

    @Synchronized
    fun clearRegisteredStickerPacks() {
        if (runtimeStickerPacks.isEmpty()) return
        runtimeStickerPacks.clear()
        _revision.value += 1
    }

    /** On-disk sticker subdir for a protocol packageId (`gifs` → `default`). */
    fun stickerSubdirForPackageId(packageId: String?): String {
        val p = packageId?.trim().orEmpty()
        return if (p.isEmpty() || p == STICKER_PACKAGE_GIFS) "default" else p
    }

    /** Coil model for a bundled emoji asset. */
    fun emojiAssetUri(key: String): String =
        runtimeEmoji[key.trim()]?.animatedUri
            ?: "file:///android_asset/$ASSET_ROOT/emoji/${key.trim()}.webp"

    fun stickerAssetUri(stickerId: String, packageId: String?): String =
        runtimeStickerPacks[packageId?.trim().takeUnless { it.isNullOrEmpty() } ?: STICKER_PACKAGE_GIFS]
            ?.stickers?.firstOrNull { it.stickerId == stickerId.trim() }?.uri
            ?: "file:///android_asset/$ASSET_ROOT/stickers/${stickerSubdirForPackageId(packageId)}/${stickerId.trim()}.webp"

    fun emojiStaticPreviewBytes(key: String): ByteArray? =
        runtimeEmoji[key.trim()]?.staticPreviewBytes?.copyOf()

    fun stickerStaticPreviewBytes(stickerId: String, packageId: String?): ByteArray? =
        runtimeStickerPacks[packageId?.trim().takeUnless { it.isNullOrEmpty() } ?: STICKER_PACKAGE_GIFS]
            ?.stickers?.firstOrNull { it.stickerId == stickerId.trim() }?.staticPreviewBytes?.copyOf()

    /**
     * Takes the parsed locale table. [ensureLoaded] calls this with what it read from the assets; a JVM
     * test — where there are no Android assets and no `org.json` — parses the same shipped file and calls
     * it directly, so the rule that reads the table is exercised rather than stubbed.
     */
    internal fun loadLocales(table: Map<String, Map<String, String>>) {
        locales = table
    }

    /** Localized emoji-pack label; falls back to the raw key. */
    fun emojiLabel(key: String, locale: String? = null): String {
        val k = key.trim()
        if (k.isEmpty()) return k
        val column = if ((locale ?: "en").lowercase().startsWith("zh")) "zh-Hans" else "en"
        runtimeEmoji[k]?.labels?.get(column)?.takeIf { it.isNotBlank() }?.let { return it.trim() }
        runtimeEmoji[k]?.labels?.get("en")?.takeIf { it.isNotBlank() }?.let { return it.trim() }
        if (locales.isEmpty()) return k
        locales[column]?.get(k)?.takeIf { it.isNotBlank() }?.let { return it.trim() }
        locales["en"]?.get(k)?.takeIf { it.isNotBlank() }?.let { return it.trim() }
        return k
    }

    /**
     * A plain line with `[pack_key]` tokens read in the reader's language: a conversation row or a reply
     * strip shows 一百分, not `[hundred_points]`. The bubble draws the real image instead; this is for the
     * places that are only text. Vue's `formatPackKeysInPlainTextForPreview`, same rule.
     */
    fun localizePackKeysInText(text: String, locale: String? = null): String =
        if (text.isEmpty()) text else PACK_KEY_TOKEN.replace(text) { emojiLabel(it.groupValues[1], locale) }

    fun emojiBracketLabel(key: String, locale: String? = null): String = "[${emojiLabel(key, locale)}]"
}

/** Coil [ImageLoader] that animates webp (emoji/stickers) on API 28+. */
fun flareEmojiStickerImageLoader(context: Context): ImageLoader =
    ImageLoader.Builder(context)
        .components {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                add(ImageDecoderDecoder.Factory())
            } else {
                add(GifDecoder.Factory())
            }
        }
        .build()
