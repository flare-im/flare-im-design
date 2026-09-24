package com.flare.im.ui

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream
import java.net.URL
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.SentimentSatisfiedAlt
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.Placeholder
import androidx.compose.ui.text.PlaceholderVerticalAlign
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.text.appendInlineContent
import androidx.compose.foundation.text.InlineTextContent
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.layout.fillMaxSize
import coil.ImageLoader
import coil.compose.AsyncImage
import coil.compose.SubcomposeAsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private val bracketKey = Regex("^\\[([a-z][a-z0-9_]*)]$")
private val bareKey = Regex("^([a-z][a-z0-9_]*)$")
private val emojiToken = Regex("\\[([a-z][a-z0-9_]*)]")

/** One `[key]` emoji-pack token inside plain text: its UTF-16 range [start, end) and its key. */
internal data class FlareInlineEmojiRun(val start: Int, val end: Int, val key: String)

/**
 * The `[key]` tokens in [text] that name a bundled emoji ([isKnown]), in order (Vue `splitPlainTextForEmojiDisplay`).
 * An unknown key is not a run: it stays the bracket text it is.
 */
internal fun flareInlineEmojiRuns(text: String, isKnown: (String) -> Boolean): List<FlareInlineEmojiRun> =
    emojiToken.findAll(text).mapNotNull { match ->
        val key = match.groupValues[1]
        if (isKnown(key)) FlareInlineEmojiRun(match.range.first, match.range.last + 1, key) else null
    }.toList()

/** Whether [text] may hold an emoji-pack token at all; text without one never loads the catalog. */
internal fun flareMayHoldEmojiTokens(text: String): Boolean = emojiToken.containsMatchIn(text)

/** The inline-content id a text body draws [key]'s emoji under. */
internal fun flareInlineEmojiId(key: String): String = "flare-emoji:$key"

private fun resolvePackKey(raw: String): String? {
    val t = raw.trim()
    bracketKey.find(t)?.let { return it.groupValues[1] }
    bareKey.find(t)?.let { return it.groupValues[1] }
    return null
}

/** A text body is an animated standalone emoji only when its entire trimmed
 * wire value is one known bracket token. Inline/mixed tokens stay static. */
internal fun flareLoneEmojiPackKey(text: String): String? {
    val key = bracketKey.matchEntire(text.trim())?.groupValues?.getOrNull(1) ?: return null
    return key.takeIf(FlareEmojiStickerCatalog::hasEmojiKey)
}

/** Remembers a Coil loader that animates webp, keyed on the application context. */
@Composable
internal fun rememberFlareEmojiStickerLoader(): ImageLoader {
    val ctx = LocalContext.current.applicationContext
    return remember(ctx) { flareEmojiStickerImageLoader(ctx) }
}

@Composable
internal fun rememberCatalogLoaded(): Boolean {
    val ctx = LocalContext.current.applicationContext
    var loaded by remember { mutableStateOf(FlareEmojiStickerCatalog.isLoaded) }
    LaunchedEffect(Unit) {
        FlareEmojiStickerCatalog.ensureLoaded(ctx)
        loaded = true
    }
    return loaded
}

private const val staticImageByteBudget = 8 * 1024 * 1024

private fun readBounded(url: String): ByteArray? {
    val connection = URL(url).openConnection().apply {
        connectTimeout = 5_000
        readTimeout = 8_000
        useCaches = true
    }
    val expected = connection.contentLengthLong
    if (expected > staticImageByteBudget) return null
    return connection.getInputStream().use { input ->
        val output = ByteArrayOutputStream()
        val buffer = ByteArray(16 * 1024)
        var total = 0
        while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            total += count
            if (total > staticImageByteBudget) return null
            output.write(buffer, 0, count)
        }
        output.toByteArray()
    }
}

