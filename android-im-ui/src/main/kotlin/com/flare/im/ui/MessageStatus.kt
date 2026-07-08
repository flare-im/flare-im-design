package com.flare.im.ui

import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.DoneAll
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/** Delivery state of an outgoing message. Spec union `'pending'|'sent'|'read'|'failed'`. */
enum class FlareMessageDeliveryStatus { Pending, Sent, Read, Failed }

/** Visual density of [MessageStatus]. Spec union `'tick'|'compact'`. */
enum class FlareMessageStatusVariant { Tick, Compact }

/**
 * Small delivery-status indicator for outgoing message bubbles.
 * Spec: General/MessageStatus (`MessageStatus`).
 */
@Composable
fun MessageStatus(
    status: FlareMessageDeliveryStatus,
    variant: FlareMessageStatusVariant = FlareMessageStatusVariant.Tick,
) {
    val colors = flareColors()
    val dim = if (variant == FlareMessageStatusVariant.Compact) 12.dp else 14.dp

    when (status) {
        FlareMessageDeliveryStatus.Pending ->
            CircularProgressIndicator(
                modifier = Modifier.size(dim),
                strokeWidth = 1.5.dp,
                color = colors.textTertiary,
            )
        FlareMessageDeliveryStatus.Sent ->
            Icon(Icons.Rounded.Check, contentDescription = null, modifier = Modifier.size(dim), tint = colors.textTertiary)
        FlareMessageDeliveryStatus.Read ->
            Icon(Icons.Rounded.DoneAll, contentDescription = null, modifier = Modifier.size(dim), tint = colors.primary)
        FlareMessageDeliveryStatus.Failed ->
            Icon(Icons.Rounded.ErrorOutline, contentDescription = null, modifier = Modifier.size(dim), tint = colors.error)
    }
}
