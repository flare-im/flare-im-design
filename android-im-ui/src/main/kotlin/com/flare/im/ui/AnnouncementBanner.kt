package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Pinned group announcement banner. Spec: Message/AnnouncementBanner. */
@Composable
fun AnnouncementBanner(
    text: String,
    author: String? = null,
    collapsible: Boolean = true,
    dismissible: Boolean = false,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var expanded by remember { mutableStateOf(false) }
    val showToggle = collapsible && text.length > 40
    Row(
        Modifier.clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSelected)
            .border(1.dp, colors.primary.copy(alpha = 0.22f), RoundedCornerShape(FlareSizes.radiusLg))
            .padding(horizontal = 12.dp, vertical = 11.dp),
    ) {
        Box(
            Modifier.size(26.dp).clip(RoundedCornerShape(8.dp)).background(colors.primary),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.Campaign, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Row {
                Text(flareStrings().groupAnnouncement, color = colors.primary, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                author?.let {
                    Text(" · $it", color = colors.textTertiary, fontSize = 12.sp)
                }
            }
            Text(text, color = colors.textPrimary, fontSize = 13.sp,
                maxLines = if (showToggle && !expanded) 1 else Int.MAX_VALUE,
                overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 3.dp))
            if (showToggle) {
                Row(
                    Modifier.padding(top = 4.dp).clickable { expanded = !expanded },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(if (expanded) flareStrings().collapse else flareStrings().expand, color = colors.primary, fontSize = 12.sp)
                    Icon(Icons.Outlined.ExpandMore, contentDescription = null, tint = colors.primary,
                        modifier = Modifier.size(14.dp).rotate(if (expanded) 180f else 0f))
                }
            }
        }
        if (dismissible) {
            Spacer(Modifier.width(6.dp))
            Icon(Icons.Outlined.Close, contentDescription = flareStrings().close, tint = colors.textTertiary,
                modifier = Modifier.size(16.dp).align(Alignment.Top).clickable { onClose?.invoke() })
        }
    }
}
