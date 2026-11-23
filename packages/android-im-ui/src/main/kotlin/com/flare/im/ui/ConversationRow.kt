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
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
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
import androidx.compose.ui.unit.sp

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
    val mention = (mentionLabel ?: strings.conversationRowMention).trim().removeSurrounding("[", "]")
    val prefix = when (item.previewKind) {
        "failed" -> "[${strings.messageFailed}] "
        "draft" -> draftLabel ?: strings.conversationRowDraft
        else -> ""
    }
    val preview = when (item.previewKind) {
        "draft" -> item.draftPreview.orEmpty().trim()
        "typing" -> strings.typing
        else -> item.preview
    }
    val label = listOf(item.title, if (item.hasUnread) strings.unreadTab(item.unreadCount) else "",
        if (item.mentioned) mention else "", if (item.pinned) strings.conversationActionSheetPin else "",
        if (item.muted) strings.conversationActionSheetMute else "", prefix + preview, item.timestampLabel).filter { it.isNotEmpty() }.joinToString(", ")
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(if (active) colors.bgSelected else Color.Transparent)
            .border(2.dp, if (focused) colors.borderSelected else Color.Transparent, RoundedCornerShape(FlareSizes.radiusMd))
            .onFocusChanged { focused = it.isFocused }
            .semantics(mergeDescendants = true) { contentDescription = label; selected = active }
            .then(if (onSelect != null || onLongPress != null) Modifier.combinedClickable(role = Role.Button, onClick = { onSelect?.invoke() }, onLongClick = onLongPress) else Modifier)
            // Phone rows are the web's mobile rows: 68 tall, full-bleed padding, a hairline under the text column.
            .then(if (compact) Modifier else Modifier.drawBehind {
                val y = size.height - 0.5.dp.toPx()
                drawLine(colors.borderSecondary.copy(alpha = 0.55f), Offset(72.dp.toPx(), y), Offset(size.width - FlareSizes.spacingLg.toPx(), y), 1.dp.toPx())
            })
            .defaultMinSize(minHeight = if (compact) 72.dp else FlareSizes.conversationRowMobileHeight)
            .padding(horizontal = if (compact) FlareSizes.spacingSm else FlareSizes.spacingLg, vertical = if (compact) FlareSizes.spacing2sm else FlareSizes.spacingMd),
    ) {
        Box(Modifier.clearAndSetSemantics {}) {
            Avatar(userId = item.id, displayName = item.title, avatarUrl = item.avatarUrl, size = if (compact) 40.dp else avatarSize, group = item.kind == FlareConversationKind.Group)
        }
        Spacer(Modifier.width(if (compact) FlareSizes.spacing2sm else FlareSizes.spacingMd))
        Column(Modifier.weight(1f).clearAndSetSemantics {}) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(item.title, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    color = colors.textPrimary, fontSize = if (compact) FlareSizes.fontSizeLg else FlareSizes.fontSize2xl, lineHeight = 20.sp,
                    fontWeight = if (item.titleEmphasis == "strong") FontWeight.Bold else FontWeight.Medium,
                    modifier = Modifier.weight(1f, fill = false))
                if (item.pinned) { Spacer(Modifier.width(FlareSizes.spacingXs)); Icon(Icons.Outlined.PushPin, null, Modifier.size(12.dp), tint = colors.textTertiary) }
                if (item.muted) { Spacer(Modifier.width(FlareSizes.spacingXs)); Icon(Icons.Outlined.NotificationsOff, null, Modifier.size(12.dp), tint = colors.textTertiary) }
            }
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Text(buildAnnotatedString {
                withStyle(SpanStyle(color = if (item.previewKind == "draft") colors.primaryText else colors.errorText)) { append(prefix) }
                append(preview)
            }, maxLines = 1, overflow = TextOverflow.Ellipsis, fontSize = FlareSizes.fontSizeMd, lineHeight = 20.sp, color = colors.textSecondary)
        }
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Column(Modifier.widthIn(min = FlareSizes.componentConversationRowMetaWidth).clearAndSetSemantics {}, horizontalAlignment = Alignment.End) {
            Text(item.timestampLabel, maxLines = 1, overflow = TextOverflow.Ellipsis,
                color = if (active) colors.textSecondary else colors.textTertiary, fontSize = FlareSizes.fontSizeXs,
                lineHeight = 20.sp, modifier = Modifier.widthIn(max = FlareSizes.componentConversationRowMetaWidth))
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Row(Modifier.heightIn(min = 20.dp), verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                if (item.mentioned) {
                    Text(mention, Modifier.clip(RoundedCornerShape(FlareSizes.radiusFull))
                        .background(colors.bgSelected).padding(horizontal = FlareSizes.spacingXs),
                        color = colors.primaryText, fontSize = FlareSizes.fontSizeXs, fontWeight = FontWeight.SemiBold)
                }
                if (item.hasUnread) {
                    val quiet = item.muted
                    // An 18 × 18 circle that widens for more digits, as on the web.
                    Box(Modifier.defaultMinSize(minWidth = 18.dp).height(18.dp).clip(RoundedCornerShape(FlareSizes.radiusFull))
                        .background(if (quiet) colors.bgTertiary else colors.primary).padding(horizontal = 5.dp), contentAlignment = Alignment.Center) {
                        Text(item.unreadLabel, fontSize = FlareSizes.fontSizeXs, fontWeight = FontWeight.SemiBold,
                            color = if (quiet) colors.textSecondary else colors.messageOutgoingForeground)
                    }
                }
            }
        }
    }
}
