package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.isTraversalGroup
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp

/**
 * One claim in a red packet's details. Every field is host-formatted: the kit does no money or time maths.
 * [best] marks the best-luck share of a finished lucky packet. Spec: RedPacketDetail `claims`.
 */
data class FlareRedPacketClaim(
    val id: String,
    val name: String,
    val time: String,
    val amount: String,
    val avatar: String? = null,
    val best: Boolean = false,
)

/**
 * A red packet's details page body: the red arc header, the sender ("X's red packet" with the kind tag), the
 * blessing, the viewer's own [amount] in large type with its [amountNote], the [summary] band and the claim list.
 * Spec: RedPacketDetail (`RedPacketDetail`).
 *
 * It is a page, not an overlay: the host puts it on its navigation stack inside [FlareScreen] (which scrolls), so it
 * lays the list out in a plain column. The list marks the best-luck claim, says so when no one has claimed yet, and
 * ends with the host's [note] (a refund notice, for instance).
 *
 * With [onBack] the page draws its own red title bar — a light back key and [title] (the kit's `packetDetailTitle` by
 * default) — in one piece with the arc below; its colour runs up under the status bar when the page is laid out edge
 * to edge, its content clears the bar, and system back steps back. The host hides its own header then. Without it the
 * page starts at the arc, as before.
 */
@Composable
fun RedPacketDetail(
    senderName: String,
    blessing: String,
    summary: String,
    modifier: Modifier = Modifier,
    senderAvatar: String? = null,
    kindLabel: String? = null,
    amount: String? = null,
    amountNote: String? = null,
    claims: List<FlareRedPacketClaim> = emptyList(),
    note: String? = null,
    title: String? = null,
    onBack: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    FlareNativeBackEffect(enabled = onBack != null) { onBack?.invoke() }
    Column(modifier.fillMaxWidth().background(colors.bgPrimary)) {
        // Bar and arc are one shape and one gradient, so there is no seam between them.
        Column(
            Modifier.fillMaxWidth()
                .background(redPacketCoverBrush(colors), RedPacketFlapShape(FlareSizes.componentRedPacketDetailHeaderHeight * 0.4f)),
        ) {
            if (onBack != null) {
                Box(
                    Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.statusBars)
                        .heightIn(min = FlareSizes.headerHeight).padding(horizontal = FlareSizes.spacingXs),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        title ?: strings.packetDetailTitle, color = colors.redPacketOnSurface, fontSize = FlareSizes.fontSize2xl,
                        fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(horizontal = FlareSizes.touchTarget).semantics { heading() },
                    )
                    FlareIconControl(label = strings.back, onClick = onBack, modifier = Modifier.align(Alignment.CenterStart)) {
                        FlareIcon("back", size = FlareSizes.iconSizeLg, tint = colors.redPacketOnSurface)
                    }
                }
            }
            Spacer(Modifier.fillMaxWidth().height(FlareSizes.componentRedPacketDetailHeaderHeight))
        }
        Column(
            Modifier.fillMaxWidth().padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacing2xl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            Row(
                Modifier.semantics(mergeDescendants = true) { heading() },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                Avatar(userId = senderName, displayName = senderName, size = FlareSizes.iconSizeXl, avatarUrl = senderAvatar)
                Text(
                    strings.packetFromSender(senderName), color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl,
                    fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (!kindLabel.isNullOrEmpty()) {
                    Text(
                        kindLabel, color = colors.redPacketGold, fontSize = FlareSizes.fontSizeXs, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clip(RoundedCornerShape(FlareSizes.radiusXs)).background(colors.redPacketEnd)
                            .padding(horizontal = FlareSizes.spacingXs, vertical = FlareSizes.spacing3xs),
                    )
                }
            }
            Text(blessing, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center)
            if (amount != null) {
                Text(
                    amount, color = colors.textPrimary, fontSize = FlareSizes.componentRedPacketAmountFontSize.value.sp,
                    fontWeight = FontWeight.SemiBold, maxLines = 1, modifier = Modifier.padding(top = FlareSizes.spacingMd),
                )
                if (!amountNote.isNullOrEmpty()) {
                    Text(amountNote, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd)
                }
            }
        }
        Text(
            summary, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd,
            modifier = Modifier.padding(top = FlareSizes.spacing2xl).fillMaxWidth().background(colors.bgSecondary)
                .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
        )
        if (claims.isEmpty()) {
            Text(
                strings.packetNoClaims, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacing2xl),
            )
        } else {
            Column(Modifier.semantics { contentDescription = strings.packetClaims; isTraversalGroup = true }) {
                claims.forEachIndexed { index, claim ->
                    RedPacketClaimRow(claim)
                    if (index < claims.lastIndex) {
                        HorizontalDivider(
                            Modifier.padding(start = FlareSizes.spacingLg + FlareSizes.componentMessageAvatarSize + FlareSizes.spacingMd),
                            thickness = RedPacketMetrics.hairline,
                            color = colors.borderSecondary,
                        )
                    }
                }
            }
        }
        if (!note.isNullOrEmpty()) {
            Text(
                note, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXl),
            )
        }
    }
}

@Composable
private fun RedPacketClaimRow(claim: FlareRedPacketClaim) {
    val colors = flareColors()
    val strings = flareStrings()
    Row(
        Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
            .semantics(mergeDescendants = true) {}
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Box(Modifier.clearAndSetSemantics {}) {
            Avatar(userId = claim.id, displayName = claim.name, size = FlareSizes.componentMessageAvatarSize, avatarUrl = claim.avatar)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
            Text(claim.name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(claim.time, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, maxLines = 1)
        }
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
            Text(claim.amount, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.Medium, maxLines = 1)
            if (claim.best) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                    FlareIcon("star", size = FlareSizes.iconSizeSm, tint = colors.warningText)
                    Text(strings.packetBestLuck, color = colors.warningText, fontSize = FlareSizes.fontSizeSm)
                }
            }
        }
    }
}
