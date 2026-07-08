package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Message
import androidx.compose.material.icons.outlined.Phone
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Contact name card — avatar/name/signature + message / voice / video / more.
 * Spec: Contacts/ContactDetail (`ContactDetail`).
 */
@Composable
fun ContactDetail(
    contact: Contact,
    onMessage: (() -> Unit)? = null,
    onCall: (() -> Unit)? = null,
    onVideo: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Column(
        Modifier.fillMaxWidth().verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(FlareSizes.spacing2xl))
        Avatar(userId = contact.id, displayName = contact.name, size = 88.dp, presence = contact.presence)
        Spacer(Modifier.height(FlareSizes.spacingMd))
        Text(contact.name, color = colors.textPrimary, fontSize = FlareSizes.fontSize4xl.value.sp, fontWeight = FontWeight.SemiBold)
        if (!contact.signature.isNullOrEmpty()) {
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Text(contact.signature, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp)
        }
        Spacer(Modifier.height(FlareSizes.spacing2xl))
        Row(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
            action("发消息", Icons.Outlined.Message, onMessage, colors, Modifier.weight(1f), primary = true)
            action("语音", Icons.Outlined.Phone, onCall, colors, Modifier.weight(1f))
            action("视频", Icons.Outlined.Videocam, onVideo, colors, Modifier.weight(1f))
        }
    }
}

@Composable
private fun action(label: String, icon: ImageVector, onClick: (() -> Unit)?, colors: FlareColors, modifier: Modifier, primary: Boolean = false) {
    Button(
        onClick = { onClick?.invoke() },
        colors = if (primary) ButtonDefaults.buttonColors(containerColor = colors.primary)
        else ButtonDefaults.buttonColors(containerColor = colors.bgSecondary, contentColor = colors.textPrimary),
        modifier = modifier,
    ) {
        Icon(icon, null, tint = if (primary) Color.White else colors.textPrimary)
        Spacer(Modifier.width(6.dp))
        Text(label, fontSize = FlareSizes.fontSizeMd.value.sp)
    }
}
