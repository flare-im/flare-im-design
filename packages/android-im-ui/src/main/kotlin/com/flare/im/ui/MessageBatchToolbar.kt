package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// MARK: contract (pure, testable without a Compose runtime)

/** Batch actions a host may expose over a multi-selection of messages. */
enum class MessageBatchAction { ForwardEach, ForwardMerged, Pin, PinSelf, Delete }

/** Host-declared capabilities; a false entry hides the action entirely. */
data class MessageBatchCapabilities(
    val forwardEach: Boolean = false,
    val forwardMerged: Boolean = false,
    val pin: Boolean = false,
    val pinSelf: Boolean = false,
    val delete: Boolean = false,
) {
    fun allows(action: MessageBatchAction): Boolean = when (action) {
        MessageBatchAction.ForwardEach -> forwardEach
        MessageBatchAction.ForwardMerged -> forwardMerged
        MessageBatchAction.Pin -> pin
        MessageBatchAction.PinSelf -> pinSelf
        MessageBatchAction.Delete -> delete
    }
}

/** What an action needs to mean anything: merging messages into one card needs two. */
val flareMessageBatchMinimumSelection: Map<MessageBatchAction, Int> = mapOf(MessageBatchAction.ForwardMerged to 2)

/**
 * Actions the toolbar may offer right now (`spec/message-batch-vectors.json`, the same table on four
 * kits): empty while busy or with nothing selected; otherwise the capability-enabled actions in
 * canonical order, minus those the selection is too small for.
 */
fun messageBatchActionsAvailable(
    selectedIds: List<String>,
    capabilities: MessageBatchCapabilities?,
    busy: Boolean,
): List<MessageBatchAction> {
    if (busy || selectedIds.isEmpty() || capabilities == null) return emptyList()
    return MessageBatchAction.entries.filter {
        capabilities.allows(it) && selectedIds.size >= (flareMessageBatchMinimumSelection[it] ?: 1)
    }
}

internal fun messageBatchActionIcon(action: MessageBatchAction): String = when (action) {
    MessageBatchAction.ForwardEach -> "forward"
    MessageBatchAction.ForwardMerged -> "merge-forward"
    MessageBatchAction.Pin -> "pin"
    MessageBatchAction.PinSelf -> "pin-self"
    MessageBatchAction.Delete -> "delete"
}

internal fun messageBatchActionLabel(action: MessageBatchAction, strings: FlareStrings): String = when (action) {
    MessageBatchAction.ForwardEach -> strings.forwardEach
    MessageBatchAction.ForwardMerged -> strings.forwardMerged
    MessageBatchAction.Pin -> strings.messageBatchPin
    MessageBatchAction.PinSelf -> strings.messageBatchPinSelf
    MessageBatchAction.Delete -> strings.delete
}

/**
 * The buttons of a [MessageBatchToolbar], in display order. Every one draws a registry glyph; all but
 * exit also show their label as text, and exit, drawn as a glyph alone, is named for what it does.
 * Selecting all and clearing the selection bracket the actions the host declared.
 */
internal fun messageBatchToolbarControls(
    strings: FlareStrings,
    selectedIds: List<String>,
    total: Int,
    capabilities: MessageBatchCapabilities,
    busy: Boolean,
): List<FlareIconControlSpec> {
    val available = messageBatchActionsAvailable(selectedIds, capabilities, busy)
    return buildList {
        add(FlareIconControlSpec("selectAll", "check", strings.selectAll, total > 0 && !busy))
        add(FlareIconControlSpec("clearSelection", "close", strings.messageBatchClear, selectedIds.isNotEmpty() && !busy))
        for (action in MessageBatchAction.entries.filter(capabilities::allows)) {
            add(FlareIconControlSpec(action.name, messageBatchActionIcon(action), messageBatchActionLabel(action, strings), action in available))
        }
        add(FlareIconControlSpec("exit", "close", strings.exitMultiSelect, !busy))
    }
}

