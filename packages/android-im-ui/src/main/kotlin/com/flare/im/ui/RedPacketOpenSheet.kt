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
import androidx.compose.foundation.focusable
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
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
 * [Expired], [Refunded] and [NotEligible] say why there is nothing to open — the first three offer the details when the
 * viewer may see them, [NotEligible] never does; [Error] keeps the button for another try. [Refunded] is a packet that
 * went back to its sender (PACKET_REFUNDED, or the public status refunded), not an expired one.
 */
enum class FlareRedPacketOpenState { Ready, Opening, Finished, Expired, Refunded, NotEligible, Error }

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
        FlareRedPacketOpenState.Refunded -> custom ?: strings.packetRefundedNotice
        FlareRedPacketOpenState.NotEligible -> custom ?: strings.packetNotEligible
    }
}

/** The small line under it: only a failed claim has one, the host's [message] or the kit's retry copy. */
internal fun redPacketOpenHint(state: FlareRedPacketOpenState, message: String?, strings: FlareStrings): String? =
    if (state == FlareRedPacketOpenState.Error) message?.takeIf { it.isNotEmpty() } ?: strings.packetOpenFailed else null

/** The open button is there while there is something to open; [reviewOnError] turns an error's retry into the result key. */
internal fun redPacketOpenShowsButton(state: FlareRedPacketOpenState, reviewOnError: Boolean = false): Boolean =
    state == FlareRedPacketOpenState.Ready || state == FlareRedPacketOpenState.Opening ||
        (state == FlareRedPacketOpenState.Error && !reviewOnError)

/**
 * The details key (spec/red-packet-vectors.json `openSheet`, `openSheetRefunded`): a finished, expired or refunded
 * packet leads to its details when the personal layer says the viewer may see them ([canViewDetails]); a not-eligible
 * viewer never gets one — the server returns them no amounts or records.
 */
internal fun redPacketOpenShowsDetails(state: FlareRedPacketOpenState, canViewDetails: Boolean = true, reviewOnError: Boolean = false): Boolean =
    (reviewOnError && state == FlareRedPacketOpenState.Error) ||
        (canViewDetails && (state == FlareRedPacketOpenState.Finished || state == FlareRedPacketOpenState.Expired ||
            state == FlareRedPacketOpenState.Refunded))

/** §12.12: while the claim runs the layer stays — the scrim, back, Escape and the close key do nothing. */
internal fun redPacketOpenDismissible(state: FlareRedPacketOpenState): Boolean = state != FlareRedPacketOpenState.Opening

/** 4.5: Enter or Space on the layer opens the packet, the same as 開 (only while 開 is there and idle). */
internal fun redPacketOpenKey(key: Key): Boolean = key == Key.Enter || key == Key.NumPadEnter || key == Key.Spacebar

/** The envelope's width: the token, never closer than an extra-large gutter to the window's sides. */
internal fun redPacketEnvelopeWidth(window: Dp): Dp =
    minOf(FlareSizes.componentRedPacketEnvelopeWidth, window - FlareSizes.spacingXl * 2).coerceAtLeast(0.dp)

