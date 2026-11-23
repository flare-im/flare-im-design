package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Red packet arch — the decorative red arch under the header of red packet pages (composer, review, detail). Spec:
 * RedPacket/RedPacketArch (`RedPacketArch`). Full width, solid `colors.redPacketEnd` with a bowed bottom edge;
 * [compact] is 32 high (composer, review), else `component.redPacketDetailHeaderHeight` (detail). Decoration only: it is
 * never read out.
 */
@Composable
fun RedPacketArch(modifier: Modifier = Modifier, compact: Boolean = false) {
    val colors = flareColors()
    val height = if (compact) FlareSizes.componentRedPacketArchCompactHeight else FlareSizes.componentRedPacketDetailHeaderHeight
    Box(
        modifier.fillMaxWidth().height(height).clearAndSetSemantics {}
            .background(colors.redPacketEnd, RedPacketFlapShape(height * 0.4f)),
    )
}

/**
 * Red packet review — the confirm step of sending a red packet (presentation renderer `redPacket.review`, 4.3 of
 * docs/plugin-experience.md). Spec: RedPacket/RedPacketReview (`RedPacketReview`). The compact arch, the total in
 * `component.redPacketAmountFontSize`, the kind and count ([kindLabel]), the [blessing], a danger banner with [error]
 * above the red send key ([submitLabel], else `packetSend`), which spins and locks while [busy].
 */
@Composable
fun RedPacketReview(
    amount: String,
    modifier: Modifier = Modifier,
    kindLabel: String? = null,
    blessing: String? = null,
    submitLabel: String? = null,
    busy: Boolean = false,
    error: String? = null,
    onSubmit: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    Column(modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        RedPacketArch(compact = true)
        Column(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacing2xl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
        ) {
            Text(
                amount, color = colors.textPrimary,
                fontSize = (if (flareCompactOverlays()) FlareSizes.componentRedPacketAmountFontSize else FlareSizes.componentRedPacketAmountFontSizeWide).value.sp,
                fontWeight = FontWeight.SemiBold, style = FlareTabularFigures, maxLines = 1,
            )
            kindLabel?.takeIf { it.isNotBlank() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg) }
            blessing?.takeIf { it.isNotBlank() }?.let {
                Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, textAlign = TextAlign.Center)
            }
            error?.takeIf { it.isNotEmpty() }?.let {
                Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm)) { StatusBanner(text = it, tone = FlareStatusTone.Danger) }
            }
            Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm)) {
                RedPacketMoneyTint {
                    // 4.3: busy looks like the composer's key — a spinner on the full red key, not a dimmed one.
                    Button(label = submitLabel ?: strings.packetSend, size = FlareControlSize.Lg, loading = busy,
                        disabled = !busy && onSubmit == null, block = true, onClick = if (busy) ({}) else onSubmit)
                }
            }
        }
    }
}
