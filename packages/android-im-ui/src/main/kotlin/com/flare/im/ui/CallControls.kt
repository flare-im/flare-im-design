package com.flare.im.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import android.view.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isAltPressed
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isMetaPressed
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.nativeKeyCode
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Audio vs video call — spec union `'audio' | 'video'`. */
enum class FlareCallMode { Audio, Video }

/**
 * The keys of a [CallControls] bar, in display order. Microphone, camera and speaker are switches
 * whose state is the device's (on = capturing, or playing out loud) and whose glyph follows it; flip,
 * switch to video, add member and hang up are buttons. The speaker shows in audio and video calls alike; switch to
 * video follows it in an audio call when the host can start video ([canStartVideo]). Hang up draws the end-call glyph, never a
 * rotated handset.
 */
internal fun callControlKeys(
    strings: FlareStrings,
    muted: Boolean,
    cameraOn: Boolean,
    speakerOn: Boolean,
    mode: FlareCallMode,
    canAddMember: Boolean,
    canStartVideo: Boolean = false,
    /** A phone's bar: only it flips the camera (§3.3, as Vue and Flutter); a wide window has no flip. */
    phone: Boolean = true,
): List<FlareIconControlSpec> = buildList {
    // 3.3: microphone, speaker (both modes), camera and flip (phone video), switch to video (audio), add member, hang up.
    add(FlareIconControlSpec("microphone", if (muted) "mic-off" else "mic", strings.microphone, checked = !muted))
    add(FlareIconControlSpec("speaker", if (speakerOn) "speaker" else "speaker-off", strings.speaker, checked = speakerOn))
    if (mode == FlareCallMode.Video) {
        add(FlareIconControlSpec("camera", if (cameraOn) "video" else "camera-off", strings.camera, checked = cameraOn))
        if (phone) add(FlareIconControlSpec("flipCamera", "switch-camera", strings.flipCamera))
    } else if (canStartVideo) {
        add(FlareIconControlSpec("startVideo", "video", strings.callSwitchToVideo))
    }
    if (canAddMember) add(FlareIconControlSpec("addMember", "person-add", strings.addMember))
    add(FlareIconControlSpec("hangUp", "end-call", strings.hangUp))
}

/**
 * 3.3 keyboard on a tablet's hardware keyboard: M the microphone, V the camera, Ctrl/⌘+Shift+H hang up (never a
 * single key, so a stray press does not end the call). The key id it runs, or null.
 */
internal fun callControlShortcut(keyCode: Int, ctrl: Boolean, shift: Boolean, meta: Boolean, alt: Boolean): String? = when {
    keyCode == KeyEvent.KEYCODE_H && (ctrl || meta) && shift && !alt -> "hangUp"
    ctrl || meta || alt || shift -> null
    keyCode == KeyEvent.KEYCODE_M -> "microphone"
    keyCode == KeyEvent.KEYCODE_V -> "camera"
    else -> null
}

/**
 * Call control bar — mute, camera, speaker, flip, hang up (adapts to audio/video). Spec: Call/CallControls
 * (`CallControls`), 3.3 of docs/plugin-experience.md.
 *
 * Round keys of `component.callControlSize` on `colors.call.control` (on: `colors.call.controlActive` with the
 * `onControlActive` glyph), their name under them; switches are switches for TalkBack ("microphone, off"). Hang up is
 * `colors.call.hangup` with 挂断 under it. A phone spaces keys `spacing.lg` and, with more than 4 other keys, gives
 * hang up its own row at `component.callHangupSize`; a wide window keeps one row spaced `spacing.2xl` with another
 * `spacing.2xl` before hang up, and takes M / V / Ctrl+Shift+H from a hardware keyboard. [onAddMember] and
 * [onStartVideo] draw their keys only when the host passes them. [disabled] (no media session yet) holds every key
 * but hang up at `opacity.disabled`, still named and stateful for TalkBack; without [onHangup] (an ended call) hang up
 * is held too. [devices] is the host's output route key (the system's), drawn after the speaker.
 */
