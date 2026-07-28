package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.CleaningServices
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.MarkEmailRead
import androidx.compose.material.icons.outlined.MarkEmailUnread
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.rounded.Sync
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Connection-status tone — spec union `'ok' | 'warn' | 'error'`. */
enum class FlareConnectionTone { Ok, Warn, Error }

/**
 * The conversation info/settings panel — counts, connection state, and
 * per-conversation actions. Spec: Conversation/ConversationDetails
 * (`ConversationDetails`).
 */
@Composable
fun ConversationDetails(
    conversation: FlareConversationSummary,
    /** Row labels — overridable so hosts can localize them. */
    labels: FlareConversationDetailsLabels = FlareConversationDetailsLabels(),
    connectionText: String? = null,
    connectionTone: FlareConnectionTone = FlareConnectionTone.Ok,
    messageCount: Int? = null,
    onMute: ((Boolean) -> Unit)? = null,
    onPin: ((Boolean) -> Unit)? = null,
    onArchive: (() -> Unit)? = null,
    onClearHistory: (() -> Unit)? = null,
    onDelete: (() -> Unit)? = null,
    onMarkRead: (() -> Unit)? = null,
    onMarkUnread: (() -> Unit)? = null,
    onSync: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var muted by remember { mutableStateOf(conversation.muted) }
    var pinned by remember { mutableStateOf(conversation.pinned) }

    Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(vertical = FlareSizes.spacingLg)) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
            Avatar(userId = conversation.id, displayName = conversation.title, size = 64.dp)
            Spacer(Modifier.size(FlareSizes.spacingSm))
            Text(conversation.title, color = colors.textPrimary, fontSize = FlareSizes.fontSize4xl.value.sp, fontWeight = FontWeight.SemiBold)
            if (conversation.kind == FlareConversationKind.Group && conversation.memberCount != null) {
                Text(flareStrings().memberCount(conversation.memberCount), color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
            if (!connectionText.isNullOrEmpty()) {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = FlareSizes.spacingSm)) {
                    Box(Modifier.size(8.dp).clip(CircleShape).background(toneColor(colors, connectionTone)))
                    Spacer(Modifier.width(FlareSizes.spacingSm))
                    Text(connectionText, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp)
                }
            }
        }
        Spacer(Modifier.size(FlareSizes.spacingLg))

        if (messageCount != null) infoRow(labels.messages, "$messageCount", colors)

        gap(colors)
        if (onMute != null) switchRow(labels.mute, Icons.Outlined.NotificationsOff, muted, colors) { muted = it; onMute(it) }
        if (onPin != null) switchRow(labels.pin, Icons.Outlined.PushPin, pinned, colors) { pinned = it; onPin(it) }

        gap(colors)
        onMarkRead?.let { actionRow(labels.markRead, Icons.Outlined.MarkEmailRead, colors, it) }
        onMarkUnread?.let { actionRow(labels.markUnread, Icons.Outlined.MarkEmailUnread, colors, it) }
        onSync?.let { actionRow(labels.sync, Icons.Rounded.Sync, colors, it) }

        gap(colors)
        onArchive?.let { actionRow(if (conversation.archived) labels.unarchive else labels.archive, Icons.Outlined.Archive, colors, it) }
        onClearHistory?.let { actionRow(labels.clearHistory, Icons.Outlined.CleaningServices, colors, it) }
        onDelete?.let { actionRow(labels.delete, Icons.Outlined.Delete, colors, it, danger = true) }
    }
}

private fun toneColor(colors: FlareColors, tone: FlareConnectionTone): Color = when (tone) {
    FlareConnectionTone.Ok -> colors.success
    FlareConnectionTone.Warn -> colors.warning
    FlareConnectionTone.Error -> colors.error
}

@Composable
private fun infoRow(label: String, value: String, colors: FlareColors) {
    Row(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
        horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg.value.sp)
        Text(value, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp)
    }
}

@Composable
private fun switchRow(label: String, icon: ImageVector, value: Boolean, colors: FlareColors, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = colors.textSecondary)
        Spacer(Modifier.width(FlareSizes.spacingMd))
        Text(label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.weight(1f))
        Switch(checked = value, onCheckedChange = onChange)
    }
}

@Composable
private fun actionRow(label: String, icon: ImageVector, colors: FlareColors, onClick: () -> Unit, danger: Boolean = false) {
    val c = if (danger) colors.error else colors.textPrimary
    Row(Modifier.fillMaxWidth().clickable { onClick() }.padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
        verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = if (danger) colors.error else colors.textSecondary)
        Spacer(Modifier.width(FlareSizes.spacingMd))
        Text(label, color = c, fontSize = FlareSizes.fontSizeLg.value.sp)
    }
}

@Composable
private fun gap(colors: FlareColors) {
    Divider(Modifier.padding(vertical = FlareSizes.spacingSm), color = colors.borderSecondary)
}

/** Localizable row labels for [ConversationDetails]. Defaults keep today's English copy. */
data class FlareConversationDetailsLabels(
    val messages: String = "消息",
    val mute: String = "免打扰",
    val pin: String = "置顶会话",
    val markRead: String = "标为已读",
    val markUnread: String = "标为未读",
    val sync: String = "同步会话",
    val archive: String = "归档会话",
    val unarchive: String = "取消归档",
    val clearHistory: String = "清空聊天记录",
    val delete: String = "删除会话",
)
