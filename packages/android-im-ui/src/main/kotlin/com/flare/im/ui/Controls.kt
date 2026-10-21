package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Screen-level large-title header — the quiet top bar for a tab surface (inbox / directory / me).
 * Sits on [FlareColors.bgPrimary], 24sp bold title, an optional trailing [actions] slot (icons).
 * Distinct from [ChatHeader], which is the conversation chrome (back + avatar + presence).
 */
@Composable
fun ScreenHeader(
    title: String,
    modifier: Modifier = Modifier,
    /**
     * What the screen is reached through — back, a profile avatar, a picker — before the title.
     * Omitted, it takes no room. Declared before [actions] so the reading order matches the row.
     */
    leading: @Composable RowScope.() -> Unit = {},
    actions: @Composable RowScope.() -> Unit = {},
) {
    val colors = flareColors()
    Row(
        modifier
            .fillMaxWidth()
            .background(colors.bgPrimary)
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacing2md),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        leading()
        Text(
            title,
            fontSize = FlareSizes.fontSize5xl,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
            modifier = Modifier.weight(1f),
        )
        actions()
    }
}

/**
 * Single-choice segmented control (分段选择器) — a row of equal-width, mutually-exclusive [options]
 * on a raised-chip track: a [FlareColors.bgSecondary] rail ([FlareSizes.radiusLg] + border), each
 * selected segment surfaced on a [FlareColors.bgPrimary] chip ([FlareSizes.radiusMd] + soft shadow,
 * [FlareColors.primary] label); unselected segments read [FlareColors.textSecondary]. Emits the
 * chosen index via [onSelect]. Use for a small, flat in-page filter (联系人 / 群组 / 新的联系人 …).
 * The rail is a touch target tall and each segment takes taps across the rail's full height, its inset included.
 * [accent] colours the selected segment's label (a text colour, readable on the raised chip); null keeps the brand's
 * `primaryText`.
 */
@Composable
fun SegmentedControl(
    options: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
    accent: Color? = null,
) {
    val colors = flareColors()
    val trackShape = RoundedCornerShape(FlareSizes.radiusLg)
    val inset = 3.dp
    Row(
        modifier
            .clip(trackShape)
            .background(colors.bgSecondary)
            .border(1.dp, colors.borderPrimary, trackShape)
            .padding(horizontal = inset),
        horizontalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        val chipShape = RoundedCornerShape(FlareSizes.radiusMd)
        options.forEachIndexed { i, label ->
            val active = selectedIndex == i
            Box(
                Modifier
                    .weight(1f)
                    .heightIn(min = FlareSizes.touchTarget)
                    .clip(chipShape)
                    .semantics { selected = active }
                    .clickable(role = Role.Tab, onClickLabel = label) { onSelect(i) }
                    // The rail's inset is inside the segment, so the whole rail height takes the tap.
                    .padding(vertical = inset)
                    .then(
                        if (active)
                            Modifier
                                .shadow(4.dp, chipShape)
                                .clip(chipShape)
                                .background(colors.bgPrimary)
                        else Modifier,
                    )
                    .padding(vertical = FlareSizes.spacingSm),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    label,
                    color = if (active) accent ?: colors.primaryText else colors.textSecondary,
                    fontSize = FlareSizes.fontSizeLg.value.sp,
                    fontWeight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                )
            }
        }
    }
}
