package com.flare.im.ui

import androidx.compose.animation.core.animateFloat
import androidx.compose.foundation.background
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.TextButton
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.offset
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/** Call state — spec union `'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed' | 'ended'`. */
enum class FlareCallState { Calling, Ringing, Connected, Reconnecting, Failed, Ended }

/**
 * The call stage (3.0 of docs/plugin-experience.md): `colors.call.stage` with `colors.call.stageTint` fading out over the
 * top 40%, the same in light and dark themes; every call surface draws on it.
 */
@Composable
internal fun Modifier.flareCallStage(): Modifier {
    val colors = flareColors()
    return background(colors.callStage).drawBehind {
        drawRect(androidx.compose.ui.graphics.Brush.verticalGradient(listOf(colors.callStageTint, Color.Transparent), endY = size.height * 0.4f),
            size = androidx.compose.ui.geometry.Size(size.width, size.height * 0.4f))
    }
}

/**
 * What [CallView] draws around the peer, without a UI: whether the avatar is shown (not while the peer's video
 * covers it), the mic-off badge's TalkBack name ([mutedLabel], null when there is no badge), whether the speaking
 * ring goes round the avatar, whether the host's own camera is drawn as the picture-in-picture, and the peer block's
 * top inset ([peerTop]: below the preview while it is drawn, inside the status bar, so the preview never covers the
 * avatar on a narrow screen).
 */
internal data class CallViewPeerMarks(
    val avatar: Boolean,
    val mutedLabel: String?,
    val speakingRing: Boolean,
    val localPreview: Boolean,
    val peerTop: Dp,
)

internal fun callViewPeerMarks(
    strings: FlareStrings,
    mode: FlareCallMode,
    hasVideo: Boolean,
    hasLocalVideo: Boolean,
    peerMuted: Boolean,
    peerSpeaking: Boolean,
): CallViewPeerMarks {
    val avatar = mode == FlareCallMode.Audio || !hasVideo
    val localPreview = mode == FlareCallMode.Video && hasLocalVideo
    return CallViewPeerMarks(
        avatar = avatar,
        mutedLabel = if (peerMuted) strings.callPeerMuted else null,
        speakingRing = avatar && peerSpeaking && !peerMuted,
        localPreview = localPreview,
        peerTop = if (localPreview) FlareSizes.spacingLg * 2 + FlareSizes.componentCallPreviewWidth * 16 / 9 else 72.dp,
    )
}

/**
 * In-call screen — peer video or avatar, state, duration, with an overlaid [CallControls]. Spec: Call/CallView
 * (`CallView`), 3.3 of docs/plugin-experience.md. Video rendering is injected by the host via [videoContent] (the
 * package bundles no RTC engine).
 *
 * The dark call stage in both themes; the peer's kit [Avatar] (`component.callAvatarSize`, a tablet window
 * `component.callAvatarSizeWindow`) with the speaking ring (`colors.call.speaking`) and a breathing ring while calling
 * or ringing (still under reduced motion); the name 24/600 (a window 20/600) and the status line 15 (tabular).
 * Reconnecting leads the status with a pulsing warning dot. [statusDetail] follows [callStatusText]: a failed call's
 * reason is the status line, any other detail goes under it. Failed swaps the controls for close ([onClose]) and call
 * again ([onRecover], [recoveryText] else `call.redial`). Ended disables every control, hang up included, and reads
 * "call ended · duration". [controlsDisabled] (no media session yet) holds every control but hang up.
 * [encrypted] shows the lock and `call.encrypted` in the top bar. [onMinimize] draws the collapse control at the top
 * start corner; the host shrinks the call into its [CallDock]. [peerMuted] adds mic-off 14 and 对方已静音 after the
 * status line.
 * [localVideoContent] is the host's own camera, a picture-in-picture at the top end corner in video mode.
 * [onStartVideo] draws "switch to video" in an audio call. [devices] is the host's output route key.
 */
