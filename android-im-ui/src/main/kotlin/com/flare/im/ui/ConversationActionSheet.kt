package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.Unarchive
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Actions a [ConversationActionSheet] can emit; names match the cross-platform contract. */
enum class FlareConversationAction { Pin, Unpin, Mute, Unmute, MarkRead, Archive, Unarchive, Hide, Delete }

/** Snapshot of the conversation the sheet acts on; [id] must be stable. */
data class FlareConversationActionSnapshot(
    val id: String,
    val title: String,
    val pinned: Boolean = false,
    val muted: Boolean = false,
    val unreadCount: Int = 0,
    val archived: Boolean = false,
)

/** Capabilities the host can honour. `false` → the action is not rendered. */
data class FlareConversationActionCapabilities(
    val pin: Boolean = false,
    val mute: Boolean = false,
    val markRead: Boolean = false,
    val archive: Boolean = false,
    val delete: Boolean = false,
    val hide: Boolean = false,
)

/** One displayable entry; [danger] entries render in the trailing group. */
data class FlareConversationActionEntry(val action: FlareConversationAction, val danger: Boolean = false)

/**
 * Ordered, displayable actions — same rule set as the other platforms: pin/unpin,
 * mute/unmute, archive/unarchive invert by state; markRead only with unread > 0;
 * delete always last and flagged danger.
 */
fun conversationActions(
    conversation: FlareConversationActionSnapshot,
    capabilities: FlareConversationActionCapabilities,
): List<FlareConversationActionEntry> = buildList {
    if (capabilities.pin) add(FlareConversationActionEntry(if (conversation.pinned) FlareConversationAction.Unpin else FlareConversationAction.Pin))
    if (capabilities.mute) add(FlareConversationActionEntry(if (conversation.muted) FlareConversationAction.Unmute else FlareConversationAction.Mute))
    if (capabilities.markRead && conversation.unreadCount > 0) add(FlareConversationActionEntry(FlareConversationAction.MarkRead))
    if (capabilities.archive) add(FlareConversationActionEntry(if (conversation.archived) FlareConversationAction.Unarchive else FlareConversationAction.Archive))
    if (capabilities.hide) add(FlareConversationActionEntry(FlareConversationAction.Hide))
    if (capabilities.delete) add(FlareConversationActionEntry(FlareConversationAction.Delete, danger = true))
}

private fun iconFor(action: FlareConversationAction): ImageVector = when (action) {
    FlareConversationAction.Pin, FlareConversationAction.Unpin -> Icons.Outlined.PushPin
    FlareConversationAction.Mute -> Icons.Outlined.NotificationsOff
    FlareConversationAction.Unmute -> Icons.Outlined.Notifications
    FlareConversationAction.MarkRead -> Icons.Outlined.DoneAll
    FlareConversationAction.Archive -> Icons.Outlined.Archive
    FlareConversationAction.Unarchive -> Icons.Outlined.Unarchive
    FlareConversationAction.Hide -> Icons.Outlined.VisibilityOff
    FlareConversationAction.Delete -> Icons.Outlined.Delete
}

/**
 * Conversation action menu — the body of a long-press / "more" sheet for ONE
 * conversation. Owns no positioning: place it in `ModalBottomSheet` or a popup.
 * Spec: Conversation/ConversationActionSheet (`ConversationActionSheet`).
 */
@Composable
fun ConversationActionSheet(
    conversation: FlareConversationActionSnapshot,
    capabilities: FlareConversationActionCapabilities = FlareConversationActionCapabilities(),
    /** Host sets this synchronously before dispatching; disables every row. */
    busy: Boolean = false,
    pinText: String = "置顶",
    unpinText: String = "取消置顶",
    muteText: String = "免打扰",
    unmuteText: String = "取消免打扰",
    markReadText: String = "标为已读",
    archiveText: String = "归档",
    unarchiveText: String = "取消归档",
    hideText: String = "隐藏",
    deleteText: String = "删除",
    emptyText: String = "暂无可用操作",
    onAction: ((String, FlareConversationAction) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val entries = conversationActions(conversation, capabilities)
    val primary = entries.filter { !it.danger }
    val danger = entries.filter { it.danger }
    fun labelFor(action: FlareConversationAction) = when (action) {
        FlareConversationAction.Pin -> pinText
        FlareConversationAction.Unpin -> unpinText
        FlareConversationAction.Mute -> muteText
        FlareConversationAction.Unmute -> unmuteText
        FlareConversationAction.MarkRead -> markReadText
        FlareConversationAction.Archive -> archiveText
        FlareConversationAction.Unarchive -> unarchiveText
        FlareConversationAction.Hide -> hideText
        FlareConversationAction.Delete -> deleteText
    }

    Column(
        Modifier.fillMaxWidth()
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs)
            .semantics { contentDescription = conversation.title }
            .onPreviewKeyEvent { ev ->
                if (ev.key == Key.Escape && onClose != null) { onClose(); true } else false
            },
    ) {
        Text(
            conversation.title,
            color = colors.textTertiary,
            fontSize = FlareSizes.fontSizeSm.value.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
        )
        if (entries.isEmpty()) {
            Text(
                emptyText,
                color = colors.textSecondary,
                fontSize = FlareSizes.fontSizeLg.value.sp,
                modifier = Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
            )
        }
        if (primary.isNotEmpty()) {
            ActionGroup(colors) {
                primary.forEach { ActionRow(it, labelFor(it.action), busy, colors, onAction?.let { cb -> { cb(conversation.id, it.action) } }) }
            }
        }
        if (danger.isNotEmpty()) {
            Spacer(Modifier.size(FlareSizes.spacingSm))
            ActionGroup(colors) {
                HorizontalDivider(color = colors.borderSecondary)
                danger.forEach { ActionRow(it, labelFor(it.action), busy, colors, onAction?.let { cb -> { cb(conversation.id, it.action) } }) }
            }
        }
    }
}

@Composable
private fun ActionGroup(colors: FlareColors, content: @Composable () -> Unit) {
    Column(
        Modifier.fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radius2xl))
            .background(colors.bgPrimary)
            .padding(vertical = FlareSizes.spacingXs),
    ) { content() }
}

@Composable
private fun ActionRow(
    entry: FlareConversationActionEntry,
    label: String,
    busy: Boolean,
    colors: FlareColors,
    onClick: (() -> Unit)?,
) {
    val enabled = !busy && onClick != null
    var focused by remember { mutableStateOf(false) }
    val accent = if (entry.danger) colors.error else colors.primary
    val fg = if (!enabled) colors.textDisabled else if (entry.danger) colors.error else colors.textPrimary
    val iconFg = if (enabled) accent else colors.textDisabled
    val iconBg = if (enabled) accent.copy(alpha = if (entry.danger) 0.12f else 0.10f) else colors.bgDisabled
    Row(
        Modifier.fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(if (focused) colors.bgHover else colors.bgPrimary)
            .onFocusChanged { focused = it.isFocused }
            .clickable(enabled = enabled, role = Role.Button, onClickLabel = label) { onClick?.invoke() }
            .heightIn(min = FlareSizes.touchTarget)
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(44.dp).clip(CircleShape).background(iconBg), contentAlignment = Alignment.Center) {
            Icon(iconFor(entry.action), null, Modifier.size(20.dp), tint = iconFg)
        }
        Spacer(Modifier.width(FlareSizes.spacingMd))
        Text(
            label,
            color = fg,
            fontSize = FlareSizes.fontSize2xl.value.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.weight(1f),
        )
    }
}
