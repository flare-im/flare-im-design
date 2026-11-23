package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/**
 * The host's video for [participant]'s tile. [tileContent] is asked only when the tile shows video — a video call with
 * the participant's camera on; null (no [tileContent], or no stream yet) leaves the avatar.
 */
internal fun callTileVideo(
    participant: CallParticipant,
    mode: FlareCallMode,
    tileContent: ((CallParticipant) -> (@Composable () -> Unit)?)?,
): (@Composable () -> Unit)? =
    if (mode == FlareCallMode.Video && !participant.cameraOff) tileContent?.invoke(participant) else null

/**
 * The grid of 3.4 and §12.16: 1 fills, 2 side by side, 3 two over one (centred, no empty cell), 4 two by two, 5–6 two
 * by three on a phone (three by two on a wide window), 7–9 three by three, 10–12 three by four on a phone (four by
 * three on a wide window). Rows of tile counts, in order; a short last row is centred.
 */
internal fun groupCallRows(count: Int, wide: Boolean = false): List<Int> {
    val perRow = when {
        count <= 0 -> return emptyList()
        count == 1 -> 1
        count <= 4 -> 2
        count <= 6 -> if (wide) 3 else 2
        count <= 9 -> 3
        else -> if (wide) 4 else 3
    }
    return (0 until count).chunked(perRow).map { it.size }
}

/**
 * Group (multi-party) call — participant grid + controls. Spec: Call/GroupCallView, 3.4 of docs/plugin-experience.md.
 * [state] is the same [FlareCallState] as [CallView].
 *
 * The dark call stage; tiles on `colors.call.tile` with `radius.card`, the avatar `component.callTileAvatar` while
 * there is no video, the name chip on `colors.call.chip` (mic-off before a muted name, "You" for the viewer), a
 * `colors.call.speaking` edge while speaking; tiles 4 apart on a phone, 8 on a wide window. A tap on a tile makes it the
 * main picture (and tells [onSelectParticipant]). The subtitle counts the people who joined (not those still being
 * called) beside the status; [statusDetail] follows [callStatusText] (a failed call's reason is the status, any other
 * detail goes under it); a failed call offers [recoveryText] (else `call.redial`) through [onRecover].
 * [controlsDisabled] holds every control but hang up; [encrypted] shows the lock and `call.encrypted`. The minimize key
 * shows only with [onMinimize].
 * [tileContent] renders a participant's video, asked only for a tile that shows video; the tile keeps its chrome over it.
 * [onStartVideo] draws the control bar's "switch to video" key in an audio call.
 */