@Composable
fun CallView(
    peerName: String,
    mode: FlareCallMode,
    state: FlareCallState,
    durationLabel: String? = null,
    peerAvatarUrl: String? = null,
    muted: Boolean = false,
    cameraOn: Boolean = true,
    speakerOn: Boolean = false,
    peerMuted: Boolean = false,
    peerSpeaking: Boolean = false,
    videoContent: (@Composable () -> Unit)? = null,
    localVideoContent: (@Composable () -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onToggleCamera: (() -> Unit)? = null,
    onToggleSpeaker: (() -> Unit)? = null,
    onSwitchCamera: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
    statusDetail: String? = null,
    recoveryText: String? = null,
    onRecover: (() -> Unit)? = null,
    onMinimize: (() -> Unit)? = null,
    onStartVideo: (() -> Unit)? = null,
    controlsDisabled: Boolean = false,
    encrypted: Boolean = false,
    /** The failed state's close key. */
    onClose: (() -> Unit)? = null,
    devices: (@Composable () -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val marks = callViewPeerMarks(strings, mode, hasVideo = videoContent != null,
        hasLocalVideo = localVideoContent != null, peerMuted = peerMuted, peerSpeaking = peerSpeaking)
    val reducedMotion = flareReducedMotion()
    val waiting = state == FlareCallState.Calling || state == FlareCallState.Ringing
    val breath = if (waiting && !reducedMotion) {
        val transition = androidx.compose.animation.core.rememberInfiniteTransition(label = "call-ring")
        transition.animateFloat(0.2f, 0.05f, androidx.compose.animation.core.infiniteRepeatable(
            androidx.compose.animation.core.tween(800), androidx.compose.animation.core.RepeatMode.Reverse), label = "ring").value
    } else 0.2f
    // 3.3: a connected video call shows the peer's name and status in the top bar, which fades after 4 s without a
    // touch (never under reduced motion); a touch anywhere brings it back.
    val videoLive = mode == FlareCallMode.Video && videoContent != null && state == FlareCallState.Connected
    var touches by remember { mutableIntStateOf(0) }
    var barShown by remember { mutableStateOf(true) }
    LaunchedEffect(videoLive, touches, reducedMotion) {
        barShown = true
        if (videoLive && !reducedMotion) { kotlinx.coroutines.delay(CALL_TOP_BAR_FADE_MS); barShown = false }
    }
    val barAlpha by androidx.compose.animation.core.animateFloatAsState(if (barShown) 1f else 0f, label = "call-top-bar")
    // A tap on the preview swaps the two pictures (3.3).
    var swapped by remember { mutableStateOf(false) }
    val showSwap = swapped && localVideoContent != null && videoContent != null
    val stagePicture = if (showSwap) localVideoContent else videoContent
    val previewPicture = if (showSwap) videoContent else localVideoContent
    val statusText = callStatusText(state, mode, durationLabel, statusDetail, strings)
    // A tablet's floating window draws the peer smaller (3.3): avatar callAvatarSizeWindow, name 20/600.
    val window = !flareCompactOverlays()
    val avatarSize = if (window) FlareSizes.componentCallAvatarSizeWindow else FlareSizes.componentCallAvatarSize
    val status: @Composable (Boolean) -> Unit = { compact ->
        val fontSize = if (compact) FlareSizes.fontSizeMd else FlareSizes.fontSizeXl
        Row(
            Modifier.semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite },
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            if (state == FlareCallState.Reconnecting) CallReconnectDot()
            // §12.17: a failure on the stage reads in call.errorText.
            Text(statusText.line, color = if (state == FlareCallState.Failed) colors.callErrorText else colors.callOnStageSecondary,
                fontSize = fontSize, style = FlareTabularFigures,
                textAlign = TextAlign.Center, modifier = Modifier.weight(1f, fill = false))
            marks.mutedLabel?.let { label ->
                // §12.17: the peer's mute is mic-off 14 and its words after the status line, not a badge by the name.
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                    Icon(flareIconVector("mic-off"), contentDescription = null, tint = colors.callOnStageSecondary, modifier = Modifier.size(FlareSizes.iconSizeXs))
                    Text(label, color = colors.callOnStageSecondary, fontSize = fontSize, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
    }
    val controls: @Composable () -> Unit = {
        if (state == FlareCallState.Failed) {
            // 3.3: a failed call offers close and call again where the controls were.
            // Phone: two equal keys across; a window: each component.callFailedActionWidth, centred.
            val wide = !flareCompactOverlays()
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd, Alignment.CenterHorizontally)) {
                Box(if (wide) Modifier.width(FlareSizes.componentCallFailedActionWidth) else Modifier.weight(1f)) {
                    Button(label = strings.close, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Lg, block = true,
                        disabled = onClose == null && onHangup == null, onClick = onClose ?: onHangup)
                }
                Box(if (wide) Modifier.width(FlareSizes.componentCallFailedActionWidth) else Modifier.weight(1f)) {
                    Button(label = recoveryText ?: strings.callRedial, size = FlareControlSize.Lg, block = true,
                        icon = if (mode == FlareCallMode.Video) "video" else "phone", disabled = onRecover == null, onClick = onRecover)
                }
            }
        } else {
            CallControls(
                muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera,
                onToggleSpeaker = onToggleSpeaker, onSwitchCamera = onSwitchCamera,
                onHangup = onHangup.takeUnless { state == FlareCallState.Ended },
                onStartVideo = onStartVideo,
                disabled = controlsDisabled || state == FlareCallState.Ended,
                devices = devices,
            )
        }
    }
    Box(
        Modifier.fillMaxSize().flareCallStage().pointerInput(Unit) {
            awaitPointerEventScope {
                while (true) {
                    val event = awaitPointerEvent(androidx.compose.ui.input.pointer.PointerEventPass.Initial)
                    if (event.changes.any { it.pressed && !it.previousPressed }) touches++
                }
            }
        },
    ) {
        if (mode == FlareCallMode.Video && stagePicture != null) {
            stagePicture()
            // Reconnecting keeps the last frame, dimmed by 40%.
            if (state == FlareCallState.Reconnecting) Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = FlareOpacity.dim)))
        }

        if (videoLive) {
            Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().navigationBarsPadding()
                .padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, bottom = FlareSizes.spacing2xl)) { controls() }
        } else androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxSize()) {
        val viewport = maxHeight
        Column(
            // At least the stage's height, so the controls sit at its foot (3.3: spacing.2xl + the safe area off the bottom);
            // still scrolls when the peer block and the controls do not fit (a short landscape window).
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).heightIn(min = viewport)
                // The preview sits under the status bar, so the peer block measures from there while it is drawn.
                .then(if (marks.localPreview) Modifier.statusBarsPadding() else Modifier)
                .padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = marks.peerTop, bottom = FlareSizes.spacing2xl)
                .navigationBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (marks.avatar) {
                Box(
                    Modifier.size(avatarSize)
                        // Drawn ahead of the avatar, so the rings sit just outside it and leave the layout alone.
                        .drawBehind {
                            if (marks.speakingRing) {
                                val ring = 3.dp.toPx()
                                drawCircle(colors.callSpeaking, radius = size.minDimension / 2 + ring / 2, style = Stroke(ring))
                            } else if (waiting) {
                                val ring = 2.dp.toPx()
                                drawCircle(colors.callOnStage.copy(alpha = breath), radius = size.minDimension / 2 + ring * 2, style = Stroke(ring))
                            }
                        },
                    contentAlignment = Alignment.Center,
                ) {
                    Avatar(userId = peerName, displayName = peerName, size = avatarSize, avatarUrl = peerAvatarUrl)
                }
                Spacer(Modifier.height(FlareSizes.spacingMd))
            }
            Text(peerName, color = colors.callOnStage, fontSize = if (window) FlareSizes.fontSize4xl else FlareSizes.fontSize5xl,
                fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center, modifier = Modifier.semantics { heading() })
            Spacer(Modifier.height(FlareSizes.spacingXs))
            status(false)
            statusText.detail?.let { detail ->
                Spacer(Modifier.height(FlareSizes.spacingXs))
                Text(detail, color = colors.callOnStage, textAlign = TextAlign.Center)
            }
            Spacer(Modifier.height(32.dp))
            Spacer(Modifier.weight(1f))
            controls()
        }
        }
        if (marks.localPreview && previewPicture != null) {
            CallPreview(strings = strings, onSwap = if (videoContent != null) ({ swapped = !swapped }) else null) { previewPicture() }
        }
        // The top bar: minimize at the start; on a live video the name and status (and the encryption note) in the middle.
        Box(Modifier.fillMaxWidth().align(Alignment.TopCenter).statusBarsPadding().flareDimmed(barAlpha)) {
            Column(
                Modifier.align(Alignment.TopCenter).padding(top = FlareSizes.spacingLg, start = 64.dp, end = 64.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
            ) {
                if (videoLive) {
                    Text(peerName, color = colors.callOnStage, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold,
                        maxLines = 1, modifier = Modifier.semantics { heading() })
                    status(true)
                }
                if (encrypted) Row(
                    Modifier.semantics(mergeDescendants = true) {},
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
                ) {
                    Icon(flareIconVector("lock"), contentDescription = null, tint = colors.callOnStageSecondary, modifier = Modifier.size(FlareSizes.iconSizeSm))
                    Text(strings.callEncrypted, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeSm)
                }
            }
            if (onMinimize != null) {
                // The disc is drawn at 36 dp inside a 48 dp touch target; the padding gives back the 6 dp a side the
                // target adds, so the disc sits spacingLg from the edges.
                CallMinimizeKey(onMinimize, Modifier.align(Alignment.TopStart).padding(start = FlareSizes.spacing2sm, top = FlareSizes.spacing2sm))
            }
        }
    }
}

