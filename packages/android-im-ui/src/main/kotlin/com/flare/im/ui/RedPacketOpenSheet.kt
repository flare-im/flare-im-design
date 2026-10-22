package com.flare.im.ui

import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * What the open-packet layer shows. Spec: RedPacketOpenSheet `state`.
 *
 * [Ready] offers the gold open button; [Opening] flips it while the claim runs and takes no second tap; [Finished],
 * [Expired] and [NotEligible] say why there is nothing to open — the first two offer the details when the viewer may
 * see them, [NotEligible] never does; [Error] keeps the button for another try.
 */
enum class FlareRedPacketOpenState { Ready, Opening, Finished, Expired, NotEligible, Error }

/**
 * The large line on the flap: the blessing while there is something to open, otherwise why not (the host's
 * non-empty [message] replaces the kit's copy).
 */
internal fun redPacketOpenHeadline(
    state: FlareRedPacketOpenState,
    blessing: String,
    message: String?,
    strings: FlareStrings,
): String {
    val custom = message?.takeIf { it.isNotEmpty() }
    return when (state) {
        FlareRedPacketOpenState.Ready, FlareRedPacketOpenState.Opening, FlareRedPacketOpenState.Error -> blessing
        FlareRedPacketOpenState.Finished -> custom ?: strings.packetMissed
        FlareRedPacketOpenState.Expired -> custom ?: strings.packetExpiredNotice
        FlareRedPacketOpenState.NotEligible -> custom ?: strings.packetNotEligible
    }
}

/** The small line under it: only a failed claim has one, the host's [message] or the kit's retry copy. */
internal fun redPacketOpenHint(state: FlareRedPacketOpenState, message: String?, strings: FlareStrings): String? =
    if (state == FlareRedPacketOpenState.Error) message?.takeIf { it.isNotEmpty() } ?: strings.packetOpenFailed else null

/** The open button is there while there is something to open. */
internal fun redPacketOpenShowsButton(state: FlareRedPacketOpenState): Boolean =
    state == FlareRedPacketOpenState.Ready || state == FlareRedPacketOpenState.Opening ||
        state == FlareRedPacketOpenState.Error

/**
 * The details key (spec/red-packet-vectors.json `openSheet`): a finished or expired packet leads to its details when the
 * personal layer says the viewer may see them ([canViewDetails]); a not-eligible viewer never gets one — the server
 * returns them no amounts or records.
 */
internal fun redPacketOpenShowsDetails(state: FlareRedPacketOpenState, canViewDetails: Boolean = true): Boolean =
    canViewDetails && (state == FlareRedPacketOpenState.Finished || state == FlareRedPacketOpenState.Expired)

/** The envelope's width: the token, never closer than an extra-large gutter to the window's sides. */
internal fun redPacketEnvelopeWidth(window: Dp): Dp =
    minOf(FlareSizes.componentRedPacketEnvelopeWidth, window - FlareSizes.spacingXl * 2).coerceAtLeast(0.dp)

/**
 * The open-packet layer: a red envelope centred over the token scrim, with the sender, the blessing and the gold
 * open button on the flap's edge, and the close button under the envelope. Spec: RedPacketOpenSheet.
 *
 * Composing it shows it, in its own full-display dialog window; the host removes it in [onClose], which a tap on the
 * scrim, system back, Escape and the close button all reach (after the exit animation; at once under reduced
 * motion).
 *
 * - Copy: [FlareRedPacketOpenState.Finished] says the packet ran out, [FlareRedPacketOpenState.Expired] that it is
 *   past its lifetime, [FlareRedPacketOpenState.NotEligible] that this viewer cannot open it; the host's [message]
 *   (for instance "only they can open it") replaces each. Under [FlareRedPacketOpenState.Error] the message, or the
 *   kit's retry copy, shows under the blessing.
 * - Motion: while opening the button turns about its vertical axis. With animations removed (animator duration
 *   scale 0) it does not turn and says the claim is in progress instead.
 * - The host formats names and passes the avatar URL; the layer requests nothing.
 */
