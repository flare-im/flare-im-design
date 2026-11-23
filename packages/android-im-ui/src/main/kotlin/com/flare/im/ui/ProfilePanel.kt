package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Size
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Personal center — avatar / name / id / QR + entry list, edit & logout.
 * Spec: Profile/ProfilePanel (`ProfilePanel`).
 *
 * Parity with `FlareProfilePanel.vue`:
 *  - The header is a quiet identity card on the same elevated surface, radius and hairline edge as the groups below it:
 *    the name in primary text, the signature in secondary, the Flare ID and the chevron in tertiary.
 *  - The identity row (avatar, name, signature, id, chevron) is one control that opens the editor ([onEdit]), named
 *    "{name}，编辑资料" ([FlareStrings.profilePanelEditProfile]); the QR button beside it is a separate control
 *    ([onQr]) named 我的二维码, never a tap nested inside the row's. A host whose identity opens an overview rather than
 *    the editor (the 我 page's 个人中心) names it with [identityActionLabel] instead. Without [onEdit] the card is no
 *    control: no chevron, and it reads as the name, signature and id.
 *  - [sidebar] (Vue `layout="sidebar"`, a wide window's menu) keeps the identity card on top while the sections scroll
 *    in the height left, so the host's page must not scroll; [current] is the key of the row whose page shows beside it.
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
    /** The identity control's name when it opens an overview rather than editing; null keeps "{name}，编辑资料". */
    identityActionLabel: String? = null,
    onEdit: (() -> Unit)? = null,
    onQr: (() -> Unit)? = null,
    onEntry: ((SettingsItem) -> Unit)? = null,
    onToggle: ((SettingsItem, Boolean) -> Unit)? = null,
    sidebar: Boolean = false,
    current: String? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    // Normalize to grouped sections so there is a single render path.
    val groups = profilePanelGroups(sections, entries, strings)
    Column(if (sidebar) Modifier.fillMaxSize() else Modifier.fillMaxWidth()) {
        // The identity card: the same surface as the groups below it. The identity row and the QR button are
        // siblings, so each is reached and named on its own.
        Box(
            Modifier.fillMaxWidth()
                .padding(start = FlareSizes.spacingMd, end = FlareSizes.spacingMd, top = FlareSizes.spacingMd)
                .clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(colors.bgElevated)
                .border(1.dp, colors.borderSecondary, RoundedCornerShape(FlareSizes.radiusLg)),
        ) {
            val editLabel = identityActionLabel?.takeIf { it.isNotBlank() } ?: strings.profilePanelEditProfile(user.name)
            Row(
                Modifier.fillMaxWidth()
                    .semantics(mergeDescendants = true) { if (onEdit != null) contentDescription = editLabel }
                    .then(if (onEdit != null) Modifier.clickable(role = Role.Button, onClick = onEdit) else Modifier)
                    .padding(FlareSizes.spacingMd)
                    .heightIn(min = FlareSizes.touchTarget),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.clearAndSetSemantics {}) { Avatar(userId = user.id, displayName = user.name, avatarUrl = user.avatarUrl, size = 48.dp) }
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f).then(if (onEdit != null) Modifier.clearAndSetSemantics {} else Modifier)) {
                    val nameSize = if (sidebar) FlareSizes.fontSizeLg else FlareSizes.fontSize3xl
                    Text(user.name, color = colors.textPrimary, fontSize = nameSize.value.sp, fontWeight = FontWeight.SemiBold,
                        maxLines = 2, overflow = TextOverflow.Ellipsis)
                    if (!user.flareId.isNullOrEmpty()) {
                        Text("Flare ID: ${user.flareId}", color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                            maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                    val signature = user.signature?.takeIf { it.isNotEmpty() }
                    if (signature != null || !signaturePlaceholder.isNullOrEmpty()) {
                        val bioSize = if (sidebar) FlareSizes.fontSizeSm else FlareSizes.fontSizeMd
                        Text(signature ?: signaturePlaceholder.orEmpty(), color = if (signature != null) colors.textSecondary else colors.textTertiary,
                            fontSize = bioSize.value.sp, maxLines = if (sidebar) 1 else 2, overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.padding(top = FlareSizes.spacing3xs))
                    }
                }
                // Room for the QR control, which sits over the row as its own sibling.
                if (onQr != null) Spacer(Modifier.width(FlareSizes.touchTarget))
                if (onEdit != null) Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, contentDescription = null, tint = colors.textTertiary)
            }
            if (onQr != null) {
                FlareIconControl(
                    label = strings.myQrCode,
                    onClick = onQr,
                    modifier = Modifier.align(Alignment.CenterEnd).padding(end = FlareSizes.spacingMd + if (onEdit != null) FlareSizes.iconSizeLg else 0.dp),
                    shape = CircleShape,
                ) {
                    Icon(Icons.Outlined.QrCode, contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(FlareSizes.iconSizeMd))
                }
            }
        }
        // Grouped section cards (iOS-style) — shared row honours kind/detail/toggle.
        Column(if (sidebar) Modifier.weight(1f).verticalScroll(rememberScrollState()) else Modifier) {
            groups.forEach { group ->
                if (group.items.isEmpty()) return@forEach
                if (!group.title.isNullOrEmpty()) {
                    Text(
                        group.title, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, fontWeight = FontWeight.Medium,
                        modifier = Modifier.padding(
                            start = FlareSizes.spacingLg, end = FlareSizes.spacingLg,
                            top = FlareSizes.spacingMd, bottom = FlareSizes.spacingSm,
                        ),
                    )
                }
                Spacer(Modifier.size(FlareSizes.spacingSm))
                // The menu beside a wide page (Vue sidebar): no card, rounded rows 2 apart, the current one with a bar on
                // its start edge.
                if (sidebar) Column(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingSm)) {
                    group.items.forEachIndexed { i, e ->
                        val marked = e.key == current
                        if (i > 0) Spacer(Modifier.size(FlareSizes.spacing3xs))
                        Box(
                            Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusMd)).drawBehind {
                                if (marked) drawRect(colors.borderSelected, size = Size(FlareSizes.spacing3xs.toPx(), size.height))
                            },
                        ) { SettingsRow(item = e, onToggle = onToggle, onSelect = { onEntry?.invoke(it) }, current = marked) }
                    }
                } else Column(
                    Modifier.fillMaxWidth()
                        .padding(horizontal = FlareSizes.spacingMd)
                        .clip(RoundedCornerShape(FlareSizes.radiusLg))
                        .background(colors.bgElevated)
                        .border(1.dp, colors.borderSecondary, RoundedCornerShape(FlareSizes.radiusLg)),
                ) {
                    group.items.forEachIndexed { i, e ->
                        if (i > 0) HorizontalDivider(color = colors.borderSecondary, modifier = Modifier.padding(start = FlareSizes.spacingMd))
                        SettingsRow(item = e, onToggle = onToggle, onSelect = { onEntry?.invoke(it) }, current = e.key == current)
                    }
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
