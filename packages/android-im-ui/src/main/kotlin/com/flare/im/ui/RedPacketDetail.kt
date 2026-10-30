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
import androidx.compose.runtime.remember
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

/** Who is looking at a red packet's details, as the server decided. Spec: dataTypes `RedPacketViewerRole`. */
enum class FlareRedPacketViewerRole(val wire: String) {
    Sender("sender"), Claimer("claimer"), Eligible("eligible"), Ineligible("ineligible");

    companion object {
        fun fromWire(value: String?): FlareRedPacketViewerRole? = entries.firstOrNull { it.wire == value }
    }
}

/**
 * The plugin's details result for one viewer (spec dataTypes `RedPacketDetailsView`). The server trims it by
 * [viewerRole]: an amount the viewer may not see is absent (null), and the kit draws only what is there. Amounts are
 * minor-unit strings of ASCII digits; [currencyExponent] is the currency's fraction digits (ISO 4217).
 */
data class FlareRedPacketDetailsView(
    val viewerRole: FlareRedPacketViewerRole,
    val status: FlareRedPacketStatus,
    val kind: FlareRedPacketKind,
    val greeting: String,
    val currency: String,
    val currencyExponent: Int,
    val claimedCount: Int,
    val shareCount: Int,
    val createdAtMs: Long,
    val expiresAtMs: Long,
    val claimsListed: Boolean,
    /** Sender only. */
    val totalMinor: String? = null,
    /** Sender only. */
    val claimedMinor: String? = null,
    /** Sender only. */
    val refundedMinor: String? = null,
    /** What the viewer received. */
    val myAmountMinor: String? = null,
    val completedAtMs: Long? = null,
    val refundedAtMs: Long? = null,
)

/**
 * One claim in a red packet's details: [id] is the claimant's user id (it seeds the avatar), [name] and [avatar] come
 * from the host's directory, the kit formats [amountMinor] and [claimedAtMs]. [best] is the server's best-luck mark.
 * Spec: dataTypes `RedPacketClaim`.
 */
data class FlareRedPacketClaim(
    val id: String,
    val name: String,
    val amountMinor: String,
    val claimedAtMs: Long,
    val avatar: String? = null,
    val best: Boolean = false,
)

/** The symbols the kits share (spec/red-packet-vectors.json `amount.symbols`); any other currency is written by its code. */
private val redPacketCurrencySymbols = mapOf("CNY" to "¥", "JPY" to "¥", "USD" to "$", "EUR" to "€", "GBP" to "£", "HKD" to "HK$")

/**
 * A minor-unit amount as text with exactly [exponent] fraction digits, leading zeros folded, no grouping — by string
 * arithmetic, never floating point (spec/red-packet-vectors.json `amount.rule`). Null for anything but ASCII digits.
 */
fun flareRedPacketAmountText(minor: String?, exponent: Int): String? {
    if (minor.isNullOrEmpty() || minor.any { it !in '0'..'9' } || exponent < 0 || exponent > 12) return null
    val digits = minor.trimStart('0')
    if (exponent == 0) return digits.ifEmpty { "0" }
    val padded = digits.padStart(exponent + 1, '0')
    return padded.dropLast(exponent) + "." + padded.takeLast(exponent)
}

/** [flareRedPacketAmountText] with the currency: its symbol when the kits share one, else "{CODE} {text}". */
fun flareRedPacketMoney(minor: String?, exponent: Int, currency: String): String? {
    val text = flareRedPacketAmountText(minor, exponent) ?: return null
    val code = currency.trim().uppercase(java.util.Locale.ROOT)
    return redPacketCurrencySymbols[code]?.let { it + text } ?: "$code $text"
}

/** What [RedPacketDetail] draws for one viewer (spec/red-packet-vectors.json `detail`). */
internal data class RedPacketDetailPresentation(
    /** The viewer's own amount, large; null when the server did not return one. */
    val amount: String?,
    /** "Saved to your wallet" under the amount. */
    val deposited: Boolean,
    /** Why there is nothing for this viewer (too late, expired, not theirs); null keeps the greeting alone. */
    val headline: String?,
    val summary: String?,
    /** The claim list shows. */
    val claims: Boolean,
    val note: String?,
)