@Composable
fun RedPacketOpenSheet(
    senderName: String,
    blessing: String,
    onClose: () -> Unit,
    senderAvatar: String? = null,
    kindLabel: String? = null,
    state: FlareRedPacketOpenState = FlareRedPacketOpenState.Ready,
    message: String? = null,
    onOpen: (() -> Unit)? = null,
    onViewDetails: (() -> Unit)? = null,
    /** From the personal layer: a finished or expired sheet offers the details key only when true. */
    canViewDetails: Boolean = true,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val reducedMotion = flareReducedMotion()
    FlareOverlayScaffold(
        kind = FlareOverlaySurfaceKind.Modal,
        onClose = onClose,
        dismissible = true,
        scrim = colors.scrim,
        // The close button under the envelope is the layer's close control; the scrim stays unannounced.
        scrimLabel = null,
        contentAlignment = Alignment.Center,
        enter = if (reducedMotion) EnterTransition.None
        else fadeIn(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) +
            scaleIn(tween(FlareMotion.spring, easing = FlareMotion.springEasing), initialScale = 0.9f),
        exit = if (reducedMotion) ExitTransition.None
        else fadeOut(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) +
            scaleOut(tween(FlareMotion.normal, easing = FlareMotion.normalEasing), targetScale = 0.9f),
    ) { close, bounds ->
        Column(
            Modifier.semantics { paneTitle = strings.packetFromSender(senderName) },
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXl),
        ) {
            RedPacketEnvelope(
                width = redPacketEnvelopeWidth(bounds.width),
                senderName = senderName,
                senderAvatar = senderAvatar,
                blessing = blessing,
                kindLabel = kindLabel,
                state = state,
                message = message,
                reducedMotion = reducedMotion,
                onOpen = onOpen,
                onViewDetails = onViewDetails.takeIf { redPacketOpenShowsDetails(state, canViewDetails) },
            )
            FlareIconControl(label = strings.close, onClick = close) {
                Box(
                    Modifier.size(FlareSizes.iconSizeXl)
                        .border(RedPacketMetrics.ringWidth, colors.redPacketOnSurface.copy(alpha = 0.85f), CircleShape),
                    contentAlignment = Alignment.Center,
                ) { FlareIcon("close", size = FlareSizes.iconSizeSm, tint = colors.redPacketOnSurface) }
            }
        }
    }
}

@Composable
private fun RedPacketEnvelope(
    width: Dp,
    senderName: String,
    senderAvatar: String?,
    blessing: String,
    kindLabel: String?,
    state: FlareRedPacketOpenState,
    message: String?,
    reducedMotion: Boolean,
    onOpen: (() -> Unit)?,
    onViewDetails: (() -> Unit)?,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    val minHeight = FlareSizes.componentRedPacketEnvelopeMinHeight
    val flapHeight = minHeight * RedPacketMetrics.flapShare
    val coin = FlareSizes.componentRedPacketOpenButtonSize
    val curve = width * RedPacketMetrics.flapCurve
    val showsCoin = redPacketOpenShowsButton(state)
    val hint = redPacketOpenHint(state, message, strings)
    // The flap, the lower body and the button on the flap's edge. The button is placed last, so it is drawn
    // and hit above both halves it straddles.
    Layout(
        modifier = Modifier.shadow(FlareSizes.spacingXl, shape, clip = false)
            .clip(shape)
            .background(redPacketBodyBrush(colors))
            // A tap on the envelope itself never reaches the scrim behind it.
            .pointerInput(Unit) { detectTapGestures {} },
        content = {
            Column(
                Modifier.fillMaxWidth()
                    .heightIn(min = flapHeight)
                    .shadow(FlareSizes.spacingSm, RedPacketFlapShape(curve), clip = false)
                    .background(redPacketFlapBrush(colors), RedPacketFlapShape(curve))
                    .padding(
                        start = FlareSizes.spacingXl, end = FlareSizes.spacingXl, top = FlareSizes.spacing2xl * 2,
                        bottom = (if (showsCoin) coin / 2 else curve) + FlareSizes.spacingLg,
                    ),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
            ) {
                Row(
                    Modifier.semantics(mergeDescendants = true) { heading() },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                ) {
                    Avatar(userId = senderName, displayName = senderName, size = FlareSizes.iconSizeXl, avatarUrl = senderAvatar)
                    Text(
                        strings.packetFromSender(senderName), color = colors.redPacketGold, fontSize = FlareSizes.fontSize2xl,
                        fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    )
                }
                if (!kindLabel.isNullOrEmpty()) {
                    Text(
                        kindLabel, color = colors.redPacketEnd, fontSize = FlareSizes.fontSizeXs, fontWeight = FontWeight.Medium,
                        modifier = Modifier.clip(CircleShape).background(colors.redPacketGold)
                            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacing3xs),
                    )
                }
                // A long notice (a host's message, a failure) wraps at the kit's body line height, three lines at most.
                Text(
                    redPacketOpenHeadline(state, blessing, message, strings), color = colors.redPacketGold,
                    fontSize = FlareSizes.fontSize5xl, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                    lineHeight = FlareSizes.fontSize5xl * FlareSizes.lineHeightNormal,
                    maxLines = 3, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = FlareSizes.spacingSm),
                )
                if (hint != null) {
                    Text(
                        hint, color = colors.redPacketOnSurface.copy(alpha = 0.85f), fontSize = FlareSizes.fontSizeMd,
                        textAlign = TextAlign.Center, lineHeight = FlareSizes.fontSizeMd * FlareSizes.lineHeightNormal,
                        maxLines = 3, overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            Box(
                Modifier.fillMaxWidth()
                    .padding(top = if (showsCoin) coin / 2 else 0.dp, bottom = FlareSizes.spacingLg),
                contentAlignment = Alignment.BottomCenter,
            ) {
                if (onViewDetails != null) {
                    Row(
                        Modifier.heightIn(min = FlareSizes.touchTarget).clip(RoundedCornerShape(FlareSizes.radiusMd))
                            .clickable(role = Role.Button) { onViewDetails() }
                            .padding(horizontal = FlareSizes.spacingMd),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                    ) {
                        Text(strings.packetViewDetails, color = colors.redPacketGold, fontSize = FlareSizes.fontSizeLg)
                        FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.redPacketGold)
                    }
                }
            }
            if (showsCoin) {
                RedPacketOpenButton(state == FlareRedPacketOpenState.Opening, reducedMotion, onOpen)
            }
        },
    ) { measurables, _ ->
        val widthPx = width.roundToPx()
        val column = Constraints(minWidth = widthPx, maxWidth = widthPx)
        val flap = measurables[0].measure(column)
        val minLower = (minHeight.roundToPx() - flap.height).coerceAtLeast(0)
        val lower = measurables[1].measure(column.copy(minHeight = minLower))
        val button = measurables.getOrNull(2)?.measure(Constraints())
        val height = flap.height + lower.height
        layout(widthPx, height) {
            flap.place(0, 0)
            lower.place(0, flap.height)
            button?.place((widthPx - button.width) / 2, flap.height - button.height / 2)
        }
    }
}

