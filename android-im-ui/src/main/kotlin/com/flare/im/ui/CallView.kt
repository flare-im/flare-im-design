package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.material3.TextButton
import androidx.compose.foundation.layout.heightIn
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

/** Call state — spec union `'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed'`. */
enum class FlareCallState { Calling, Ringing, Connected, Reconnecting, Failed }

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
    statusDetail: String? = null,
    recoveryText: String? = null,
    onRecover: (() -> Unit)? = null,
) {
    Box(Modifier.fillMaxSize().background(Color(0xFF111318))) {
        if (mode == FlareCallMode.Video && videoContent != null) {
            videoContent()
        }

        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(start = 16.dp, end = 16.dp, top = 72.dp, bottom = 48.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (mode == FlareCallMode.Audio || videoContent == null) {
                val peerTint = seedTint(peerName)
                Box(
                    Modifier.size(96.dp).clip(CircleShape).background(peerTint.first),
                    contentAlignment = Alignment.Center,
                ) {
                    if (peerAvatarUrl != null) {
                        AsyncImage(model = peerAvatarUrl, contentDescription = null,
                            modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                    } else {
                        Text(initials(peerName), color = peerTint.second, fontSize = 36.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
                Spacer(Modifier.height(FlareSizes.spacingMd))
            }
            if (statusDetail != null) Text(statusDetail, color = Color.White)
            if (state == FlareCallState.Failed && recoveryText != null) {
                TextButton(onClick = { onRecover?.invoke() }, enabled = onRecover != null, modifier = Modifier.heightIn(min = 48.dp)) { Text(recoveryText, color = Color.White) }
            }
            Text(peerName, color = Color.White, fontSize = FlareSizes.fontSize4xl.value.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Text(
                statusLabel(state, mode, durationLabel, flareStrings()),
                color = Color.White.copy(alpha = 0.7f),
                fontSize = FlareSizes.fontSizeLg.value.sp,
            )
            Spacer(Modifier.height(32.dp))
            CallControls(
                muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera,
                onToggleSpeaker = onToggleSpeaker, onSwitchCamera = onSwitchCamera, onHangup = onHangup,
            )
        }
    }
}

private fun statusLabel(
    state: FlareCallState,
    mode: FlareCallMode,
    duration: String?,
    strings: FlareStrings,
): String = when (state) {
    FlareCallState.Calling ->
        if (mode == FlareCallMode.Video) strings.callWaitingAnswer else strings.callCalling
    FlareCallState.Ringing -> strings.callRinging
    FlareCallState.Reconnecting -> strings.callReconnecting
    FlareCallState.Failed -> strings.callFailed
    FlareCallState.Connected -> duration ?: strings.callConnected
}
