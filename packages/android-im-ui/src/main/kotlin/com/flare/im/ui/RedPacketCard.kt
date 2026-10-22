package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp

/**
 * What a red packet card shows. Spec: dataTypes `RedPacketCardState` (spec/red-packet-vectors.json `cardState`), derived
 * by [flareRedPacketCardState] from the plugin's public layer and the viewer's personal layer — never from an amount.
 *
 * [Viewable] is an open packet the viewer will not open from here (the sender's own, or someone else's exclusive one).
 * Every state but [Unopened] and [Viewable] fades the card; every state stays tappable.
 */
enum class FlareRedPacketCardState { Unopened, Viewable, Claimed, Finished, Expired, Refunded }

/** The plugin's packet status (public layer). Spec: dataTypes `RedPacketStatus`. */
enum class FlareRedPacketStatus(val wire: String) {
    Open("open"), Completed("completed"), Expired("expired"), Refunded("refunded");

    companion object {
        fun fromWire(value: String?): FlareRedPacketStatus? = entries.firstOrNull { it.wire == value }
    }
}

/** Where a tap on the card goes, as the viewer's personal layer says (`tapAction`). */
enum class FlareRedPacketTapAction(val wire: String) {
    /** The open sheet with its coin. */
    Open("open"),
    /** The details page. */
    Details("details"),
    /** The open sheet saying who may open it. */
    NotEligible("notEligible");

    companion object {
        fun fromWire(value: String?): FlareRedPacketTapAction? = entries.firstOrNull { it.wire == value }
    }
}

/**
 * The card state from the public layer's [status] and the personal layer's [claimedByMe] and [tapAction]
 * (spec/red-packet-vectors.json `cardState`): what the viewer took wins, then the packet's end (completed, expired,
 * refunded); an open packet is unopened unless the personal layer sends the tap elsewhere (the sender's details, the
 * not-eligible notice). Before the personal layer arrives an open packet is unopened.
 */
fun flareRedPacketCardState(
    status: FlareRedPacketStatus,
    claimedByMe: Boolean = false,
    tapAction: FlareRedPacketTapAction? = null,
): FlareRedPacketCardState = when {
    claimedByMe -> FlareRedPacketCardState.Claimed
    status == FlareRedPacketStatus.Completed -> FlareRedPacketCardState.Finished
    status == FlareRedPacketStatus.Expired -> FlareRedPacketCardState.Expired
    status == FlareRedPacketStatus.Refunded -> FlareRedPacketCardState.Refunded
    tapAction == FlareRedPacketTapAction.Details || tapAction == FlareRedPacketTapAction.NotEligible -> FlareRedPacketCardState.Viewable
    else -> FlareRedPacketCardState.Unopened
}

/**
 * The status line, in the contract's order (spec/red-packet-vectors.json `card`): [busy], the host's [statusLabel], then
 * the state — a spent card says what happened (claimed, finished, expired, refunded) even when [disabled]; an unopened or
 * viewable card says "unavailable" when [disabled], else its call (open, view). Never an amount.
 */
internal fun redPacketCardStatus(
    state: FlareRedPacketCardState,
    statusLabel: String?,
    busy: Boolean,
    disabled: Boolean,
    strings: FlareStrings,
): String = when {
    busy -> strings.packetBusy
    statusLabel != null -> statusLabel
    state == FlareRedPacketCardState.Claimed -> strings.packetStateClaimed
    state == FlareRedPacketCardState.Finished -> strings.packetFinished
    state == FlareRedPacketCardState.Expired -> strings.packetStateExpired
    state == FlareRedPacketCardState.Refunded -> strings.packetRefunded
    disabled -> strings.packetUnavailable
    state == FlareRedPacketCardState.Viewable -> strings.packetView
    else -> strings.packetTapToClaim
}

/** Only [busy], [disabled] or a missing handler make the card inert; every state opens (the host routes by `tapAction`). */
internal fun redPacketCardInteractive(busy: Boolean, disabled: Boolean, hasHandler: Boolean): Boolean =
    !busy && !disabled && hasHandler

/** A spent card fades: claimed, finished, expired and refunded. */
internal fun redPacketCardFaded(state: FlareRedPacketCardState): Boolean =
    state != FlareRedPacketCardState.Unopened && state != FlareRedPacketCardState.Viewable

/** The kind badge and the exclusive recipient line (spec/red-packet-vectors.json `cardBadge`). */
internal data class RedPacketCardBadge(val badge: String?, val recipient: String?)

