package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/** One picked attachment a host holds before it is sent: a picture drawn from [previewUrl] (any Coil model string), or a file. */
data class FlareMediaUploadItem(
    val id: String,
    val name: String,
    val image: Boolean,
    val previewUrl: String? = null,
    /** The line on the item (待发送, …); none when null. */
    val status: String? = null,
)

/**
 * Picked attachments waiting to be sent (Vue `FlareMediaUpload` without its pick key, as the chat's 发送附件 sheet uses
 * it): pictures in a three-column grid, anything else as file rows. Each item shows its status and an ✕ named
 * `pluginFileRemove` that calls [onRemove]; a picture opens [onPreview]. [disabled] locks both.
 */
@Composable
fun MediaUpload(
    items: List<FlareMediaUploadItem>,
    onRemove: ((String) -> Unit)? = null,
    onPreview: ((String) -> Unit)? = null,
    disabled: Boolean = false,
) {
    val colors = flareColors()
    val strings = flareStrings()
    @Composable fun remove(item: FlareMediaUploadItem, modifier: Modifier = Modifier) {
        if (onRemove == null) return
        Box(
            modifier.size(FlareSizes.touchTarget).clickable(enabled = !disabled, role = Role.Button) { onRemove(item.id) }
                .semantics { contentDescription = "${strings.pluginFileRemove} ${item.name}" },
            contentAlignment = Alignment.Center,
        ) {
            Box(Modifier.size(22.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.55f)), contentAlignment = Alignment.Center) {
                FlareIcon(name = "close", size = FlareSizes.iconSizeXs, tint = Color.White)
            }
        }
    }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        items.filter { it.image }.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                row.forEach { item ->
                    Box(
                        Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)
                            .clickable(enabled = !disabled && onPreview != null, onClickLabel = strings.pluginFilePreview) { onPreview?.invoke(item.id) },
                    ) {
                        AsyncImage(model = item.previewUrl, contentDescription = item.name, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                        item.status?.let {
                            Text(
                                it, color = Color.White, fontSize = FlareSizes.fontSizeXs.value.sp, maxLines = 1,
                                modifier = Modifier.align(Alignment.BottomStart).fillMaxWidth().background(Color.Black.copy(alpha = 0.45f))
                                    .padding(horizontal = FlareSizes.spacingXs, vertical = 2.dp),
                            )
                        }
                        remove(item, Modifier.align(Alignment.TopEnd))
                    }
                }
                repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
        items.filterNot { it.image }.forEach { item ->
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)
                    .padding(start = FlareSizes.spacingMd),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                FlareIcon(name = "file", size = FlareSizes.iconSizeLg, tint = colors.textSecondary)
                Spacer(Modifier.width(FlareSizes.spacingSm))
                Column(Modifier.weight(1f).padding(vertical = FlareSizes.spacingSm)) {
                    Text(item.name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    item.status?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp) }
                }
                remove(item)
            }
        }
    }
}
