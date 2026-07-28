package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
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
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Personal center — avatar / name / id / QR + entry list, edit & logout.
 * Spec: Profile/ProfilePanel (`ProfilePanel`).
 *
 * Parity with `FlareProfilePanel.vue`:
 *  - The aurora header is one tap target for **edit**; the QR badge is a *separate* tap target
 *    ([onQr]) that no longer bubbles into edit.
 *  - A trailing chevron hints the header is tappable.
 *  - [signaturePlaceholder] shows an italic hint when the user has no signature yet.
 *  - Entries render as grouped section cards ([sections]) rather than one flat list; [entries] stays
 *    as the single-group convenience path.
 */
@Composable
fun ProfilePanel(
    user: UserProfile,
    entries: List<SettingsItem> = defaultProfileEntries,
    /** Grouped rows (iOS-style cards). Overrides [entries] when non-null. */
    sections: List<SettingsSection>? = null,
    /** Italic hint shown in the header when the user has no signature yet. */
    signaturePlaceholder: String? = null,
    onEdit: (() -> Unit)? = null,
    onQr: (() -> Unit)? = null,
    onEntry: ((SettingsItem) -> Unit)? = null,
    onToggle: ((SettingsItem, Boolean) -> Unit)? = null,
) {
    val colors = flareColors()
    // Normalize to grouped sections so there is a single render path.
    val groups = sections ?: listOf(SettingsSection(items = entries))
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
                // The model carries a signature — render it (it was silently dropped before), else the
                // placeholder hint when one is supplied.
                if (!user.signature.isNullOrEmpty()) {
                    Text(user.signature, color = Color.White.copy(alpha = 0.82f), fontSize = FlareSizes.fontSizeSm.value.sp)
                } else if (!signaturePlaceholder.isNullOrEmpty()) {
                    Text(
                        signaturePlaceholder, color = Color.White.copy(alpha = 0.62f),
                        fontSize = FlareSizes.fontSizeSm.value.sp, fontStyle = FontStyle.Italic,
                    )
                }
                if (!user.flareId.isNullOrEmpty()) {
                    Text("Flare ID: ${user.flareId}", color = Color.White.copy(alpha = 0.62f), fontSize = FlareSizes.fontSizeSm.value.sp)
                }
            }
            // QR badge — its own tap target, distinct from the header's edit click.
            Box(
                Modifier.size(34.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.14f))
                    .clickable(enabled = onQr != null) { onQr?.invoke() },
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Outlined.QrCode, "二维码", tint = Color.White.copy(alpha = 0.92f), modifier = Modifier.size(20.dp)) }
            Spacer(Modifier.width(FlareSizes.spacingXs))
            Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, contentDescription = null, tint = Color.White.copy(alpha = 0.7f))
        }
        // Grouped section cards (iOS-style) — shared row honours kind/detail/toggle.
        groups.forEach { group ->
            if (group.items.isEmpty()) return@forEach
            if (!group.title.isNullOrEmpty()) {
                Text(
                    group.title, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.padding(
                        start = FlareSizes.spacingLg, end = FlareSizes.spacingLg,
                        top = FlareSizes.spacingMd, bottom = FlareSizes.spacingSm,
                    ),
                )
            }
            Spacer(Modifier.size(FlareSizes.spacingSm))
            Column(
                Modifier.fillMaxWidth()
                    .padding(horizontal = FlareSizes.spacingMd)
                    .shadow(2.dp, RoundedCornerShape(16.dp), clip = false)
                    .clip(RoundedCornerShape(16.dp))
                    .background(colors.bgElevated),
            ) {
                group.items.forEachIndexed { i, e ->
                    if (i > 0) Divider(color = colors.borderSecondary, modifier = Modifier.padding(start = FlareSizes.spacingMd))
                    SettingsRow(item = e, onToggle = onToggle, onSelect = { onEntry?.invoke(it) })
                }
            }
        }
    }
}

val defaultProfileEntries: List<SettingsItem> = listOf(
    SettingsItem("favorites", "Favorites", Icons.Outlined.Star),
    SettingsItem("moments", "Moments", Icons.Outlined.Collections),
    SettingsItem("settings", "Settings", Icons.Outlined.Settings),
)
