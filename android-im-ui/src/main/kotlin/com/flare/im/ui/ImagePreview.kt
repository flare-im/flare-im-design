package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BrokenImage
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * Full-screen image viewer — download with progress. Spec:
 * Media/ImagePreviewModal (`ImagePreview`). Renders nothing when [show] is
 * false. The package bundles no image loader; pass [image] to render the real
 * image (e.g. a zoomable Coil `AsyncImage`), otherwise a placeholder is shown.
 */
@Composable
fun ImagePreview(
    show: Boolean,
    imageSrc: String,
    loading: Boolean = false,
    downloading: Boolean = false,
    progressPct: Int = 0,
    onClose: (() -> Unit)? = null,
    onDownload: (() -> Unit)? = null,
    image: (@Composable () -> Unit)? = null,
) {
    if (!show) return
    val colors = flareColors()
    Box(Modifier.fillMaxSize().background(Color.Black)) {
        Box(Modifier.fillMaxSize().clickable { onClose?.invoke() }, contentAlignment = Alignment.Center) {
            when {
                loading -> CircularProgressIndicator(color = Color.White)
                image != null -> image()
                else -> Icon(Icons.Outlined.BrokenImage, null, Modifier.size(64.dp), tint = Color.White.copy(alpha = 0.5f))
            }
        }
        Row(Modifier.fillMaxWidth().padding(FlareSizes.spacingMd)) {
            circleButton(Icons.Rounded.Close) { onClose?.invoke() }
            androidx.compose.foundation.layout.Spacer(Modifier.weight(1f))
            if (onDownload != null) {
                if (downloading) {
                    Box(Modifier.size(38.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(progress = { progressPct / 100f }, color = Color.White, strokeWidth = 2.dp)
                        Text("$progressPct", color = Color.White, fontSize = androidx.compose.ui.unit.TextUnit(10f, androidx.compose.ui.unit.TextUnitType.Sp))
                    }
                } else {
                    circleButton(Icons.Rounded.Download) { onDownload() }
                }
            }
        }
    }
}

@Composable
private fun circleButton(icon: androidx.compose.ui.graphics.vector.ImageVector, onClick: () -> Unit) {
    Box(
        Modifier.size(38.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.25f)).clickable { onClick() },
        contentAlignment = Alignment.Center,
    ) { Icon(icon, null, tint = Color.White) }
}