internal object RedPacketDetailFormat {
    /** HH:mm on the viewer's day of [nowMs], else month, day and time, with the year outside now's year. */
    fun time(ms: Long, nowMs: Long, strings: FlareStrings, utcOffsetMinutes: Int?): String {
        val at = PluginViewFormat.wallClock(ms, utcOffsetMinutes)
        val now = PluginViewFormat.wallClock(nowMs, utcOffsetMinutes)
        if (at.year == now.year && at.month == now.month && at.day == now.day) return PluginViewFormat.render("HH:mm", at)
        return PluginViewFormat.dateTime(ms, nowMs, strings, utcOffsetMinutes)
    }

    /** Whole seconds under a minute, whole minutes under an hour, whole hours under a day, else whole days. */
    fun duration(ms: Long, strings: FlareStrings): String {
        val seconds = (ms / 1000).coerceAtLeast(0)
        return when {
            seconds < 60 -> strings.packetDurationSeconds.replace("{n}", seconds.toString())
            seconds < 3600 -> strings.packetDurationMinutes.replace("{n}", (seconds / 60).toString())
            seconds < 86_400 -> strings.packetDurationHours.replace("{n}", (seconds / 3600).toString())
            else -> strings.packetDurationDays.replace("{n}", (seconds / 86_400).toString())
        }
    }

    fun presentation(
        details: FlareRedPacketDetailsView,
        designatedName: String?,
        nowMs: Long,
        strings: FlareStrings,
        utcOffsetMinutes: Int? = null,
    ): RedPacketDetailPresentation {
        fun money(minor: String?) = flareRedPacketMoney(minor, details.currencyExponent, details.currency)
        val role = details.viewerRole
        val status = details.status
        val ended = status == FlareRedPacketStatus.Expired || status == FlareRedPacketStatus.Refunded
        val amount = money(details.myAmountMinor)
        val headline = when {
            role == FlareRedPacketViewerRole.Ineligible ->
                designatedName?.trim()?.takeIf { it.isNotEmpty() }?.let { strings.packetNotEligibleName.replace("{name}", it) }
                    ?: strings.packetNotEligible
            role == FlareRedPacketViewerRole.Eligible && status == FlareRedPacketStatus.Completed -> strings.packetMissed
            role == FlareRedPacketViewerRole.Eligible && ended -> strings.packetExpiredNotice
            else -> null
        }
        val total = money(details.totalMinor)
        val claimed = money(details.claimedMinor)
        val summary = when {
            role == FlareRedPacketViewerRole.Ineligible || (role == FlareRedPacketViewerRole.Eligible && ended) -> null
            status == FlareRedPacketStatus.Completed && total != null && details.completedAtMs != null ->
                strings.packetSummaryCompleted
                    .replace("{shares}", details.shareCount.toString())
                    .replace("{totalMoney}", total)
                    .replace("{duration}", duration(details.completedAtMs - details.createdAtMs, strings))
            total != null && claimed != null -> strings.packetSummarySender
                .replace("{claimed}", details.claimedCount.toString())
                .replace("{shares}", details.shareCount.toString())
                .replace("{claimedMoney}", claimed)
                .replace("{totalMoney}", total)
            else -> strings.packetSummaryCount
                .replace("{claimed}", details.claimedCount.toString())
                .replace("{shares}", details.shareCount.toString())
        }
        val refunded = details.refundedMinor?.takeIf { flareRedPacketAmountText(it, 0)?.let { digits -> digits != "0" } == true }
        val note = when {
            role != FlareRedPacketViewerRole.Sender -> null
            status == FlareRedPacketStatus.Open -> strings.packetRefundAt.replace("{time}", time(details.expiresAtMs, nowMs, strings, utcOffsetMinutes))
            ended && refunded != null -> {
                val text = strings.packetRefundedNote.replace("{money}", money(refunded).orEmpty())
                details.refundedAtMs?.let { text.replace("{time}", time(it, nowMs, strings, utcOffsetMinutes)) }
                    ?: text.replace(Regex("\\s*·\\s*\\{time\\}"), "").replace("{time}", "")
            }
            else -> null
        }
        return RedPacketDetailPresentation(amount, amount != null, headline, summary, details.claimsListed, note)
    }
}