@Composable
fun GroupCallView(
    participants: List<CallParticipant>,
    mode: FlareCallMode,
    state: FlareCallState,
    title: String? = null,
    durationLabel: String? = null,
    muted: Boolean = false,
    cameraOn: Boolean = true,
    speakerOn: Boolean = false,
    onHangup: (() -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onToggleCamera: (() -> Unit)? = null,
    onToggleSpeaker: (() -> Unit)? = null,
    onSwitchCamera: (() -> Unit)? = null,
    onMinimize: (() -> Unit)? = null,
    onAddMember: (() -> Unit)? = null,
    onStartVideo: (() -> Unit)? = null,
    tileContent: ((CallParticipant) -> (@Composable () -> Unit)?)? = null,
    statusDetail: String? = null,
    recoveryText: String? = null,
    onRecover: (() -> Unit)? = null,
    controlsDisabled: Boolean = false,
    encrypted: Boolean = false,
    onSelectParticipant: ((CallParticipant) -> Unit)? = null,
    devices: (@Composable () -> Unit)? = null,
    /** The failed state's close key. */
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val status = callStatusText(state, mode, durationLabel, statusDetail, strings)
    val wide = !flareCompactOverlays()
    val tileGap = if (wide) FlareSizes.spacingSm else FlareSizes.spacingXs
    Column(
        Modifier.fillMaxWidth().flareCallStage()
            // The backdrop runs under the system bars; the header starts below the status bar.
            .statusBarsPadding(),
    ) {
        // The minimize disc is drawn at 36 dp inside a 48 dp touch target; the start and top padding
        // and the gap give back the 6 dp a side the target adds, so the header keeps its layout. Without the key the
        // title starts spacing.lg in.
        Row(Modifier.fillMaxWidth().padding(start = if (onMinimize != null) FlareSizes.spacing2sm else FlareSizes.spacingLg,
            end = FlareSizes.spacingLg, top = FlareSizes.spacingSm, bottom = 0.dp),
            verticalAlignment = Alignment.CenterVertically) {
            if (onMinimize != null) {
                CallMinimizeKey(onMinimize)
                Spacer(Modifier.width(FlareSizes.spacing2xs))
            }
            Column(Modifier.weight(1f)) {
                Text(title ?: strings.groupCall, color = colors.callOnStage, fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSizeXl, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                    if (state == FlareCallState.Reconnecting) CallReconnectDot()
                    // §12.16: only the people who answered have joined.
                    Text(strings.joinedCount(participants.count { !it.calling }, status.line),
                        color = if (state == FlareCallState.Failed) colors.callErrorText else colors.callOnStageSecondary,
                        fontSize = FlareSizes.fontSizeMd, style = FlareTabularFigures)
                }
                status.detail?.let { Text(it, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeMd) }
            }
            if (encrypted) Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                Icon(flareIconVector("lock"), contentDescription = null, tint = colors.callOnStageSecondary, modifier = Modifier.size(FlareSizes.iconSizeSm))
                Text(strings.callEncrypted, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeSm)
            }
        }
        // 3.4: a tapped tile fills the stage and the others line up in a strip under it; a second tap, or that person
        // leaving, returns to the grid.
        var enlarged by remember { mutableStateOf<String?>(null) }
        val focus = participants.firstOrNull { it.id == enlarged }
        androidx.compose.runtime.LaunchedEffect(enlarged, focus == null) { if (enlarged != null && focus == null) enlarged = null }
        val select: (CallParticipant) -> Unit = { p ->
            enlarged = if (enlarged == p.id) null else p.id
            onSelectParticipant?.invoke(p)
        }
        if (focus != null) Column(
            Modifier.weight(1f).fillMaxWidth().padding(tileGap),
            verticalArrangement = Arrangement.spacedBy(tileGap),
        ) {
            Box(Modifier.weight(1f).fillMaxWidth()) { callTile(focus, mode, callTileVideo(focus, mode, tileContent), select) }
            val others = participants.filter { it.id != focus.id }
            if (others.isNotEmpty()) androidx.compose.foundation.lazy.LazyRow(
                Modifier.fillMaxWidth().height(FlareSizes.componentCallStripTileHeight),
                horizontalArrangement = Arrangement.spacedBy(tileGap),
            ) {
                items(others.size, key = { others[it].id }) { index ->
                    val p = others[index]
                    Box(Modifier.fillMaxHeight().aspectRatio(3f / 4f)) { callTile(p, mode, callTileVideo(p, mode, tileContent), select) }
                }
            }
        } else Column(
            Modifier.weight(1f).fillMaxWidth().padding(tileGap),
            verticalArrangement = Arrangement.spacedBy(tileGap),
        ) {
            var start = 0
            val rows = groupCallRows(participants.size, wide)
            val columns = rows.maxOrNull() ?: 1
            rows.forEach { inRow ->
                val row = participants.subList(start, start + inRow)
                start += inRow
                Row(Modifier.weight(1f).fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(tileGap, Alignment.CenterHorizontally)) {
                    row.forEach { p ->
                        Box(Modifier.fillMaxHeight().fillMaxWidth(1f / (columns - row.indexOf(p)).coerceAtLeast(1))) {
                            callTile(p, mode, callTileVideo(p, mode, tileContent), select)
                        }
                    }
                }
            }
        }
        Box(Modifier.fillMaxWidth().navigationBarsPadding().padding(top = FlareSizes.spacingXl, bottom = FlareSizes.spacing2xl, start = FlareSizes.spacingLg, end = FlareSizes.spacingLg),
            contentAlignment = Alignment.Center) {
            if (state == FlareCallState.Failed) {
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
            } else CallControls(muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera, onToggleSpeaker = onToggleSpeaker,
                onSwitchCamera = onSwitchCamera, onHangup = onHangup.takeUnless { state == FlareCallState.Ended },
                onAddMember = onAddMember, onStartVideo = onStartVideo,
                disabled = controlsDisabled || state == FlareCallState.Ended, devices = devices)
        }
    }
}

@Composable
private fun callTile(p: CallParticipant, mode: FlareCallMode, video: (@Composable () -> Unit)?, onSelect: ((CallParticipant) -> Unit)?) {
    val colors = flareColors()
    val strings = flareStrings()
    val shape = RoundedCornerShape(FlareSizes.radiusCard)
    Box(
        Modifier.fillMaxSize().clip(shape).background(colors.callTile)
            .border(2.dp, if (p.speaking) colors.callSpeaking else androidx.compose.ui.graphics.Color.Transparent, shape)
            .then(if (onSelect != null) Modifier.clickable(role = androidx.compose.ui.semantics.Role.Button) { onSelect(p) } else Modifier),
        contentAlignment = Alignment.Center,
    ) {
        if (video != null && !p.calling) {
            // The video fills the tile; the speaking border is drawn over the content, the name tag after it.
            Box(Modifier.fillMaxSize()) { video() }
        } else Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
            // 3.4: someone invited who has not answered: the avatar at half strength and "calling…".
            Box(Modifier.flareDimmed(if (p.calling) 0.5f else 1f)) {
                Avatar(
                    userId = p.id, displayName = p.name, size = FlareSizes.componentCallTileAvatar,
                    image = p.avatarUrl?.let { url ->
                        { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
                    },
                )
            }
            if (p.calling) Text(strings.callCalling, color = colors.callOnStageSecondary, fontSize = FlareSizes.fontSizeSm)
        }
        Row(
            Modifier.align(Alignment.BottomStart).padding(FlareSizes.spacingSm)
                .clip(RoundedCornerShape(FlareSizes.radiusSm)).background(colors.callChip)
                .padding(horizontal = 6.dp, vertical = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
        ) {
            if (p.muted) Icon(flareIconVector("mic-off"), contentDescription = strings.callPeerMuted, tint = colors.callOnStage, modifier = Modifier.size(12.dp))
            else if (p.cameraOff && mode == FlareCallMode.Video) Icon(flareIconVector("camera-off"), contentDescription = null, tint = colors.callOnStage, modifier = Modifier.size(12.dp))
            // 3.4: the viewer's own tile reads "You".
            Text(if (p.isSelf) strings.callYou else p.name, color = colors.callOnStage, fontSize = FlareSizes.fontSizeSm,
                maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}