/** How long a live video's top bar stays without a touch before it fades (3.3). */
internal const val CALL_TOP_BAR_FADE_MS = 4_000L

/**
 * Where the preview snaps after a drag (3.3): the corner nearest to where its centre was let go, as
 * 0 top start, 1 top end, 2 bottom start, 3 bottom end. Sizes are in pixels of the stage less its insets.
 */
internal fun callPreviewCorner(corner: Int, dragX: Float, dragY: Float, width: Float, height: Float, previewWidth: Float, previewHeight: Float, margin: Float): Int {
    val start = corner == 0 || corner == 2
    val top = corner == 0 || corner == 1
    val x = (if (start) margin + previewWidth / 2 else width - margin - previewWidth / 2) + dragX
    val y = (if (top) margin + previewHeight / 2 else height - margin - previewHeight / 2) + dragY
    return (if (y < height / 2) 0 else 2) + (if (x < width / 2) 0 else 1)
}

/**
 * The local preview (3.3): `component.callPreviewWidth` wide, 9:16, `radius.lg`, `spacing.lg` from the edges at the top
 * end corner; dragged, it snaps to the nearest corner; a tap swaps the two pictures ([onSwap]).
 */
@Composable
private fun CallPreview(strings: FlareStrings, onSwap: (() -> Unit)?, content: @Composable () -> Unit) {
    val colors = flareColors()
    val density = androidx.compose.ui.platform.LocalDensity.current
    val swapLabel = strings.callSwapVideo
    var corner by remember { mutableIntStateOf(1) }
    var drag by remember { mutableStateOf(androidx.compose.ui.geometry.Offset.Zero) }
    androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
        val margin = FlareSizes.spacingLg
        val previewWidth = FlareSizes.componentCallPreviewWidth
        val previewHeight = previewWidth * 16 / 9
        val align = when (corner) {
            0 -> Alignment.TopStart
            1 -> Alignment.TopEnd
            2 -> Alignment.BottomStart
            else -> Alignment.BottomEnd
        }
        Box(
            Modifier.align(align).padding(margin)
                .offset { androidx.compose.ui.unit.IntOffset(drag.x.toInt(), drag.y.toInt()) }
                .width(previewWidth).aspectRatio(9f / 16f)
                .clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.callTile)
                .pointerInput(Unit) {
                    detectDragGestures(
                        onDragEnd = {
                            with(density) {
                                corner = callPreviewCorner(corner, drag.x, drag.y, maxWidth.toPx(), maxHeight.toPx(),
                                    previewWidth.toPx(), previewHeight.toPx(), margin.toPx())
                            }
                            drag = androidx.compose.ui.geometry.Offset.Zero
                        },
                        onDragCancel = { drag = androidx.compose.ui.geometry.Offset.Zero },
                    ) { change, amount -> change.consume(); drag += amount }
                }
                .then(if (onSwap != null) Modifier.clickable(role = androidx.compose.ui.semantics.Role.Button, onClickLabel = swapLabel, onClick = onSwap)
                    .semantics { contentDescription = swapLabel } else Modifier),
        ) { content() }
    }
}

