package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/**
 * The host's video for [participant]'s tile. [tileContent] is asked only when the tile shows video — a video call with
 * the participant's camera on; null (no [tileContent], or no stream yet) leaves the avatar.
 */
internal fun callTileVideo(
    participant: CallParticipant,
    mode: FlareCallMode,
    tileContent: ((CallParticipant) -> (@Composable () -> Unit)?)?,
): (@Composable () -> Unit)? =
    if (mode == FlareCallMode.Video && !participant.cameraOff) tileContent?.invoke(participant) else null

/**
 * Group (multi-party) call — participant grid + controls. Spec: Call/GroupCallView. [state] is the same [FlareCallState]
 * as [CallView].
 *
 * [tileContent] renders a participant's video. It is asked only for a tile that shows video (a video call with the
 * participant's camera on); that tile when it returns null, and every other tile, show the avatar. The tile keeps its
 * chrome over the video: the speaking ring, the mute or camera-off badge and the name.
 *
 * [onStartVideo] draws the control bar's "switch to video" key in an audio call; the host turns the call into video.
 */
@Composable
fun GroupCallView(
    participants: List<CallParticipant>,
    mode: FlareCallMode,
    state: FlareCallState,
    title: String? = null,
    durationLabel: String? = null,
    muted: Boolean = false,
    cameraOn: Boolean = true,
    speakerOn: Boolean = false,
    onHangup: (() -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onToggleCamera: (() -> Unit)? = null,
    onToggleSpeaker: (() -> Unit)? = null,
    onSwitchCamera: (() -> Unit)? = null,
    onMinimize: (() -> Unit)? = null,
    onAddMember: (() -> Unit)? = null,
    onStartVideo: (() -> Unit)? = null,
    tileContent: ((CallParticipant) -> (@Composable () -> Unit)?)? = null,
) {
    val cols = when {
        participants.size <= 1 -> 1
        participants.size <= 4 -> 2
        participants.size <= 9 -> 3
        else -> 4
    }
    val strings = flareStrings()
    val status = when (state) {
        FlareCallState.Reconnecting -> strings.callReconnecting
        FlareCallState.Failed -> strings.callFailed
        FlareCallState.Connected -> durationLabel ?: strings.callConnected
        FlareCallState.Ringing -> strings.callRinging
        FlareCallState.Calling -> strings.callCalling
    }
    Column(
        Modifier.fillMaxWidth().background(
            Brush.verticalGradient(listOf(Color(0xFF18181B), Color(0xFF101012), Color(0xFF09090B))))
            // The backdrop runs under the system bars; the header starts below the status bar.
            .statusBarsPadding(),
    ) {
        // The minimize disc is drawn at 36 dp inside a 48 dp touch target; the start and top padding
        // and the gap give back the 6 dp a side the target adds, so the header keeps its layout.
        Row(Modifier.fillMaxWidth().padding(start = FlareSizes.spacing2sm, end = FlareSizes.spacingLg, top = FlareSizes.spacingSm, bottom = 0.dp),
            verticalAlignment = Alignment.CenterVertically) {
            FlareIconControl(label = strings.callMinimize, onClick = onMinimize) {
                Box(Modifier.size(36.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f)))
                Icon(flareIconVector("collapse"), contentDescription = null, tint = Color.White, modifier = Modifier.size(FlareSizes.iconSizeMd))
            }
            Spacer(Modifier.width(FlareSizes.spacing2xs))
            Column {
                Text(title ?: strings.groupCall, color = Color.White, fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(flareStrings().joinedCount(participants.size, status), color = Color.White.copy(alpha = 0.62f), fontSize = 12.sp)
            }
        }
        LazyVerticalGrid(
            columns = GridCells.Fixed(cols),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            contentPadding = PaddingValues(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
            modifier = Modifier.weight(1f),
        ) {
            items(participants, key = { it.id }) { p -> callTile(p, mode, callTileVideo(p, mode, tileContent)) }
        }
        Box(Modifier.fillMaxWidth().navigationBarsPadding().padding(top = FlareSizes.spacingXl, bottom = 36.dp),
            contentAlignment = Alignment.Center) {
            CallControls(muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera, onToggleSpeaker = onToggleSpeaker,
                onSwitchCamera = onSwitchCamera, onHangup = onHangup, onAddMember = onAddMember, onStartVideo = onStartVideo)
        }
    }
}

@Composable
private fun callTile(p: CallParticipant, mode: FlareCallMode, video: (@Composable () -> Unit)?) {
    val colors = flareColors()
    Box(
        Modifier.aspectRatio(0.86f).clip(RoundedCornerShape(FlareSizes.radiusBubble))
            .background(if (p.isSelf) colors.primary.copy(alpha = 0.16f) else Color.White.copy(alpha = 0.06f))
            .border(2.dp, if (p.speaking) Color(0xFF34D17F) else Color.Transparent, RoundedCornerShape(FlareSizes.radiusBubble)),
        contentAlignment = Alignment.Center,
    ) {
        if (video != null) {
            // The video fills the tile; the speaking border is drawn over the content, the name tag after it.
            Box(Modifier.fillMaxSize()) { video() }
        } else {
            Avatar(
                userId = p.id, displayName = p.name, size = 56.dp,
                image = p.avatarUrl?.let { url ->
                    { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
                },
            )
        }
        Row(Modifier.align(Alignment.BottomStart).padding(FlareSizes.spacingSm), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp)) {
            if (p.muted) {
                Box(Modifier.size(20.dp).clip(RoundedCornerShape(FlareSizes.radiusSm)).background(Color.Black.copy(alpha = 0.42f)),
                    contentAlignment = Alignment.Center) {
                    Icon(flareIconVector("mic-off"), contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                }
            } else if (p.cameraOff && mode == FlareCallMode.Video) {
                Box(Modifier.size(20.dp).clip(RoundedCornerShape(FlareSizes.radiusSm)).background(Color.Black.copy(alpha = 0.42f)),
                    contentAlignment = Alignment.Center) {
                    Icon(flareIconVector("camera-off"), contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                }
            }
            Text(if (p.isSelf) flareStrings().selfSuffix(p.name) else p.name, color = Color.White, fontSize = 12.sp,
                maxLines = 1, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.clip(RoundedCornerShape(FlareSizes.radiusSm)).background(Color.Black.copy(alpha = 0.42f))
                    .padding(horizontal = FlareSizes.spacingSm, vertical = 2.dp))
        }
    }
}
