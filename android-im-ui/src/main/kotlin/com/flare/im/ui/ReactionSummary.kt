package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddReaction
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Message reaction pills + add button. Spec: Message/ReactionSummary. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ReactionSummary(
    reactions: List<ReactionGroup>,
    hideAdd: Boolean = false,
    onToggle: ((String) -> Unit)? = null,
    onAdd: (() -> Unit)? = null,
) {
    val colors = flareColors()
    if (reactions.isEmpty() && hideAdd) return
    val pillShape = RoundedCornerShape(999.dp)
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        reactions.forEach { r ->
            val active = r.reactedBySelf
            Row(
                Modifier.height(26.dp)
                    .clip(pillShape)
                    .background(if (active) colors.bgSelected else colors.bgSecondary)
                    .border(1.dp, if (active) colors.primary else colors.borderPrimary, pillShape)
                    .then(if (onToggle != null) Modifier.clickable { onToggle(r.emoji) } else Modifier)
                    .padding(horizontal = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(r.emoji, fontSize = FlareSizes.fontSizeMd.value.sp)
                Text(
                    "${r.count}",
                    color = if (active) colors.primary else colors.textSecondary,
                    fontWeight = FontWeight.Medium,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                )
            }
        }
        if (!hideAdd) {
            Row(
                Modifier.height(26.dp)
                    .clip(pillShape)
                    .background(colors.bgSecondary)
                    .border(1.dp, colors.borderPrimary, pillShape)
                    .then(if (onAdd != null) Modifier.clickable { onAdd() } else Modifier)
                    .padding(horizontal = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.Outlined.AddReaction,
                    contentDescription = flareStrings().addReaction,
                    tint = colors.textTertiary,
                    modifier = Modifier.size(15.dp),
                )
            }
        }
    }
}
