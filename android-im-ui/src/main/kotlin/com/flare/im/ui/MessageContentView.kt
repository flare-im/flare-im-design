package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Movie
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material.icons.rounded.PlayCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Context passed to every content renderer. */
data class FlareContentContext(
    val isSelf: Boolean,
    val previewMode: Boolean = false,
    val senderName: String? = null,
    val mediaState: FlareMediaDownloadState? = null,
    val onMediaAction: ((FlareMessageContent) -> Unit)? = null,
)

typealias FlareContentBuilder = @Composable (FlareMessageContent, FlareContentContext) -> Unit

/**
 * Registry for product content types (`vote`, `task`…). Built-in types are
 * rendered directly by [MessageContentView]; register a builder to add/override.
 */
object FlareContentRegistry {
    private val builders = mutableMapOf<String, FlareContentBuilder>()
    fun register(type: String, builder: FlareContentBuilder) { builders[type] = builder }
    fun unregister(type: String) { builders.remove(type) }
    fun lookup(type: String): FlareContentBuilder? = builders[type]
}

/**
 * Content-type dispatcher — renders a message body by type. Spec:
 * Message/MessageContentView (`MessageContentView`). Image/video are shown as
 * placeholders (the package bundles no image loader); register a builder or wrap
 * with Coil in the host to display real media.
 */
@Composable
fun MessageContentView(
    content: FlareMessageContent,
    isSelf: Boolean = false,
    senderName: String? = null,
    mediaState: FlareMediaDownloadState? = null,
    onMediaAction: ((FlareMessageContent) -> Unit)? = null,
) {
    val ctx = FlareContentContext(isSelf, senderName = senderName, mediaState = mediaState, onMediaAction = onMediaAction)
    val custom = FlareContentRegistry.lookup(content.type)
    if (custom != null) { custom(content, ctx); return }

    val colors = flareColors()
    val onBubble = if (isSelf) Color.White else colors.textPrimary

    when (content) {
        is FlareTextContent -> Text(content.text, color = onBubble, fontSize = FlareSizes.fontSizeXl.value.sp, lineHeight = (FlareSizes.fontSizeXl.value * 1.45f).sp)
        is FlareEmojiContent -> FlareEmojiPackMessage(content.emoji, isSelf = ctx.isSelf)
        is FlareStickerContent -> FlareStickerPackMessage(
            stickerId = content.stickerId.orEmpty(),
            packageId = content.packageId,
            url = content.url,
            width = content.width,
            height = content.height,
            isSelf = ctx.isSelf,
        )
        is FlareImageContent -> Box {
            mediaPlaceholder(200.dp, colors, Icons.Outlined.Image, onClick = { onMediaAction?.invoke(content) })
            if (mediaState?.isDownloading == true) {
                Box(Modifier.size(200.dp).background(Color.Black.copy(alpha = 0.35f)), contentAlignment = Alignment.Center) {
                    Text("${mediaState.progressPct}%", color = Color.White, fontWeight = FontWeight.SemiBold)
                }
            }
        }
        is FlareVideoContent -> Box(contentAlignment = Alignment.Center) {
            mediaPlaceholder(200.dp, colors, Icons.Outlined.Movie, onClick = { onMediaAction?.invoke(content) })
            Icon(Icons.Rounded.PlayCircle, null, Modifier.size(44.dp), tint = Color.White.copy(alpha = 0.9f))
        }
        is FlareAudioContent -> Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Outlined.VolumeUp, null, tint = onBubble)
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Text(duration(content.durationSec), color = onBubble, fontSize = FlareSizes.fontSizeLg.value.sp)
        }
        is FlareFileContent -> Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.clickable { onMediaAction?.invoke(content) },
        ) {
            Icon(Icons.Outlined.Description, null, Modifier.size(28.dp), tint = onBubble)
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Column {
                Text(content.name, color = onBubble, fontWeight = FontWeight.Medium, maxLines = 1,
                    overflow = TextOverflow.Ellipsis, modifier = Modifier.widthIn(max = 180.dp))
                if (content.sizeBytes > 0) Text(bytes(content.sizeBytes), color = onBubble.copy(alpha = 0.7f), fontSize = FlareSizes.fontSizeSm.value.sp)
            }
        }
        is FlareLocationContent -> Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Outlined.LocationOn, null, tint = colors.error)
            Spacer(Modifier.width(FlareSizes.spacingXs))
            Column {
                Text(content.name, color = onBubble, fontWeight = FontWeight.Medium)
                if (content.address.isNotEmpty()) Text(content.address, color = onBubble.copy(alpha = 0.7f),
                    fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.widthIn(max = 200.dp))
            }
        }
        is FlareCardContent -> Column(
            Modifier.widthIn(max = 240.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(colors.bgPrimary).border(1.dp, colors.borderSecondary, RoundedCornerShape(FlareSizes.radiusLg))
                .padding(FlareSizes.spacingMd),
        ) {
            Text(content.title, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, maxLines = 2, overflow = TextOverflow.Ellipsis)
            content.subtitle?.takeIf { it.isNotEmpty() }?.let {
                Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
            }
            content.sourceLabel?.takeIf { it.isNotEmpty() }?.let {
                Spacer(Modifier.size(FlareSizes.spacingSm)); Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs.value.sp)
            }
        }
        is FlarePlaceholderContent -> chip(content.label, colors)
        is FlareGenericContent -> chip("[${content.label}]", colors)
        else -> chip("[${content.type}]", colors)
    }
}

@Composable
private fun chip(label: String, colors: FlareColors) {
    Box(
        Modifier.clip(RoundedCornerShape(FlareSizes.radiusSm)).background(colors.bgTertiary)
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
    ) { Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp) }
}

@Composable
private fun mediaPlaceholder(side: androidx.compose.ui.unit.Dp, colors: FlareColors, icon: androidx.compose.ui.graphics.vector.ImageVector, onClick: (() -> Unit)? = null) {
    Box(
        Modifier.size(side).heightIn(max = 200.dp).clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgTertiary)
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, null, Modifier.size(32.dp), tint = colors.textTertiary) }
}

internal fun duration(seconds: Int): String = "%02d:%02d".format(seconds / 60, seconds % 60)

internal fun bytes(b: Int): String = when {
    b < 1024 -> "$b B"
    b < 1024 * 1024 -> "%.1f KB".format(b / 1024.0)
    b < 1024 * 1024 * 1024 -> "%.1f MB".format(b / 1024.0 / 1024)
    else -> "%.1f GB".format(b / 1024.0 / 1024 / 1024)
}