/** Lucky and exclusive packets carry their badge, a normal one none; only an exclusive packet names its recipient. */
internal fun redPacketCardBadge(kind: FlareRedPacketKind, recipientName: String?, strings: FlareStrings): RedPacketCardBadge = when (kind) {
    FlareRedPacketKind.Lucky -> RedPacketCardBadge(strings.packetBadgeLucky, null)
    FlareRedPacketKind.Normal -> RedPacketCardBadge(null, null)
    FlareRedPacketKind.Exclusive -> RedPacketCardBadge(
        strings.packetBadgeExclusive,
        recipientName?.trim()?.takeIf { it.isNotEmpty() }?.let { strings.packetForRecipient.replace("{name}", it) },
    )
}

/**
 * Red packet card — the festive envelope in the timeline, and the message's card surface (no bubble around it). Spec:
 * Message/RedPacketCard (`RedPacketCard`).
 *
 * Red packet v5: the greeting, the [kind] badge on the brand row (lucky, exclusive; normal has none), "For {name}" with
 * [recipientName] on an exclusive packet, and one status line ([redPacketCardStatus]) — never an amount, not even the
 * viewer's own. At most `componentRedPacketCardWidth` wide inside its parent and never under the touch target tall. A
 * spent card keeps its hue and recedes: each colour is mixed toward `redPacketFadedMixTarget` ([redPacketFade]), the
 * text takes `redPacketFadedInk` and the card lies flat. A busy or unavailable card keeps its colours; only its status
 * line says why it does not open. Every other state calls [onOpen]; the host routes by the personal layer's tapAction.
 */
@Composable
fun RedPacketCard(
    blessing: String,
    kind: FlareRedPacketKind = FlareRedPacketKind.Normal,
    recipientName: String? = null,
    state: FlareRedPacketCardState = FlareRedPacketCardState.Unopened,
    statusLabel: String? = null,
    busy: Boolean = false,
    disabled: Boolean = false,
    onOpen: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val status = redPacketCardStatus(state, statusLabel, busy, disabled, strings)
    val canOpen = redPacketCardInteractive(busy, disabled, onOpen != null)
    val faded = redPacketCardFaded(state)
    val badge = redPacketCardBadge(kind, recipientName, strings)
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    val ink = if (faded) colors.redPacketFadedInk else colors.redPacketOnSurface
    Column(
        Modifier.widthIn(max = FlareSizes.componentRedPacketCardWidth).fillMaxWidth()
            .heightIn(min = FlareSizes.touchTarget)
            .shadow(if (faded) 0.dp else FlareSizes.spacingSm, shape, clip = false,
                ambientColor = colors.redPacketEnd, spotColor = colors.redPacketEnd)
            .clip(shape)
            .background(redPacketCoverBrush(colors, faded))
            .semantics(mergeDescendants = true) {
                stateDescription = status
                if (busy) liveRegion = LiveRegionMode.Polite
            }
            .clickable(enabled = canOpen, role = Role.Button) { if (canOpen) onOpen?.invoke() },
    ) {
        Row(
            Modifier.padding(horizontal = FlareSizes.spacing2md, vertical = FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            RedPacketGlyph(RedPacketMetrics.cardGlyphWidth, faded)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Column(Modifier.weight(1f)) {
                Text(
                    blessing, color = ink, fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSizeXl, maxLines = 1, overflow = TextOverflow.Ellipsis,
                )
                Text(
                    status,
                    color = if (faded) ink else ink.copy(alpha = 0.85f),
                    fontSize = FlareSizes.fontSizeSm, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = FlareSizes.spacing3xs),
                )
            }
        }
        HorizontalDivider(
            Modifier.padding(horizontal = FlareSizes.spacing2md),
            thickness = RedPacketMetrics.hairline,
            color = ink.copy(alpha = if (faded) 0.18f else 0.24f),
        )
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacing2md, vertical = FlareSizes.spacingXs),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
        ) {
            val footer = ink.copy(alpha = if (faded) 0.72f else 0.75f)
            badge.badge?.let { Text(it, color = footer, fontSize = FlareSizes.fontSize2xs, fontWeight = FontWeight.SemiBold, maxLines = 1) }
            badge.recipient?.let {
                Text(it, color = footer, fontSize = FlareSizes.fontSize2xs, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false))
            }
            Spacer(Modifier.weight(1f))
            Text(strings.packetBrand, color = footer, fontSize = FlareSizes.fontSize2xs, maxLines = 1)
        }
    }
}

// MARK: - Shared red packet drawing

/** Geometry the red packet family shares that has no token of its own: proportions and hairlines. */
internal object RedPacketMetrics {
    val hairline: Dp = 0.5.dp
    val ringWidth: Dp = 1.5.dp
    val cardGlyphWidth: Dp = 30.dp
    /** The glyph is an envelope: taller than wide. */
    const val glyphAspect = 1.3f
    /** The envelope's flap covers this share of its minimum height; the open button sits on its edge. */
    const val flapShare = 0.62f
    /** How far the flap's curved edge dips below its straight sides, as a share of the envelope width. */
    const val flapCurve = 0.1f
    /** The open button's glyph against the button's diameter. */
    const val openGlyphShare = 0.42f
    /** One turn of the opening flip, in milliseconds. */
    const val flipMillis = 900
}

