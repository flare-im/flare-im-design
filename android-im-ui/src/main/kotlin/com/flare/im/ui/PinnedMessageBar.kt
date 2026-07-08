package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.PushPin
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Sticky bar above the thread showing pinned messages; tap to focus one, and
 * (when many) cycle. Spec: Message/PinnedMessageBar (`PinnedMessageBar`).
 */
@Composable
fun PinnedMessageBar(
    items: List<FlarePinnedMessage>,
    onFocus: ((FlarePinnedMessage) -> Unit)? = null,
) {
    if (items.isEmpty()) return
    val colors = flareColors()
    var index by remember { mutableIntStateOf(0) }
    val safeIndex = index.coerceIn(0, items.size - 1)
    val item = items[safeIndex]

    Row(
        Modifier.fillMaxWidth().background(colors.bgSecondary).clickable {
            onFocus?.invoke(item)
            if (items.size > 1) index = (safeIndex + 1) % items.size
        }.padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(3.dp).height(28.dp).background(colors.pinned))
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Icon(Icons.Rounded.PushPin, null, tint = colors.pinned)
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Column(Modifier.weight(1f)) {
            if (!item.senderName.isNullOrEmpty()) {
                Text(item.senderName, color = colors.pinned, fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold)
            }
            Text(item.summary, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (items.size > 1) {
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Text("${safeIndex + 1}/${items.size}", color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs.value.sp)
        }
    }
}
