package com.flare.im.ui

import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.indication
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * One option in a [FilterTabs] row. [badge] is drawn when it is above 0 or [badgeMore] says there are more than it (the
 * server had more than it counted), and reads 99+ above 99 or with [badgeMore] (`spec/count-badge-vectors.json`).
 */
data class FlareFilterTabOption(val value: String, val label: String, val badge: Int? = null, val badgeMore: Boolean = false)

/**
 * A horizontal, scrollable tablist for filtering (conversations, search kinds…).
 * Spec: General/FilterTabs (`FilterTabs`).
 *
 * Each option is a tab that reads its selected state; [label] names the tab list for screen readers (what it filters).
 * [enabled] false keeps the tabs in place, dimmed, and takes no taps — while the list behind them reloads.
 * A pill keeps the size it is drawn at and sits centred in a cell at least [FlareSizes.touchTarget] square that takes
 * the taps; the press shows on the pill. [quiet] draws the Vue kit's `appearance="quiet"`: text with an underline under
 * the selected one, no capsules (a list's own filters, where capsules would shout over the rows).
 */
@Composable
fun FilterTabs(
    options: List<FlareFilterTabOption>,
    selected: String,
    onSelect: (String) -> Unit,
    enabled: Boolean = true,
    label: String? = null,
    quiet: Boolean = false,
) {
    val colors = flareColors()
    Row(
        modifier = Modifier
            // Quiet: a full-width hairline under the row, the selected tab's underline sitting on it (Vue `--quiet`).
            .then(if (quiet) Modifier.fillMaxWidth().drawBehind {
                val y = size.height - 0.5.dp.toPx()
                drawLine(colors.borderSecondary, Offset(0f, y), Offset(size.width, y), 1.dp.toPx())
            } else Modifier)
            .horizontalScroll(rememberScrollState())
            .flareDimmed(if (enabled) 1f else FlareOpacity.disabled)
            .selectableGroup()
            .then(if (label != null) Modifier.semantics { contentDescription = label } else Modifier)
            .padding(if (quiet) 0.dp else 2.dp),
        horizontalArrangement = Arrangement.spacedBy(if (quiet) 0.dp else FlareSizes.spacing2xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        for (option in options) key(option.value) {
            val active = option.value == selected
            val interaction = remember { MutableInteractionSource() }
            Box(
                modifier = Modifier
                    .sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
                    .selectable(
                        selected = active,
                        interactionSource = interaction,
                        indication = null,
                        enabled = enabled,
                        role = Role.Tab,
                    ) { onSelect(option.value) },
                contentAlignment = if (quiet) Alignment.BottomCenter else Alignment.Center,
            ) {
                Row(
                    modifier = (if (quiet) Modifier.drawBehind {
                        val inset = FlareSizes.spacingSm.toPx()
                        if (active) drawRect(colors.primary, topLeft = Offset(inset, size.height - 2.dp.toPx()), size = Size(size.width - 2 * inset, 2.dp.toPx()))
                    } else Modifier
                        .clip(RoundedCornerShape(FlareSizes.radiusFull))
                        .background(
                            if (active) colors.primary.copy(alpha = 0.12f) else colors.bgSecondary,
                        )
                        .border(
                            1.dp,
                            if (active) colors.primary.copy(alpha = 0.26f) else Color.Transparent,
                            RoundedCornerShape(FlareSizes.radiusFull),
                        ))
                        .indication(interaction, LocalIndication.current)
                        .padding(horizontal = if (quiet) FlareSizes.spacingSm else FlareSizes.spacing2md, vertical = if (quiet) FlareSizes.spacingSm else FlareSizes.spacing2xs),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        option.label,
                        color = if (active) colors.primaryText else colors.textSecondary,
                        fontSize = FlareSizes.fontSizeMd.value.sp,
                        fontWeight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                    )
                    // Quiet: the count is a side note in the tab's own colour, not a badge (Vue `--quiet .__badge`).
                    if (quiet && flareCountBadgeDrawn(option.badge, option.badgeMore)) {
                        Spacer(Modifier.width(FlareSizes.spacingXs))
                        Text(
                            flareCountBadgeText(option.badge, option.badgeMore),
                            color = if (active) colors.primaryText else colors.textSecondary,
                            fontSize = FlareSizes.fontSizeXs.value.sp,
                            modifier = Modifier.flareDimmed(0.7f),
                        )
                    } else if (flareCountBadgeDrawn(option.badge, option.badgeMore)) {
                        Spacer(Modifier.width(FlareSizes.spacingXs))
                        Box(
                            modifier = Modifier
                                .defaultMinSize(minWidth = 16.dp)
                                .height(16.dp)
                                .clip(RoundedCornerShape(FlareSizes.radiusFull))
                                .background(colors.primary)
                                .padding(horizontal = 5.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                flareCountBadgeText(option.badge, option.badgeMore),
                                color = Color.White,
                                fontSize = FlareSizes.fontSizeXs.value.sp,
                                fontWeight = FontWeight.SemiBold,
                                textAlign = TextAlign.Center,
                            )
                        }
                    }
                }
            }
        }
    }
}
