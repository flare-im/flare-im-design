package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.VideocamOff
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

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
) {
    val cols = when {
        participants.size <= 1 -> 1
        participants.size <= 4 -> 2
        participants.size <= 9 -> 3
        else -> 4
    }
    val strings = flareStrings()
    val status = when (state) {
        "connected" -> durationLabel ?: strings.callConnected
        "ringing" -> strings.callRinging
        else -> strings.callCalling
    }
    Column(
        Modifier.fillMaxWidth().background(
            Brush.verticalGradient(listOf(Color(0xFF211D30), Color(0xFF17131F), Color(0xFF100C17)))),
    ) {
        Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(36.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f))
                .then(if (onMinimize != null) Modifier.clickable { onMinimize() } else Modifier),
                contentAlignment = Alignment.Center) {
                Icon(Icons.Outlined.ExpandMore, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column {
                Text(title ?: flareStrings().groupCall, color = Color.White, fontWeight = FontWeight.SemiBold,
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
        Box(Modifier.fillMaxWidth().padding(vertical = 20.dp), contentAlignment = Alignment.Center) {
            CallControls(muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera, onToggleSpeaker = onToggleSpeaker,
                onSwitchCamera = onSwitchCamera, onHangup = onHangup)
        }
    }
}

@Composable
private fun callTile(p: CallParticipant, mode: FlareCallMode) {
    Box(
        Modifier.aspectRatio(0.86f).clip(RoundedCornerShape(16.dp))
            .background(if (p.isSelf) Color(0x297C3AED) else Color.White.copy(alpha = 0.06f))
            .border(2.dp, if (p.speaking) Color(0xFF34D17F) else Color.Transparent, RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center,
    ) {
        Avatar(userId = p.id, displayName = p.name, size = 56.dp)
        Row(Modifier.align(Alignment.BottomStart).padding(8.dp), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp)) {
            if (p.muted) {
                Box(Modifier.size(20.dp).clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f)),
                    contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.MicOff, contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                }
            } else if (p.cameraOff && mode == FlareCallMode.Video) {
                Box(Modifier.size(20.dp).clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f)),
                    contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.VideocamOff, contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                }
            }
            Text(if (p.isSelf) flareStrings().selfSuffix(p.name) else p.name, color = Color.White, fontSize = 12.sp,
                maxLines = 1, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f))
                    .padding(horizontal = 8.dp, vertical = 2.dp))
        }
    }
}