/**
 * Multi-select toolbar for batch message actions. Spec: Message/MessageBatchToolbar.
 *
 * The keys wrap onto a second line when the bar is too narrow for them all — a phone is: on a 412 dp screen the five
 * keys need about 404 dp beside the count, and a row that cannot wrap squeezed the last one, exit, to nothing.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun MessageBatchToolbar(
    selectedIds: List<String>,
    total: Int,
    capabilities: MessageBatchCapabilities,
    busy: Boolean = false,
    onAction: ((MessageBatchAction, List<String>) -> Unit)? = null,
    onSelectAll: (() -> Unit)? = null,
    onClearSelection: (() -> Unit)? = null,
    onExit: (() -> Unit)? = null,
) {
    val count = selectedIds.size
    val colors = flareColors()
    val strings = flareStrings()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    Row(
        Modifier.fillMaxWidth()
            .shadow(8.dp, shape, clip = false)
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, shape)
            // The exit button's 48 dp touch target is 16 dp taller than the 32 dp pills; the vertical
            // padding gives those 8 dp a side back, so the bar keeps its height and the pills their place.
            .padding(horizontal = 14.dp, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("$count", color = colors.primaryText, fontWeight = FontWeight.Bold, fontSize = FlareSizes.fontSizeLg.value.sp)
            Text(" / $total · ${strings.selectedSuffix}", color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
        }
        Spacer(Modifier.width(FlareSizes.spacingMd))
        FlowRow(
            Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm, Alignment.End),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs, Alignment.CenterVertically),
        ) {
            messageBatchToolbarControls(strings, selectedIds, total, capabilities, busy).forEach { control ->
                when (control.id) {
                    "selectAll" -> MessageBatchButton(colors, control, onSelectAll)
                    "clearSelection" -> MessageBatchButton(colors, control, onClearSelection)
                    "exit" -> MessageBatchExitButton(colors, control, onExit)
                    else -> {
                        val action = MessageBatchAction.valueOf(control.id)
                        MessageBatchButton(
                            colors, control, { onAction?.invoke(action, selectedIds.toList()) },
                            tint = if (action == MessageBatchAction.Delete) colors.errorText else null,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MessageBatchButton(
    colors: FlareColors,
    control: FlareIconControlSpec,
    onTap: (() -> Unit)?,
    tint: Color? = null,
) {
    Row(
        Modifier.height(FlareSizes.controlHeightSm)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(colors.bgSecondary)
            .then(if (control.enabled && onTap != null) Modifier.clickable(role = Role.Button) { onTap() } else Modifier)
            .alpha(if (control.enabled) 1f else 0.45f)
            .padding(horizontal = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(flareIconVector(control.icon), contentDescription = null, tint = tint ?: colors.textPrimary, modifier = Modifier.size(FlareSizes.iconSizeSm))
        Text(control.label, color = tint ?: colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeSm.value.sp)
    }
}

/** Exit: the glyph alone on a pill as wide as the touch target, named by [FlareIconControlSpec.label]. */
@Composable
private fun MessageBatchExitButton(colors: FlareColors, control: FlareIconControlSpec, onTap: (() -> Unit)?) {
    FlareIconControl(
        label = control.label,
        onClick = onTap,
        enabled = control.enabled,
        shape = RoundedCornerShape(FlareSizes.radiusMd),
        modifier = Modifier.alpha(if (control.enabled) 1f else 0.45f),
    ) {
        Box(
            Modifier.size(width = FlareSizes.touchTarget, height = FlareSizes.controlHeightSm)
                .clip(RoundedCornerShape(FlareSizes.radiusMd))
                .background(colors.bgSecondary),
        )
        Icon(flareIconVector(control.icon), contentDescription = null, tint = colors.textPrimary, modifier = Modifier.size(FlareSizes.iconSizeSm))
    }
}
