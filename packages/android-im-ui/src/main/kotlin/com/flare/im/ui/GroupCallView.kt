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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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

/** Group (multi-party) call — participant grid + controls. Spec: Call/GroupCallView. */
@Composable
fun GroupCallView(
    participants: List<CallParticipant>,
    mode: FlareCallMode,
    state: String,
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
) {
    val cols = when {
        participants.size <= 1 -> 1
        participants.size <= 4 -> 2
        participants.size <= 9 -> 3
        else -> 4
    }
    val strings = flareStrings()
    val status = when (state) {
        "reconnecting" -> strings.callReconnecting
        "failed" -> strings.callFailed
        "connected" -> durationLabel ?: strings.callConnected
        "ringing" -> strings.callRinging
        else -> strings.callCalling
    }
    Column(
        Modifier.fillMaxWidth().background(
            Brush.verticalGradient(listOf(Color(0xFF18181B), Color(0xFF101012), Color(0xFF09090B)))),
    ) {
        // The minimize disc is drawn at 36 dp inside a 48 dp touch target; the start and top padding
        // and the gap give back the 6 dp a side the target adds, so the header keeps its layout.
        Row(Modifier.fillMaxWidth().padding(start = 10.dp, end = 16.dp, top = 8.dp, bottom = 0.dp),
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
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
            modifier = Modifier.weight(1f),
        ) {
            items(participants, key = { it.id }) { p -> callTile(p, mode) }
        }
        Box(Modifier.fillMaxWidth().padding(top = 20.dp, bottom = 36.dp), contentAlignment = Alignment.Center) {
            CallControls(muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera, onToggleSpeaker = onToggleSpeaker,
                onSwitchCamera = onSwitchCamera, onHangup = onHangup, onAddMember = onAddMember)
        }
    }
}

@Composable
private fun callTile(p: CallParticipant, mode: FlareCallMode) {
    val colors = flareColors()
    Box(
        Modifier.aspectRatio(0.86f).clip(RoundedCornerShape(16.dp))
            .background(if (p.isSelf) colors.primary.copy(alpha = 0.16f) else Color.White.copy(alpha = 0.06f))
            .border(2.dp, if (p.speaking) Color(0xFF34D17F) else Color.Transparent, RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center,
    ) {
        Avatar(
            userId = p.id, displayName = p.name, size = 56.dp,
            image = p.avatarUrl?.let { url ->
                { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
            },
        )
        Row(Modifier.align(Alignment.BottomStart).padding(8.dp), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp)) {
            if (p.muted) {
                Box(Modifier.size(20.dp).clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f)),
                    contentAlignment = Alignment.Center) {
                    Icon(flareIconVector("mic-off"), contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                }
            } else if (p.cameraOff && mode == FlareCallMode.Video) {
                Box(Modifier.size(20.dp).clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f)),
                    contentAlignment = Alignment.Center) {
                    Icon(flareIconVector("camera-off"), contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                }
            }
            Text(if (p.isSelf) flareStrings().selfSuffix(p.name) else p.name, color = Color.White, fontSize = 12.sp,
                maxLines = 1, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f))
                    .padding(horizontal = 8.dp, vertical = 2.dp))
        }
    }
}
