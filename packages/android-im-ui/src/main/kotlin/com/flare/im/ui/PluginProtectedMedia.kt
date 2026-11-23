package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.draw.blur
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.disabled
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
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
 * A protected media block (spec Message/PluginView, protected-media; 6.1 of docs/plugin-experience.md): private
 * material read one item at a time, as 16:10 thumbnails three to a row. Nothing is fetched until the viewer asks: a
 * thumbnail starts veiled (the eye over a soft ground); a tap reads it (a block that declares a reason input first asks
 * why, the owner's own page reads with one tap), and the picture opens full screen once the host hands the address
 * back in [states]. The thumbnail of a read picture stays blurred. The picture is held in memory only and takes no
 * touch: no long-press menu, no share or save. TalkBack reads each thumbnail as "{label}, view".
 */
@OptIn(androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
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
    // The item the viewer asked to see: it opens full screen as soon as its address arrives.
    var wanted by remember { mutableStateOf<String?>(null) }
    var viewing by remember { mutableStateOf<PluginProtectedItem?>(null) }
    fun request(item: PluginProtectedItem) {
        if (FlarePluginProtectedMedia.source(states[item.id]?.url) != null) { viewing = item; return }
        if (busy || onRead == null || states[item.id]?.loading == true) return
        wanted = item.id
        if (block.asksReason) asking = item else block.read(item, "")?.let(onRead)
    }
    LaunchedEffect(states, wanted) {
        val id = wanted ?: return@LaunchedEffect
        if (FlarePluginProtectedMedia.source(states[id]?.url) != null) {
            viewing = block.items.firstOrNull { it.id == id }
            wanted = null
        } else if (states[id]?.error != null) wanted = null
    }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        block.label?.takeIf { it.isNotEmpty() }?.let { PluginSectionTitle(it) }
        // R8: no material is the compact empty state (a document page's icon).
        if (block.items.isEmpty()) EmptyState(title = block.emptyText ?: strings.pluginViewEmpty, icon = "admin", compact = true)
        androidx.compose.foundation.layout.FlowRow(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
                block.items.forEach { item ->
                    val state = states[item.id]
                    val source = FlarePluginProtectedMedia.source(state?.url)
                    val enabled = block.action != null && (source != null || (!busy && onRead != null && state?.loading != true))
                    Column(Modifier.width(FlareSizes.componentDocumentThumbHeight * 1.6f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                        Box(
                            // 6.1: component.documentThumbHeight high, 16:10.
                            Modifier.size(FlareSizes.componentDocumentThumbHeight * 1.6f, FlareSizes.componentDocumentThumbHeight)
                                .clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgTertiary)
                                // The tag sits outside the cleared semantics, or clearAndSetSemantics drops it.
                                .testTag("plugin-media-${item.id}-thumb")
                                .clickable(enabled = enabled, role = Role.Button) { request(item) }
                                .clearAndSetSemantics {
                                    contentDescription = strings.pluginProtectedMediaTapToView.replace("{label}", item.label)
                                    role = Role.Button
                                    if (!enabled) disabled()
                                },
                            contentAlignment = Alignment.Center,
                        ) {
                            if (source != null && item.isImage) SubcomposeAsyncImage(
                                model = remember(source) { pluginProtectedImageRequest(context, source) },
                                contentDescription = null,
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.fillMaxSize().blur(12.dp),
                            )
                            when {
                                state?.loading == true -> CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeMd), strokeWidth = 2.dp, color = colors.textSecondary)
                                else -> FlareIcon(if (item.isImage) "eye" else "file", size = FlareSizes.iconSizeMd, tint = colors.textSecondary)
                            }
                        }
                        Text(item.label, color = colors.textSecondary, fontSize = FlareTextRoles.Caption.fontSize, maxLines = 1,
                            modifier = Modifier.clearAndSetSemantics {})
                        state?.error?.let { Text(it, color = colors.errorText, fontSize = FlareTextRoles.Caption.fontSize) }
                    }
                }
        }
        Text(if (block.asksReason) strings.pluginProtectedMediaNotice else strings.pluginProtectedMediaOwnNotice,
            color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
    }
    asking?.let { item ->
        BottomSheet(onClose = { asking = null; wanted = null }, title = block.action?.label) {
            PluginForm(
                inputs = listOf(PluginInput(id = "reason", kind = PluginInputKind.Textarea, label = strings.pluginProtectedMediaReason,
                    required = true, maxLength = 160)),
                submitLabel = block.action?.label,
                onSubmit = { values ->
                    val reason = (values["reason"] as? String)?.trim().orEmpty()
                    asking = null
                    if (reason.isNotEmpty()) block.read(item, reason)?.let { onRead?.invoke(it) }
                },
                onCancel = { asking = null; wanted = null },
            )
        }
    }
    viewing?.let { item ->
        val source = FlarePluginProtectedMedia.source(states[item.id]?.url)
        androidx.compose.ui.window.Dialog(
            onDismissRequest = { viewing = null },
            properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
        ) {
            FlareEdgeToEdgeDialogWindow()
            Box(Modifier.fillMaxSize().background(colors.mediaStage).semantics { paneTitle = item.label }, contentAlignment = Alignment.Center) {
                when {
                    source == null -> Unit
                    item.isImage -> SubcomposeAsyncImage(
                        model = remember(source) { pluginProtectedImageRequest(context, source) },
                        contentDescription = item.label,
                        contentScale = ContentScale.Fit,
                        loading = { CircularProgressIndicator(color = colors.mediaOnStage) },
                        error = { Text(strings.pluginProtectedMediaUnavailable, color = colors.mediaOnStage, fontSize = FlareSizes.fontSizeMd) },
                        modifier = Modifier.fillMaxSize().testTag("plugin-media-${item.id}-image"),
                    )
                    else -> Text(strings.pluginProtectedMediaNotPreviewable, color = colors.mediaOnStage, fontSize = FlareSizes.fontSizeMd)
                }
                Box(Modifier.align(Alignment.TopEnd).statusBarsPadding().padding(FlareSizes.spacingSm)) {
                    IconButton(icon = "close", contentDescription = strings.close, tint = colors.mediaOnStage, onClick = { viewing = null })
                }
            }
        }
    }
}
