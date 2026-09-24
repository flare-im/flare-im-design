package com.flare.im.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Canonical row; the host owns selection, actions and authoritative state. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ConversationRow(
    item: ConversationRowData,
    draftLabel: String? = null,
    mentionLabel: String? = null,
    active: Boolean = false,
    avatarSize: Dp = FlareSizes.avatarSize,
    onSelect: (() -> Unit)? = null,
    onLongPress: (() -> Unit)? = null,
    compact: Boolean = false,
) {
    val colors = flareColors()
    val strings = flareStrings()
    var focused by remember { mutableStateOf(false) }
    val prefix = when (item.previewKind) {
        "failed" -> "[${strings.messageFailed}] "
        "draft" -> draftLabel ?: strings.conversationRowDraft
        "mention" -> mentionLabel ?: strings.conversationRowMention
        else -> ""
    }
    val preview = when (item.previewKind) {
        "draft" -> item.draftPreview.orEmpty().trim()
        "typing" -> strings.typing
        else -> item.preview
    }
    val label = listOf(item.title, if (item.hasUnread) strings.unreadTab(item.unreadCount) else "",
        if (item.mentioned) (mentionLabel ?: strings.conversationRowMention) else "", if (item.pinned) strings.conversationActionSheetPin else "",
        if (item.muted) strings.conversationActionSheetMute else "", prefix + preview, item.timestampLabel).filter { it.isNotEmpty() }.joinToString(", ")
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(if (active) colors.bgSelected else Color.Transparent)
            .border(2.dp, if (focused) colors.borderSelected else Color.Transparent, RoundedCornerShape(FlareSizes.radiusMd))
            .onFocusChanged { focused = it.isFocused }
            .semantics(mergeDescendants = true) { contentDescription = label; selected = active }
            .then(if (onSelect != null || onLongPress != null) Modifier.combinedClickable(role = Role.Button, onClick = { onSelect?.invoke() }, onLongClick = onLongPress) else Modifier)
            .defaultMinSize(minHeight = if (compact) 72.dp else 80.dp)
            .padding(horizontal = FlareSizes.spacingSm, vertical = if (compact) FlareSizes.spacing2sm else FlareSizes.spacing2md),
    ) {
        Box(Modifier.clearAndSetSemantics {}) {
            Avatar(userId = item.id, displayName = item.title, avatarUrl = item.avatarUrl, size = if (compact) 40.dp else avatarSize, presence = item.presence)
        }
        Spacer(Modifier.width(FlareSizes.spacing2sm))
        Column(Modifier.weight(1f).clearAndSetSemantics {}) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(item.title, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg,
                    fontWeight = if (item.titleEmphasis == "strong") FontWeight.Bold else FontWeight.Medium,
                    modifier = Modifier.weight(1f, fill = false))
                if (item.pinned) { Spacer(Modifier.width(4.dp)); Icon(Icons.Outlined.PushPin, null, Modifier.size(12.dp), tint = colors.textTertiary) }
                if (item.muted) { Spacer(Modifier.width(4.dp)); Icon(Icons.Outlined.NotificationsOff, null, Modifier.size(12.dp), tint = colors.textTertiary) }
            }
            Spacer(Modifier.height(4.dp))
            Text(buildAnnotatedString {
                withStyle(SpanStyle(color = if (item.previewKind == "draft") colors.primaryText else colors.errorText)) { append(prefix) }
                append(preview)
            }, maxLines = 1, overflow = TextOverflow.Ellipsis, fontSize = FlareSizes.fontSizeMd, color = colors.textSecondary)
        }
        Spacer(Modifier.width(8.dp))
        Column(Modifier.width(FlareSizes.componentConversationRowMetaWidth).clearAndSetSemantics {}, horizontalAlignment = Alignment.End) {
            Text(item.timestampLabel, maxLines = 1, overflow = TextOverflow.Ellipsis, color = if (active) colors.textSecondary else colors.textTertiary, fontSize = FlareSizes.fontSizeXs)
            Spacer(Modifier.height(4.dp))
            Box(Modifier.heightIn(min = 20.dp), contentAlignment = Alignment.CenterEnd) {
                if (item.hasUnread) {
                    val quiet = item.muted && !item.mentioned
                    Text(item.unreadLabel, fontSize = FlareSizes.fontSizeXs, fontWeight = FontWeight.SemiBold,
                        color = if (quiet) colors.textSecondary else colors.messageOutgoingForeground,
                        modifier = Modifier.clip(RoundedCornerShape(FlareSizes.radiusFull)).background(if (quiet) colors.bgTertiary else colors.primary).padding(horizontal = 5.dp, vertical = 2.dp))
                }
            }
        }
    }
}
