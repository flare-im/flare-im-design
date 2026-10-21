package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
 * What a red packet card shows for the person looking at it. Spec: Message/RedPacketCard `state`.
 *
 * The host derives it from the plugin's state values; the kit only draws it. Every state but [Unopened] fades the
 * card. [Finished] and [Expired] stay tappable so the viewer can open the details.
 */
enum class FlareRedPacketState { Unopened, Claimed, Finished, Expired }

/**
 * The status line, in the contract's order: [busy], the host's [statusLabel], then the state ([claimed][FlareRedPacketState.Claimed]
 * with or without the host-formatted [amount], finished, expired), [disabled], and the default call to open.
 */
internal fun redPacketCardStatus(
    state: FlareRedPacketState,
    amount: String?,
    statusLabel: String?,
    busy: Boolean,
    disabled: Boolean,
    strings: FlareStrings,
): String = when {
    busy -> strings.packetBusy
    statusLabel != null -> statusLabel
    state == FlareRedPacketState.Claimed -> amount?.let(strings.packetClaimed) ?: strings.packetStateClaimed
    state == FlareRedPacketState.Finished -> strings.packetFinished
    state == FlareRedPacketState.Expired -> strings.packetStateExpired
    disabled -> strings.packetUnavailable
    else -> strings.packetTapToClaim
}

/** Only [busy], [disabled] or a missing handler make the card inert; finished and expired cards still open. */
internal fun redPacketCardInteractive(busy: Boolean, disabled: Boolean, hasHandler: Boolean): Boolean =
    !busy && !disabled && hasHandler

/** Every state the viewer has moved past fades the card. */
internal fun redPacketCardFaded(state: FlareRedPacketState): Boolean = state != FlareRedPacketState.Unopened

/**
 * Red packet card — the festive envelope in the timeline. Spec: Message/RedPacketCard (`RedPacketCard`).
 *
 * The status line follows [redPacketCardStatus]. [kindLabel] (for example the lucky-draw kind) sits on the brand
 * row, leading; the brand stays trailing. At most `componentRedPacketCardWidth` wide inside its parent and never
 * under the touch target tall. A spent card (every state but unopened) keeps its hue and recedes: each colour is
 * mixed toward `redPacketFadedMixTarget` ([redPacketFade]; white in light mode, a red-tinted dark ground in dark
 * mode), the text takes `redPacketFadedInk` (the small print at 72%, the rule at 18%) and the card lies flat. A busy
 * or unavailable card keeps its colours; only its status line says why it does not open.
 */
@Composable
fun RedPacketCard(
    blessing: String,
    kindLabel: String? = null,
    state: FlareRedPacketState = FlareRedPacketState.Unopened,
    amount: String? = null,
    statusLabel: String? = null,
    busy: Boolean = false,
    disabled: Boolean = false,
    onOpen: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val status = redPacketCardStatus(state, amount, statusLabel, busy, disabled, strings)
    val canOpen = redPacketCardInteractive(busy, disabled, onOpen != null)
    val faded = redPacketCardFaded(state)
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    val claimedAmount = !busy && statusLabel == null && state == FlareRedPacketState.Claimed && amount != null
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
                    color = when {
                        faded -> ink
                        claimedAmount -> colors.redPacketGold
                        else -> ink.copy(alpha = 0.85f)
                    },
                    fontWeight = if (claimedAmount) FontWeight.SemiBold else FontWeight.Normal,
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
        ) {
            val footer = ink.copy(alpha = if (faded) 0.72f else 0.75f)
            if (!kindLabel.isNullOrEmpty()) {
                Text(kindLabel, color = footer, fontSize = FlareSizes.fontSize2xs, maxLines = 1, overflow = TextOverflow.Ellipsis)
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
