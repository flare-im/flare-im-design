package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

enum class FlareMessageMetaDensity { Compact, Normal }

/** The colours the meta of one placement draws with (spec/message-meta-placement-vectors.json `rules.tone`). */
internal data class MessageMetaPalette(val text: Color, val read: Color, val failed: Color, val glyph: Color?)

internal fun messageMetaPalette(colors: FlareColors, tone: FlareMessageMetaTone): MessageMetaPalette = when (tone) {
    FlareMessageMetaTone.OnOutgoing -> MessageMetaPalette(
        text = colors.messageStatusOnOutgoing, read = colors.messageStatusReadOnOutgoing,
        failed = colors.messageStatusFailed, glyph = colors.messageStatusOnOutgoing,
    )
    FlareMessageMetaTone.Default -> MessageMetaPalette(
        text = colors.messageMetaForeground, read = colors.messageStatusRead, failed = colors.messageStatusFailed, glyph = null,
    )
}

/**
 * Stable metadata row: the time, the edited and ephemeral labels, and for the viewer's own messages the receipt.
 * Spec: Message/MessageMeta (`MessageMeta`).
 *
 * - [placement] (spec/message-meta-placement-vectors.json): inside a bubble ([FlareMessageMetaPlacement.Inline],
 *   [FlareMessageMetaPlacement.BubbleFooter]) an outgoing message ([outgoing]) uses the outgoing foreground; below a
 *   surface ([FlareMessageMetaPlacement.Below]) the meta always takes the default palette, and a failed message shows the
 *   text key "Failed to send. Retry" before the time in place of the glyph.
 * - [status] (only for the viewer's own messages) draws the receipt glyph ([MessageStatus]); with [onResend] the failed
 *   glyph, or the text key, is the retry, its hit area at least the touch target.
 * - [readSummary] (the SDK's group read summary) replaces the check with "N unread" / "Read by all" while the message is
 *   sent or read; with [onReadReceiptOpen] the summary is a text button that opens the read list.
 */
@Composable
fun MessageMeta(
    timestamp: String = "",
    edited: Boolean = false,
    status: FlareMessageDeliveryStatus? = null,
    lifecycle: FlareMessageLifecycle? = null,
    ephemeral: FlareMessageEphemeralState = FlareMessageEphemeralState.None,
    density: FlareMessageMetaDensity = FlareMessageMetaDensity.Compact,
    placement: FlareMessageMetaPlacement = FlareMessageMetaPlacement.BubbleFooter,
    /** The meta belongs to the viewer's own message: inside a bubble it takes the outgoing foreground. */
    outgoing: Boolean = status != null,
    readSummary: FlareMessageReadSummary? = null,
    onResend: (() -> Unit)? = null,
    onReadReceiptOpen: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) = MessageMetaContent(
    timestamp, edited, status, lifecycle, ephemeral, density, placement, outgoing, readSummary, onResend, onReadReceiptOpen,
    modifier, inRow = false,
)

/**
 * [MessageMeta] as a message row draws it. [inRow]: the row already reads the status in its own name, so the glyph's
 * name is left out of the row (it would be read twice); the time stays as the row's text, and the retry and the
 * read-summary key stay keys of their own.
 */
@Composable
internal fun MessageMetaContent(
    timestamp: String,
    edited: Boolean,
    status: FlareMessageDeliveryStatus?,
    lifecycle: FlareMessageLifecycle?,
    ephemeral: FlareMessageEphemeralState,
    density: FlareMessageMetaDensity,
    placement: FlareMessageMetaPlacement,
    outgoing: Boolean,
    readSummary: FlareMessageReadSummary?,
    onResend: (() -> Unit)?,
    onReadReceiptOpen: (() -> Unit)?,
    modifier: Modifier,
    inRow: Boolean,
) {
    if (placement == FlareMessageMetaPlacement.None) return
    val strings = flareStrings()
    val colors = flareColors()
    val effective = if (status != null || lifecycle != null) lifecycle?.visualStatus ?: status ?: FlareMessageDeliveryStatus.Sent else null
    val tone = flareMessageMetaTone(placement, outgoing, effective ?: FlareMessageDeliveryStatus.Sent)
    val palette = messageMetaPalette(colors, tone)
    val resolvedEphemeral = lifecycle?.ephemeral ?: ephemeral
    val ephemeralLabel = when (resolvedEphemeral) {
        FlareMessageEphemeralState.None -> ""
        FlareMessageEphemeralState.ReadOnce -> strings.messageReadOnce
        FlareMessageEphemeralState.BurnAfterRead -> strings.messageBurnAfterRead
        FlareMessageEphemeralState.Expired -> strings.messageExpired
    }
    val labels = buildList {
        if (timestamp.isNotEmpty()) add(timestamp)
        if (edited || lifecycle?.mutation == FlareMessageMutationState.Edited) add(strings.messageEdited)
        if (ephemeralLabel.isNotEmpty()) add(ephemeralLabel)
    }
    val receipt = effective?.let { flareMessageReceiptPresentation(FlareConversationKind.Group, self = true, status = it, readSummary = readSummary) }
    val retry = effective?.let { flareMessageRetryControl(placement, outgoing, it) }
    val decorative = if (inRow) Modifier.clearAndSetSemantics {} else Modifier
    Row(
        modifier = modifier.heightIn(min = FlareSizes.iconSizeSm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(
            if (density == FlareMessageMetaDensity.Compact) FlareSizes.spacingXs else FlareSizes.spacing2xs,
        ),
    ) {
        // Below a surface the failure leads, as words, and takes the glyph's place.
        val failedText = retry == FlareMessageRetryControl.Text && onResend != null
        if (failedText) {
            Box(
                Modifier.flareTouchTargetAround()
                    .clickable(role = Role.Button, onClickLabel = strings.retry) { onResend?.invoke() }
                    .semantics { contentDescription = strings.messageSendFailedRetry },
                contentAlignment = Alignment.Center,
            ) {
                Text(strings.messageSendFailedRetry, color = palette.failed, fontSize = FlareSizes.fontSizeXs.value.sp,
                    fontWeight = FontWeight.Medium, maxLines = 1)
            }
        }
        if (labels.isNotEmpty()) {
            Text(
                labels.joinToString(" · "),
                color = palette.text,
                fontSize = FlareSizes.fontSizeXs.value.sp,
                maxLines = 1,
            )
        }
        val summary = receipt?.summary
        when {
            failedText -> Unit
            summary != null -> {
                val text = summary.text(strings)
                val color = if (summary.allRead) palette.read else palette.text
                val open = onReadReceiptOpen
                if (open != null) {
                    Box(
                        Modifier.flareTouchTargetAround()
                            .clickable(role = Role.Button) { open() }
                            .semantics { contentDescription = text },
                        contentAlignment = Alignment.Center,
                    ) { Text(text, color = color, fontSize = FlareSizes.fontSizeXs.value.sp, maxLines = 1) }
                } else {
                    Text(text, color = color, fontSize = FlareSizes.fontSizeXs.value.sp, maxLines = 1)
                }
            }
            effective != null -> {
                val resend = onResend?.takeIf { messageStatusResendable(effective, true) }
                Box(if (resend == null) decorative else Modifier) {
                    MessageStatus(
                        status = effective,
                        variant = FlareMessageStatusVariant.Compact,
                        tint = if (effective == FlareMessageDeliveryStatus.Read) palette.read else palette.glyph,
                        onResend = resend,
                    )
                }
            }
        }
    }
}
