package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.CallEnd
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Incoming call / invite — caller avatar/name, audio/video kind, accept &
 * reject. Spec: Call/IncomingCall (`IncomingCall`).
 */
@Composable
fun IncomingCall(
    callerName: String,
    mode: FlareCallMode,
    callerAvatarUrl: String? = null,
    onAccept: (() -> Unit)? = null,
    onReject: (() -> Unit)? = null,
) {
    Box(Modifier.fillMaxSize().background(Color(0xFF111318))) {
        Column(
            Modifier.fillMaxWidth().padding(top = 120.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            val callerTint = seedTint(callerName)
            Box(
                Modifier.size(104.dp).clip(CircleShape).background(callerTint.first),
                contentAlignment = Alignment.Center,
            ) { Text(initials(callerName), color = callerTint.second, fontSize = 40.sp, fontWeight = FontWeight.SemiBold) }
            Spacer(Modifier.height(FlareSizes.spacingLg))
            Text(callerName, color = Color.White, fontSize = FlareSizes.fontSize4xl.value.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Text(
                if (mode == FlareCallMode.Video) "is inviting you to a video call" else "is inviting you to a voice call",
                color = Color.White.copy(alpha = 0.7f), fontSize = FlareSizes.fontSizeLg.value.sp,
            )
        }

        Row(
            Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(bottom = 56.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
        ) {
            action(Icons.Outlined.CallEnd, "Decline", Color(0xFFEF4444), onReject)
            action(Icons.Outlined.Call, "Answer", Color(0xFF22C55E), onAccept)
        }
    }
}

@Composable
private fun action(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, color: Color, onClick: (() -> Unit)?) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier.size(64.dp).clip(CircleShape).background(color).clickable(enabled = onClick != null) { onClick?.invoke() },
            contentAlignment = Alignment.Center,
        ) { Icon(icon, label, tint = Color.White) }
        Spacer(Modifier.height(FlareSizes.spacingSm))
        Text(label, color = Color.White.copy(alpha = 0.8f), fontSize = 13.sp)
    }
}
