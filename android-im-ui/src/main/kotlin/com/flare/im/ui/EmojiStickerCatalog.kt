package com.flare.im.ui

import android.content.Context
import android.os.Build
import coil.ImageLoader
import coil.decode.GifDecoder
import coil.decode.ImageDecoderDecoder
import kotlinx.coroutines.Dispatchers
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

/**
 * Cross-platform emoji-pack + sticker catalog, backed by the flare-im-design
 * manifest bundled with this library (a symlink mirror of the single source
 * `flare-im-design/assets/emoji-sticker`, packaged under `assets/emoji-sticker`).
 *
 * Message views resolve assets by path convention (Coil renders the webp, a
 * missing file triggers the fallback). The picker + localized labels use
 * [ensureLoaded] to read the manifest + locales from `assets`.
 */
object FlareEmojiStickerCatalog {
    const val ASSET_ROOT = "emoji-sticker"

    /** Protocol packageId whose on-disk dir is `default/`. */
    const val STICKER_PACKAGE_GIFS = "gifs"

    @Volatile
    private var loaded = false
    val isLoaded: Boolean get() = loaded

    var emojiKeys: List<String> = emptyList()
        private set
    private var emojiKeySet: Set<String> = emptySet()

    var stickerPacks: List<FlareStickerPack> = emptyList()
        private set

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
        emojiKeys = keys
        emojiKeySet = keys.toSet()

        val packsJson = manifest.optJSONArray("stickerPacks")
        stickerPacks = buildList {
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

        locales = runCatching {
            val raw = JSONObject(assets.open("$ASSET_ROOT/emoji-locales.json").use { it.readBytes().decodeToString() })
            buildMap {
                for (col in raw.keys()) {
                    val map = raw.getJSONObject(col)
                    put(col, buildMap { for (k in map.keys()) put(k, map.getString(k)) })
                }
            }
        }.getOrDefault(emptyMap())

        loaded = true
    }

    fun hasEmojiKey(key: String): Boolean = emojiKeySet.contains(key.trim())

    /** On-disk sticker subdir for a protocol packageId (`gifs` → `default`). */
    fun stickerSubdirForPackageId(packageId: String?): String {
        val p = packageId?.trim().orEmpty()
        return if (p.isEmpty() || p == STICKER_PACKAGE_GIFS) "default" else p
    }

    /** Coil model for a bundled emoji asset. */
    fun emojiAssetUri(key: String): String =
        "file:///android_asset/$ASSET_ROOT/emoji/${key.trim()}.webp"

    fun stickerAssetUri(stickerId: String, packageId: String?): String =
        "file:///android_asset/$ASSET_ROOT/stickers/${stickerSubdirForPackageId(packageId)}/${stickerId.trim()}.webp"

    /** Localized emoji-pack label; falls back to the raw key. */
    fun emojiLabel(key: String, locale: String? = null): String {
        val k = key.trim()
        if (k.isEmpty() || locales.isEmpty()) return k
        val column = if ((locale ?: "en").lowercase().startsWith("zh")) "zh-Hans" else "en"
        locales[column]?.get(k)?.takeIf { it.isNotBlank() }?.let { return it.trim() }
        locales["en"]?.get(k)?.takeIf { it.isNotBlank() }?.let { return it.trim() }
        return k
    }

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
