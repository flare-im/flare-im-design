package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.Placeable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

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
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        reactions.forEach { reaction -> ReactionGroupPill(reaction, onToggle) }
        if (!hideAdd) {
            ReactionPill(onClick = onAdd, enabled = onAdd != null) {
                Icon(
                    flareIconVector("reaction"),
                    contentDescription = flareStrings().addReaction,
                    tint = if (onAdd == null) colors.textDisabled else colors.textTertiary,
                    modifier = Modifier.size(FlareSizes.iconSizeSm),
                )
            }
        }
    }
}

private val reactionPillHeight = 22.dp

/**
 * Fits the footer to the message. Short messages can widen the footer to fit two pills and the timestamp.
 * Each run hugs the sender's edge. The trailing metadata joins the final run when there is space.
 */
@Composable
internal fun MessageReactionFooter(
    reactions: List<ReactionGroup>,
    outgoing: Boolean,
    onToggle: ((String) -> Unit)?,
    modifier: Modifier = Modifier,
    metadataNeedsOwnRow: Boolean = false,
    body: @Composable () -> Unit,
    metadata: @Composable () -> Unit,
) {
    val pills: @Composable () -> Unit = {
        reactions.forEach { reaction -> ReactionGroupPill(reaction, onToggle) }
    }
    val surfaceContent: @Composable () -> Unit = { Box { body() } }
    Layout(
        contents = listOf(surfaceContent, pills, metadata),
        modifier = modifier,
    ) { (surfaces, pillMeasurables, metadataMeasurables), constraints ->
        val loose = constraints.copy(minWidth = 0, minHeight = 0)
        val surface = surfaces.single().measure(loose)
        val chips = pillMeasurables.map { it.measure(loose) }
        val meta = metadataMeasurables.singleOrNull()?.measure(loose)
        val gap = FlareSizes.spacingXs.roundToPx()
        val preferredChipWidth = chips.take(2).sumOf { it.width } + if (chips.size > 1) gap else 0
        val preferredWidth = when {
            meta == null -> preferredChipWidth
            metadataNeedsOwnRow -> maxOf(preferredChipWidth, meta.width)
            else -> preferredChipWidth + gap + meta.width
        }
        val width = maxOf(surface.width, preferredWidth, chips.maxOf { it.width })
            .coerceIn(constraints.minWidth, constraints.maxWidth)

        val rows = mutableListOf<List<Placeable>>()
        var run = mutableListOf<androidx.compose.ui.layout.Placeable>()
        var runWidth = 0
        for (chip in chips) {
            if (run.isNotEmpty() && runWidth + gap + chip.width > width) {
                rows += run
                run = mutableListOf()
                runWidth = 0
            }
            if (run.isNotEmpty()) runWidth += gap
            run += chip
            runWidth += chip.width
        }
        rows += run
        val inlineMeta = meta?.takeIf { !metadataNeedsOwnRow && runWidth + gap + it.width <= width }
        val stackedMeta = meta?.takeUnless { it === inlineMeta }
        val metaOffset = ((reactionPillHeight.roundToPx() - (inlineMeta?.height ?: 0)) / 2).coerceAtLeast(0)
        val rowHeights = rows.map { row -> row.maxOf { it.height } }.toMutableList()
        if (inlineMeta != null) {
            rowHeights[rows.lastIndex] = maxOf(rowHeights.last(), metaOffset + inlineMeta.height)
        }
        val footerTop = surface.height + gap
        val pillsHeight = rowHeights.sum() + gap * rows.lastIndex
        val metaHeight = stackedMeta?.let { gap + it.height } ?: 0
        layout(width, (footerTop + pillsHeight + metaHeight).coerceIn(constraints.minHeight, constraints.maxHeight)) {
            surface.placeRelative(if (outgoing) width - surface.width else 0, 0)
            var y = footerTop
            rows.forEachIndexed { index, row ->
                val rowWidth = row.sumOf { it.width } + gap * row.lastIndex
                val rowMeta = inlineMeta?.takeIf { index == rows.lastIndex }
                val trailing = rowMeta?.let { it.width + gap } ?: 0
                var x = if (outgoing) width - rowWidth - trailing else 0
                row.forEach { chip ->
                    chip.placeRelative(x, y)
                    x += chip.width + gap
                }
                rowMeta?.placeRelative(width - rowMeta.width, y + metaOffset)
                y += rowHeights[index] + gap
            }
            stackedMeta?.placeRelative(width - stackedMeta.width, footerTop + pillsHeight + gap)
        }
    }
}

@Composable
private fun ReactionGroupPill(reaction: ReactionGroup, onToggle: ((String) -> Unit)?) {
    val colors = flareColors()
    ReactionPill(
        selected = reaction.reactedBySelf,
        onClick = onToggle?.let { toggle -> { toggle(reaction.emoji) } },
    ) {
        Text(
            reaction.emoji,
            fontSize = FlareSizes.fontSizeLg,
            lineHeight = FlareSizes.fontSizeLg * FlareSizes.lineHeightSnug,
        )
        Text(
            reaction.count.toString(),
            color = if (reaction.reactedBySelf) colors.primaryText else colors.textSecondary,
            fontWeight = FontWeight.Medium,
            fontSize = FlareSizes.fontSizeSm,
            lineHeight = FlareSizes.fontSizeSm * FlareSizes.lineHeightSnug,
        )
    }
}

@Composable
private fun ReactionPill(
    selected: Boolean? = null,
    enabled: Boolean = true,
    onClick: (() -> Unit)?,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    val active = selected == true
    val shape = RoundedCornerShape(FlareSizes.radiusFull)
    val target = when {
        onClick != null -> Modifier
            .sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
            .clickable(role = Role.Button, onClick = onClick)
        !enabled -> Modifier.clickable(enabled = false, role = Role.Button, onClick = {})
        else -> Modifier
    }
    Box(
        modifier = target.semantics(mergeDescendants = true) {
            if (selected != null) this.selected = selected
        },
        contentAlignment = Alignment.TopStart,
    ) {
        Row(
            Modifier.sizeIn(minWidth = FlareSizes.touchTarget, minHeight = reactionPillHeight)
                .background(if (active) colors.messageReactionSelected else colors.messageReactionBackground, shape)
                .border(1.dp, if (active) colors.primary else colors.borderPrimary, shape)
                .padding(horizontal = FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs, Alignment.CenterHorizontally),
        ) { content() }
    }
}
