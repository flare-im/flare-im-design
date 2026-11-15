package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

/**
 * The payment confirmation a host shows for the engine's confirmPayment request (design 7.3; spec
 * Message/PaymentConfirmation). The amount, payee, what it is for and the order number come only from the [order], so
 * a plugin cannot change the panel; the countdown runs on the server clock ([FlareServerClock]) and an expired order
 * cannot be confirmed.
 *
 * Verifying the viewer (payment password, BiometricPrompt) stays the host's existing reauthenticate flow: [onConfirm]
 * only says the viewer confirmed; the host verifies and answers the engine with its proof. A host that asks for the
 * password inside the panel passes the field as [credential]. Composing it shows it in a kit [BottomSheet]; [busy]
 * locks every key and the sheet.
 */
@Composable
fun FlarePaymentConfirmation(
    order: FlarePaymentOrder,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
    pluginName: String? = null,
    busy: Boolean = false,
    error: String? = null,
    confirmDisabled: Boolean = false,
    credential: (@Composable () -> Unit)? = null,
    onExpire: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    BottomSheet(onClose = { if (!busy) onCancel() }, title = strings.paymentConfirmationTitle, titleHidden = true, dismissible = !busy) {
        FlarePaymentConfirmationBody(order, onConfirm, onCancel, pluginName, busy, error, confirmDisabled, credential, onExpire)
    }
}

@Composable
internal fun FlarePaymentConfirmationBody(
    order: FlarePaymentOrder,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
    pluginName: String? = null,
    busy: Boolean = false,
    error: String? = null,
    confirmDisabled: Boolean = false,
    credential: (@Composable () -> Unit)? = null,
    onExpire: (() -> Unit)? = null,
    nowMs: (() -> Long) = FlareServerClock::nowMs,
) {
    val colors = flareColors()
    val strings = flareStrings()
    var now by remember { mutableLongStateOf(nowMs()) }
    var expiredSaid by remember(order) { mutableStateOf(false) }
    LaunchedEffect(order) {
        while (true) {
            now = nowMs()
            val (_, expired) = FlarePaymentRules.countdown(order.expiresAtMs - now)
            if (expired && !expiredSaid) { expiredSaid = true; onExpire?.invoke() }
            if (expired) break
            delay(1000)
        }
    }
    val amount = FlarePaymentRules.amountText(order.amount, order.currency)
    val (left, expired) = FlarePaymentRules.countdown(order.expiresAtMs - now)
    val enabled = FlarePaymentRules.confirmEnabled(order, now, busy, confirmDisabled)
    @Composable
    fun row(label: String, value: String) {
        Row(Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget).semantics(mergeDescendants = true) {},
            verticalAlignment = Alignment.CenterVertically) {
            Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Text(value, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.End, modifier = Modifier.weight(1f))
        }
    }
    Column(
        Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Text(strings.paymentConfirmationTitle, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl,
            fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() })
        Text(amount ?: "—", color = colors.textPrimary, fontSize = FlareSizes.componentRedPacketAmountFontSize.value.sp,
            fontWeight = FontWeight.SemiBold, maxLines = 1, modifier = Modifier.testTag("flare-payment-amount"))
        Column(Modifier.fillMaxWidth()) {
            HorizontalDivider(thickness = 1.dp, color = colors.borderSecondary)
            row(strings.paymentConfirmationPayee, order.payee)
            if (order.title.isNotEmpty()) row(strings.paymentConfirmationItem, order.title)
            row(strings.paymentConfirmationOrder, order.orderId)
            HorizontalDivider(thickness = 1.dp, color = colors.borderSecondary)
        }
        val live = Modifier.semantics { liveRegion = LiveRegionMode.Polite }
        when {
            amount == null -> Text(strings.paymentConfirmationInvalid, color = colors.errorText, fontSize = FlareSizes.fontSizeMd, modifier = live)
            expired -> Text(strings.paymentConfirmationExpired, color = colors.errorText, fontSize = FlareSizes.fontSizeMd,
                modifier = live.testTag("flare-payment-expired"))
            else -> Text(strings.paymentConfirmationExpiresIn.replace("{time}", left), color = colors.textSecondary,
                fontSize = FlareSizes.fontSizeSm, modifier = Modifier.testTag("flare-payment-countdown"))
        }
        if (pluginName != null) Text(strings.paymentConfirmationRequestedBy.replace("{plugin}", pluginName),
            color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
        credential?.invoke()
        if (error != null) Text(error, color = colors.errorText, fontSize = FlareSizes.fontSizeMd, modifier = live)
        Column(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            Button(label = if (busy) strings.paymentConfirmationVerifying else strings.paymentConfirmationConfirm, size = FlareControlSize.Lg,
                loading = busy, disabled = !enabled && !busy, block = true, onClick = { if (enabled) onConfirm() })
            Button(label = strings.cancel, variant = FlareButtonVariant.Quiet, size = FlareControlSize.Lg, disabled = busy, block = true,
                onClick = { if (!busy) onCancel() })
        }
    }
}
