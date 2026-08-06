package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** One option in a [FilterTabs] row. */
data class FlareFilterTabOption(val value: String, val label: String, val badge: Int? = null)

/**
 * A horizontal, scrollable tablist for filtering (conversations, search kinds…).
 * Spec: General/FilterTabs (`FilterTabs`).
 */
@Composable
fun FilterTabs(
    options: List<FlareFilterTabOption>,
    selected: String,
    onSelect: (String) -> Unit,
) {
    val colors = flareColors()
    Row(
        modifier = Modifier
            .horizontalScroll(rememberScrollState())
            .padding(FlareSizes.spacingXs),
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        for (option in options) {
            val active = option.value == selected
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
                    .clickable { onSelect(option.value) }
                    .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    option.label,
                    color = if (active) colors.primary else colors.textSecondary,
                    fontSize = FlareSizes.fontSizeMd.value.sp,
                    fontWeight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                )
                val badge = option.badge
                if (badge != null && badge > 0) {
                    Spacer(Modifier.width(FlareSizes.spacingXs))
                    Box(
                        modifier = Modifier
                            .defaultMinSize(minWidth = FlareSizes.spacingLg)
                            .clip(RoundedCornerShape(FlareSizes.radiusFull))
                            .background(colors.primary)
                            .padding(horizontal = FlareSizes.spacingXs, vertical = FlareSizes.spacingXs / 2),
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