@Composable
@OptIn(ExperimentalLayoutApi::class)
fun CallControls(
    muted: Boolean = false,
    cameraOn: Boolean = true,
    speakerOn: Boolean = false,
    mode: FlareCallMode = FlareCallMode.Video,
    onToggleMute: (() -> Unit)? = null,
    onToggleCamera: (() -> Unit)? = null,
    onToggleSpeaker: (() -> Unit)? = null,
    onSwitchCamera: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
    onAddMember: (() -> Unit)? = null,
    onStartVideo: (() -> Unit)? = null,
    disabled: Boolean = false,
    devices: (@Composable () -> Unit)? = null,
) {
    val strings = flareStrings()
    val wide = !flareCompactOverlays()
    val keys = callControlKeys(strings, muted, cameraOn, speakerOn, mode, canAddMember = onAddMember != null,
        canStartVideo = onStartVideo != null, phone = !wide)
    val toggles = keys.filter { it.id != "hangUp" }
    val hangUp = keys.first { it.id == "hangUp" }
    // A phone with more than 4 keys besides hang up puts hang up alone on the row under them (3.3).
    val ownRow = !wide && toggles.size + (if (devices != null) 1 else 0) > 4
    val gap = if (wide) FlareSizes.spacing2xl else FlareSizes.spacingLg
    val toggleRow: @Composable () -> Unit = {
        toggles.forEach { key ->
            when (key.id) {
                // The active disc marks the state that departs from a normal call: muted, camera off, speaker on.
                "microphone" -> CallKey(key, highlighted = muted, onToggleMute, disabled)
                "camera" -> CallKey(key, highlighted = !cameraOn, onToggleCamera, disabled)
                "flipCamera" -> CallKey(key, highlighted = false, onSwitchCamera, disabled)
                "speaker" -> {
                    CallKey(key, highlighted = speakerOn, onToggleSpeaker, disabled)
                    devices?.let { Box(Modifier.flareDimmed(if (disabled) FlareOpacity.disabled else 1f)) { it() } }
                }
                "startVideo" -> CallKey(key, highlighted = false, onStartVideo, disabled)
                "addMember" -> CallKey(key, highlighted = false, onAddMember, disabled)
            }
        }
    }
    val shortcuts = if (!wide) Modifier else Modifier.onPreviewKeyEvent { event ->
        if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
        val run = when (callControlShortcut(event.key.nativeKeyCode, event.isCtrlPressed, event.isShiftPressed, event.isMetaPressed, event.isAltPressed)) {
            "microphone" -> onToggleMute.takeUnless { disabled }
            "camera" -> onToggleCamera.takeIf { !disabled && mode == FlareCallMode.Video }
            "hangUp" -> onHangup
            else -> null
        }
        run?.invoke()
        run != null
    }
    Column(shortcuts, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(gap, Alignment.CenterHorizontally),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
        ) {
            toggleRow()
            if (!ownRow) HangUpKey(hangUp, onHangup, FlareSizes.componentCallControlSize,
                if (wide) Modifier.padding(start = FlareSizes.spacing2xl) else Modifier)
        }
        if (ownRow) HangUpKey(hangUp, onHangup, FlareSizes.componentCallHangupSize)
    }
}

@Composable
private fun CallKey(key: FlareIconControlSpec, highlighted: Boolean, onClick: (() -> Unit)?, disabled: Boolean = false) {
    val colors = flareColors()
    Column(
        Modifier.widthIn(max = 112.dp).flareDimmed(if (disabled) FlareOpacity.disabled else 1f),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        // A held key keeps its name, role and state, so TalkBack reads "microphone, on, disabled" rather than nothing.
        CallRoundKey(
            label = key.label, icon = key.icon, size = FlareSizes.componentCallControlSize,
            fill = if (highlighted) colors.callControlActive else colors.callControl,
            pressed = if (highlighted) colors.callControlActive else colors.callControlHover,
            tint = if (highlighted) colors.callOnControlActive else colors.callOnStage,
            onClick = onClick ?: {}, enabled = !disabled && onClick != null, checked = key.checked,
        )
        // The caption repeats the control's name, which the control already announces.
        Text(key.label, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeSm, modifier = Modifier.clearAndSetSemantics {})
    }
}

