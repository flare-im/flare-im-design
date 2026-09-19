package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
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
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
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
 *  - The header is a quiet identity card on the same elevated surface, radius and shadow as the groups below it:
 *    the name in primary text, the signature in secondary, the Flare ID and the chevron in tertiary.
 *  - The identity row (avatar, name, signature, id, chevron) is one control that opens the editor ([onEdit]), named
 *    "{name}，编辑资料" ([FlareStrings.profilePanelEditProfile]); the QR button beside it is a separate control
 *    ([onQr]) named 我的二维码, never a tap nested inside the row's.
 *  - [signaturePlaceholder] shows a tertiary hint when the user has no signature yet.
 *  - Entries render as grouped section cards ([sections]) rather than one flat list; [entries] stays
 *    as the single-group convenience path. Without either, the panel lists [profileEntries] labelled from the
 *    ambient [FlareStrings] (`favorites`, `moments`, `settings`), as iOS `ProfilePanelView.entries(for:)` and
 *    Flutter `FlareProfilePanel.entriesFor` do.
 */
@Composable
fun ProfilePanel(
    user: UserProfile,
    /** Flat entry list, used only when [sections] is null. Null lists [profileEntries] labelled from the ambient [FlareStrings]. */
    entries: List<SettingsItem>? = null,
    /** Grouped rows (iOS-style cards). Overrides [entries] when non-null. */
    sections: List<SettingsSection>? = null,
    /** Tertiary hint shown in the header when the user has no signature yet. */
    signaturePlaceholder: String? = null,
    onEdit: (() -> Unit)? = null,
    onQr: (() -> Unit)? = null,
    onEntry: ((SettingsItem) -> Unit)? = null,
    onToggle: ((SettingsItem, Boolean) -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    // Normalize to grouped sections so there is a single render path.
    val groups = profilePanelGroups(sections, entries, strings)
    Column(Modifier.fillMaxWidth()) {
        // The identity card: the same surface as the groups below it. The identity row and the QR button are
        // siblings, so each is reached and named on its own.
        Box(
            Modifier.fillMaxWidth()
                .padding(start = FlareSizes.spacingMd, end = FlareSizes.spacingMd, top = FlareSizes.spacingMd)
                .shadow(2.dp, RoundedCornerShape(FlareSizes.radiusXl), clip = false)
                .clip(RoundedCornerShape(FlareSizes.radiusXl))
                .background(colors.bgElevated),
        ) {
            val editLabel = strings.profilePanelEditProfile(user.name)
            Row(
                Modifier.fillMaxWidth()
                    .heightIn(min = 88.dp)
                    .semantics(mergeDescendants = true) { contentDescription = editLabel }
                    .clickable(enabled = onEdit != null, role = Role.Button) { onEdit?.invoke() }
                    .padding(start = FlareSizes.spacingLg, top = FlareSizes.spacingLg, bottom = FlareSizes.spacingLg, end = FlareSizes.spacingMd),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.clearAndSetSemantics {}) { Avatar(userId = user.id, displayName = user.name, avatarUrl = user.avatarUrl, size = 56.dp) }
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f).clearAndSetSemantics {}) {
                    Text(user.name, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl.value.sp, fontWeight = FontWeight.Bold,
                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                    if (!user.signature.isNullOrEmpty()) {
                        Text(user.signature, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    } else if (!signaturePlaceholder.isNullOrEmpty()) {
                        Text(signaturePlaceholder, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                    if (!user.flareId.isNullOrEmpty()) {
                        Text("Flare ID: ${user.flareId}", color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                    }
                }
                // Room for the QR control, which sits over the row as its own sibling.
                Spacer(Modifier.width(FlareSizes.touchTarget))
                Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, contentDescription = null, tint = colors.textTertiary)
            }
            if (onQr != null) {
                FlareIconControl(
                    label = strings.myQrCode,
                    onClick = onQr,
                    modifier = Modifier.align(Alignment.CenterEnd).padding(end = FlareSizes.spacingMd + FlareSizes.iconSizeLg),
                    shape = CircleShape,
                ) {
                    Icon(Icons.Outlined.QrCode, contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(FlareSizes.iconSizeMd))
                }
            }
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
                    .shadow(2.dp, RoundedCornerShape(FlareSizes.radiusXl), clip = false)
                    .clip(RoundedCornerShape(FlareSizes.radiusXl))
                    .background(colors.bgElevated),
            ) {
                group.items.forEachIndexed { i, e ->
                    if (i > 0) HorizontalDivider(color = colors.borderSecondary, modifier = Modifier.padding(start = FlareSizes.spacingMd))
                    SettingsRow(item = e, onToggle = onToggle, onSelect = { onEntry?.invoke(it) })
                }
            }
        }
    }
}

/**
 * The profile panel's default entries — favorites, moments and settings — labelled from [strings] (`favorites`,
 * `moments`, `settings`), so a host changes their copy through [LocalFlareStrings]. Mirrors iOS
 * `ProfilePanelView.entries(for:)` and Flutter `FlareProfilePanel.entriesFor`.
 */
fun profileEntries(strings: FlareStrings): List<SettingsItem> = listOf(
    SettingsItem("favorites", strings.favorites, "star"),
    SettingsItem("moments", strings.moments, "moments"),
    SettingsItem("settings", strings.settings, "settings"),
)

/**
 * The groups the panel renders: the host's [sections]; else one group of the host's [entries] (an empty list included,
 * which shows no rows); else one group of [profileEntries] from [strings].
 */
internal fun profilePanelGroups(sections: List<SettingsSection>?, entries: List<SettingsItem>?, strings: FlareStrings): List<SettingsSection> =
    sections ?: listOf(SettingsSection(items = entries ?: profileEntries(strings)))