/**
 * A red packet's details page body: the red arc header, the sender ("X's red packet" with the kind badge), the greeting
 * and what this viewer may see. Spec: RedPacketDetail (`RedPacketDetail`), red packet v5 §2.
 *
 * [details] is the plugin's result for this viewer, already trimmed by the server; the page draws only what is there
 * (spec/red-packet-vectors.json `detail`): the viewer's own amount large with "Saved to your wallet" when it is there; a
 * headline for an eligible member who came too late or after expiry and for a viewer the packet is not for ("Only
 * {[designatedName]} can open this"); the summary band (totals only for the sender); the claim list ([claims]: name,
 * time, amount, best luck) only when the viewer may see it; and the sender's refund note. Amounts are formatted from
 * minor units with the currency's exponent ([flareRedPacketMoney]); times in the device zone.
 *
 * It is a page, not an overlay: the host puts it on its navigation stack inside [FlareScreen] (which scrolls). With
 * [onBack] the page draws its own red title bar — a light back key and [title] (the kit's `packetDetailTitle` by
 * default) — in one piece with the arc below; its colour runs up under the status bar when the page is laid out edge to
 * edge, and system back steps back.
 */
@Composable
fun RedPacketDetail(
    senderName: String,
    details: FlareRedPacketDetailsView,
    modifier: Modifier = Modifier,
    senderAvatar: String? = null,
    designatedName: String? = null,
    claims: List<FlareRedPacketClaim> = emptyList(),
    title: String? = null,
    onBack: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val now = remember(details) { System.currentTimeMillis() }
    val shown = RedPacketDetailFormat.presentation(details, designatedName, now, strings)
    val badge = redPacketCardBadge(details.kind, null, strings).badge
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
                if (badge != null) {
                    Text(
                        badge, color = colors.redPacketGold, fontSize = FlareSizes.fontSizeXs, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clip(RoundedCornerShape(FlareSizes.radiusXs)).background(colors.redPacketEnd)
                            .padding(horizontal = FlareSizes.spacingXs, vertical = FlareSizes.spacing3xs),
                    )
                }
            }
            Text(details.greeting, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center)
            shown.headline?.let {
                Text(
                    it, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl, fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center, modifier = Modifier.padding(top = FlareSizes.spacingMd),
                )
            }
            shown.amount?.let { amount ->
                Text(
                    amount, color = colors.textPrimary, fontSize = FlareSizes.componentRedPacketAmountFontSize.value.sp,
                    fontWeight = FontWeight.SemiBold, maxLines = 1, modifier = Modifier.padding(top = FlareSizes.spacingMd),
                )
                if (shown.deposited) Text(strings.packetDeposited, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd)
            }
        }
        shown.summary?.let { summary ->
            Text(
                summary, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd,
                modifier = Modifier.padding(top = FlareSizes.spacing2xl).fillMaxWidth().background(colors.bgSecondary)
                    .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
            )
        }
        if (shown.claims) {
            if (claims.isEmpty()) {
                Text(
                    strings.packetNoClaims, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacing2xl),
                )
            } else {
                Column(Modifier.semantics { contentDescription = strings.packetClaims; isTraversalGroup = true }) {
                    claims.forEachIndexed { index, claim ->
                        RedPacketClaimRow(
                            claim,
                            time = RedPacketDetailFormat.time(claim.claimedAtMs, now, strings, null),
                            amount = flareRedPacketMoney(claim.amountMinor, details.currencyExponent, details.currency).orEmpty(),
                        )
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
        }
        shown.note?.let { note ->
            Text(
                note, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXl),
            )
        }
    }
}

@Composable
private fun RedPacketClaimRow(claim: FlareRedPacketClaim, time: String, amount: String) {
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
            Text(time, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, maxLines = 1)
        }
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
            Text(amount, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.Medium, maxLines = 1)
            if (claim.best) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                    FlareIcon("star", size = FlareSizes.iconSizeSm, tint = colors.warningText)
                    Text(strings.packetBestLuck, color = colors.warningText, fontSize = FlareSizes.fontSizeSm)
                }
            }
        }
    }
}
