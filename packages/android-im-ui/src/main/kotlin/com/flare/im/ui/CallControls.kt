package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Audio vs video call — spec union `'audio' | 'video'`. */
enum class FlareCallMode { Audio, Video }

/**
 * The keys of a [CallControls] bar, in display order. Microphone, camera and speaker are switches
 * whose state is the device's (on = capturing, or playing out loud) and whose glyph follows it; flip,
 * add member and hang up are buttons. Hang up draws the end-call glyph, never a rotated handset.
 */
internal fun callControlKeys(
    strings: FlareStrings,
    muted: Boolean,
    cameraOn: Boolean,
    speakerOn: Boolean,
    mode: FlareCallMode,
    canAddMember: Boolean,
): List<FlareIconControlSpec> = buildList {
    add(FlareIconControlSpec("microphone", if (muted) "mic-off" else "mic", strings.microphone, checked = !muted))
    if (mode == FlareCallMode.Video) {
        add(FlareIconControlSpec("camera", if (cameraOn) "video" else "camera-off", strings.camera, checked = cameraOn))
        add(FlareIconControlSpec("flipCamera", "switch-camera", strings.flipCamera))
    } else {
        add(FlareIconControlSpec("speaker", if (speakerOn) "speaker" else "speaker-off", strings.speaker, checked = speakerOn))
    }
    if (canAddMember) add(FlareIconControlSpec("addMember", "person-add", strings.addMember))
    add(FlareIconControlSpec("hangUp", "end-call", strings.hangUp))
}

/**
 * Call control bar — mute, camera, speaker, flip, hang up (adapts to
 * audio/video). Spec: Call/CallControls (`CallControls`).
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
) {
    val strings = flareStrings()
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg, Alignment.CenterHorizontally),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
    ) {
        callControlKeys(strings, muted, cameraOn, speakerOn, mode, canAddMember = onAddMember != null).forEach { key ->
            when (key.id) {
                // The white disc marks the state that departs from a normal call: muted, camera off, speaker on.
                "microphone" -> CallKey(key, highlighted = muted, onToggleMute)
                "camera" -> CallKey(key, highlighted = !cameraOn, onToggleCamera)
                "flipCamera" -> CallKey(key, highlighted = false, onSwitchCamera)
                "speaker" -> CallKey(key, highlighted = speakerOn, onToggleSpeaker)
                "addMember" -> CallKey(key, highlighted = false, onAddMember)
                "hangUp" -> HangUpKey(key, onHangup)
            }
        }
    }
}

@Composable
private fun CallKey(key: FlareIconControlSpec, highlighted: Boolean, onClick: (() -> Unit)?) {
    Column(Modifier.widthIn(max = 112.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        FlareIconControl(label = key.label, onClick = onClick, checked = key.checked) {
            Box(Modifier.size(56.dp).clip(CircleShape).background(if (highlighted) Color.White else Color.White.copy(alpha = 0.16f)))
            Icon(flareIconVector(key.icon), contentDescription = null, tint = if (highlighted) Color.Black else Color.White)
        }
        // The caption repeats the control's name, which the control already announces.
        Text(key.label, color = Color.White.copy(alpha = 0.75f), fontSize = 11.sp, modifier = Modifier.clearAndSetSemantics {})
    }
}

@Composable
private fun HangUpKey(key: FlareIconControlSpec, onClick: (() -> Unit)?) {
    FlareIconControl(label = key.label, onClick = onClick) {
        Box(Modifier.size(56.dp).clip(CircleShape).background(Color(0xFFEF4444)))
        Icon(flareIconVector(key.icon), contentDescription = null, tint = Color.White)
    }
}
