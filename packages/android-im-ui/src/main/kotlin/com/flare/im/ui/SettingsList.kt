package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.selection.toggleable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
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
    HorizontalDivider(color = flareColors().borderSecondary, modifier = Modifier.padding(start = FlareSizes.spacingMd))
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
    SettingsSectionFooter(section.footer)
}

/** The note under a section's card, in the section title's quiet colour. */
@Composable
internal fun SettingsSectionFooter(text: String?) {
    if (text.isNullOrEmpty()) return
    Text(
        text,
        color = flareColors().textTertiary,
        fontSize = FlareSizes.fontSizeSm,
        lineHeight = FlareSizes.fontSizeSm * FlareSizes.lineHeightNormal,
        modifier = Modifier.padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingXs,
            bottom = FlareSizes.spacingSm),
    )
}

/** Values longer than this many characters go under the label (Vue `FlareSettingsRow`). */
internal const val SETTINGS_ROW_STACK_AFTER_CHARACTERS = 16

/**
 * Whether [item]'s value goes under its label: a value (or navigation detail) longer than
 * [SETTINGS_ROW_STACK_AFTER_CHARACTERS] characters, counted in code points. Toggles never stack.
 */
internal fun settingsRowStacked(item: SettingsItem): Boolean {
    val detail = item.detail ?: return false
    return item.kind != FlareSettingKind.Toggle && detail.codePointCount(0, detail.length) > SETTINGS_ROW_STACK_AFTER_CHARACTERS
}

/** Whether [kind] draws the trailing chevron: only a row that opens a page or a picker does. */
internal fun settingsRowHasChevron(kind: FlareSettingKind): Boolean = kind == FlareSettingKind.Navigation

/** Whether [item] draws its red dot: every kind but a toggle, whose end is the switch. */
internal fun settingsRowDrawsBadge(item: SettingsItem): Boolean = item.badge && item.kind != FlareSettingKind.Toggle

/** The red dot of [SettingsItem.badge]. The row merges its description, so a screen reader hears it with the row. */
@Composable
private fun SettingsRowDot() {
    val description = flareStrings().settingsRowBadge
    Spacer(Modifier.width(FlareSizes.spacingSm))
    Box(
        Modifier.size(FlareSizes.spacingSm)
            .clip(CircleShape)
            .background(flareColors().error)
            .semantics { contentDescription = description },
    )
}

/**
 * One settings/profile entry row — icon, label, then the trailing affordance for its
 * [FlareSettingKind]: a switch (Toggle), detail + chevron (Navigation), a plain button (Action) or
 * read-only information (Value).
 *
 * A [FlareSettingKind.Value] row is **not a control**: it takes no click, has no button role and merges
 * its label and detail into one element, so a screen reader reads "群公告，欢迎大家" instead of offering an
 * action that does not exist. An [FlareSettingKind.Action] row runs in place, so it is a button without a
 * chevron (`danger` colours the destructive ones).
 *
 * A short value stays end-aligned on one line and truncates; a value longer than 16 characters (a group
 * announcement) goes under the label on up to three lines in the secondary text colour ([settingsRowStacked]).
 * A [SettingsItem.description] goes under the label in a smaller size (a switch's title, explanation and switch);
 * the end of the row stays centred beside both lines.
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
    val stacked = settingsRowStacked(item)
    val behaviour = when (item.kind) {
        FlareSettingKind.Toggle -> Modifier.toggleable(
            value = item.value, enabled = !item.disabled && onToggle != null, role = Role.Switch,
            onValueChange = { onToggle?.invoke(item, it) },
        )
        // Information, not an action: nothing to press, and one element to read out.
        FlareSettingKind.Value -> Modifier.semantics(mergeDescendants = true) {}
        FlareSettingKind.Navigation, FlareSettingKind.Action ->
            Modifier.clickable(enabled = !item.disabled && onSelect != null, role = Role.Button) { onSelect?.invoke(item) }
    }
    Row(
        Modifier.fillMaxWidth()
            .heightIn(min = FlareSizes.touchTarget)
            .flareDimmed(if (item.disabled) 0.45f else 1f)
            .then(behaviour)
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
        verticalAlignment = if (stacked) Alignment.Top else Alignment.CenterVertically,
    ) {
        item.icon?.let { name -> FlareIcon(name = name, tint = colors.textSecondary); Spacer(Modifier.width(FlareSizes.spacingMd)) }
        val labelColor = if (item.danger) colors.errorText else colors.textPrimary
        if (stacked) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(item.label, color = labelColor, fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.weight(1f))
                    if (settingsRowDrawsBadge(item)) SettingsRowDot()
                    if (settingsRowHasChevron(item.kind)) Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = colors.textTertiary)
                }
                item.description?.let { SettingsRowDescription(it) }
                Text(item.detail.orEmpty(), color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 3, overflow = TextOverflow.Ellipsis)
            }
        } else if (item.description != null) {
            // The explanation goes under the label; the switch or value stays centred at the end.
            Column(Modifier.weight(1f).padding(end = FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(item.label, color = labelColor, fontSize = FlareSizes.fontSizeLg.value.sp)
                SettingsRowDescription(item.description)
            }
            SettingsRowTrailing(item)
        } else {
            Text(item.label, color = labelColor, fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.weight(1f))
            SettingsRowTrailing(item)
        }
    }
}

/** The line under a row's label ([SettingsItem.description]), in the secondary colour on up to three lines. */
@Composable
private fun SettingsRowDescription(text: String) {
    Text(
        text,
        color = flareColors().textSecondary,
        fontSize = FlareSizes.fontSizeSm,
        lineHeight = FlareSizes.fontSizeSm * FlareSizes.lineHeightNormal,
        maxLines = 3,
        overflow = TextOverflow.Ellipsis,
    )
}

/** The end of an unstacked row, drawn into the row: the switch, the value, or the value and the chevron. */
@Composable
private fun SettingsRowTrailing(item: SettingsItem) {
    val colors = flareColors()
    when (item.kind) {
        FlareSettingKind.Toggle -> FlareSwitchTrack(item.value, size = FlareControlSize.Sm)
        // A short value stays end-aligned on one line (at most 16 characters; a longer one stacks).
        // An action's optional detail reads the same way; neither draws a chevron.
        FlareSettingKind.Value, FlareSettingKind.Action -> {
            item.detail?.let { d ->
                Text(d, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            if (settingsRowDrawsBadge(item)) SettingsRowDot()
        }
        FlareSettingKind.Navigation -> {
            item.detail?.let { d ->
                Text(d, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
                Spacer(Modifier.width(6.dp))
            }
            if (settingsRowDrawsBadge(item)) SettingsRowDot()
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = colors.textTertiary)
        }
    }
}