@Composable
private fun FlareStaticCatalogImage(
    assetPath: String?,
    previewBytes: ByteArray?,
    remoteUrl: String? = null,
    contentDescription: String?,
    modifier: Modifier,
    fallback: @Composable () -> Unit = {},
) {
    val context = LocalContext.current.applicationContext
    val revision by FlareEmojiStickerCatalog.revision.collectAsState()
    val bitmap by produceState<Bitmap?>(null, assetPath, previewBytes?.contentHashCode(), remoteUrl, revision) {
        value = withContext(Dispatchers.IO) {
            previewBytes
                ?.takeIf { it.isNotEmpty() && it.size <= staticImageByteBudget }
                ?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
                ?: assetPath?.takeIf(String::isNotBlank)?.let { path ->
                    runCatching { context.assets.open(path).use(BitmapFactory::decodeStream) }.getOrNull()
                }
                ?: remoteUrl
                    ?.takeIf { it.startsWith("https://") || it.startsWith("http://") }
                    ?.let(::readBounded)
                    ?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
        }
    }
    val frame = bitmap
    if (frame != null) {
        androidx.compose.foundation.Image(
            bitmap = frame.asImageBitmap(),
            contentDescription = contentDescription,
            modifier = modifier,
        )
    } else {
        fallback()
    }
}

@Composable
private fun currentLocaleTag(): String =
    LocalConfiguration.current.locales.get(0)?.toLanguageTag() ?: "en"

/**
 * Emoji-pack message body (`[key]` / bare key / a raw unicode emoji). A known
 * pack key renders the animated webp; otherwise the localized `[label]` or a
 * large unicode glyph.
 */
@Composable
fun FlareEmojiPackMessage(emoji: String, isSelf: Boolean = false) {
    val colors = flareColors()
    val loaded = rememberCatalogLoaded()
    val locale = currentLocaleTag()
    val loader = rememberFlareEmojiStickerLoader()
    val packKey = resolvePackKey(emoji)

    if (packKey != null) {
        val label = if (loaded) FlareEmojiStickerCatalog.emojiBracketLabel(packKey, locale) else "[$packKey]"
        SubcomposeAsyncImage(
            model = FlareEmojiStickerCatalog.emojiAssetUri(packKey),
            imageLoader = loader,
            contentDescription = label,
            modifier = Modifier.size(120.dp),
            error = {
                Box(Modifier.size(120.dp), contentAlignment = Alignment.Center) {
                    Text(label, color = colors.textSecondary, fontSize = 20.sp, fontWeight = FontWeight.Medium)
                }
            },
        )
        return
    }
    Text(emoji, fontSize = 48.sp)
}

/**
 * Sticker message body — resolves a bundled pack sticker by `packageId` +
 * `stickerId`, falling back to a network url, then a placeholder.
 */
@Composable
fun FlareStickerPackMessage(
    stickerId: String,
    packageId: String? = null,
    url: String? = null,
    width: Int? = null,
    height: Int? = null,
    isSelf: Boolean = false,
) {
    val colors = flareColors()
    val maxSide = 120
    var w = if ((width ?: 0) > 0) width!! else 68
    var h = if ((height ?: 0) > 0) height!! else 68
    if (w > maxSide || h > maxSide) {
        val scale = maxSide.toDouble() / (if (w > h) w else h)
        w = (w * scale).toInt()
        h = (h * scale).toInt()
    }

    val net = url?.trim().orEmpty()
    val sid = stickerId.trim()
    val preview = FlareEmojiStickerCatalog.stickerStaticPreviewBytes(sid, packageId)
    FlareStaticCatalogImage(
        assetPath = if (sid.isNotEmpty() && preview == null) {
            "${FlareEmojiStickerCatalog.ASSET_ROOT}/stickers/${FlareEmojiStickerCatalog.stickerSubdirForPackageId(packageId)}/$sid.webp"
        } else null,
        previewBytes = preview,
        remoteUrl = net.takeIf(String::isNotEmpty),
        contentDescription = flareStrings().sticker,
        modifier = Modifier.size(w.dp, h.dp),
        fallback = {
            Box(
                Modifier
                    .size(w.dp, h.dp)
                    .clip(RoundedCornerShape(FlareSizes.radiusLg))
                    .background(colors.bgHover)
                    .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Outlined.SentimentSatisfiedAlt, contentDescription = null, tint = colors.textSecondary)
            }
        },
    )
}

// --- inline `[key]` emoji inside plain text: see [flareInlineEmojiRuns] and TextMessage ---------------

/**
 * The inline emoji a text body draws for [keys]: each bundled webp in a square of the text's 1.72 em (Vue
 * `PlainTextEmojiRich`), centred on the line. The token stays the text underneath, so selection, copy and the
 * mention and link ranges keep their offsets.
 */
