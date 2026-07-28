package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CallEnd
import androidx.compose.material.icons.outlined.Cameraswitch
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.MicOff
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material.icons.outlined.VideocamOff
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Audio vs video call — spec union `'audio' | 'video'`. */
enum class FlareCallMode { Audio, Video }

/**
 * Call control bar — mute, camera, speaker, flip, hang up (adapts to
 * audio/video). Spec: Call/CallControls (`CallControls`).
 */
@Composable
fun CallControls(
    muted: Boolean = false,
    cameraOn: Boolean = true,
    speakerOn: Boolean = false,
    mode: FlareCallMode = FlareCallMode.Video,
    onToggleMute: (() -> Unit)? = null,
    onToggleCamera: (() -> Unit)? = null,
    onToggleSpeaker: (() -> Unit)? = null,
    onSwitchCamera: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    Row(
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ctrl(if (muted) Icons.Outlined.MicOff else Icons.Outlined.Mic, strings.microphone, muted, onToggleMute)
        if (mode == FlareCallMode.Video) {
            ctrl(if (cameraOn) Icons.Outlined.Videocam else Icons.Outlined.VideocamOff, strings.camera, !cameraOn, onToggleCamera)
            ctrl(Icons.Outlined.Cameraswitch, strings.flipCamera, false, onSwitchCamera)
        } else {
            ctrl(Icons.Outlined.VolumeUp, strings.speaker, speakerOn, onToggleSpeaker)
        }
        hangup(onHangup)
    }
}

@Composable
private fun ctrl(icon: ImageVector, label: String, on: Boolean, onClick: (() -> Unit)?) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier.size(56.dp).clip(CircleShape)
                .background(if (on) Color.White else Color.White.copy(alpha = 0.16f))
                .clickable(enabled = onClick != null) { onClick?.invoke() },
            contentAlignment = Alignment.Center,
        ) { Icon(icon, label, tint = if (on) Color.Black else Color.White) }
        Text(label, color = Color.White.copy(alpha = 0.75f), fontSize = 11.sp)
    }
}

@Composable
private fun hangup(onClick: (() -> Unit)?) {
    Box(
        Modifier.size(56.dp).clip(CircleShape).background(Color(0xFFEF4444))
            .clickable(enabled = onClick != null) { onClick?.invoke() },
        contentAlignment = Alignment.Center,
    ) { Icon(Icons.Outlined.CallEnd, flareStrings().hangUp, tint = Color.White) }
}
