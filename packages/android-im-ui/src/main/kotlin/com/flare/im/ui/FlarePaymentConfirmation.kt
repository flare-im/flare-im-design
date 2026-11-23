package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.stateDescription
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
 *
 * 4.3 of docs/plugin-experience.md: the title, "requested by", the amount (`component.amountHeroFontSize`, tabular),
 * the payee and what it is for, the order number folded behind "订单号 ›" (opened, it can be copied), the countdown
 * (under a minute in the warning colour), a danger banner with [error] above the keys. [shortfall] (insufficient
 * balance) holds confirm, says how much is missing and offers top up ([onTopUp]); an expired order greys the amount
 * and offers to start again ([onStartAgain]) instead of confirm.
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
    /** Insufficient balance: the formatted missing amount. */
    shortfall: String? = null,
    onTopUp: (() -> Unit)? = null,
    onStartAgain: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val body: @Composable () -> Unit = {
        FlarePaymentConfirmationBody(order, onConfirm, onCancel, pluginName, busy, error, confirmDisabled, credential, onExpire,
            shortfall = shortfall, onTopUp = onTopUp, onStartAgain = onStartAgain)
    }
    // 4.3: a phone's bottom sheet; a wide window's dialog of component.paymentDialogWidth.
    if (flareCompactOverlays()) BottomSheet(onClose = { if (!busy) onCancel() }, title = strings.paymentConfirmationTitle, titleHidden = true, dismissible = !busy) { body() }
    else Modal(onClose = { if (!busy) onCancel() }, title = strings.paymentConfirmationTitle, titleHidden = true,
        width = FlareSizes.componentPaymentDialogWidth, dismissible = !busy, showClose = false, busy = busy) { body() }
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
    shortfall: String? = null,
    onTopUp: (() -> Unit)? = null,
    onStartAgain: (() -> Unit)? = null,
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
    val enabled = FlarePaymentRules.confirmEnabled(order, now, busy, confirmDisabled || shortfall != null)
    var orderOpen by remember(order) { mutableStateOf(false) }
    val clipboard = androidx.compose.ui.platform.LocalClipboardManager.current
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
        // §12.19: the title is 15/600, centred.
        Text(strings.paymentConfirmationTitle, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl,
            fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center, modifier = Modifier.semantics { heading() })
        if (pluginName != null) Text(strings.paymentConfirmationRequestedBy.replace("{plugin}", pluginName),
            color = colors.textSecondary, fontSize = FlareTextRoles.Caption.fontSize)
        Text(amount ?: "—", color = if (expired) colors.textTertiary else colors.textPrimary,
            fontSize = FlareSizes.componentAmountHeroFontSize.value.sp, fontWeight = FontWeight.Bold, style = FlareTabularFigures,
            maxLines = 1, modifier = Modifier.testTag("flare-payment-amount"))
        Column(Modifier.fillMaxWidth()) {
            HorizontalDivider(thickness = 1.dp, color = colors.borderSecondary)
            row(strings.paymentConfirmationPayee, order.payee)
            if (order.title.isNotEmpty()) row(strings.paymentConfirmationItem, order.title)
            // P-06: the order number folds behind its label; opened, it can be copied.
            Row(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
                    .clickable(role = Role.Button) { orderOpen = !orderOpen }
                    .semantics(mergeDescendants = true) { stateDescription = if (orderOpen) strings.collapse else strings.expand },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(strings.paymentConfirmationOrder, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.weight(1f))
                FlareIcon(if (orderOpen) "chevron-down" else "chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textTertiary)
            }
            if (orderOpen) Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(order.orderId, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, modifier = Modifier.weight(1f))
                IconButton(icon = "copy", contentDescription = strings.pluginViewCopyReference.replace("{label}", strings.paymentConfirmationOrder),
                    size = FlareControlSize.Sm, onClick = { clipboard.setText(androidx.compose.ui.text.AnnotatedString(order.orderId)) })
            }
            HorizontalDivider(thickness = 1.dp, color = colors.borderSecondary)
        }
        val live = Modifier.semantics { liveRegion = LiveRegionMode.Polite }
        when {
            amount == null -> Text(strings.paymentConfirmationInvalid, color = colors.errorText, fontSize = FlareSizes.fontSizeMd, modifier = live)
            expired -> Text(strings.paymentConfirmationExpired, color = colors.errorText, fontSize = FlareSizes.fontSizeMd,
                modifier = live.testTag("flare-payment-expired"))
            else -> Text(strings.paymentConfirmationExpiresIn.replace("{time}", left),
                color = if (order.expiresAtMs - now < 60_000) colors.warningText else colors.textSecondary,
                fontSize = FlareTextRoles.Caption.fontSize, style = FlareTabularFigures, modifier = Modifier.testTag("flare-payment-countdown"))
        }
        credential?.invoke()
        if (error != null) Box(Modifier.fillMaxWidth().then(live)) { StatusBanner(text = error, tone = FlareStatusTone.Danger) }
        shortfall?.let {
            Text(strings.paymentConfirmationInsufficient.replace("{amount}", it), color = colors.errorText,
                fontSize = FlareTextRoles.Caption.fontSize, modifier = live)
        }
        // The contract's md action keys (each with a 48 touch target); §12.19: cancel is a secondary key.
        Column(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            if (expired && onStartAgain != null) {
                Button(label = strings.paymentConfirmationStartAgain, size = FlareControlSize.Md, block = true, maintainTouchTarget = true, onClick = onStartAgain)
            } else {
                Button(label = if (busy) strings.paymentConfirmationVerifying else strings.paymentConfirmationConfirm, size = FlareControlSize.Md,
                    loading = busy, disabled = !enabled && !busy, block = true, maintainTouchTarget = true, onClick = { if (enabled) onConfirm() })
            }
            if (shortfall != null && onTopUp != null) Button(label = strings.paymentConfirmationTopUp, variant = FlareButtonVariant.Secondary,
                size = FlareControlSize.Md, disabled = busy, block = true, maintainTouchTarget = true, onClick = onTopUp)
            Button(label = strings.cancel, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Md, disabled = busy, block = true,
                maintainTouchTarget = true, onClick = { if (!busy) onCancel() })
        }
    }
}