@Composable
internal fun rememberFlareInlineEmojiContent(keys: Set<String>): Map<String, InlineTextContent> {
    val revision by FlareEmojiStickerCatalog.revision.collectAsState()
    return remember(keys, revision) {
        keys.associate { key ->
            flareInlineEmojiId(key) to InlineTextContent(Placeholder(1.72.em, 1.72.em, PlaceholderVerticalAlign.TextCenter)) {
                val preview = FlareEmojiStickerCatalog.emojiStaticPreviewBytes(key)
                FlareStaticCatalogImage(
                    assetPath = if (preview == null) "${FlareEmojiStickerCatalog.ASSET_ROOT}/emoji/$key.webp" else null,
                    previewBytes = preview,
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                )
            }
        }
    }
}

/**
 * Composer emoji-pack + sticker picker. One tab for the emoji pack plus one per
 * sticker pack; taps emit [onInsertEmoji] (`key` to insert as `[key]`) or
 * [onSendSticker] (`packageId`, `stickerId`).
 */
@Suppress("NAME_SHADOWING")
@Composable
fun FlareEmojiStickerPicker(
    onInsertEmoji: ((String) -> Unit)? = null,
    onSendSticker: ((packageId: String, stickerId: String) -> Unit)? = null,
    emojiLabel: String? = null,
    modifier: Modifier = Modifier,
) {
    val strings = flareStrings()
    val emojiLabel = emojiLabel ?: strings.emojiStickerPickerEmoji
    val colors = flareColors()
    val loaded = rememberCatalogLoaded()
    val revision by FlareEmojiStickerCatalog.revision.collectAsState()
    var tab by remember { mutableStateOf(0) }

    if (!loaded) {
        Box(modifier.fillMaxWidth().height(300.dp), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(
                Modifier.size(FlareSizes.iconSizeLg).semantics { contentDescription = strings.emojiStickerPickerLoading },
                color = colors.textTertiary,
                strokeWidth = 2.dp,
            )
        }
        return
    }

    val packs = remember(revision) { FlareEmojiStickerCatalog.stickerPacks }
    val current = tab.coerceIn(0, packs.size)

    Column(modifier.fillMaxWidth().height(300.dp)) {
        Box(Modifier.weight(1f)) {
            if (current == 0) {
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(48.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(FlareSizes.spacing2sm),
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs),
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs),
                ) {
                    items(FlareEmojiStickerCatalog.emojiKeys) { key ->
                        val preview = FlareEmojiStickerCatalog.emojiStaticPreviewBytes(key)
                        FlareStaticCatalogImage(
                            assetPath = if (preview == null) "${FlareEmojiStickerCatalog.ASSET_ROOT}/emoji/$key.webp" else null,
                            previewBytes = preview,
                            contentDescription = key,
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(FlareSizes.radiusMd))
                                .clickable { onInsertEmoji?.invoke(key) }
                                .padding(FlareSizes.spacingXs),
                        )
                    }
                }
            } else {
                val pack = packs[current - 1]
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(84.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(FlareSizes.spacing2sm),
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                ) {
                    items(pack.stickerIds) { id ->
                        val preview = FlareEmojiStickerCatalog.stickerStaticPreviewBytes(id, pack.id)
                        FlareStaticCatalogImage(
                            assetPath = if (preview == null) "${FlareEmojiStickerCatalog.ASSET_ROOT}/stickers/${FlareEmojiStickerCatalog.stickerSubdirForPackageId(pack.id)}/$id.webp" else null,
                            previewBytes = preview,
                            contentDescription = id,
                            modifier = Modifier
                                .size(76.dp)
                                .clip(RoundedCornerShape(FlareSizes.radiusMd))
                                .clickable { onSendSticker?.invoke(pack.id, id) }
                                .padding(FlareSizes.spacingXs),
                        )
                    }
                }
            }
        }
        Row(
            Modifier
                .fillMaxWidth()
                .height(44.dp)
                .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacing2xs),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            val labels = listOf(emojiLabel) + packs.map { it.title }
            labels.forEachIndexed { i, label ->
                val selected = i == current
                Text(
                    label,
                    color = if (selected) colors.textPrimary else colors.textSecondary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                    modifier = Modifier
                        .clip(RoundedCornerShape(FlareSizes.radiusMd))
                        .background(if (selected) colors.bgHover else androidx.compose.ui.graphics.Color.Transparent)
                        .clickable { tab = i }
                        .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacing2xs),
                )
            }
        }
    }
}
