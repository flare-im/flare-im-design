package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/** Adaptive album grid (九宫格) with +N overflow. Spec: Message/ImageGrid. */
@Composable
fun ImageGrid(
    images: List<GridImage>,
    max: Int = 9,
    onOpen: ((Int) -> Unit)? = null,
) {
    val colors = flareColors()
    val visible = images.take(max)
    val overflow = images.size - visible.size
    if (visible.isEmpty()) return

    if (visible.size == 1) {
        Box(
            Modifier.widthIn(max = 220.dp).heightIn(max = 260.dp)
                .clip(RoundedCornerShape(12.dp)).background(colors.bgSecondary)
                .clickable { onOpen?.invoke(0) },
        ) { imageOrPlaceholder(visible[0].url, ContentScale.Fit) }
        return
    }

    val cols = when {
        visible.size == 4 -> 2
        visible.size <= 3 -> visible.size
        else -> 3
    }
    val rows = visible.chunked(cols)
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        rows.forEachIndexed { rowIdx, row ->
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                row.forEachIndexed { colIdx, img ->
                    val index = rowIdx * cols + colIdx
                    Box(
                        Modifier.size(84.dp).clip(RoundedCornerShape(8.dp))
                            .background(colors.bgSecondary).clickable { onOpen?.invoke(index) },
                    ) {
                        imageOrPlaceholder(img.url, ContentScale.Crop)
                        if (overflow > 0 && index == visible.size - 1) {
                            Box(
                                Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.42f)),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text("+$overflow", color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 18.sp)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun imageOrPlaceholder(url: String?, scale: ContentScale) {
    if (url != null) {
        AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = scale)
    }
}
