package com.flare.im.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.EmojiEmotions
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.rounded.ArrowUpward
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** A lightweight reply target shown as a strip above the composer input. */
data class FlareReplyTarget(val senderName: String, val summary: String)

/**
 * The message input — plain or rich text, attach, emoji, send, optional reply
 * strip. Spec: Composer/Composer (`Composer`). Send is optimistic: [onSend]
 * fires immediately; the host does the local echo + core write.
 */
@Composable
fun Composer(
    rich: Boolean = false,
    placeholder: String = "Message",
    disabled: Boolean = false,
    replyTo: FlareReplyTarget? = null,
    maxLength: Int? = null,
    onSend: ((String) -> Unit)? = null,
    onAttach: (() -> Unit)? = null,
    onEmoji: (() -> Unit)? = null,
    onCancelReply: (() -> Unit)? = null,
    actions: List<FlareComposerAction>? = null,
    onAction: ((FlareComposerAction) -> Unit)? = null,
    enableVoice: Boolean = false,
    onVoiceStart: (() -> Unit)? = null,
    onVoiceEnd: (() -> Unit)? = null,
    onVoiceCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var text by remember { mutableStateOf("") }
    var voiceMode by remember { mutableStateOf(false) }
    var panelOpen by remember { mutableStateOf(false) }
    val canSend = text.isNotBlank() && !disabled
    fun send() {
        val t = text.trim()
        if (t.isEmpty()) return
        onSend?.invoke(t); text = ""
    }

    Column(Modifier.fillMaxWidth().background(colors.bgPrimary)) {
        HorizontalDivider(color = colors.borderPrimary)
        replyTo?.let { ReplyStrip(it, colors, onCancelReply) }
        Row(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingSm),
            verticalAlignment = Alignment.Bottom,
        ) {
            if (enableVoice) {
                IconButton(onClick = { voiceMode = !voiceMode }, enabled = !disabled) {
                    Icon(
                        if (voiceMode) Icons.Outlined.Keyboard else Icons.Outlined.Mic, null,
                        tint = if (voiceMode) colors.primary else colors.textSecondary,
                    )
                }
            }
            IconButton(
                onClick = { if (actions != null) panelOpen = !panelOpen else onAttach?.invoke() },
                enabled = !disabled,
            ) {
                Icon(Icons.Outlined.AddCircleOutline, null,
                    tint = if (panelOpen) colors.primary else colors.textSecondary)
            }
            Box(Modifier.weight(1f)) {
                if (voiceMode) {
                    FlareVoiceHoldButton(
                        onStart = onVoiceStart, onEnd = onVoiceEnd, onCancel = onVoiceCancel)
                } else {
                    Box(
                        Modifier.clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgSecondary)
                            .padding(horizontal = FlareSizes.spacingMd, vertical = 2.dp),
                    ) {
                        if (rich) {
                            RichMarkdownInput(value = text, onValueChange = { text = it }, disabled = disabled,
                                maxLength = maxLength, placeholder = placeholder)
                        } else {
                            TextField(
                                value = text, onValueChange = { text = it }, enabled = !disabled,
                                placeholder = { Text(placeholder, color = colors.textTertiary) },
                                maxLines = 5,
                                colors = TextFieldDefaults.colors(
                                    focusedContainerColor = Color.Transparent,
                                    unfocusedContainerColor = Color.Transparent,
                                    disabledContainerColor = Color.Transparent,
                                    focusedIndicatorColor = Color.Transparent,
                                    unfocusedIndicatorColor = Color.Transparent,
                                ),
                                modifier = Modifier.fillMaxWidth(),
                            )
                        }
                    }
                }
            }
            if (!voiceMode) {
                IconButton(onClick = { onEmoji?.invoke() }, enabled = !disabled) {
                    Icon(Icons.Outlined.EmojiEmotions, null, tint = colors.textSecondary)
                }
                Box(
                    Modifier.padding(start = 2.dp).size(34.dp).clip(CircleShape)
                        .background(if (canSend) colors.primary else colors.bgDisabled)
                        .clickable(enabled = canSend) { send() },
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Rounded.ArrowUpward, null, Modifier.size(20.dp),
                        tint = if (canSend) Color.White else colors.textDisabled)
                }
            }
        }
        AnimatedVisibility(visible = panelOpen && actions != null) {
            FlareComposerActionPanel(
                actions = actions ?: defaultComposerActions,
                onAction = { onAction?.invoke(it); panelOpen = false },
            )
        }
    }
}

@Composable
private fun ReplyStrip(reply: FlareReplyTarget, colors: FlareColors, onCancel: (() -> Unit)?) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs)
            .clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(3.dp).size(width = 3.dp, height = 28.dp).background(colors.primary))
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Column(Modifier.weight(1f)) {
            Text("Reply ${reply.senderName}", color = colors.primary, fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold)
            Text(reply.summary, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        IconButton(onClick = { onCancel?.invoke() }) { Icon(Icons.Rounded.Close, null, Modifier.size(18.dp), tint = colors.textTertiary) }
    }
}
