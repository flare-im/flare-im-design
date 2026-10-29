package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.TextButton
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/** Call state — spec union `'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed'`. */
enum class FlareCallState { Calling, Ringing, Connected, Reconnecting, Failed }

/**
 * What [CallView] draws around the peer, without a UI: whether the avatar is shown (not while the peer's video
 * covers it), the mic-off badge's TalkBack name ([mutedLabel], null when there is no badge), whether the speaking
 * ring goes round the avatar, whether the host's own camera is drawn as the picture-in-picture, and the peer block's
 * top inset ([peerTop]: below the preview while it is drawn, inside the status bar, so the preview never covers the
 * avatar on a narrow screen).
 */
internal data class CallViewPeerMarks(
    val avatar: Boolean,
    val mutedLabel: String?,
    val speakingRing: Boolean,
    val localPreview: Boolean,
    val peerTop: Dp,
)

internal fun callViewPeerMarks(
    strings: FlareStrings,
    mode: FlareCallMode,
    hasVideo: Boolean,
    hasLocalVideo: Boolean,
    peerMuted: Boolean,
    peerSpeaking: Boolean,
): CallViewPeerMarks {
    val avatar = mode == FlareCallMode.Audio || !hasVideo
    val localPreview = mode == FlareCallMode.Video && hasLocalVideo
    return CallViewPeerMarks(
        avatar = avatar,
        mutedLabel = if (peerMuted) strings.callPeerMuted else null,
        speakingRing = avatar && peerSpeaking && !peerMuted,
        localPreview = localPreview,
        peerTop = if (localPreview) FlareSizes.spacingLg * 2 + FlareSizes.componentCallPreviewWidth * 4 / 3 else 72.dp,
    )
}

/**
 * In-call screen — peer video/avatar, state, duration, with an overlaid
 * [CallControls]. Spec: Call/CallView (`CallView`). Video rendering is injected
 * by the host via [videoContent] (the package bundles no RTC engine).
 *
 * [onMinimize] draws the collapse control at the top start corner (the same 36 dp disc as [GroupCallView]); the
 * host shrinks the call into its [CallDock]. Without it the control is not drawn.
 *
 * [peerMuted] draws the [GroupCallView] tile's mic-off badge beside the peer's name; [peerSpeaking] draws the tile's
 * green as a ring round the peer's avatar. [localVideoContent] is the host's own camera, drawn as a 3:4
 * picture-in-picture at the top end corner in video mode.
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
    peerMuted: Boolean = false,
    peerSpeaking: Boolean = false,
    videoContent: (@Composable () -> Unit)? = null,
    localVideoContent: (@Composable () -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onToggleCamera: (() -> Unit)? = null,
    onToggleSpeaker: (() -> Unit)? = null,
    onSwitchCamera: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
    statusDetail: String? = null,
    recoveryText: String? = null,
    onRecover: (() -> Unit)? = null,
    onMinimize: (() -> Unit)? = null,
) {
    val marks = callViewPeerMarks(flareStrings(), mode, hasVideo = videoContent != null,
        hasLocalVideo = localVideoContent != null, peerMuted = peerMuted, peerSpeaking = peerSpeaking)
    Box(Modifier.fillMaxSize().background(Color(0xFF111318))) {
        if (mode == FlareCallMode.Video && videoContent != null) {
            videoContent()
        }

        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                // The preview sits under the status bar, so the peer block measures from there while it is drawn.
                .then(if (marks.localPreview) Modifier.statusBarsPadding() else Modifier)
                .padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = marks.peerTop, bottom = 48.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (marks.avatar) {
                val peerTint = seedTint(peerName)
                Box(
                    Modifier.size(96.dp)
                        // Drawn ahead of the clip, so the ring sits just outside the avatar and leaves the layout alone.
                        .then(if (marks.speakingRing) Modifier.drawBehind {
                            val ring = 3.dp.toPx()
                            drawCircle(Color(0xFF34D17F), radius = size.minDimension / 2 + ring / 2, style = Stroke(ring))
                        } else Modifier)
                        .clip(CircleShape).background(peerTint.first),
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
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                Text(peerName, color = Color.White, fontSize = FlareSizes.fontSize4xl.value.sp, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f, fill = false))
                marks.mutedLabel?.let { label ->
                    // The GroupCallView tile's mute badge, named for TalkBack.
                    Box(Modifier.size(FlareSizes.iconSizeMd).clip(RoundedCornerShape(FlareSizes.radiusSm)).background(Color.Black.copy(alpha = 0.42f)),
                        contentAlignment = Alignment.Center) {
                        Icon(flareIconVector("mic-off"), contentDescription = label, tint = Color.White, modifier = Modifier.size(FlareSizes.spacingMd))
                    }
                }
            }
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Text(
                statusLabel(state, mode, durationLabel, flareStrings()),
                color = Color.White.copy(alpha = 0.7f),
                fontSize = FlareSizes.fontSizeLg.value.sp,
            )
            if (statusDetail != null) {
                Spacer(Modifier.height(FlareSizes.spacingXs))
                Text(statusDetail, color = Color.White, textAlign = TextAlign.Center)
            }
            if (state == FlareCallState.Failed && recoveryText != null) {
                TextButton(onClick = { onRecover?.invoke() }, enabled = onRecover != null, modifier = Modifier.heightIn(min = FlareSizes.touchTarget)) { Text(recoveryText, color = Color.White) }
            }
            Spacer(Modifier.height(32.dp))
            CallControls(
                muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera,
                onToggleSpeaker = onToggleSpeaker, onSwitchCamera = onSwitchCamera, onHangup = onHangup,
            )
        }
        if (marks.localPreview && localVideoContent != null) {
            // The host's own camera: a 3:4 picture-in-picture at the top end corner, under the status bar.
            Box(
                Modifier.align(Alignment.TopEnd).statusBarsPadding().padding(top = FlareSizes.spacingLg, end = FlareSizes.spacingLg)
                    .width(FlareSizes.componentCallPreviewWidth).aspectRatio(3f / 4f)
                    .clip(RoundedCornerShape(FlareSizes.radiusCard)).background(Color.Black),
            ) {
                localVideoContent()
            }
        }
        if (onMinimize != null) {
            // The disc is drawn at 36 dp inside a 48 dp touch target; the padding gives back the 6 dp a side the
            // target adds, so the disc sits spacingLg from the edges.
            Box(Modifier.align(Alignment.TopStart).statusBarsPadding().padding(start = FlareSizes.spacing2sm, top = FlareSizes.spacing2sm)) {
                FlareIconControl(label = flareStrings().callMinimize, onClick = onMinimize) {
                    Box(Modifier.size(36.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f)))
                    Icon(flareIconVector("collapse"), contentDescription = null, tint = Color.White, modifier = Modifier.size(FlareSizes.iconSizeMd))
                }
            }
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
