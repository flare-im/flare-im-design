package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
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

/**
 * Full-screen video player chrome — title, close, play surface. Spec:
 * Media/VideoPlayerModal (`VideoPlayer`).
 *
 * The package stays dependency-free, so real decoding is provided by the host
 * via [player] (e.g. an ExoPlayer `AndroidView`); without it, a play affordance
 * is shown and [onPlay] fires on tap.
 */
@Composable
fun VideoPlayer(
    show: Boolean,
    videoSrc: String,
    title: String? = null,
    player: (@Composable () -> Unit)? = null,
    onPlay: (() -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    if (!show) return
    Box(Modifier.fillMaxSize().background(Color.Black)) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            if (player != null) {
                player()
            } else {
                Box(Modifier.size(64.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.25f)).clickable { onPlay?.invoke() },
                    contentAlignment = Alignment.Center) {
                    Icon(Icons.Rounded.PlayCircle, null, Modifier.size(44.dp), tint = Color.White.copy(alpha = 0.9f))
                }
            }
        }
        Row(Modifier.fillMaxWidth().padding(FlareSizes.spacingMd), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(38.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.25f)).clickable { onClose?.invoke() },
                contentAlignment = Alignment.Center) { Icon(Icons.Rounded.Close, null, tint = Color.White) }
            if (!title.isNullOrEmpty()) {
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Text(title, color = Color.White, fontSize = FlareSizes.fontSize2xl.value.sp, fontWeight = FontWeight.SemiBold,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}
