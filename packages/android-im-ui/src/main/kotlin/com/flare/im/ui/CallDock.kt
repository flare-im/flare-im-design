package com.flare.im.ui

import androidx.compose.animation.core.animateFloat
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage

/**
 * The icon-only controls of a [CallDock]: the microphone switch (on = capturing, glyph follows the
 * state) and hang up, which draws the end-call glyph rather than a rotated handset.
 */
internal fun callDockControls(strings: FlareStrings, muted: Boolean): List<FlareIconControlSpec> = listOf(
    FlareIconControlSpec("microphone", if (muted) "mic-off" else "mic", strings.microphone, checked = !muted),
    FlareIconControlSpec("hangUp", "end-call", strings.hangUp),
)

/**
 * The dock's one status line (3.5, §12.17): [callStatusText] in its short wording — the duration when connected,
 * 等待接听, 正在重连, 通话中断 (or the host's reason) — with the host's other detail in its place, as the dock has one line.
 */
internal fun callDockStatus(state: FlareCallState, mode: FlareCallMode, durationLabel: String?, detail: String?, strings: FlareStrings): String =
    callStatusText(state, mode, durationLabel, detail, strings, short = true).let { it.detail ?: it.line }

/**
 * Minimized floating call bar. Spec: Call/CallDock (`CallDock`), 3.5 of docs/plugin-experience.md: a
 * `component.callDockHeight` capsule (`radius.full`) on the call stage (never brand coloured), the kit avatar 40 (a
 * breathing `colors.call.speaking` ring while connected; still under reduced motion), the name and the status line 12
 * — [state] says which ([callDockStatus]; reconnecting with a pulsing warning dot, failed in `colors.call.errorText`)
 * and [statusDetail] takes its place — then the microphone switch and hang up, 36 each. The body returns to the call
 * ([onExpand]).
 */
@Composable
fun CallDock(
    title: String,
    avatarUrl: String? = null,
    durationLabel: String? = null,
    mode: FlareCallMode = FlareCallMode.Audio,
    muted: Boolean = false,
    onExpand: (() -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
    state: FlareCallState = FlareCallState.Connected,
    statusDetail: String? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val (microphone, hangUp) = callDockControls(strings, muted)
    val status = callDockStatus(state, mode, durationLabel, statusDetail, strings)
    val connected = state == FlareCallState.Connected
    val reducedMotion = flareReducedMotion()
    val ring = if (connected && !reducedMotion) {
        val transition = androidx.compose.animation.core.rememberInfiniteTransition(label = "dock-ring")
        transition.animateFloat(1f, 0.4f, androidx.compose.animation.core.infiniteRepeatable(
            androidx.compose.animation.core.tween(800), androidx.compose.animation.core.RepeatMode.Reverse), label = "ring").value
    } else 1f
    // The mute and hang-up discs are drawn at 36 dp inside 48 dp touch targets; the bar's padding and
    // the gaps give back the 6 dp a side the targets add, so the dock keeps its size and insets.
    Row(
        Modifier
            .heightIn(min = FlareSizes.componentCallDockHeight)
            .shadow(flareShadowElevation(flareShadows().lg), RoundedCornerShape(FlareSizes.radiusFull), clip = false)
            .clip(RoundedCornerShape(FlareSizes.radiusFull))
            .flareCallStage()
            .padding(start = FlareSizes.spacingXs, end = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            Modifier.then(
                if (onExpand != null) Modifier.clickable(role = Role.Button, onClickLabel = strings.callReturn) { onExpand() } else Modifier,
            ).semantics(mergeDescendants = true) {},
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(contentAlignment = Alignment.Center) {
                Avatar(
                    userId = title, displayName = title, size = FlareSizes.componentCallDockAvatarSize,
                    image = avatarUrl?.let { url ->
                        { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
                    },
                )
                if (connected) Box(Modifier.size(FlareSizes.componentCallDockAvatarSize + FlareSizes.spacingXs).clip(CircleShape)
                    .border(FlareSizes.spacing3xs, colors.callSpeaking.copy(alpha = ring), CircleShape))
            }
            Spacer(Modifier.width(FlareSizes.spacing2sm))
            Column {
                Text(title, color = colors.callOnStage, fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSizeLg, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.widthIn(max = FlareSizes.componentCallDockNameMaxWidth))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (state == FlareCallState.Reconnecting) {
                        CallReconnectDot()
                    } else {
                        Icon(flareIconVector(if (mode == FlareCallMode.Video) "video" else "phone"),
                            contentDescription = null, tint = colors.callOnStageSecondary, modifier = Modifier.size(FlareSizes.iconSizeSm))
                    }
                    Spacer(Modifier.width(FlareSizes.spacingXs))
                    Text(status, color = if (state == FlareCallState.Failed) colors.callErrorText else colors.callOnStageSecondary,
                        fontSize = FlareSizes.fontSizeSm, style = FlareTabularFigures, maxLines = 1)
                }
            }
            Spacer(Modifier.width(FlareSizes.spacing3xs))
            Icon(flareIconVector("expand"), contentDescription = null, tint = colors.callOnStageSecondary, modifier = Modifier.size(FlareSizes.iconSizeSm))
        }
        Spacer(Modifier.width(FlareSizes.spacingXs))
        CallRoundKey(label = microphone.label, icon = microphone.icon, size = callSmallKeySize,
            fill = if (muted) colors.callControlActive else colors.callControl,
            pressed = if (muted) colors.callControlActive else colors.callControlHover,
            tint = if (muted) colors.callOnControlActive else colors.callOnStage, iconSize = FlareSizes.iconSizeMd,
            onClick = onToggleMute, checked = microphone.checked)
        CallRoundKey(label = hangUp.label, icon = hangUp.icon, size = callSmallKeySize, fill = colors.callHangup,
            pressed = colors.callHangupPressed, iconSize = FlareSizes.iconSizeMd, onClick = onHangup)
    }
}