/** Hang up with 挂断 under it (§12.17); without [onClick] (the call ended) it is held at `opacity.disabled`. */
@Composable
private fun HangUpKey(key: FlareIconControlSpec, onClick: (() -> Unit)?, size: Dp, modifier: Modifier = Modifier) {
    val colors = flareColors()
    Column(
        modifier.flareDimmed(if (onClick == null) FlareOpacity.disabled else 1f),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        CallRoundKey(label = key.label, icon = key.icon, size = size, fill = colors.callHangup, pressed = colors.callHangupPressed,
            onClick = onClick ?: {}, enabled = onClick != null)
        Text(key.label, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeSm, modifier = Modifier.clearAndSetSemantics {})
    }
}

/** The small round keys of the call chrome (minimize, expand, the dock's keys): `component.callDockKeySize`. */
internal val callSmallKeySize: Dp get() = FlareSizes.componentCallDockKeySize

/**
 * A round call key (3.0, 3.2, §12.10): a disc of [size] in [fill] that turns [pressed] while pressed or hovered and
 * scales to 0.98 while pressed (`transitions.fast`; colour only under reduced motion), with a 2-wide `borderSelected` ring 3
 * outside the circle while it has keyboard focus. [label], [checked] and [enabled] are what TalkBack reads.
 */
@Composable
internal fun CallRoundKey(
    label: String,
    icon: String,
    size: Dp,
    fill: Color,
    pressed: Color,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    checked: Boolean? = null,
    tint: Color = flareColors().callOnStage,
    iconSize: Dp = FlareSizes.iconSizeLg,
) {
    val colors = flareColors()
    val source = remember { MutableInteractionSource() }
    val down by source.collectIsPressedAsState()
    val hovered by source.collectIsHoveredAsState()
    val focused by source.collectIsFocusedAsState()
    val reducedMotion = flareReducedMotion()
    val disc by animateColorAsState(if (enabled && (down || hovered)) pressed else fill,
        tween(FlareMotion.fast, easing = FlareMotion.fastEasing), label = "call-key-fill")
    val scale by animateFloatAsState(if (enabled && down && !reducedMotion) FlareSizes.componentPressScale else 1f,
        tween(FlareMotion.fast, easing = FlareMotion.fastEasing), label = "call-key-scale")
    // 3.2: the ring is `component.focusRingWidth` wide and stands `component.focusRingOffset` off the disc.
    val ringInset = size / 2 + FlareSizes.componentFocusRingOffset
    FlareIconControl(
        label = label, onClick = onClick, enabled = enabled, checked = checked, minSize = maxOf(size, FlareSizes.touchTarget),
        interactionSource = source,
        // Drawn ahead of the control's clip, so the ring follows the disc outside it.
        modifier = modifier.drawBehind {
            if (focused) {
                val width = FlareSizes.componentFocusRingWidth.toPx()
                drawCircle(colors.borderSelected, radius = ringInset.toPx() + width / 2, style = Stroke(width))
            }
        },
    ) {
        Box(Modifier.size(size).graphicsLayer { scaleX = scale; scaleY = scale }.clip(CircleShape).background(disc))
        Icon(flareIconVector(icon), contentDescription = null, tint = tint, modifier = Modifier.size(iconSize))
    }
}

/** The collapse key that shrinks a call into its dock (3.1), read 最小化. */
@Composable
internal fun CallMinimizeKey(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val colors = flareColors()
    CallRoundKey(label = flareStrings().callMinimize, icon = "collapse", size = callSmallKeySize, fill = colors.callControl,
        pressed = colors.callControlHover, onClick = onClick, modifier = modifier, iconSize = FlareSizes.iconSizeMd)
}

/** Reconnecting's `color.warning` dot (3.3, 3.5): it pulses, and holds still under reduced motion. */
@Composable
internal fun CallReconnectDot() {
    val colors = flareColors()
    val pulse = if (flareReducedMotion()) 1f else rememberInfiniteTransition(label = "call-reconnect")
        .animateFloat(1f, 0.35f, infiniteRepeatable(tween(800), RepeatMode.Reverse), label = "pulse").value
    Box(Modifier.size(FlareSizes.spacingSm).graphicsLayer { alpha = pulse }.clip(CircleShape).background(colors.warning))
}
