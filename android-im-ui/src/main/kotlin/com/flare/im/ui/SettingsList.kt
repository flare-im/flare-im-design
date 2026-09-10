package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.selection.toggleable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.draw.alpha
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * The Feishu-style grouped settings card: a section's rows float together on one
 * [FlareColors.bgElevated] surface with [FlareSizes.radiusXl] corners and a soft shadow.
 *
 * Extracted from [SettingsList] so every settings-shaped surface in the kit (settings list,
 * profile panel, group detail) draws the *same* card instead of each re-deriving one — this
 * mirrors the iOS `flareGroupedCard()` modifier.
 */
@Composable
fun FlareGroupedCard(
    modifier: Modifier = Modifier,
    content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit,
) {
    val colors = flareColors()
    Column(
        modifier.fillMaxWidth()
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs)
            .shadow(2.dp, RoundedCornerShape(FlareSizes.radiusXl), clip = false)
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgElevated),
        content = content,
    )
}

/** The indented hairline between two rows of a [FlareGroupedCard]. */
@Composable
fun FlareGroupedCardDivider() {
    Divider(color = flareColors().borderSecondary, modifier = Modifier.padding(start = FlareSizes.spacingMd))
}

/**
 * Settings list — grouped toggle / navigation / value rows. A generic settings
 * container. Spec: Profile/SettingsList (`SettingsList`).
 */
@Composable
fun SettingsList(
    sections: List<SettingsSection>,
    onToggle: ((SettingsItem, Boolean) -> Unit)? = null,
    onSelect: ((SettingsItem) -> Unit)? = null,
    /** Set false when the host already owns vertical scrolling. */
    scrollable: Boolean = true,
) {
    if (scrollable) {
        LazyColumn(Modifier.fillMaxWidth()) {
            sections.forEachIndexed { index, section ->
                item(key = "section-$index") { SettingsSectionContent(section, onToggle, onSelect) }
            }
        }
    } else {
        Column(Modifier.fillMaxWidth()) {
            sections.forEach { section -> SettingsSectionContent(section, onToggle, onSelect) }
        }
    }
}

@Composable
private fun SettingsSectionContent(
    section: SettingsSection,
    onToggle: ((SettingsItem, Boolean) -> Unit)?,
    onSelect: ((SettingsItem) -> Unit)?,
) {
    val colors = flareColors()
    if (!section.title.isNullOrEmpty()) {
        Text(section.title, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
            modifier = Modifier.padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg,
                top = FlareSizes.spacingMd, bottom = FlareSizes.spacingSm))
    }
    FlareGroupedCard {
        section.items.forEachIndexed { index, item ->
            if (index > 0) FlareGroupedCardDivider()
            SettingsRow(item = item, onToggle = onToggle, onSelect = onSelect)
        }
    }
}

/**
 * One settings/profile entry row — icon, label, then the trailing affordance for its
 * [FlareSettingKind]: a switch (Toggle), a value (Value), or detail + chevron (Navigation).
 *
 * Shared by [SettingsList] and [ProfilePanel] so the two can't drift — previously `ProfilePanel`
 * re-implemented this row and silently dropped `kind` and `detail`, rendering every entry as a bare
 * label + chevron.
 */
@Composable
fun SettingsRow(
    item: SettingsItem,
    onToggle: ((SettingsItem, Boolean) -> Unit)? = null,
    onSelect: ((SettingsItem) -> Unit)? = null,
) {
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth()
            .heightIn(min = 48.dp)
            .alpha(if (item.disabled) 0.45f else 1f)
            .then(if (item.kind == FlareSettingKind.Toggle) Modifier.toggleable(
                value = item.value, enabled = !item.disabled && onToggle != null, role = Role.Switch,
                onValueChange = { onToggle?.invoke(item, it) },
            ) else Modifier.clickable(enabled = !item.disabled && onSelect != null, role = Role.Button) { onSelect?.invoke(item) })
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        item.icon?.let { ic -> Icon(ic, null, tint = colors.textSecondary); Spacer(Modifier.width(FlareSizes.spacingMd)) }
        Text(item.label, color = if (item.danger) colors.error else colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.weight(1f))
        when (item.kind) {
            FlareSettingKind.Toggle -> Switch(checked = item.value, enabled = !item.disabled && onToggle != null, onCheckedChange = null)
            FlareSettingKind.Value -> Text(item.detail ?: "", color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp)
            FlareSettingKind.Navigation -> {
                item.detail?.let { d ->
                    Text(d, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp)
                    Spacer(Modifier.width(6.dp))
                }
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = colors.textTertiary)
            }
        }
    }
}
