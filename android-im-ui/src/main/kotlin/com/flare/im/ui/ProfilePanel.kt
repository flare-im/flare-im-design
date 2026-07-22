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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
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
            Modifier.fillMaxWidth()
                // Aurora glow header — a violet light source, white text over it.
                .background(Brush.linearGradient(listOf(Color(0xFF3B1F7A), Color(0xFF7C3AED), Color(0xFF8B5CF6))))
                .clickable(enabled = onEdit != null) { onEdit?.invoke() }
                .padding(FlareSizes.spacingLg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Avatar(userId = user.id, displayName = user.name, size = 56.dp)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Column(Modifier.weight(1f)) {
                Text(user.name, color = Color.White, fontSize = FlareSizes.fontSize3xl.value.sp, fontWeight = FontWeight.Bold)
                // The model carries a signature — render it (it was silently dropped before).
                if (!user.signature.isNullOrEmpty()) {
                    Text(user.signature, color = Color.White.copy(alpha = 0.82f), fontSize = FlareSizes.fontSizeSm.value.sp)
                }
                if (!user.flareId.isNullOrEmpty()) {
                    Text("Flare ID: ${user.flareId}", color = Color.White.copy(alpha = 0.62f), fontSize = FlareSizes.fontSizeSm.value.sp)
                }
            }
            Icon(Icons.Outlined.QrCode, "QR code", tint = Color.White.copy(alpha = 0.9f))
        }
        Spacer(Modifier.size(FlareSizes.spacingMd))
        // Aurora — entries float together on one elevated grouped card (iOS-style),
        // matching the settings surface. Shared row honours kind/detail.
        Column(
            Modifier.fillMaxWidth()
                .padding(horizontal = FlareSizes.spacingMd)
                .shadow(2.dp, RoundedCornerShape(16.dp), clip = false)
                .clip(RoundedCornerShape(16.dp))
                .background(colors.bgElevated),
        ) {
            entries.forEachIndexed { i, e ->
                if (i > 0) Divider(color = colors.borderSecondary, modifier = Modifier.padding(start = FlareSizes.spacingMd))
                SettingsRow(item = e, onSelect = { onEntry?.invoke(it) })
            }
        }
    }
}

val defaultProfileEntries: List<SettingsItem> = listOf(
    SettingsItem("favorites", "Favorites", Icons.Outlined.Star),
    SettingsItem("moments", "Moments", Icons.Outlined.Collections),
    SettingsItem("settings", "Settings", Icons.Outlined.Settings),
)