/** What a call says about its state (3.3–3.5): the status line, and the host's detail drawn under it. */
internal data class CallStatusText(val line: String, val detail: String?)

/**
 * The one statusDetail rule of [CallView], [GroupCallView] and [CallDock]. Failed: the host's reason is the status
 * line (else `call.failed`; the dock's 通话中断). Any other state: the state's own line, and the host's [detail] under
 * it when it says something else. [short] is the dock's wording (§12.17): 等待接听, 正在重连, 通话中断. A one-line
 * surface (the dock) draws the detail in place of the line.
 */
internal fun callStatusText(
    state: FlareCallState,
    mode: FlareCallMode,
    duration: String?,
    detail: String?,
    strings: FlareStrings,
    short: Boolean = false,
): CallStatusText {
    val host = detail?.trim()?.takeIf { it.isNotEmpty() }
    val line = when {
        state == FlareCallState.Failed -> host ?: if (short) strings.callInterrupted else strings.callFailed
        short && (state == FlareCallState.Calling || state == FlareCallState.Ringing) -> strings.callDockWaiting
        short && state == FlareCallState.Reconnecting -> strings.callReconnectingShort
        else -> callStatusLabel(state, mode, duration, strings)
    }
    return CallStatusText(line, host?.takeIf { state != FlareCallState.Failed && it != line })
}

/** The status line of a call (3.3): calling, ringing, the duration, reconnecting, failed, ended · duration. */
internal fun callStatusLabel(
    state: FlareCallState,
    mode: FlareCallMode,
    duration: String?,
    strings: FlareStrings,
): String = when (state) {
    FlareCallState.Calling ->
        if (mode == FlareCallMode.Video) strings.callWaitingAnswer else strings.callCalling
    FlareCallState.Ringing -> strings.callRinging
    FlareCallState.Reconnecting -> strings.callReconnecting
    FlareCallState.Failed -> strings.callFailed
    FlareCallState.Connected -> duration ?: strings.callConnected
    FlareCallState.Ended -> duration?.let { strings.callEnded.replace("{duration}", it) }
        ?: strings.callEnded.substringBefore(" ·").substringBefore("·").trim()
}
