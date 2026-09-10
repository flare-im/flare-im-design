package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.RadioButtonUnchecked
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** What the multi-select layer of [MessageBubble] renders for one row. */
internal data class MessageSelectionUi(
    /** Leading check control is shown. */
    val showCheck: Boolean,
    /** Tapping the whole row toggles selection. */
    val toggles: Boolean,
    /** Row background uses `bgSelected`. */
    val highlighted: Boolean,
)

/**
 * Multi-select rules, same as Flutter `FlareMessageBubble`: the check control
 * appears in multi-select mode only; the row toggles only when the host also
 * supplied `onToggleSelect`; the highlight follows `selected` regardless of
 * mode (so a host can keep the tint while the toolbar animates away). System
 * notices are never selectable.
 */
internal fun messageSelectionUi(
    multiSelectMode: Boolean,
    selected: Boolean,
    hasToggle: Boolean,
    isSystem: Boolean = false,
): MessageSelectionUi {
    if (isSystem) return MessageSelectionUi(showCheck = false, toggles = false, highlighted = false)
    return MessageSelectionUi(
        showCheck = multiSelectMode,
        toggles = multiSelectMode && hasToggle,
        highlighted = selected,
    )
}

/**
 * One message in a thread — content, sender, grouping, delivery status. Spec:
 * Message/MessageBubble (`MessageBubble`). Status comes from the core view
 * (optimistic), never a network wait.
 *
 * Multi-select (names shared with Flutter/iOS): [multiSelectMode] shows a leading
 * check control and makes the whole row tap-to-toggle via [onToggleSelect]
 * (receives the message id); [selected] tints the row. Default appearance is
 * unchanged when [multiSelectMode] is false.
 */
@Composable
fun MessageBubble(
    message: FlareMessageData,
    currentUserId: String,
    conversationKind: FlareConversationKind = FlareConversationKind.Single,
    groupStart: Boolean = true,
    groupEnd: Boolean = true,
    mediaState: FlareMediaDownloadState? = null,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
    onResend: ((FlareMessageData) -> Unit)? = null,
    multiSelectMode: Boolean = false,
    selected: Boolean = false,
    onToggleSelect: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    val self = message.senderId == currentUserId

    if (message.isSystem) {
        val text = (message.content as FlareNotificationContent).text
        Box(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingSm), contentAlignment = Alignment.Center) {
            Box(
                Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgTertiary)
                    .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
            ) { Text(text, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp) }
        }
        return
    }

    val showAvatar = !self && conversationKind != FlareConversationKind.Single && groupStart
    val selection = messageSelectionUi(multiSelectMode, selected, onToggleSelect != null)
    val selectLabel = flareStrings().select
    Row(
        // Group-aware rhythm (matches Flutter/iOS/web): a clear breath before a
        // new sender's run, tight within a run.
        Modifier.fillMaxWidth()
            .then(if (selection.highlighted) Modifier.background(colors.bgSelected) else Modifier)
            .then(
                if (selection.toggles) Modifier.selectable(selected = selected, onClick = { onToggleSelect?.invoke(message.id) })
                else Modifier,
            )
            .padding(
                start = FlareSizes.spacingMd,
                end = FlareSizes.spacingMd,
                top = if (groupStart) FlareSizes.spacingSm else 2.dp,
                bottom = if (groupEnd) FlareSizes.spacingSm else 2.dp,
            ),
        horizontalArrangement = if (self) Arrangement.End else Arrangement.Start,
        verticalAlignment = Alignment.Top,
    ) {
        if (selection.showCheck) {
            Icon(
                if (selected) Icons.Rounded.CheckCircle else Icons.Rounded.RadioButtonUnchecked,
                contentDescription = selectLabel,
                tint = if (selected) colors.primary else colors.textTertiary,
                modifier = Modifier.size(22.dp).align(Alignment.CenterVertically),
            )
            Spacer(Modifier.width(FlareSizes.spacingSm))
            if (self) Spacer(Modifier.weight(1f))
        }
        if (!self) {
            if (showAvatar) Avatar(userId = message.senderId, displayName = message.senderName, size = 34.dp)
            else Spacer(Modifier.width(34.dp))
            Spacer(Modifier.width(FlareSizes.spacingSm))
        }
        Column(horizontalAlignment = if (self) Alignment.End else Alignment.Start) {
            if (showAvatar) Text(message.senderName, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            bubble(message, self, colors, mediaState, onResend, onMediaAction)
        }
    }
}

@Composable
private fun bubble(
    message: FlareMessageData,
    self: Boolean,
    colors: FlareColors,
    mediaState: FlareMediaDownloadState?,
    onResend: ((FlareMessageData) -> Unit)?,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)?,
) {
    val bare = isBareMedia(message.content)
    val body: @Composable () -> Unit = {
        MessageContentView(
            content = message.content, isSelf = self, senderName = message.senderName, mediaState = mediaState,
            onMediaAction = onMediaAction?.let { cb -> { c -> cb(message, c) } },
        )
    }
    if (bare) {
        Box(Modifier.widthIn(max = 320.dp)) { body() }
        return
    }

    // Flare thread grammar: radius 16 with a 4dp tail; received = white card +
    // hairline border + whisper of lift; self = brand purple. Inline time meta.
    val shape = RoundedCornerShape(
        topStart = 16.dp, topEnd = 16.dp,
        bottomStart = if (self) 16.dp else 4.dp,
        bottomEnd = if (self) 4.dp else 16.dp,
    )
    val inner: @Composable () -> Unit = {
        Column(horizontalAlignment = if (self) Alignment.End else Alignment.Start) {
            body()
            // Inline meta: time + (self) delivery status, kept inside the bubble.
            if (message.timeLabel.isNotEmpty() || self) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.padding(top = 3.dp),
                ) {
                    if (message.timeLabel.isNotEmpty()) {
                        Text(
                            message.timeLabel,
                            fontSize = FlareSizes.fontSizeXs.value.sp,
                            color = if (self) Color.White.copy(alpha = 0.8f) else colors.textTertiary,
                        )
                    }
                    if (self) {
                        MessageStatus(
                            message.status,
                            variant = FlareMessageStatusVariant.Compact,
                            tint = if (message.status == FlareMessageDeliveryStatus.Failed) null
                            else Color.White.copy(alpha = 0.85f),
                            onResend = onResend?.let { cb -> { cb(message) } },
                        )
                    }
                }
            }
        }
    }
    if (self) {
        Box(
            Modifier.widthIn(max = 320.dp)
                .clip(shape).background(colors.bubbleSelf)
                .padding(horizontal = 14.dp, vertical = 9.dp),
        ) { inner() }
    } else {
        Box(
            Modifier.widthIn(max = 320.dp)
                .shadow(2.dp, shape, clip = false)
                .clip(shape)
                .background(colors.bgPrimary)
                .border(1.dp, colors.borderSecondary, shape)
                .padding(horizontal = 14.dp, vertical = 9.dp),
        ) { inner() }
    }
}

internal fun isBareMedia(content: FlareMessageContent): Boolean =
    content is FlareImageContent || content is FlareVideoContent ||
        content is FlareStickerContent || content is FlareEmojiContent
