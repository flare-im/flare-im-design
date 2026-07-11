package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.rounded.PushPin
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * A single inbox row — avatar, title, preview/draft, unread badge, time, and
 * mute/pin markers. Spec: Conversation/ConversationRow (`ConversationRow`).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ConversationRow(
    item: ConversationRowData,
    active: Boolean = false,
    avatarSize: Dp = 48.dp,
    onSelect: (() -> Unit)? = null,
    onLongPress: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (onSelect != null || onLongPress != null)
                    Modifier.combinedClickable(
                        onClick = { onSelect?.invoke() },
                        onLongClick = onLongPress?.let { lp -> { lp() } },
                    )
                else Modifier,
            )
            .background(if (active) colors.bgSelected else Color.Transparent)
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingMd),
    ) {
        Box(contentAlignment = Alignment.BottomEnd) {
            Avatar(userId = item.id, displayName = item.title, size = avatarSize, presence = item.presence)
            if (item.pinned) {
                Box(
                    Modifier.size(15.dp).clip(CircleShape).background(colors.bgPrimary)
                        .border(1.dp, colors.borderSecondary, CircleShape),
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.Rounded.PushPin, null, Modifier.size(9.dp), tint = colors.pinned) }
            }
        }
        Spacer(Modifier.width(FlareSizes.spacingMd))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        item.title, maxLines = 1, overflow = TextOverflow.Ellipsis,
                        color = colors.textPrimary,
                        fontSize = FlareSizes.fontSize3xl.value.sp,
                        fontWeight = if (item.hasUnread) FontWeight.Bold else FontWeight.SemiBold,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (item.tags.isNotEmpty()) {
                        Spacer(Modifier.width(4.dp))
                        TagStrip(item.tags, colors)
                    }
                }
                Spacer(Modifier.width(FlareSizes.spacingSm))
                TimeStamp(item.timestampLabel)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (item.muted) {
                    Icon(Icons.Outlined.NotificationsOff, null, Modifier.size(14.dp).padding(end = 2.dp), tint = colors.textTertiary)
                }
                Text(
                    previewText(item, colors), maxLines = 1, overflow = TextOverflow.Ellipsis,
                    fontSize = FlareSizes.fontSizeLg.value.sp, color = colors.textSecondary,
                    modifier = Modifier.weight(1f),
                )
                if (item.hasUnread) {
                    Spacer(Modifier.width(FlareSizes.spacingSm))
                    Box(
                        Modifier.defaultMinSize(minWidth = 22.dp, minHeight = 22.dp)
                            .clip(RoundedCornerShape(999.dp)).background(colors.primary)
                            .padding(horizontal = 7.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(if (item.unreadCount > 99) "99+" else "${item.unreadCount}",
                            color = Color.White, fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}

private fun previewText(item: ConversationRowData, colors: FlareColors): AnnotatedString = buildAnnotatedString {
    when {
        item.hasDraft -> {
            withStyle(SpanStyle(color = colors.error, fontWeight = FontWeight.Medium)) { append("[Draft] ") }
            append(item.draftPreview ?: "")
        }
        item.mentioned -> {
            withStyle(SpanStyle(color = colors.error, fontWeight = FontWeight.SemiBold)) { append("[@me] ") }
            append(item.preview)
        }
        else -> append(item.preview)
    }
}

@Composable
private fun TagStrip(tags: List<ConversationRowTag>, colors: FlareColors) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        tags.forEach { tag ->
            val tint = when (tag.tone) {
                FlareTagTone.Info -> colors.info
                FlareTagTone.Warning -> colors.warning
                FlareTagTone.Neutral -> colors.textTertiary
            }
            Text(
                tag.text,
                color = tint,
                fontSize = FlareSizes.fontSizeXs.value.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(tint.copy(alpha = 0.12f))
                    .padding(horizontal = 5.dp, vertical = 1.dp),
            )
        }
    }
}
