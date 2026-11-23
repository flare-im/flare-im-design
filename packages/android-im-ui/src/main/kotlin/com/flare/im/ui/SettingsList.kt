package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.selection.toggleable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTag
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.height
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * The grouped settings card: a section's rows sit together on one [FlareColors.bgElevated] surface with
 * [FlareSizes.radiusLg] corners and one hairline edge — no shadow, as Vue's `.flare-settings__group`.
 *
 * Extracted from [SettingsList] so every settings-shaped surface in the kit (settings list,
 * profile panel, group detail) draws the *same* card instead of each re-deriving one — this
 * mirrors the iOS `flareGroupedCard()` modifier.
 */
@Composable
fun FlareGroupedCard(
    modifier: Modifier = Modifier,
    /** Vue's `surface="flush"`: full-bleed rows on the page surface — no inset, edge or corners. */
    flush: Boolean = false,
    content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit,
) {
    val colors = flareColors()
    Column(
        if (flush) modifier.fillMaxWidth().background(colors.bgPrimary)
        else modifier.fillMaxWidth()
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs)
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(colors.bgElevated)
            .border(1.dp, colors.borderSecondary, RoundedCornerShape(FlareSizes.radiusLg)),
        content = content,
    )
}

/** A full-width hairline between two parts of a page (the Vue panels' `border-bottom`, e.g. under a search's type row). */
@Composable
fun FlareHairline() {
    HorizontalDivider(thickness = 1.dp, color = flareColors().borderSecondary)
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
    /** Rows flush with the page instead of in cards ([FlareGroupedCard] `flush`). */
    flush: Boolean = false,
) {
    if (scrollable) {
        LazyColumn(Modifier.fillMaxWidth()) {
            sections.forEachIndexed { index, section ->
                item(key = "section-$index") { SettingsSectionContent(section, onToggle, onSelect, flush) }
            }
        }
    } else {
        Column(Modifier.fillMaxWidth()) {
            sections.forEach { section -> SettingsSectionContent(section, onToggle, onSelect, flush) }
        }
    }
}

