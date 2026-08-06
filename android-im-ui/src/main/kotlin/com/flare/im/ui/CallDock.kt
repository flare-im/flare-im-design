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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.MicOff
import androidx.compose.material.icons.outlined.OpenInFull
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Minimized floating call bar. Spec: Call/CallDock. */
@Composable
fun CallDock(
    title: String,
    avatarUrl: String? = null,
    durationLabel: String? = null,
    mode: FlareCallMode = FlareCallMode.Audio,
    muted: Boolean = false,
    onExpand: (() -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Row(
        Modifier.clip(RoundedCornerShape(999.dp))
            .background(Brush.linearGradient(listOf(Color(0xFF2A2438), Color(0xFF191320))))
            .padding(start = 8.dp, top = 8.dp, bottom = 8.dp, end = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            Modifier.clickable { onExpand?.invoke() },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(contentAlignment = Alignment.Center) {
                Avatar(userId = title, displayName = title, size = 34.dp)
                Box(Modifier.size(40.dp).clip(CircleShape).border(2.dp, colors.success, CircleShape))
            }
            Spacer(Modifier.width(10.dp))
            Column {
                Text(title, color = Color.White, fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.widthIn(max = 120.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(if (mode == FlareCallMode.Video) Icons.Outlined.Videocam else Icons.Outlined.Call,
                        contentDescription = null, tint = Color.White.copy(alpha = 0.66f), modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(durationLabel ?: flareStrings().callConnected, color = Color.White.copy(alpha = 0.66f), fontSize = 12.sp)
                }
            }
            Spacer(Modifier.width(2.dp))
            Icon(Icons.Outlined.OpenInFull, contentDescription = null, tint = Color.White.copy(alpha = 0.5f), modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.width(10.dp))
        Box(
            Modifier.size(36.dp).clip(CircleShape)
                .background(if (muted) Color.White else Color.White.copy(alpha = 0.14f))
                .clickable { onToggleMute?.invoke() },
            contentAlignment = Alignment.Center,
        ) {
            Icon(if (muted) Icons.Outlined.MicOff else Icons.Outlined.Mic, contentDescription = flareStrings().microphone,
                tint = if (muted) Color(0xFF17131F) else Color.White, modifier = Modifier.size(18.dp))
        }
        Spacer(Modifier.width(6.dp))
        Box(
            Modifier.size(36.dp).clip(CircleShape).background(colors.error).clickable { onHangup?.invoke() },
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.Call, contentDescription = flareStrings().hangUp, tint = Color.White,
                modifier = Modifier.size(18.dp).rotate(135f))
        }
    }
}
