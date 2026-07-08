package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.Collections
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.QrCode
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Personal center — avatar / name / id / QR + entry list, edit & logout.
 * Spec: Profile/ProfilePanel (`ProfilePanel`).
 */
@Composable
fun ProfilePanel(
    user: UserProfile,
    entries: List<SettingsItem> = defaultProfileEntries,
    onEdit: (() -> Unit)? = null,
    onEntry: ((SettingsItem) -> Unit)? = null,
) {
    val colors = flareColors()
    Column(Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().background(colors.bgSelected)
                .clickable(enabled = onEdit != null) { onEdit?.invoke() }
                .padding(FlareSizes.spacingLg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Avatar(userId = user.id, displayName = user.name, size = 56.dp)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Column(Modifier.weight(1f)) {
                Text(user.name, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl.value.sp, fontWeight = FontWeight.SemiBold)
                if (!user.flareId.isNullOrEmpty()) {
                    Text("Flare ID: ${user.flareId}", color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                }
            }
            Icon(Icons.Outlined.QrCode, "二维码", tint = colors.textTertiary)
        }
        Spacer(Modifier.size(FlareSizes.spacingSm))
        entries.forEachIndexed { i, e ->
            if (i > 0) Divider(color = colors.borderSecondary)
            Row(
                Modifier.fillMaxWidth().clickable { onEntry?.invoke(e) }
                    .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingMd),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                e.icon?.let { Icon(it, null, tint = colors.textSecondary); Spacer(Modifier.width(FlareSizes.spacingMd)) }
                Text(e.label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.weight(1f))
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = colors.textTertiary)
            }
        }
    }
}

val defaultProfileEntries: List<SettingsItem> = listOf(
    SettingsItem("favorites", "我的收藏", Icons.Outlined.Star),
    SettingsItem("moments", "朋友圈", Icons.Outlined.Collections),
    SettingsItem("settings", "设置", Icons.Outlined.Settings),
)
