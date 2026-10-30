package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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

/** The actions that forward the selection: they count and report only its forwardable ids. */
val MessageBatchAction.forwards: Boolean
    get() = this == MessageBatchAction.ForwardEach || this == MessageBatchAction.ForwardMerged

/**
 * The ids an action works on (`spec/message-batch-vectors.json` forward): for a forward action the selection minus
 * [unforwardableIds] — the ids the core answers canForward false for — in selection order; for any other action the
 * whole selection.
 */
fun messageBatchActionIds(
    action: MessageBatchAction,
    selectedIds: List<String>,
    unforwardableIds: Set<String> = emptySet(),
): List<String> =
    if (!action.forwards || unforwardableIds.isEmpty()) selectedIds.toList()
    else selectedIds.filter { it !in unforwardableIds }

/** How many of the selected ids cannot be forwarded: the count the toolbar's hint shows. */
fun messageBatchUnforwardableCount(selectedIds: List<String>, unforwardableIds: Set<String> = emptySet()): Int =
    selectedIds.toSet().count { it in unforwardableIds }

/**
 * Actions the toolbar may offer right now (`spec/message-batch-vectors.json`, the same table on four
 * kits): empty while busy or with nothing selected; otherwise the capability-enabled actions in
 * canonical order, minus those too few ids are left for — a forward action counts only the forwardable
 * ids (the selection minus [unforwardableIds]), every other action the whole selection.
 */
fun messageBatchActionsAvailable(
    selectedIds: List<String>,
    capabilities: MessageBatchCapabilities?,
    busy: Boolean,
    unforwardableIds: Set<String> = emptySet(),
): List<MessageBatchAction> {
    if (busy || selectedIds.isEmpty() || capabilities == null) return emptyList()
    return MessageBatchAction.entries.filter {
        capabilities.allows(it) &&
            messageBatchActionIds(it, selectedIds, unforwardableIds).size >= (flareMessageBatchMinimumSelection[it] ?: 1)
    }
}

/** The toolbar's "N 条不支持转发" for [count] selected messages the forward keys leave out, in the kit locale's plural. */
internal fun messageBatchUnforwardableText(count: Int, strings: FlareStrings, locale: java.util.Locale): String =
    flarePlural(count.toLong(), strings.messageBatchUnforwardableOne, strings.messageBatchUnforwardable, locale)

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
    unforwardableIds: Set<String> = emptySet(),
): List<FlareIconControlSpec> {
    val available = messageBatchActionsAvailable(selectedIds, capabilities, busy, unforwardableIds)
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
 * [unforwardableIds] are selected ids the core answers canForward false for (a plugin card that is not forwardable):
 * the forward keys leave them out, report only the forwardable ids, and the count says how many were left out.
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
    unforwardableIds: Set<String> = emptySet(),
    onAction: ((MessageBatchAction, List<String>) -> Unit)? = null,
    onSelectAll: (() -> Unit)? = null,
    onClearSelection: (() -> Unit)? = null,
    onExit: (() -> Unit)? = null,
) {
    val count = selectedIds.size
    val colors = flareColors()
    val strings = flareStrings()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    // The toolbar being on screen is the selection being on: the system back (and a hardware
    // keyboard's Escape, which Android maps to it) leaves the selection before it leaves the chat.
    // While busy the press is consumed and nothing exits — the same rule as the disabled exit key.
    FlareNativeBackEffect(enabled = onExit != null) { if (!busy) onExit?.invoke() }
    Row(
        Modifier.fillMaxWidth()
            .shadow(8.dp, shape, clip = false)
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, shape)
            // The exit button's 48 dp touch target is 16 dp taller than the 32 dp pills; the vertical
            // padding gives those 8 dp a side back, so the bar keeps its height and the pills their place.
            .padding(horizontal = FlareSizes.spacing2md, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        val unforwardable = messageBatchUnforwardableCount(selectedIds, unforwardableIds)
        val locale = flareLocale()
        Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("$count", color = colors.primaryText, fontWeight = FontWeight.Bold, fontSize = FlareSizes.fontSizeLg.value.sp)
                Text(" / $total · ${strings.selectedSuffix}", color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
            // The forward keys leave these out: say how many.
            if (unforwardable > 0) {
                Text(messageBatchUnforwardableText(unforwardable, strings, locale), color = colors.textTertiary,
                    fontSize = FlareSizes.fontSizeXs.value.sp)
            }
        }
        Spacer(Modifier.width(FlareSizes.spacingMd))
        FlowRow(
            Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm, Alignment.End),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs, Alignment.CenterVertically),
        ) {
            messageBatchToolbarControls(strings, selectedIds, total, capabilities, busy, unforwardableIds).forEach { control ->
                when (control.id) {
                    "selectAll" -> MessageBatchButton(colors, control, onSelectAll)
                    "clearSelection" -> MessageBatchButton(colors, control, onClearSelection)
                    "exit" -> MessageBatchExitButton(colors, control, onExit)
                    else -> {
                        val action = MessageBatchAction.valueOf(control.id)
                        MessageBatchButton(
                            colors, control, { onAction?.invoke(action, messageBatchActionIds(action, selectedIds, unforwardableIds)) },
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
            .flareDimmed(if (control.enabled) 1f else 0.45f)
            .padding(horizontal = FlareSizes.spacing2sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs),
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
        modifier = Modifier.flareDimmed(if (control.enabled) 1f else 0.45f),
    ) {
        Box(
            Modifier.size(width = FlareSizes.touchTarget, height = FlareSizes.controlHeightSm)
                .clip(RoundedCornerShape(FlareSizes.radiusMd))
                .background(colors.bgSecondary),
        )
        Icon(flareIconVector(control.icon), contentDescription = null, tint = colors.textPrimary, modifier = Modifier.size(FlareSizes.iconSizeSm))
    }
}