/** The festive colour ramps, all from the `colors.redPacket*` tokens; a spent card's stops are faded. */
internal fun redPacketCoverBrush(colors: FlareColors, faded: Boolean = false): Brush =
    Brush.linearGradient(redPacketCoverStops(colors, faded))

internal fun redPacketCoverStops(colors: FlareColors, faded: Boolean): List<Color> =
    listOf(colors.redPacketStart, colors.redPacketMiddle, colors.redPacketEnd).map { if (faded) redPacketFade(it, colors) else it }

/**
 * [color] moved `componentRedPacketFadedMix` of the way to `redPacketFadedMixTarget`, per sRGB channel (CSS
 * `color-mix(in srgb …)`): white in light mode, a red-tinted dark ground in dark mode, so the hue stays. Compose's own
 * `lerp` mixes in Oklab, which the other kits do not.
 */
internal fun redPacketFade(color: Color, colors: FlareColors): Color =
    redPacketMix(color, colors.redPacketFadedMixTarget, FlareSizes.componentRedPacketFadedMix)

internal fun redPacketMix(a: Color, b: Color, share: Float): Color = Color(
    red = a.red + (b.red - a.red) * share,
    green = a.green + (b.green - a.green) * share,
    blue = a.blue + (b.blue - a.blue) * share,
    alpha = a.alpha + (b.alpha - a.alpha) * share,
)

internal fun redPacketFlapBrush(colors: FlareColors): Brush =
    Brush.verticalGradient(listOf(colors.redPacketStart, colors.redPacketMiddle))

internal fun redPacketBodyBrush(colors: FlareColors): Brush =
    Brush.verticalGradient(listOf(colors.redPacketMiddle, colors.redPacketEnd))

internal fun redPacketCoinBrush(colors: FlareColors): Brush =
    Brush.radialGradient(listOf(colors.redPacketGold, colors.redPacketGoldDeep))

/**
 * A rectangle whose bottom edge bows downwards: the envelope's flap. The lowest point of the curve is the bottom of
 * the bounds, at the middle; the straight sides end [depth] above it.
 */
internal class RedPacketFlapShape(private val depth: Dp) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(redPacketFlapPath(size, with(density) { depth.toPx() }))
}

internal fun redPacketFlapPath(size: Size, depth: Float): Path {
    val side = size.height - depth.coerceIn(0f, size.height)
    return Path().apply {
        moveTo(0f, 0f)
        lineTo(size.width, 0f)
        lineTo(size.width, side)
        // A quadratic curve through (width / 2, height): its control point sits as far below as the sides are above.
        quadraticTo(size.width / 2, size.height + (size.height - side), 0f, side)
        close()
    }
}

/**
 * Re-tints the kit's primary role with the red packet's deep red for the family's money buttons ("put money in",
 * "pay"), so they stay kit [Button]s — focus, loading, disabled and touch target included — rather than a second
 * button drawn here. White text on the deep red is above 4.5:1.
 */
@Composable
internal fun RedPacketMoneyTint(content: @Composable () -> Unit) {
    val colors = flareColors()
    val red = colors.redPacketEnd
    FlareThemeProvider(
        colors = colors.copy(
            primary = red,
            primaryHover = lerp(red, Color.Black, 0.12f),
            primaryActive = lerp(red, Color.Black, 0.22f),
        ),
        content = content,
    )
}

/** The small gold envelope on a card: body, flap and a red seal, paler on a spent card. Decoration only. */
@Composable
internal fun RedPacketGlyph(width: Dp, faded: Boolean = false) {
    val colors = flareColors()
    val tone: (Color) -> Color = { c -> if (faded) redPacketFade(c, colors) else c }
    Box(Modifier.size(width, width * RedPacketMetrics.glyphAspect)) {
        Canvas(Modifier.matchParentSize()) {
            val corner = CornerRadius(size.width * 0.18f)
            val flap = size.height * 0.42f
            val seal = size.width * 0.18f
            val body = Path().apply { addRoundRect(androidx.compose.ui.geometry.RoundRect(Rect(Offset.Zero, size), corner)) }
            clipPath(body) {
                drawRect(Brush.verticalGradient(listOf(tone(colors.redPacketGold), tone(colors.redPacketGoldDeep))))
                drawPath(redPacketFlapPath(Size(size.width, flap), flap * 0.3f), tone(colors.redPacketGoldDeep))
                drawCircle(tone(colors.redPacketEnd), radius = seal, center = Offset(size.width / 2, flap))
            }
        }
    }
}
