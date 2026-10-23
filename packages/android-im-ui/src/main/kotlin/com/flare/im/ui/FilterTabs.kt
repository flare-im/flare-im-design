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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** One option in a [FilterTabs] row. */
data class FlareFilterTabOption(val value: String, val label: String, val badge: Int? = null)

/**
 * A horizontal, scrollable tablist for filtering (conversations, search kinds…).
 * Spec: General/FilterTabs (`FilterTabs`).
 *
 * Each option is a tab that reads its selected state; [label] names the tab list for screen readers (what it filters).
 * [enabled] false keeps the tabs in place, dimmed, and takes no taps — while the list behind them reloads.
 * A pill keeps the size it is drawn at and sits centred in a cell at least [FlareSizes.touchTarget] square that takes
 * the taps; the press shows on the pill.
 */
@Composable
fun FilterTabs(
    options: List<FlareFilterTabOption>,
    selected: String,
    onSelect: (String) -> Unit,
    enabled: Boolean = true,
    label: String? = null,
) {
    val colors = flareColors()
    Row(
        modifier = Modifier
            .horizontalScroll(rememberScrollState())
            .flareDimmed(if (enabled) 1f else FlareOpacity.disabled)
            .selectableGroup()
            .then(if (label != null) Modifier.semantics { contentDescription = label } else Modifier)
            .padding(2.dp),
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs),
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
                contentAlignment = Alignment.Center,
            ) {
                Row(
                    modifier = Modifier
                        .clip(RoundedCornerShape(FlareSizes.radiusFull))
                        .background(
                            if (active) colors.primary.copy(alpha = 0.12f) else colors.bgSecondary,
                        )
                        .border(
                            1.dp,
                            if (active) colors.primary.copy(alpha = 0.26f) else Color.Transparent,
                            RoundedCornerShape(FlareSizes.radiusFull),
                        )
                        .indication(interaction, LocalIndication.current)
                        .padding(horizontal = FlareSizes.spacing2md, vertical = FlareSizes.spacing2xs),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        option.label,
                        color = if (active) colors.primaryText else colors.textSecondary,
                        fontSize = FlareSizes.fontSizeMd.value.sp,
                        fontWeight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                    )
                    val badge = option.badge
                    if (badge != null && badge > 0) {
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
                                badge.toString(),
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
