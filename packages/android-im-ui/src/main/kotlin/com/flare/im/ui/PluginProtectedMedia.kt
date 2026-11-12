package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import coil.compose.SubcomposeAsyncImage
import coil.request.CachePolicy
import coil.request.ImageRequest

/**
 * The image request for a protected picture: memory only. The disk cache is off for reading and writing, so the
 * grant address and the bytes never reach a file; the memory entry goes away with the process.
 */
internal fun pluginProtectedImageRequest(context: android.content.Context, url: String): ImageRequest =
    ImageRequest.Builder(context)
        .data(url)
        .diskCachePolicy(CachePolicy.DISABLED)
        .networkCachePolicy(CachePolicy.ENABLED)
        .memoryCachePolicy(CachePolicy.ENABLED)
        .build()

/**
 * A protected media block (spec Message/PluginView, protected-media): private material read one item at a time.
 * Nothing is fetched until the viewer asks; a block that declares a reason input first asks why, the owner's own page
 * reads with one tap. The host runs the read ([onRead]) and hands the address back in [states]. The picture is held in
 * memory only and takes no touch: no long-press menu, no share or save.
 */
@Composable
internal fun PluginProtectedMediaBlockView(
    block: PluginProtectedMediaBlock,
    states: Map<String, PluginProtectedMediaState>,
    busy: Boolean,
    onRead: ((PluginProtectedMediaRead) -> Unit)?,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val context = LocalContext.current
    var asking by remember { mutableStateOf<PluginProtectedItem?>(null) }
    fun request(item: PluginProtectedItem) {
        if (busy || onRead == null) return
        if (block.asksReason) asking = item else block.read(item, "")?.let(onRead)
    }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        block.label?.takeIf { it.isNotEmpty() }?.let {
            Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium)
        }
        if (block.items.isEmpty()) Text(block.emptyText ?: strings.pluginViewEmpty, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
        block.items.forEach { item ->
            val state = states[item.id]
            val source = FlarePluginProtectedMedia.source(state?.url)
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                    Text(item.label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, modifier = Modifier.weight(1f))
                    val action = block.action
                    if (action != null && source == null) Button(
                        label = if (block.asksReason) action.label else strings.pluginProtectedMediaView,
                        variant = FlareButtonVariant.Secondary, size = FlareControlSize.Sm, loading = state?.loading == true,
                        disabled = busy || onRead == null || state?.loading == true, onClick = { request(item) },
                    )
                }
                if (source != null) {
                    if (item.isImage) SubcomposeAsyncImage(
                        model = remember(source) { pluginProtectedImageRequest(context, source) },
                        contentDescription = item.label,
                        contentScale = ContentScale.Fit,
                        loading = { CircularProgressIndicator() },
                        error = { Text(strings.pluginProtectedMediaUnavailable, color = colors.errorText, fontSize = FlareSizes.fontSizeSm) },
                        modifier = Modifier.fillMaxWidth().heightIn(max = FlareSizes.componentRichCardWidth)
                            .clip(RoundedCornerShape(FlareSizes.radiusMd)).testTag("plugin-media-${item.id}-image"),
                    ) else Text(strings.pluginProtectedMediaNotPreviewable, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                }
                state?.error?.let { Text(it, color = colors.errorText, fontSize = FlareSizes.fontSizeSm) }
            }
        }
        Text(if (block.asksReason) strings.pluginProtectedMediaNotice else strings.pluginProtectedMediaOwnNotice,
            color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
    }
    asking?.let { item ->
        BottomSheet(onClose = { asking = null }, title = block.action?.label) {
            PluginForm(
                inputs = listOf(PluginInput(id = "reason", kind = PluginInputKind.Textarea, label = strings.pluginProtectedMediaReason,
                    required = true, maxLength = 160)),
                submitLabel = block.action?.label,
                onSubmit = { values ->
                    val reason = (values["reason"] as? String)?.trim().orEmpty()
                    asking = null
                    if (reason.isNotEmpty()) block.read(item, reason)?.let { onRead?.invoke(it) }
                },
                onCancel = { asking = null },
            )
        }
    }
}
