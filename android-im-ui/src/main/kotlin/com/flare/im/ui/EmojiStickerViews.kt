package com.flare.im.ui

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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.Placeholder
import androidx.compose.ui.text.PlaceholderVerticalAlign
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.text.appendInlineContent
import androidx.compose.foundation.text.InlineTextContent
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.ImageLoader
import coil.compose.AsyncImage
import coil.compose.SubcomposeAsyncImage

private val bracketKey = Regex("^\\[([a-z][a-z0-9_]*)]$")
private val bareKey = Regex("^([a-z][a-z0-9_]*)$")
private val emojiToken = Regex("\\[([a-z][a-z0-9_]*)]")

private fun resolvePackKey(raw: String): String? {
    val t = raw.trim()
    bracketKey.find(t)?.let { return it.groupValues[1] }
    bareKey.find(t)?.let { return it.groupValues[1] }
    return null
}

/** Remembers a Coil loader that animates webp, keyed on the application context. */
@Composable
fun rememberFlareEmojiStickerLoader(): ImageLoader {
    val ctx = LocalContext.current.applicationContext
    return remember(ctx) { flareEmojiStickerImageLoader(ctx) }
}

@Composable
private fun rememberCatalogLoaded(): Boolean {
    val ctx = LocalContext.current.applicationContext
    var loaded by remember { mutableStateOf(FlareEmojiStickerCatalog.isLoaded) }
    LaunchedEffect(Unit) {
        FlareEmojiStickerCatalog.ensureLoaded(ctx)
        loaded = true
    }
    return loaded
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
    val loader = rememberFlareEmojiStickerLoader()
    val maxSide = 120
    var w = if ((width ?: 0) > 0) width!! else 68
    var h = if ((height ?: 0) > 0) height!! else 68
    if (w > maxSide || h > maxSide) {
        val scale = maxSide.toDouble() / (if (w > h) w else h)
        w = (w * scale).toInt()
        h = (h * scale).toInt()
    }

    val net = url?.trim().orEmpty()
    val model: Any = if (stickerId.trim().isNotEmpty()) {
        FlareEmojiStickerCatalog.stickerAssetUri(stickerId, packageId)
    } else {
        net
    }

    SubcomposeAsyncImage(
        model = model,
        imageLoader = loader,
        contentDescription = "贴纸",
        modifier = Modifier.size(w.dp, h.dp),
        error = {
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

// --- inline `[key]` emoji inside plain text -------------------------------

/**
 * Renders plain text with inline `[key]` emoji images (unknown keys show their
 * localized label). Call only after excluding Markdown.
 */
@Composable
fun FlarePlainTextEmojiRich(
    text: String,
    style: TextStyle = TextStyle.Default,
    inlineSize: Int = 20,
) {
    rememberCatalogLoaded()
    val locale = currentLocaleTag()
    val loader = rememberFlareEmojiStickerLoader()

    val matches = emojiToken.findAll(text).toList()
    if (matches.isEmpty()) {
        Text(text, style = style)
        return
    }

    val inline = mutableMapOf<String, InlineTextContent>()
    val annotated = buildAnnotatedString {
        var cursor = 0
        matches.forEachIndexed { i, m ->
            if (m.range.first > cursor) append(text.substring(cursor, m.range.first))
            val key = m.groupValues[1]
            if (FlareEmojiStickerCatalog.hasEmojiKey(key)) {
                val id = "emoji_$i"
                appendInlineContent(id, "[$key]")
                inline[id] = InlineTextContent(
                    Placeholder(
                        width = inlineSize.sp,
                        height = inlineSize.sp,
                        placeholderVerticalAlign = PlaceholderVerticalAlign.TextCenter,
                    ),
                ) {
                    AsyncImage(
                        model = FlareEmojiStickerCatalog.emojiAssetUri(key),
                        imageLoader = loader,
                        contentDescription = key,
                        modifier = Modifier.size(inlineSize.dp),
                    )
                }
            } else {
                append(FlareEmojiStickerCatalog.emojiBracketLabel(key, locale))
            }
            cursor = m.range.last + 1
        }
        if (cursor < text.length) append(text.substring(cursor))
    }
    Text(annotated, style = style, inlineContent = inline)
}

/**
 * Composer emoji-pack + sticker picker. One tab for the emoji pack plus one per
 * sticker pack; taps emit [onInsertEmoji] (`key` to insert as `[key]`) or
 * [onSendSticker] (`packageId`, `stickerId`).
 */
@Composable
fun FlareEmojiStickerPicker(
    onInsertEmoji: ((String) -> Unit)? = null,
    onSendSticker: ((packageId: String, stickerId: String) -> Unit)? = null,
    emojiLabel: String = "表情",
    modifier: Modifier = Modifier,
) {
    val colors = flareColors()
    val loaded = rememberCatalogLoaded()
    val loader = rememberFlareEmojiStickerLoader()
    var tab by remember { mutableStateOf(0) }

    if (!loaded) {
        Box(modifier.fillMaxWidth().height(300.dp), contentAlignment = Alignment.Center) {
            Text("…", color = colors.textTertiary)
        }
        return
    }

    val packs = FlareEmojiStickerCatalog.stickerPacks
    val current = tab.coerceIn(0, packs.size)

    Column(modifier.fillMaxWidth().height(300.dp)) {
        Box(Modifier.weight(1f)) {
            if (current == 0) {
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(48.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(10.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    items(FlareEmojiStickerCatalog.emojiKeys) { key ->
                        AsyncImage(
                            model = FlareEmojiStickerCatalog.emojiAssetUri(key),
                            imageLoader = loader,
                            contentDescription = key,
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(FlareSizes.radiusMd))
                                .clickable { onInsertEmoji?.invoke(key) }
                                .padding(4.dp),
                        )
                    }
                }
            } else {
                val pack = packs[current - 1]
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(84.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(10.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    items(pack.stickerIds) { id ->
                        AsyncImage(
                            model = FlareEmojiStickerCatalog.stickerAssetUri(id, pack.id),
                            imageLoader = loader,
                            contentDescription = id,
                            modifier = Modifier
                                .size(76.dp)
                                .clip(RoundedCornerShape(FlareSizes.radiusMd))
                                .clickable { onSendSticker?.invoke(pack.id, id) }
                                .padding(4.dp),
                        )
                    }
                }
            }
        }
        Row(
            Modifier
                .fillMaxWidth()
                .height(44.dp)
                .padding(horizontal = 8.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
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
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                )
            }
        }
    }
}
