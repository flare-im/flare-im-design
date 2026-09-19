package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material.icons.rounded.Schedule
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Final visual projection of the orthogonal message lifecycle. */
enum class FlareMessageDeliveryStatus { Pending, Sending, Sent, Delivered, Read, Failed, Retrying }

enum class FlareMessageStatusVariant { Tick, Compact }

/** One compact double-check silhouette shared by delivered and read receipts. */
@Composable
private fun MessageDoubleCheck(color: Color, size: Dp = 16.dp, modifier: Modifier = Modifier) {
    MessageCheckCanvas(doubleCheck = true, color = color, size = size, modifier = modifier)
}

@Composable
private fun MessageCheckCanvas(doubleCheck: Boolean, color: Color, size: Dp, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size)) {
        val scale = this.size.width / 16f
        val style = Stroke(width = 1.5f * scale, cap = StrokeCap.Round, join = StrokeJoin.Round)
        fun check(a: Offset, b: Offset, c: Offset) = Path().apply {
            moveTo(a.x * scale, a.y * scale)
            lineTo(b.x * scale, b.y * scale)
            lineTo(c.x * scale, c.y * scale)
        }
        if (doubleCheck) {
            drawPath(check(Offset(1.75f, 8.5f), Offset(4.5f, 11.25f), Offset(9.25f, 5.75f)), color, style = style)
            drawPath(check(Offset(6f, 8.5f), Offset(8.75f, 11.25f), Offset(14.25f, 4.75f)), color, style = style)
        } else {
            drawPath(check(Offset(3.5f, 8f), Offset(6.5f, 11f), Offset(12.5f, 4.75f)), color, style = style)
        }
    }
}

@Composable
fun MessageStatus(
    status: FlareMessageDeliveryStatus,
    lifecycle: FlareMessageLifecycle? = null,
    variant: FlareMessageStatusVariant = FlareMessageStatusVariant.Tick,
    tint: Color? = null,
    onResend: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val retry = strings.retry
    val effectiveStatus = lifecycle?.visualStatus ?: status
    val dim = if (variant == FlareMessageStatusVariant.Compact) 12.dp else 16.dp
    val label = when (effectiveStatus) {
        FlareMessageDeliveryStatus.Pending -> strings.messagePending
        FlareMessageDeliveryStatus.Sending -> strings.messageSending
        FlareMessageDeliveryStatus.Sent -> strings.messageSent
        FlareMessageDeliveryStatus.Delivered -> strings.messageDelivered
        FlareMessageDeliveryStatus.Read -> strings.messageRead
        FlareMessageDeliveryStatus.Failed -> strings.messageFailed
        FlareMessageDeliveryStatus.Retrying -> strings.messageRetrying
    }
    val semantics = if (messageStatusResendable(effectiveStatus, onResend != null)) {
        Modifier.semantics { contentDescription = "$label, $retry" }
            .clickable(role = Role.Button, onClickLabel = retry) { onResend?.invoke() }
    } else Modifier.semantics { contentDescription = label }

    when (effectiveStatus) {
        FlareMessageDeliveryStatus.Pending ->
            Icon(Icons.Rounded.Schedule, contentDescription = null, modifier = semantics.size(dim), tint = tint ?: colors.messageStatusPending)
        FlareMessageDeliveryStatus.Sending, FlareMessageDeliveryStatus.Retrying ->
            CircularProgressIndicator(modifier = semantics.size(dim), strokeWidth = 1.5.dp, color = tint ?: colors.messageStatusPending)
        FlareMessageDeliveryStatus.Sent ->
            MessageCheckCanvas(false, tint ?: colors.messageStatusSent, dim, semantics)
        FlareMessageDeliveryStatus.Delivered ->
            MessageDoubleCheck(tint ?: colors.messageStatusDelivered, dim, semantics)
        FlareMessageDeliveryStatus.Read ->
            MessageDoubleCheck(tint ?: colors.messageStatusRead, dim, semantics)
        FlareMessageDeliveryStatus.Failed ->
            Icon(Icons.Rounded.ErrorOutline, contentDescription = null, modifier = semantics.size(dim), tint = colors.messageStatusFailed)
    }
}

internal fun messageStatusResendable(status: FlareMessageDeliveryStatus, hasOnResend: Boolean): Boolean =
    status == FlareMessageDeliveryStatus.Failed && hasOnResend
