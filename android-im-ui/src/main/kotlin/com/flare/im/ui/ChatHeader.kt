package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * The active conversation's header — title, subtitle/presence, and actions.
 * Spec: Message/ChatHeader (`ChatHeader`).
 */
@Composable
fun ChatHeader(
    title: String,
    subtitle: String? = null,
    presence: FlarePresence? = null,
    avatarUserId: String? = null,
    onBack: (() -> Unit)? = null,
    onSearch: (() -> Unit)? = null,
    onCall: (() -> Unit)? = null,
    onDetails: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Column {
        Row(
            Modifier.fillMaxWidth().height(FlareSizes.headerHeight).background(colors.bgPrimary)
                .padding(horizontal = FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (onBack != null) IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, null, tint = colors.textPrimary) }
            if (avatarUserId != null) {
                Avatar(userId = avatarUserId, displayName = title, presence = presence, size = 36.dp)
                Spacer(Modifier.width(FlareSizes.spacingSm))
            }
            Column(Modifier.weight(1f)) {
                Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl.value.sp,
                    fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                if (!subtitle.isNullOrEmpty()) {
                    Text(subtitle, color = if (presence == FlarePresence.Online) colors.success else colors.textTertiary,
                        fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
            onSearch?.let { action(Icons.Rounded.Search, it, colors) }
            onCall?.let { action(Icons.Outlined.Call, it, colors) }
            onDetails?.let { action(Icons.Rounded.MoreHoriz, it, colors) }
        }
        HorizontalDivider(color = colors.borderPrimary)
    }
}

@Composable
private fun action(icon: ImageVector, onClick: () -> Unit, colors: FlareColors) {
    IconButton(onClick = onClick) { Icon(icon, null, tint = colors.textSecondary) }
}
