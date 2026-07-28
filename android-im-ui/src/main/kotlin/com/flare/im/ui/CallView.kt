package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Call state — spec union `'calling' | 'ringing' | 'connected'`. */
enum class FlareCallState { Calling, Ringing, Connected }

/**
 * In-call screen — peer video/avatar, state, duration, with an overlaid
 * [CallControls]. Spec: Call/CallView (`CallView`). Video rendering is injected
 * by the host via [videoContent] (the package bundles no RTC engine).
 */
@Composable
fun CallView(
    peerName: String,
    mode: FlareCallMode,
    state: FlareCallState,
    durationLabel: String? = null,
    peerAvatarUrl: String? = null,
    muted: Boolean = false,
    cameraOn: Boolean = true,
    speakerOn: Boolean = false,
    videoContent: (@Composable () -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onToggleCamera: (() -> Unit)? = null,
    onToggleSpeaker: (() -> Unit)? = null,
    onSwitchCamera: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
) {
    Box(Modifier.fillMaxSize().background(Color(0xFF111318))) {
        if (mode == FlareCallMode.Video && videoContent != null) {
            videoContent()
        }

        Column(
            Modifier.fillMaxWidth().padding(top = 72.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (mode == FlareCallMode.Audio || videoContent == null) {
                val peerTint = seedTint(peerName)
                Box(
                    Modifier.size(96.dp).clip(CircleShape).background(peerTint.first),
                    contentAlignment = Alignment.Center,
                ) { Text(initials(peerName), color = peerTint.second, fontSize = 36.sp, fontWeight = FontWeight.SemiBold) }
                Spacer(Modifier.height(FlareSizes.spacingMd))
            }
            Text(peerName, color = Color.White, fontSize = FlareSizes.fontSize4xl.value.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Text(
                statusLabel(state, mode, durationLabel),
                color = Color.White.copy(alpha = 0.7f),
                fontSize = FlareSizes.fontSizeLg.value.sp,
            )
        }

        Column(
            Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(bottom = 48.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            CallControls(
                muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera,
                onToggleSpeaker = onToggleSpeaker, onSwitchCamera = onSwitchCamera, onHangup = onHangup,
            )
        }
    }
}

private fun statusLabel(state: FlareCallState, mode: FlareCallMode, duration: String?): String = when (state) {
    FlareCallState.Calling -> if (mode == FlareCallMode.Video) "等待对方接听…" else "正在呼叫…"
    FlareCallState.Ringing -> "正在响铃…"
    FlareCallState.Connected -> duration ?: "已接通"
}
