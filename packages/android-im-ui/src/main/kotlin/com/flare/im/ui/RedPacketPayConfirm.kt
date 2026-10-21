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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp

/** Confirm takes a tap only with enough balance and nothing running. */
internal fun redPacketPayConfirmEnabled(insufficient: Boolean, busy: Boolean): Boolean = !insufficient && !busy

/**
 * The payment confirmation for a red packet, as a bottom panel: the title, the [amount] in large type, the payment
 * method row ([methodLabel], for example the wallet and its balance), and confirm / cancel. Spec: RedPacketPayConfirm
 * (`RedPacketPayConfirm`).
 *
 * Composing it shows it in a kit [BottomSheet] (a bottom panel on the phone form factor, a [Modal] elsewhere); the
 * host removes it in [onCancel], which the scrim and system back also reach, and in its own confirm flow.
 * [insufficient] disables confirm and says the balance is too low; [busy] shows progress on confirm, disables cancel
 * and locks the sheet. Confirm is the kit button re-tinted with the deep red, cancel the quiet one.
 */
@Composable
fun RedPacketPayConfirm(
    amount: String,
    methodLabel: String,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
    insufficient: Boolean = false,
    busy: Boolean = false,
) {
    val strings = flareStrings()
    BottomSheet(
        onClose = onCancel,
        title = strings.packetPayTitle,
        // The panel draws its own heading over the amount.
        titleHidden = true,
        dismissible = !busy,
    ) {
        RedPacketPayConfirmBody(amount, methodLabel, insufficient, busy, onConfirm, onCancel)
    }
}

@Composable
internal fun RedPacketPayConfirmBody(
    amount: String,
    methodLabel: String,
    insufficient: Boolean,
    busy: Boolean,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    Column(
        Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
    ) {
        Text(
            strings.packetPayTitle, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl,
            fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() },
        )
        Text(
            amount, color = colors.textPrimary, fontSize = FlareSizes.componentRedPacketAmountFontSize.value.sp,
            fontWeight = FontWeight.SemiBold, maxLines = 1,
        )
        Column(Modifier.fillMaxWidth()) {
            HorizontalDivider(thickness = RedPacketMetrics.hairline, color = colors.borderSecondary)
            Row(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget).semantics(mergeDescendants = true) {},
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(strings.packetPayMethod, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Text(
                    methodLabel, color = if (insufficient) colors.errorText else colors.textPrimary,
                    fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.End, modifier = Modifier.weight(1f),
                )
            }
            HorizontalDivider(thickness = RedPacketMetrics.hairline, color = colors.borderSecondary)
        }
        if (insufficient) {
            Text(
                strings.packetInsufficient, color = colors.errorText, fontSize = FlareSizes.fontSizeMd,
                modifier = Modifier.fillMaxWidth().semantics { liveRegion = LiveRegionMode.Polite },
            )
        }
        Column(
            Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            // The family's red action. `loading` already holds it while busy; `disabled` would also dim the progress.
            RedPacketMoneyTint {
                Button(
                    label = strings.packetPayConfirm, variant = FlareButtonVariant.Primary, size = FlareControlSize.Lg,
                    loading = busy, disabled = insufficient, block = true, onClick = onConfirm,
                )
            }
            Button(
                label = strings.cancel, variant = FlareButtonVariant.Quiet, size = FlareControlSize.Lg,
                disabled = busy, block = true, onClick = onCancel,
            )
        }
    }
}