@Composable
private fun RedPacketOpenButton(opening: Boolean, reducedMotion: Boolean, onOpen: (() -> Unit)?) {
    val colors = flareColors()
    val strings = flareStrings()
    val coin = FlareSizes.componentRedPacketOpenButtonSize
    val rotation = remember { Animatable(0f) }
    LaunchedEffect(opening, reducedMotion) {
        rotation.snapTo(0f)
        // Never loop with animations removed: every turn would finish at once.
        if (opening && !reducedMotion) {
            while (true) {
                rotation.animateTo(360f, tween(RedPacketMetrics.flipMillis, easing = LinearEasing))
                rotation.snapTo(0f)
            }
        }
    }
    val label = strings.packetOpenAction
    Box(
        Modifier.size(coin)
            .graphicsLayer {
                rotationY = rotation.value
                cameraDistance = 12f * density
            }
            .shadow(FlareSizes.spacingXs, CircleShape, clip = false)
            .clip(CircleShape)
            .background(redPacketCoinBrush(colors))
            .border(FlareSizes.spacing3xs, colors.redPacketGoldDeep, CircleShape)
            .semantics(mergeDescendants = true) {
                contentDescription = label
                // With animations removed the progress is the button's own text; otherwise it is its state.
                if (opening && !reducedMotion) stateDescription = strings.packetBusy
            }
            .clickable(enabled = !opening && onOpen != null, role = Role.Button) { if (!opening) onOpen?.invoke() },
        contentAlignment = Alignment.Center,
    ) {
        if (opening && reducedMotion) {
            // Animations removed: the claim's progress in words instead of the turning coin.
            Text(
                strings.packetBusy, color = colors.redPacketEnd, fontSize = FlareSizes.fontSizeMd,
                fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center, maxLines = 2,
                modifier = Modifier.padding(FlareSizes.spacingSm),
            )
        } else {
            Text(
                label, color = colors.redPacketEnd, fontSize = (coin.value * RedPacketMetrics.openGlyphShare).sp,
                fontWeight = FontWeight.SemiBold, fontFamily = FontFamily.Serif,
                // The button carries the name; the glyph alone would be read twice.
                modifier = Modifier.clearAndSetSemantics {},
            )
        }
    }
}