@Composable
private fun SettingsSectionContent(
    section: SettingsSection,
    onToggle: ((SettingsItem, Boolean) -> Unit)?,
    onSelect: ((SettingsItem) -> Unit)?,
    flush: Boolean = false,
) {
    val colors = flareColors()
    if (!section.title.isNullOrEmpty()) {
        // Vue `.flare-settings__title`: sm, secondary, medium.
        Text(section.title, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Medium,
            modifier = Modifier.padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg,
                top = FlareSizes.spacingMd, bottom = FlareSizes.spacingSm))
    }
    FlareGroupedCard(flush = flush) {
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

/** Whether [item] draws its count badge ([SettingsItem.count] above 0): every kind but a toggle. */
internal fun settingsRowDrawsCount(item: SettingsItem): Boolean =
    item.kind != FlareSettingKind.Toggle && flareCountBadgeDrawn(item.count)

/** The count badge of [SettingsItem.count], read with the row. */
@Composable
private fun SettingsRowCount(count: Int?) {
    Spacer(Modifier.width(FlareSizes.spacing2xs))
    UnreadBadge(count)
}

/**
 * The kit's red count capsule (Vue `FlareUnreadBadge`): 99+ above 99 (`spec/count-badge-vectors.json`); nothing for 0.
 * Decorative: the control it sits on says the count.
 */
@Composable
fun UnreadBadge(count: Int?) {
    if (!flareCountBadgeDrawn(count)) return
    Box(
        Modifier.defaultMinSize(minWidth = 18.dp)
            .height(18.dp)
            .clip(RoundedCornerShape(FlareSizes.radiusFull))
            .background(flareColors().error)
            .padding(horizontal = 5.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(flareCountBadgeText(count), color = androidx.compose.ui.graphics.Color.White, fontSize = FlareSizes.fontSizeXs.value.sp,
            fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold)
    }
}

/** [item]'s tag when it draws one: every kind but a toggle, and only non-blank words. */
internal fun settingsRowTag(item: SettingsItem): String? =
    item.tag?.trim()?.takeIf { it.isNotEmpty() && item.kind != FlareSettingKind.Toggle }

/** The warning tag of [SettingsItem.tag], drawn as a plugin badge (the kit's tinted capsule). */
@Composable
private fun SettingsRowTag(text: String) {
    Spacer(Modifier.width(FlareSizes.spacing2xs))
    PluginBadgeTag(PluginBadge(text, PluginTone.Warning), Modifier.semantics { testTag = "settings.row.tag" })
}

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
 *
 * [current] marks the row whose page is showing beside the list (Vue `item.current`): the selected fill, the label in
 * the primary text colour and semibold, so not by colour alone, and read out as selected.
 */
@Composable
fun SettingsRow(
    item: SettingsItem,
    onToggle: ((SettingsItem, Boolean) -> Unit)? = null,
    onSelect: ((SettingsItem) -> Unit)? = null,
    current: Boolean = false,
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
            Modifier.clickable(enabled = !item.disabled && !item.loading && onSelect != null, role = Role.Button) { onSelect?.invoke(item) }
    }
    Row(
        Modifier.fillMaxWidth()
            .heightIn(min = FlareSizes.touchTarget)
            .flareDimmed(if (item.disabled) 0.45f else 1f)
            .then(if (current) Modifier.background(colors.bgSelected).semantics { selected = true } else Modifier)
            .then(behaviour)
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
        verticalAlignment = if (stacked) Alignment.Top else Alignment.CenterVertically,
    ) {
        item.icon?.let { name ->
            // Beside a label with an explanation under it, the icon sits on the label's line, as Vue's described rows.
            Box(if (item.description != null && !stacked) Modifier.align(Alignment.Top).padding(top = 2.dp) else Modifier) {
                FlareIcon(name = name, tint = colors.textSecondary)
            }
            Spacer(Modifier.width(FlareSizes.spacingMd))
        }
        val labelColor = if (item.danger) colors.errorText else if (current) colors.primaryText else colors.textPrimary
        val labelWeight = if (current) FontWeight.SemiBold else null
        if (stacked) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(item.label, color = labelColor, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = labelWeight, modifier = Modifier.weight(1f))
                    settingsRowTag(item)?.let { SettingsRowTag(it) }
                    if (settingsRowDrawsCount(item)) SettingsRowCount(item.count)
                    if (settingsRowDrawsBadge(item)) SettingsRowDot()
                    if (item.loading) SettingsRowSpinner()
                    else if (settingsRowHasChevron(item.kind)) Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = colors.textTertiary, modifier = Modifier.size(FlareSizes.iconSizeSm))
                }
                item.description?.let { SettingsRowDescription(it) }
                Text(item.detail.orEmpty(), color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 3, overflow = TextOverflow.Ellipsis)
            }
        } else if (item.description != null) {
            // The explanation goes under the label; the switch or value stays centred at the end.
            Column(Modifier.weight(1f).padding(end = FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(item.label, color = labelColor, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = labelWeight)
                SettingsRowDescription(item.description)
            }
            SettingsRowTrailing(item)
        } else {
            Text(item.label, color = labelColor, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = labelWeight, modifier = Modifier.weight(1f))
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
    if (item.loading && item.kind != FlareSettingKind.Toggle) { SettingsRowSpinner(); return }
    when (item.kind) {
        FlareSettingKind.Toggle -> FlareSwitchTrack(item.value, size = FlareControlSize.Sm)
        // A short value stays end-aligned on one line (at most 16 characters; a longer one stacks).
        // An action's optional detail reads the same way; neither draws a chevron.
        FlareSettingKind.Value, FlareSettingKind.Action -> {
            item.detail?.let { d ->
                Text(d, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            settingsRowTag(item)?.let { SettingsRowTag(it) }
            if (settingsRowDrawsCount(item)) SettingsRowCount(item.count)
            if (settingsRowDrawsBadge(item)) SettingsRowDot()
        }
        FlareSettingKind.Navigation -> {
            item.detail?.let { d ->
                Text(d, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
                Spacer(Modifier.width(FlareSizes.spacing2xs))
            }
            settingsRowTag(item)?.let { SettingsRowTag(it) }
            if (settingsRowDrawsCount(item)) SettingsRowCount(item.count)
            if (settingsRowDrawsBadge(item)) SettingsRowDot()
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = colors.textTertiary, modifier = Modifier.size(FlareSizes.iconSizeSm))
        }
    }
}

/** A running row's end: a 16 spinner in the tertiary ink, read as loading. */
@Composable
internal fun SettingsRowSpinner() {
    val label = flareStrings().loading
    androidx.compose.material3.CircularProgressIndicator(
        Modifier.size(FlareSizes.iconSizeSm).semantics { contentDescription = label },
        color = flareColors().textTertiary, strokeWidth = 2.dp,
    )
}
