package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.LibraryBooks
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Multi-select toolbar for batch message actions. Spec: Message/MessageBatchToolbar. */
@Composable
fun MessageBatchToolbar(
    count: Int,
    total: Int,
    busy: Boolean = false,
    onSelectAll: (() -> Unit)? = null,
    onForwardEach: (() -> Unit)? = null,
    onForwardMerged: (() -> Unit)? = null,
    onDelete: (() -> Unit)? = null,
    onExit: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    Row(
        Modifier.fillMaxWidth()
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, shape)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("$count", color = colors.primary, fontWeight = FontWeight.Bold, fontSize = FlareSizes.fontSizeLg.value.sp)
            Text(" / $total · ${flareStrings().selectedSuffix}", color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
        }
        Spacer(Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalAlignment = Alignment.CenterVertically) {
            batchBtn(colors, Icons.Outlined.DoneAll, flareStrings().selectAll, total > 0 && !busy, onSelectAll)
            batchBtn(colors, Icons.Outlined.Share, flareStrings().forwardEach, count > 0 && !busy, onForwardEach)
            batchBtn(colors, Icons.AutoMirrored.Outlined.LibraryBooks, flareStrings().forwardMerged, count >= 2 && !busy, onForwardMerged)
            batchBtn(colors, Icons.Outlined.DeleteOutline, flareStrings().delete, count > 0 && !busy, onDelete, tint = colors.error)
            batchBtn(colors, Icons.Outlined.Close, null, !busy, onExit)
        }
    }
}

@Composable
private fun batchBtn(
    colors: FlareColors,
    icon: ImageVector,
    label: String?,
    enabled: Boolean,
    onTap: (() -> Unit)?,
    tint: Color? = null,
) {
    Row(
        Modifier.height(32.dp)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(colors.bgSecondary)
            .then(if (enabled && onTap != null) Modifier.clickable { onTap() } else Modifier)
            .alpha(if (enabled) 1f else 0.45f)
            .padding(horizontal = if (label == null) 8.dp else 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(icon, contentDescription = label, tint = tint ?: colors.textPrimary, modifier = Modifier.size(16.dp))
        if (label != null) {
            Text(label, color = tint ?: colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeSm.value.sp)
        }
    }
}
