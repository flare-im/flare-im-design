package com.flare.im.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** How an incoming call shows (IncomingCall `presentation`): the phone's full screen, or the wide window's banner. */
enum class FlareIncomingCallPresentation { Fullscreen, Banner }

/**
 * Incoming call / invite — caller avatar and name, audio or video, accept and reject. Spec: Call/IncomingCall
 * (`IncomingCall`), 3.2 of docs/plugin-experience.md.
 *
 * [FlareIncomingCallPresentation.Fullscreen] (phones): the dark call stage, the kit [Avatar] 96 with a breathing ring
 * (still under reduced motion), the name 24/600 and the invitation 15; reject and accept 64 (`colors.call.hangup`,
 * `colors.call.accept`) centred on the quarter lines; a video call also offers "answer with audio" ([onAcceptAudio])
 * between them. [FlareIncomingCallPresentation.Banner] (a wide window): a non-modal stage-coloured strip
 * (`component.callIncomingBannerWidth` × 88) with the avatar 48, the name and the invitation, and decline and accept
 * at the medium control height, `spacing.sm` apart — it never takes focus from the window's work. Every round key
 * darkens while pressed (`hangupPressed`, `acceptPressed`) and rings in `borderSelected` under keyboard focus. The caller and the invitation are announced politely when it appears; the
 * full screen moves focus to accept.
 */
@Composable
fun IncomingCall(
    callerName: String,
    mode: FlareCallMode,
    callerAvatarUrl: String? = null,
    onAccept: (() -> Unit)? = null,
    onReject: (() -> Unit)? = null,
    onAcceptAudio: (() -> Unit)? = null,
    presentation: FlareIncomingCallPresentation = FlareIncomingCallPresentation.Fullscreen,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val invitation = if (mode == FlareCallMode.Video) strings.incomingVideoCall else strings.incomingVoiceCall
    val acceptIcon = if (mode == FlareCallMode.Video) "video" else "phone"
    if (presentation == FlareIncomingCallPresentation.Banner) {
        Row(
            Modifier.width(FlareSizes.componentCallIncomingBannerWidth).height(FlareSizes.componentCallIncomingBannerHeight)
                .shadow(flareShadowElevation(flareShadows().lg), RoundedCornerShape(FlareSizes.radiusXl), clip = false)
                .clip(RoundedCornerShape(FlareSizes.radiusXl)).flareCallStage()
                .padding(horizontal = FlareSizes.spacingLg)
                .semantics { liveRegion = LiveRegionMode.Polite },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
        ) {
            Avatar(userId = callerName, displayName = callerName, size = FlareSizes.componentCallIncomingBannerAvatar, avatarUrl = callerAvatarUrl)
            Column(Modifier.weight(1f).semantics(mergeDescendants = true) {}) {
                Text(callerName, color = colors.callOnStage, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(invitation, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeMd, maxLines = 1)
            }
            // The discs stand spacing.sm apart; each touch target reaches past its disc into the gap and the padding.
            val dense = Modifier.flareTouchTargetBeyond(FlareSizes.controlHeightMd)
            Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                IncomingKey("end-call", strings.callDecline, colors.callHangup, colors.callHangupPressed, FlareSizes.controlHeightMd, onReject,
                    caption = false, modifier = dense)
                IncomingKey(acceptIcon, strings.accept, colors.callAccept, colors.callAcceptPressed, FlareSizes.controlHeightMd, onAccept,
                    caption = false, modifier = dense)
            }
        }
        return
    }
    val acceptFocus = remember { FocusRequester() }
    LaunchedEffect(Unit) { runCatching { acceptFocus.requestFocus() } }
    val reducedMotion = flareReducedMotion()
    val breath = if (reducedMotion) 0.2f else {
        val transition = rememberInfiniteTransition(label = "incoming-ring")
        transition.animateFloat(0.2f, 0.05f, infiniteRepeatable(tween(800), RepeatMode.Reverse), label = "ring").value
    }
    BoxWithConstraints(Modifier.fillMaxSize().flareCallStage().statusBarsPadding().navigationBarsPadding()) {
        Column(
            Modifier.fillMaxWidth().padding(top = maxHeight * 0.22f)
                .semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite },
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                Modifier.size(FlareSizes.componentCallAvatarSize).drawBehind {
                    val ring = 2.dp.toPx()
                    drawCircle(colors.callOnStage.copy(alpha = breath), radius = size.minDimension / 2 + ring * 2, style = Stroke(ring))
                },
                contentAlignment = Alignment.Center,
            ) { Avatar(userId = callerName, displayName = callerName, size = FlareSizes.componentCallAvatarSize, avatarUrl = callerAvatarUrl) }
            Spacer(Modifier.height(FlareSizes.spacingLg))
            Text(callerName, color = colors.callOnStage, fontSize = FlareSizes.fontSize5xl, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Text(invitation, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeXl)
        }
        // The two keys sit on the quarter lines, 64 above the bottom; a video call's audio answer sits between them.
        Column(
            Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(bottom = 64.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xl),
        ) {
            if (mode == FlareCallMode.Video && onAcceptAudio != null) {
                IconButton(icon = "phone", contentDescription = strings.callAnswerAudio, size = FlareControlSize.Md,
                    tint = colors.callOnStage, background = colors.callControl, onClick = onAcceptAudio)
            }
            Row(Modifier.fillMaxWidth()) {
                Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                    IncomingKey("end-call", strings.callDecline, colors.callHangup, colors.callHangupPressed, FlareSizes.componentCallHangupSize, onReject)
                }
                Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                    IncomingKey(acceptIcon, strings.accept, colors.callAccept, colors.callAcceptPressed, FlareSizes.componentCallHangupSize, onAccept,
                        modifier = Modifier.focusRequester(acceptFocus))
                }
            }
        }
    }
}

@Composable
private fun IncomingKey(icon: String, label: String, fill: Color, pressed: Color, size: Dp, onClick: (() -> Unit)?, caption: Boolean = true, modifier: Modifier = Modifier) {
    val colors = flareColors()
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        CallRoundKey(label = label, icon = icon, size = size, fill = fill, pressed = pressed, onClick = onClick, modifier = modifier)
        if (caption) {
            Spacer(Modifier.height(FlareSizes.spacingSm))
            // The caption repeats the button's name, which the button already announces.
            Text(label, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeSm, modifier = Modifier.clearAndSetSemantics {})
        }
    }
}
