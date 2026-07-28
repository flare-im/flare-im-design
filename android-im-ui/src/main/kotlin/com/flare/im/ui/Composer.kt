package com.flare.im.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.text.BasicTextField
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** A lightweight reply target shown as a strip above the composer input. */
data class FlareReplyTarget(val senderName: String, val summary: String)

/** A quiet circular icon control used across the composer row (attach / voice / emoji). */
@Composable
private fun composerGlyph(
    icon: ImageVector,
    tint: Color,
    enabled: Boolean,
    size: Dp = 40.dp,
    onClick: () -> Unit,
) {
    Box(
        Modifier.size(size).clip(CircleShape).clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, null, Modifier.size(24.dp), tint = tint)
    }
}

/**
 * The message input — plain or rich text, attach, emoji, send, optional reply
 * strip. Spec: Composer/Composer (`Composer`). Send is optimistic: [onSend]
 * fires immediately; the host does the local echo + core write.
 */
@Composable
fun Composer(
    modifier: Modifier = Modifier,
    rich: Boolean = false,
    placeholder: String = "消息",
    disabled: Boolean = false,
    replyTo: FlareReplyTarget? = null,
    /** Prefix on the reply strip above the input, e.g. "Reply Ivy". */
    replyLabel: String = "回复",
    maxLength: Int? = null,
    /** Optional brand accent for the active send button (e.g. a gradient). Defaults to `primary`. */
    sendAccent: androidx.compose.ui.graphics.Brush? = null,
    onSend: ((String) -> Unit)? = null,
    onAttach: (() -> Unit)? = null,
    onEmoji: (() -> Unit)? = null,
    onCancelReply: (() -> Unit)? = null,
    actions: List<FlareComposerAction>? = null,
    onAction: ((FlareComposerAction) -> Unit)? = null,
    enableVoice: Boolean = false,
    /** Hold-to-talk labels — forwarded to [FlareVoiceHoldButton] so hosts can localize them. */
    voiceLabel: String = "按住 说话",
    voiceRecordingLabel: String = "松开发送 · 上滑取消",
    voiceCancelLabel: String = "松开取消",
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

    Column(modifier.fillMaxWidth().background(colors.bgPrimary)) {
        HorizontalDivider(color = colors.borderPrimary)
        replyTo?.let { ReplyStrip(it, replyLabel, colors, onCancelReply) }
        // Row grammar: [voice] [attach] [ ── pill: text + emoji inside ── ] [send]
        // Emoji lives *inside* the pill (iMessage/Telegram idiom) so the input gets the full width
        // and the row reads calm instead of four competing controls.
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingSm),
            verticalAlignment = Alignment.Bottom,
        ) {
            if (enableVoice) {
                composerGlyph(
                    icon = if (voiceMode) Icons.Outlined.Keyboard else Icons.Outlined.Mic,
                    tint = if (voiceMode) colors.primary else colors.textSecondary,
                    enabled = !disabled,
                ) { voiceMode = !voiceMode }
            }
            composerGlyph(
                icon = Icons.Outlined.AddCircleOutline,
                tint = if (panelOpen) colors.primary else colors.textSecondary,
                enabled = !disabled,
            ) { if (actions != null) panelOpen = !panelOpen else onAttach?.invoke() }

            Box(Modifier.weight(1f).padding(horizontal = 6.dp)) {
                if (voiceMode) {
                    FlareVoiceHoldButton(
                        label = voiceLabel,
                        recordingLabel = voiceRecordingLabel,
                        cancelLabel = voiceCancelLabel,
                        onStart = onVoiceStart, onEnd = onVoiceEnd, onCancel = onVoiceCancel)
                } else {
                    val pill = RoundedCornerShape(FlareSizes.radiusXl)
                    Row(
                        Modifier.clip(pill)
                            .background(colors.bgSecondary)
                            .border(1.dp, colors.borderPrimary, pill)
                            .padding(start = 14.dp, end = 6.dp, top = 6.dp, bottom = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(Modifier.weight(1f)) {
                            if (rich) {
                                RichMarkdownInput(value = text, onValueChange = { text = it }, disabled = disabled,
                                    maxLength = maxLength, placeholder = placeholder)
                            } else {
                                // BasicTextField, not Material TextField: the latter forces a 56dp min
                                // height and its own paddings, which bloats the composer pill.
                                BasicTextField(
                                    value = text,
                                    onValueChange = { text = it },
                                    enabled = !disabled,
                                    maxLines = 5,
                                    textStyle = TextStyle(
                                        color = colors.textPrimary,
                                        fontSize = FlareSizes.fontSizeXl.value.sp,
                                    ),
                                    cursorBrush = SolidColor(colors.primary),
                                    modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                                    decorationBox = { inner ->
                                        Box(contentAlignment = Alignment.CenterStart) {
                                            if (text.isEmpty()) {
                                                Text(placeholder, color = colors.textTertiary,
                                                    fontSize = FlareSizes.fontSizeXl.value.sp)
                                            }
                                            inner()
                                        }
                                    },
                                )
                            }
                        }
                        composerGlyph(
                            icon = Icons.Outlined.EmojiEmotions,
                            tint = colors.textSecondary,
                            enabled = !disabled,
                            size = 30.dp,
                        ) { onEmoji?.invoke() }
                    }
                }
            }

            if (!voiceMode) {
                Box(
                    Modifier.size(38.dp).clip(CircleShape).then(
                        if (canSend && sendAccent != null) Modifier.background(sendAccent)
                        else Modifier.background(if (canSend) colors.primary else colors.bgDisabled)
                    ).clickable(enabled = canSend) { send() },
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
private fun ReplyStrip(reply: FlareReplyTarget, label: String, colors: FlareColors, onCancel: (() -> Unit)?) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs)
            .clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(3.dp).size(width = 3.dp, height = 28.dp).background(colors.primary))
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Column(Modifier.weight(1f)) {
            Text("$label ${reply.senderName}", color = colors.primary, fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold)
            Text(reply.summary, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        IconButton(onClick = { onCancel?.invoke() }) { Icon(Icons.Rounded.Close, null, Modifier.size(18.dp), tint = colors.textTertiary) }
    }
}
