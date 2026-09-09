package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// MARK: contract (pure, testable without a Compose runtime)

/** Batch actions a host may expose over a multi-selection of conversations. */
enum class ConversationBatchAction { MarkRead, Mute, Archive, Delete }

/** Host-declared capabilities; a false entry hides the action entirely. */
data class ConversationBatchCapabilities(
    val markRead: Boolean = false,
    val mute: Boolean = false,
    val archive: Boolean = false,
    val delete: Boolean = false,
) {
    fun allows(action: ConversationBatchAction): Boolean = when (action) {
        ConversationBatchAction.MarkRead -> markRead
        ConversationBatchAction.Mute -> mute
        ConversationBatchAction.Archive -> archive
        ConversationBatchAction.Delete -> delete
    }
}

/** One failed item of the previous batch, with a user-facing reason mapped by the host. */
data class ConversationBatchFailure(val id: String, val title: String, val reason: String)

/** Outcome of the previous batch as written by the host. */
data class ConversationBatchResult(
    val succeeded: List<String> = emptyList(),
    val failed: List<ConversationBatchFailure> = emptyList(),
)

data class ConversationBatchSummary(val succeededCount: Int, val failedCount: Int, val retryIds: List<String>)

/** True when the host limit is positive and the selection exceeds it. */
fun batchSelectionExceeded(selectedCount: Int, maxSelection: Int?): Boolean =
    maxSelection != null && maxSelection > 0 && selectedCount > maxSelection

/**
 * Actions the toolbar may offer right now: empty while busy, with nothing selected, or over
 * `maxSelection`; otherwise capability-enabled actions in canonical order.
 */
fun batchActionsAvailable(
    selectedIds: List<String>,
    capabilities: ConversationBatchCapabilities?,
    busy: Boolean,
    maxSelection: Int? = null,
): List<ConversationBatchAction> {
    if (busy || selectedIds.isEmpty() || batchSelectionExceeded(selectedIds.size, maxSelection)) return emptyList()
    if (capabilities == null) return emptyList()
    return ConversationBatchAction.entries.filter(capabilities::allows)
}

/** Counts of the previous batch and the deduplicated IDs a retry should target. */
fun summarizeBatchResult(result: ConversationBatchResult?): ConversationBatchSummary {
    if (result == null) return ConversationBatchSummary(0, 0, emptyList())
    val retryIds = LinkedHashSet<String>()
    for (f in result.failed) if (f.id.isNotEmpty()) retryIds.add(f.id)
    return ConversationBatchSummary(result.succeeded.size, result.failed.size, retryIds.toList())
}

private object RetryPending

