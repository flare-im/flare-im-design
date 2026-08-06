package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Mini profile card. Spec: Profile/ProfileCard. */
@Composable
fun ProfileCard(
    user: Contact,
    onMessage: (() -> Unit)? = null,
    onCall: (() -> Unit)? = null,
    onVideo: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val meta = buildList {
        add("Flare ID · ${user.id}")
        if (!user.region.isNullOrEmpty()) add(user.region)
    }.joinToString(" · ")
    Column(
        Modifier.width(260.dp)
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl))
            .padding(FlareSizes.spacingLg),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Avatar(userId = user.id, displayName = user.name, size = 56.dp, presence = user.presence)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Text(user.name, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSize2xl.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (!user.signature.isNullOrEmpty()) {
            Spacer(Modifier.height(FlareSizes.spacingMd))
            Text(user.signature, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg.value.sp)
        }
        Spacer(Modifier.height(FlareSizes.spacingSm))
        Text(meta, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
            maxLines = 1, overflow = TextOverflow.Ellipsis)
        if (user.tags.isNotEmpty()) {
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                user.tags.forEach { t ->
                    Text(t, color = colors.primary, fontSize = FlareSizes.fontSizeXs.value.sp,
                        modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgSelected)
                            .padding(horizontal = 9.dp, vertical = 2.dp))
                }
            }
        }
        Spacer(Modifier.height(FlareSizes.spacingLg))
        Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            cardAction(colors, Icons.Outlined.ChatBubbleOutline, flareStrings().sendMessage, onMessage, primary = true, modifier = Modifier.weight(1f))
            cardAction(colors, Icons.Outlined.Call, null, onCall)
            cardAction(colors, Icons.Outlined.Videocam, null, onVideo)
        }
    }
}

@Composable
private fun cardAction(
    colors: FlareColors,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String?,
    onTap: (() -> Unit)?,
    primary: Boolean = false,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier
            .then(if (label == null) Modifier.width(44.dp) else Modifier)
            .height(38.dp)
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(if (primary) colors.primary else colors.bgSecondary)
            .then(if (onTap != null) Modifier.clickable { onTap() } else Modifier)
            .padding(horizontal = 10.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = label, tint = if (primary) Color.White else colors.textPrimary,
            modifier = Modifier.size(17.dp))
        if (label != null) {
            Spacer(Modifier.width(6.dp))
            Text(label, color = if (primary) Color.White else colors.textPrimary,
                fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeLg.value.sp)
        }
    }
}
