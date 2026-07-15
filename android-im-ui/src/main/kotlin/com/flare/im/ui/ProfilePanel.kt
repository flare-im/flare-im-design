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
                // The model carries a signature — render it (it was silently dropped before).
                if (!user.signature.isNullOrEmpty()) {
                    Text(user.signature, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
                }
                if (!user.flareId.isNullOrEmpty()) {
                    Text("Flare ID: ${user.flareId}", color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                }
            }
            Icon(Icons.Outlined.QrCode, "QR code", tint = colors.textTertiary)
        }
        Spacer(Modifier.size(FlareSizes.spacingSm))
        // Shared row → `kind` (Toggle/Value/Navigation) and `detail` are honoured here too.
        entries.forEachIndexed { i, e ->
            if (i > 0) Divider(color = colors.borderSecondary)
            SettingsRow(item = e, onSelect = { onEntry?.invoke(it) })
        }
    }
}

val defaultProfileEntries: List<SettingsItem> = listOf(
    SettingsItem("favorites", "Favorites", Icons.Outlined.Star),
    SettingsItem("moments", "Moments", Icons.Outlined.Collections),
    SettingsItem("settings", "Settings", Icons.Outlined.Settings),
)
