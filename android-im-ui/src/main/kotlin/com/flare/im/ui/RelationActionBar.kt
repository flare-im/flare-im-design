package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Block
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.PersonAddAlt
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// MARK: contract (pure, testable without a Compose runtime)

/** Relation between the viewer and the contact, as decided by the host. */
enum class FlareRelationState { None, PendingOut, PendingIn, Friends, Blocked }

/** Commands the bar may ask the host to run. */
enum class FlareRelationAction { Add, Accept, Reject, Remove, Block, Unblock, Message }

/** Capabilities the host can honour. `false` → the action is not rendered. */
data class FlareRelationCapabilities(
    val add: Boolean = false,
    val accept: Boolean = false,
    val reject: Boolean = false,
    val remove: Boolean = false,
    val block: Boolean = false,
    val unblock: Boolean = false,
    val message: Boolean = false,
) {
    fun allows(action: FlareRelationAction): Boolean = when (action) {
        FlareRelationAction.Add -> add
        FlareRelationAction.Accept -> accept
        FlareRelationAction.Reject -> reject
        FlareRelationAction.Remove -> remove
        FlareRelationAction.Block -> block
        FlareRelationAction.Unblock -> unblock
        FlareRelationAction.Message -> message
    }
}

/** One displayable entry; [destructive] entries render in the trailing group. */
data class FlareRelationActionEntry(
    val action: FlareRelationAction,
    val primary: Boolean = false,
    val destructive: Boolean = false,
)

/**
 * The full, ordered rule table. Capabilities filter it; they never reorder it, so a
 * button keeps its slot whichever switches the host flips.
 */
private fun relationRules(relation: FlareRelationState): List<FlareRelationActionEntry> = when (relation) {
    FlareRelationState.None -> listOf(
        FlareRelationActionEntry(FlareRelationAction.Add, primary = true),
        FlareRelationActionEntry(FlareRelationAction.Block),
    )
    // PendingOut deliberately omits Add: the request is already out, so the bar shows a
    // disabled "waiting" notice instead of a button that would re-send it.
    FlareRelationState.PendingOut -> listOf(FlareRelationActionEntry(FlareRelationAction.Block))
    FlareRelationState.PendingIn -> listOf(
        FlareRelationActionEntry(FlareRelationAction.Accept, primary = true),
        FlareRelationActionEntry(FlareRelationAction.Reject),
        FlareRelationActionEntry(FlareRelationAction.Block),
    )
    FlareRelationState.Friends -> listOf(
        FlareRelationActionEntry(FlareRelationAction.Message, primary = true),
        FlareRelationActionEntry(FlareRelationAction.Remove, destructive = true),
        FlareRelationActionEntry(FlareRelationAction.Block, destructive = true),
    )
    // While blocked nothing else is offered — no message, no friend request.
    FlareRelationState.Blocked -> listOf(FlareRelationActionEntry(FlareRelationAction.Unblock, primary = true))
}

/**
 * Ordered, displayable actions for [relation] under [capabilities].
 * The host owns the relation; the component owns nothing but this table.
 */
fun relationActions(
    relation: FlareRelationState?,
    capabilities: FlareRelationCapabilities?,
): List<FlareRelationActionEntry> {
    val caps = capabilities ?: FlareRelationCapabilities()
    return relationRules(relation ?: FlareRelationState.None).filter { caps.allows(it.action) }
}

/**
 * True while an outgoing request is waiting: the bar shows a disabled primary notice in
 * place of the add button, regardless of capabilities, because it reports state rather
 * than offering a command.
 */
fun relationShowsPending(relation: FlareRelationState?): Boolean = relation == FlareRelationState.PendingOut

private fun iconFor(action: FlareRelationAction): ImageVector = when (action) {
    FlareRelationAction.Add -> Icons.Outlined.PersonAddAlt
    FlareRelationAction.Accept -> Icons.Outlined.Check
    FlareRelationAction.Reject -> Icons.Outlined.Close
    FlareRelationAction.Remove -> Icons.Outlined.DeleteOutline
    FlareRelationAction.Block -> Icons.Outlined.Block
    FlareRelationAction.Unblock -> Icons.Outlined.CheckCircle
    FlareRelationAction.Message -> Icons.Outlined.ChatBubbleOutline
}

