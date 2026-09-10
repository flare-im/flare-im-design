package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.DoneAll
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** Delivery state of an outgoing message. Spec union `'pending'|'sent'|'read'|'failed'`. */
enum class FlareMessageDeliveryStatus { Pending, Sent, Read, Failed }

/** Visual density of [MessageStatus]. Spec union `'tick'|'compact'`. */
enum class FlareMessageStatusVariant { Tick, Compact }

/**
 * Small delivery-status indicator for outgoing message bubbles.
 * Spec: General/MessageStatus (`MessageStatus`).
 *
 * [onResend] makes the failed glyph tappable (label = strings.retry); with no
 * callback the failed state stays a passive indicator.
 */
@Composable
fun MessageStatus(
    status: FlareMessageDeliveryStatus,
    variant: FlareMessageStatusVariant = FlareMessageStatusVariant.Tick,
    tint: Color? = null,
    onResend: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val dim = if (variant == FlareMessageStatusVariant.Compact) 12.dp else 14.dp
    val retry = flareStrings().retry
    val resendModifier = if (messageStatusResendable(status, onResend != null)) {
        Modifier.semantics { contentDescription = retry }.clickable(onClickLabel = retry) { onResend?.invoke() }
    } else Modifier

    when (status) {
        FlareMessageDeliveryStatus.Pending ->
            CircularProgressIndicator(
                modifier = Modifier.size(dim),
                strokeWidth = 1.5.dp,
                color = tint ?: colors.textTertiary,
            )
        FlareMessageDeliveryStatus.Sent ->
            Icon(Icons.Rounded.Check, contentDescription = null, modifier = Modifier.size(dim), tint = tint ?: colors.textTertiary)
        FlareMessageDeliveryStatus.Read ->
            Icon(Icons.Rounded.DoneAll, contentDescription = null, modifier = Modifier.size(dim), tint = tint ?: colors.primary)
        FlareMessageDeliveryStatus.Failed ->
            Icon(Icons.Rounded.ErrorOutline, contentDescription = null, modifier = resendModifier.size(dim), tint = colors.error)
    }
}

/** Only a failed message with a host-supplied `onResend` is tappable. */
internal fun messageStatusResendable(status: FlareMessageDeliveryStatus, hasOnResend: Boolean): Boolean =
    status == FlareMessageDeliveryStatus.Failed && hasOnResend