/**
 * The open-packet layer: a red envelope centred over the token scrim, with the sender, the blessing and the gold
 * open button on the flap's edge, and the close button under the envelope. Spec: RedPacketOpenSheet.
 *
 * Composing it shows it, in its own full-display dialog window; the host removes it in [onClose], which a tap on the
 * scrim, system back, Escape and the close button all reach (after the exit animation; at once under reduced
 * motion) — except while [FlareRedPacketOpenState.Opening], when none of them closes it (§12.12). The layer takes the
 * keyboard focus on open: Enter or Space opens the packet like 開.
 *
 * - Copy: [FlareRedPacketOpenState.Finished] says the packet ran out, [FlareRedPacketOpenState.Expired] that it is
 *   past its lifetime, [FlareRedPacketOpenState.Refunded] that it went back to its sender,
 *   [FlareRedPacketOpenState.NotEligible] that this viewer cannot open it; the host's [message]
 *   (for instance "only they can open it") replaces each. Under [FlareRedPacketOpenState.Error] the message, or the
 *   kit's retry copy, shows under the blessing.
 * - Motion: while opening the button turns about its vertical axis, a turn per 0.8 s. With animations removed
 *   (animator duration scale 0) it does not turn and spins a progress ring instead.
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
    /**
     * The claim may have landed though it failed here: the error state offers the result (onViewDetails) instead of
     * another try (4.5).
     */
    reviewOnError: Boolean = false,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val reducedMotion = flareReducedMotion()
    FlareOverlayScaffold(
        kind = FlareOverlaySurfaceKind.Modal,
        onClose = onClose,
        dismissible = redPacketOpenDismissible(state),
        scrim = colors.scrim,
        // The close key at the envelope's top trailing corner is the layer's close control; the scrim stays unannounced.
        scrimLabel = null,
        contentAlignment = Alignment.Center,
        enter = if (reducedMotion) EnterTransition.None
        else fadeIn(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) +
            scaleIn(tween(FlareMotion.spring, easing = FlareMotion.springEasing), initialScale = 0.9f),
        exit = if (reducedMotion) ExitTransition.None
        else fadeOut(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) +
            scaleOut(tween(FlareMotion.normal, easing = FlareMotion.normalEasing), targetScale = 0.9f),
    ) { close, bounds ->
        val keys = remember { FocusRequester() }
        var keysFocused by remember { mutableStateOf(false) }
        val canOpen = redPacketOpenShowsButton(state, reviewOnError) && state != FlareRedPacketOpenState.Opening && onOpen != null
        LaunchedEffect(Unit) { runCatching { keys.requestFocus() } }
        Box(
            Modifier.semantics { paneTitle = strings.packetFromSender(senderName) }
                // Only while the layer itself holds focus: a focused key (close, the result key) keeps its own Enter.
                .onFocusChanged { keysFocused = it.isFocused }
                .focusRequester(keys)
                .onKeyEvent { event ->
                    if (!keysFocused || !redPacketOpenKey(event.key)) return@onKeyEvent false
                    if (event.type == KeyEventType.KeyUp && canOpen) onOpen?.invoke()
                    true
                }
                .focusable(),
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
                onViewDetails = onViewDetails.takeIf { redPacketOpenShowsDetails(state, canViewDetails, reviewOnError) },
                reviewOnError = reviewOnError,
            )
            // 4.5: a close key of component.redPacketCloseSize at the envelope's top trailing corner (a 48 target),
            // spoken "close"; it waits while the claim runs.
            Box(Modifier.align(Alignment.TopEnd).padding(FlareSizes.spacingXs)) {
                FlareIconControl(label = strings.close, onClick = close, enabled = redPacketOpenDismissible(state)) {
                    Box(
                        Modifier.size(FlareSizes.componentRedPacketCloseSize)
                            .border(RedPacketMetrics.ringWidth, colors.redPacketOnSurface.copy(alpha = 0.85f), CircleShape),
                        contentAlignment = Alignment.Center,
                    ) { FlareIcon("close", size = FlareSizes.iconSizeSm, tint = colors.redPacketOnSurface) }
                }
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
    reviewOnError: Boolean = false,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val shape = RoundedCornerShape(FlareSizes.radius2xl)
    val minHeight = FlareSizes.componentRedPacketEnvelopeMinHeight
    val flapHeight = minHeight * RedPacketMetrics.flapShare
    val coin = FlareSizes.componentRedPacketOpenButtonSize
    val curve = width * RedPacketMetrics.flapCurve
    val showsCoin = redPacketOpenShowsButton(state, reviewOnError)
    val hint = redPacketOpenHint(state, message, strings)
    // The flap, the lower body and the button on the flap's edge. The button is placed last, so it is drawn
    // and hit above both halves it straddles.
    Layout(
        modifier = Modifier.shadow(flareShadowElevation(flareShadows().xl), shape, clip = false)
            .clip(shape)
            .background(redPacketBodyBrush(colors))
            // A tap on the envelope itself never reaches the scrim behind it.
            .pointerInput(Unit) { detectTapGestures {} },
        content = {
            Column(
                Modifier.fillMaxWidth()
                    .heightIn(min = flapHeight)
                    .shadow(flareShadowElevation(flareShadows().md), RedPacketFlapShape(curve), clip = false)
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
                    // 4.5: avatar 56, "X's red packet" 15/600.
                    Avatar(userId = senderName, displayName = senderName, size = FlareSizes.componentRedPacketDetailAvatarSize, avatarUrl = senderAvatar)
                    Text(
                        strings.packetFromSender(senderName), color = colors.redPacketGold, fontSize = FlareSizes.fontSizeXl,
                        fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    )
                }
                if (!kindLabel.isNullOrEmpty()) {
                    Text(
                        kindLabel, color = colors.redPacketEnd, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.Medium,
                        modifier = Modifier.clip(CircleShape).background(colors.redPacketGold)
                            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacing3xs),
                    )
                }
                // 4.5: the blessing (or why there is nothing to open) 20/600, two lines at most.
                Text(
                    redPacketOpenHeadline(state, blessing, message, strings), color = colors.redPacketGold,
                    fontSize = FlareSizes.fontSize4xl, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                    lineHeight = FlareSizes.fontSize4xl * FlareSizes.lineHeightNormal,
                    maxLines = 2, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = FlareSizes.spacingSm),
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
                        Text(if (reviewOnError && state == FlareRedPacketOpenState.Error) strings.packetViewResult else strings.packetViewDetails, color = colors.redPacketGold, fontSize = FlareSizes.fontSizeLg)
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
            .shadow(flareShadowElevation(flareShadows().sm), CircleShape, clip = false)
            .clip(CircleShape)
            .background(redPacketCoinBrush(colors))
            .border(FlareSizes.spacing3xs, colors.redPacketGoldDeep, CircleShape)
            .semantics(mergeDescendants = true) {
                contentDescription = label
                if (opening) stateDescription = strings.packetBusy
            }
            .clickable(enabled = !opening && onOpen != null, role = Role.Button) { if (!opening) onOpen?.invoke() },
        contentAlignment = Alignment.Center,
    ) {
        if (opening && reducedMotion) {
            // Animations removed (§7): a progress ring on the still coin instead of the turning one.
            CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeLg).clearAndSetSemantics {}, color = colors.redPacketEnd,
                strokeWidth = FlareSizes.spacing3xs)
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