/**
 * Relation action bar for the bottom of a contact detail page. The host owns the relation
 * state and every command; the bar only decides which buttons exist and emits intent. It
 * never mutates the relation, never retries, and keeps the previous failure reason on
 * screen until it is dismissed. Spec: Contacts/RelationActionBar (`RelationActionBar`).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun RelationActionBar(
    relation: FlareRelationState,
    capabilities: FlareRelationCapabilities = FlareRelationCapabilities(),
    /** Host sets this synchronously before dispatching; disables every button. */
    busy: Boolean = false,
    /** Reason the previous command failed; kept until dismissed, never auto-cleared. */
    error: String? = null,
    onAction: ((FlareRelationAction) -> Unit)? = null,
    onDismissError: (() -> Unit)? = null,
    addText: String = "添加好友",
    acceptText: String = "接受",
    rejectText: String = "拒绝",
    removeText: String = "删除好友",
    blockText: String = "加入黑名单",
    unblockText: String = "移出黑名单",
    messageText: String = "发消息",
    pendingText: String = "等待对方验证",
    busyText: String = "处理中",
    dismissErrorText: String = "关闭错误提示",
    emptyText: String = "暂无可用操作",
) {
    val colors = flareColors()
    var pending by remember { mutableStateOf<FlareRelationAction?>(null) }
    LaunchedEffect(busy) { if (!busy) pending = null }

    val entries = relationActions(relation, capabilities)
    val safe = entries.filter { !it.destructive }
    val danger = entries.filter { it.destructive }
    val pendingNotice = relationShowsPending(relation)
    val isEmpty = entries.isEmpty() && !pendingNotice
    val reason = (error ?: "").trim()

    fun labelFor(action: FlareRelationAction) = when (action) {
        FlareRelationAction.Add -> addText
        FlareRelationAction.Accept -> acceptText
        FlareRelationAction.Reject -> rejectText
        FlareRelationAction.Remove -> removeText
        FlareRelationAction.Block -> blockText
        FlareRelationAction.Unblock -> unblockText
        FlareRelationAction.Message -> messageText
    }

    Column(Modifier.fillMaxWidth().background(colors.bgPrimary)) {
        HorizontalDivider(color = colors.borderSecondary)
        if (reason.isNotEmpty()) {
            Row(
                Modifier.fillMaxWidth()
                    .background(colors.error.copy(alpha = 0.10f))
                    .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = colors.error, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(FlareSizes.spacingSm))
                Text(
                    reason,
                    color = colors.error,
                    fontSize = FlareSizes.fontSizeMd.value.sp,
                    modifier = Modifier.weight(1f).semantics { liveRegion = LiveRegionMode.Polite },
                )
                if (onDismissError != null) {
                    val enabled = !busy
                    Row(
                        Modifier.size(FlareSizes.touchTarget)
                            .clip(RoundedCornerShape(FlareSizes.radiusMd))
                            .then(if (enabled) Modifier.clickable(onClick = onDismissError) else Modifier)
                            .alpha(if (enabled) 1f else 0.45f)
                            .semantics(mergeDescendants = true) { contentDescription = dismissErrorText },
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center,
                    ) {
                        Icon(Icons.Outlined.Close, contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(16.dp))
                    }
                }
            }
            HorizontalDivider(color = colors.borderSecondary)
        }

        FlowRow(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            if (pendingNotice) {
                Row(
                    Modifier.defaultMinSize(minHeight = FlareSizes.touchTarget)
                        .clip(RoundedCornerShape(FlareSizes.radiusMd))
                        .background(colors.bgDisabled)
                        .padding(horizontal = FlareSizes.spacingMd)
                        .semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Outlined.Schedule, contentDescription = null, tint = colors.textDisabled, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(
                        pendingText,
                        color = colors.textDisabled,
                        fontSize = FlareSizes.fontSizeMd.value.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
            if (isEmpty) {
                Row(
                    Modifier.defaultMinSize(minHeight = FlareSizes.touchTarget),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(emptyText, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp)
                }
            }
            for (entry in safe) {
                RelationButton(
                    colors = colors,
                    entry = entry,
                    label = labelFor(entry.action),
                    enabled = !busy && onAction != null,
                    inProgress = busy && pending == entry.action,
                    busyText = busyText,
                ) {
                    pending = entry.action
                    onAction?.invoke(entry.action)
                }
            }
            if (danger.isNotEmpty()) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(Modifier.size(width = 1.dp, height = 24.dp).background(colors.borderSecondary)) {}
                    for (entry in danger) {
                        RelationButton(
                            colors = colors,
                            entry = entry,
                            label = labelFor(entry.action),
                            enabled = !busy && onAction != null,
                            inProgress = busy && pending == entry.action,
                            busyText = busyText,
                        ) {
                            pending = entry.action
                            onAction?.invoke(entry.action)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun RelationButton(
    colors: FlareColors,
    entry: FlareRelationActionEntry,
    label: String,
    enabled: Boolean,
    inProgress: Boolean,
    busyText: String,
    onTap: () -> Unit,
) {
    val fg = when {
        entry.primary -> Color.White
        entry.destructive -> colors.error
        else -> colors.textPrimary
    }
    val bg = when {
        entry.primary -> colors.primary
        entry.destructive -> colors.error.copy(alpha = 0.10f)
        else -> colors.bgSecondary
    }
    val description = if (inProgress) "$label · $busyText" else label
    Row(
        Modifier.defaultMinSize(minHeight = FlareSizes.touchTarget, minWidth = FlareSizes.touchTarget)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(bg)
            .then(if (enabled) Modifier.clickable(onClick = onTap) else Modifier)
            .alpha(if (enabled) 1f else if (inProgress) 0.85f else 0.45f)
            .padding(horizontal = FlareSizes.spacingMd)
            .semantics(mergeDescendants = true) { contentDescription = description },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        if (inProgress) {
            CircularProgressIndicator(Modifier.size(14.dp), color = fg, strokeWidth = 2.dp)
        } else {
            Icon(iconFor(entry.action), contentDescription = null, tint = fg, modifier = Modifier.size(16.dp))
        }
        Text(label, color = fg, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 1)
    }
}
