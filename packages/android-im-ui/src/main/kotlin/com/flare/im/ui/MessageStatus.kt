package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material.icons.rounded.Schedule
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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

/**
 * The receipt status the core SDK projects for a message (`MessageReceiptView.status`): five visual states. There is no
 * delivered state — a single check means the server has the message, a double check that it was read
 * (spec/message-receipt-vectors.json).
 */
enum class FlareMessageDeliveryStatus { Pending, Sending, Sent, Read, Failed }

enum class FlareMessageStatusVariant { Tick, Compact }

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

/**
 * The receipt glyph of a message: a clock while pending, a spinner while sending (still under reduced motion), one
 * check once the server has it, a double check in the read colour once it is read (never the same shape as sent), and
 * the alert when it failed. Spec: Message/MessageStatus (`MessageStatus`).
 *
 * A failed glyph with [onResend] is the retry: a button (role Button, click label "retry") named "{failed}, {retry}"
 * whose hit area is the full touch target around the glyph, while the glyph keeps its own place in the row
 * ([flareTouchTargetBeyond]).
 */
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
    val effectiveStatus = lifecycle?.visualStatus ?: status
    val dim = if (variant == FlareMessageStatusVariant.Compact) 12.dp else 16.dp
    val label = flareMessageStatusLabel(effectiveStatus, strings)
    if (messageStatusResendable(effectiveStatus, onResend != null)) {
        val retry = strings.retry
        // The glyph keeps its place in the row; the button around it is the full touch target.
        Box(
            Modifier.flareTouchTargetBeyond(dim)
                .sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
                .clip(CircleShape)
                .clickable(role = Role.Button, onClickLabel = retry) { onResend?.invoke() }
                .semantics { contentDescription = "$label, $retry" },
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Rounded.ErrorOutline, contentDescription = null, modifier = Modifier.size(dim), tint = colors.messageStatusFailed)
        }
        return
    }
    val named = Modifier.semantics { contentDescription = label }
    when (flareMessageReceiptGlyph(effectiveStatus)) {
        FlareMessageReceiptGlyph.Clock ->
            Icon(Icons.Rounded.Schedule, contentDescription = null, modifier = named.size(dim), tint = tint ?: colors.messageStatusPending)
        FlareMessageReceiptGlyph.Spinner ->
            if (flareReducedMotion()) {
                // Reduced motion: the same ring, standing still.
                CircularProgressIndicator(progress = { 0.7f }, modifier = named.size(dim), strokeWidth = 1.5.dp,
                    color = tint ?: colors.messageStatusPending, trackColor = Color.Transparent)
            } else {
                CircularProgressIndicator(modifier = named.size(dim), strokeWidth = 1.5.dp, color = tint ?: colors.messageStatusPending)
            }
        FlareMessageReceiptGlyph.Check -> MessageCheckCanvas(false, tint ?: colors.messageStatusSent, dim, named)
        FlareMessageReceiptGlyph.DoubleCheck -> MessageCheckCanvas(true, tint ?: colors.messageStatusRead, dim, named)
        FlareMessageReceiptGlyph.Alert ->
            Icon(Icons.Rounded.ErrorOutline, contentDescription = null, modifier = named.size(dim), tint = colors.messageStatusFailed)
    }
}

internal fun messageStatusResendable(status: FlareMessageDeliveryStatus, hasOnResend: Boolean): Boolean =
    status == FlareMessageDeliveryStatus.Failed && hasOnResend
