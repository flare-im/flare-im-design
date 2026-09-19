package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * image group — an album: square tiles laid out by the shared rule (`spec/image-group-layout-vectors.json`), the last
 * drawn tile covered with `+N` when the album holds more images than tiles, and the album's [description] under them.
 *
 * Presentational: a tile calls [onOpen] with its image's index — the covered tile opens its own image — and the host
 * decides what opens (one image, or the conversation's gallery). Every tile is a button named with its position in
 * the album; without [onOpen] the tiles are pictures only.
 */
@Composable
fun ImageGroupMessage(
    images: List<FlareImageContent>,
    description: String = "",
    self: Boolean = false,
    width: Dp = 240.dp,
    onOpen: ((Int) -> Unit)? = null,
) {
    if (images.isEmpty()) return
    val colors = flareColors()
    val strings = flareStrings()
    val layout = flareImageGroupLayout(images.size)
    val gap = FlareSizes.spacingXs
    val side = (width - gap * (layout.columns - 1)) / layout.columns
    Column(
        Modifier.width(width).semantics { contentDescription = strings.messageImageGroupLabel(images.size) },
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs),
    ) {
        Column(Modifier.clip(RoundedCornerShape(FlareSizes.radiusLg)), verticalArrangement = Arrangement.spacedBy(gap)) {
            for (start in 0 until layout.visible step layout.columns) {
                Row(horizontalArrangement = Arrangement.spacedBy(gap)) {
                    for (index in start until minOf(start + layout.columns, layout.visible)) {
                        val image = images[index]
                        val label = flareImageGroupTileLabel(index, images.size, layout, strings)
                        Box(
                            Modifier.size(side)
                                .background(colors.bgTertiary)
                                .then(if (onOpen != null) Modifier.clickable { onOpen(index) } else Modifier)
                                .clearAndSetSemantics {
                                    contentDescription = label
                                    if (onOpen != null) {
                                        role = Role.Button
                                        onClick { onOpen(index); true }
                                    }
                                },
                            contentAlignment = Alignment.Center,
                        ) {
                            NetImage(image.thumbnailUrl?.takeIf { it.isNotBlank() } ?: image.url, Modifier.matchParentSize()) {
                                Icon(flareIconVector("image"), null, Modifier.size(22.dp), tint = colors.textTertiary)
                            }
                            if (layout.covers(index)) {
                                Box(Modifier.matchParentSize().background(Color.Black.copy(alpha = 0.45f)), contentAlignment = Alignment.Center) {
                                    Text("+${layout.more}", color = Color.White, fontSize = FlareSizes.fontSize2xl, fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }
            }
        }
        val text = description.trim()
        if (text.isNotEmpty()) {
            Text(
                text,
                color = if (self) colors.messageOutgoingForeground else colors.messageIncomingForeground,
                fontSize = FlareSizes.fontSizeMd,
            )
        }
    }
}