/**
 * Batch toolbar for the conversation list in multi-select mode. Same bar / count / actions /
 * cancel visual as [MessageBatchToolbar], plus a partial-failure strip with per-item reasons and a
 * retry-failed entry. Emits intents only; the host owns `busy`, `result` and the DangerConfirm
 * step for Delete. Spec: Conversation/ConversationBatchToolbar.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ConversationBatchToolbar(
    selectedIds: List<String>,
    capabilities: ConversationBatchCapabilities,
    busy: Boolean = false,
    result: ConversationBatchResult? = null,
    maxSelection: Int? = null,
    onAction: ((ConversationBatchAction, List<String>) -> Unit)? = null,
    onRetryFailed: ((List<String>) -> Unit)? = null,
    onClearSelection: (() -> Unit)? = null,
    onDismissResult: (() -> Unit)? = null,
    selectedText: String = "已选",
    emptyText: String = "请选择会话",
    markReadText: String = "标为已读",
    muteText: String = "免打扰",
    archiveText: String = "归档",
    deleteText: String = "删除",
    cancelText: String = "取消选择",
    busyText: String = "处理中",
    succeededSummaryText: String = "成功 {n} 项",
    failedSummaryText: String = "{n} 项失败",
    retryFailedText: String = "重试失败项",
    dismissText: String = "关闭结果",
    expandText: String = "查看详情",
    collapseText: String = "收起",
    maxSelectionText: String = "最多可选 {n} 项",
) {
    val colors = flareColors()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    var pending by remember { mutableStateOf<Any?>(null) }
    var expanded by remember { mutableStateOf(false) }
    LaunchedEffect(busy) { if (!busy) pending = null }
    LaunchedEffect(result) { expanded = false }

    val count = selectedIds.size
    val exceeded = batchSelectionExceeded(count, maxSelection)
    val available = batchActionsAvailable(selectedIds, capabilities, busy, maxSelection)
    val summary = summarizeBatchResult(result)
    val hasResult = summary.failedCount > 0 || summary.succeededCount > 0
    val hint = when {
        busy -> busyText
        count == 0 -> emptyText
        exceeded -> maxSelectionText.replace("{n}", "${maxSelection ?: 0}")
        else -> null
    }
    val visible = ConversationBatchAction.entries.filter(capabilities::allows)

    Column(
        Modifier.fillMaxWidth()
            .shadow(8.dp, shape, clip = false)
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, shape),
    ) {
        FlowRow(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd, Alignment.Start),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.defaultMinSize(minHeight = FlareSizes.touchTarget)) {
                    Text("$count", color = colors.primary, fontWeight = FontWeight.Bold, fontSize = FlareSizes.fontSize2xl.value.sp)
                    Text(" $selectedText", color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp)
                }
                if (hint != null) {
                    val tint = if (exceeded && !busy) colors.warning else colors.textTertiary
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        modifier = Modifier.defaultMinSize(minHeight = FlareSizes.touchTarget)
                            .semantics { liveRegion = LiveRegionMode.Polite },
                    ) {
                        if (busy) CircularProgressIndicator(Modifier.size(14.dp), color = tint, strokeWidth = 2.dp)
                        else if (exceeded) Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = tint, modifier = Modifier.size(14.dp))
                        Text(hint, color = tint, fontSize = FlareSizes.fontSizeSm.value.sp)
                    }
                }
            }
            if (onAction != null || onClearSelection != null) {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    if (onAction != null) {
                        for (action in visible) {
                            BatchButton(
                                colors,
                                icon = action.icon(),
                                label = action.label(markReadText, muteText, archiveText, deleteText),
                                enabled = action in available,
                                pending = busy && pending == action,
                                busyText = busyText,
                                tint = if (action == ConversationBatchAction.Delete) colors.error else null,
                            ) {
                                pending = action
                                onAction(action, selectedIds.toList())
                            }
                        }
                    }
                    if (onClearSelection != null) {
                        BatchIconButton(colors, Icons.Outlined.Close, cancelText, enabled = !busy, onTap = onClearSelection)
                    }
                }
            }
        }

        if (hasResult) {
            val failed = summary.failedCount > 0
            Column(
                Modifier.fillMaxWidth().background(colors.bgSecondary).padding(horizontal = 14.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                FlowRow(
                    Modifier.fillMaxWidth().semantics { liveRegion = LiveRegionMode.Polite },
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                        modifier = Modifier.defaultMinSize(minHeight = FlareSizes.touchTarget),
                    ) {
                        Icon(
                            if (failed) Icons.Outlined.ErrorOutline else Icons.Outlined.CheckCircle,
                            contentDescription = null,
                            tint = if (failed) colors.error else colors.success,
                            modifier = Modifier.size(16.dp),
                        )
                        Row {
                            if (failed) {
                                Text(
                                    failedSummaryText.replace("{n}", "${summary.failedCount}"),
                                    color = colors.error, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeMd.value.sp,
                                )
                            }
                            if (failed && summary.succeededCount > 0) Text(" · ", color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp)
                            if (summary.succeededCount > 0 || !failed) {
                                Text(
                                    succeededSummaryText.replace("{n}", "${summary.succeededCount}"),
                                    color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp,
                                )
                            }
                        }
                    }
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        if (failed) {
                            BatchButton(
                                colors,
                                icon = if (expanded) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore,
                                label = if (expanded) collapseText else expandText,
                                enabled = true, pending = false, busyText = busyText, ghost = true,
                            ) { expanded = !expanded }
                        }
                        if (summary.retryIds.isNotEmpty() && onRetryFailed != null) {
                            BatchButton(
                                colors,
                                icon = Icons.Outlined.Refresh,
                                label = "$retryFailedText (${summary.retryIds.size})",
                                enabled = !busy, pending = busy && pending === RetryPending, busyText = busyText, primary = true,
                            ) {
                                pending = RetryPending
                                onRetryFailed(summary.retryIds.toList())
                            }
                        }
                        if (onDismissResult != null) {
                            BatchIconButton(colors, Icons.Outlined.Close, dismissText, enabled = !busy) {
                                expanded = false
                                onDismissResult()
                            }
                        }
                    }
                }
                if (expanded && result != null && result.failed.isNotEmpty()) {
                    LazyColumn(Modifier.fillMaxWidth().heightIn(max = 200.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        itemsIndexed(result.failed, key = { i, f -> "${f.id}-$i" }) { _, item ->
                            FlowRow(
                                Modifier.fillMaxWidth()
                                    .clip(RoundedCornerShape(FlareSizes.radiusSm))
                                    .background(colors.bgPrimary)
                                    .padding(horizontal = 8.dp, vertical = 6.dp)
                                    .semantics(mergeDescendants = true) { contentDescription = "${item.title} ${item.reason}" },
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                Text(
                                    item.title, color = colors.textPrimary, fontWeight = FontWeight.Medium,
                                    fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                                )
                                Text(item.reason, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun ConversationBatchAction.icon(): ImageVector = when (this) {
    ConversationBatchAction.MarkRead -> Icons.Outlined.DoneAll
    ConversationBatchAction.Mute -> Icons.Outlined.NotificationsOff
    ConversationBatchAction.Archive -> Icons.Outlined.Archive
    ConversationBatchAction.Delete -> Icons.Outlined.DeleteOutline
}

private fun ConversationBatchAction.label(markRead: String, mute: String, archive: String, delete: String): String = when (this) {
    ConversationBatchAction.MarkRead -> markRead
    ConversationBatchAction.Mute -> mute
    ConversationBatchAction.Archive -> archive
    ConversationBatchAction.Delete -> delete
}

@Composable
private fun BatchButton(
    colors: FlareColors,
    icon: ImageVector,
    label: String,
    enabled: Boolean,
    pending: Boolean,
    busyText: String,
    tint: Color? = null,
    ghost: Boolean = false,
    primary: Boolean = false,
    onTap: () -> Unit,
) {
    val fg = when {
        primary -> Color.White
        enabled || pending -> tint ?: if (ghost) colors.textSecondary else colors.textPrimary
        else -> colors.textTertiary
    }
    val bg = when {
        primary -> colors.primary
        ghost -> Color.Transparent
        else -> colors.bgSecondary
    }
    val description = if (pending) "$label · $busyText" else label
    Row(
        Modifier.defaultMinSize(minHeight = FlareSizes.touchTarget, minWidth = FlareSizes.touchTarget)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(bg)
            .then(if (enabled) Modifier.clickable(onClick = onTap) else Modifier)
            .alpha(if (enabled) 1f else if (pending) 0.85f else 0.45f)
            .padding(horizontal = 10.dp)
            .semantics(mergeDescendants = true) { contentDescription = description },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        if (pending) CircularProgressIndicator(Modifier.size(14.dp), color = fg, strokeWidth = 2.dp)
        else Icon(icon, contentDescription = null, tint = fg, modifier = Modifier.size(16.dp))
        Text(label, color = fg, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 1)
    }
}

@Composable
private fun BatchIconButton(colors: FlareColors, icon: ImageVector, label: String, enabled: Boolean, onTap: () -> Unit) {
    Row(
        Modifier.size(FlareSizes.touchTarget)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(colors.bgSecondary)
            .then(if (enabled) Modifier.clickable(onClick = onTap) else Modifier)
            .alpha(if (enabled) 1f else 0.45f),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        Icon(icon, contentDescription = label, tint = colors.textSecondary, modifier = Modifier.size(16.dp))
    }
}
