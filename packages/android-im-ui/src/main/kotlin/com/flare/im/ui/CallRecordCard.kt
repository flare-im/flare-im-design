package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp

/** A call record's conversation kind. Spec: dataTypes `FlareCallRecordScope`. */
enum class FlareCallRecordScope { Single, Group }

/** Where the recorded call is. Spec: dataTypes `FlareCallRecordState`. */
enum class FlareCallRecordState { Ringing, Ongoing, Ended }

/** Why an ended call ended. Spec: dataTypes `FlareCallEndReason`. */
enum class FlareCallEndReason { Completed, Cancelled, Declined, Missed, Busy, Unavailable, Failed }

/** The status line a call record shows, viewer-relative (spec/call-record-vectors.json `rules.status`). */
enum class FlareCallRecordStatus {
    WaitingAnswer, Incoming, GroupRinging, InCall, GroupOngoing, GroupInProgress, Duration, GroupEndedDuration,
    GroupEnded, CancelledByYou, CancelledByCaller, DeclinedByPeer, DeclinedByYou, NoAnswer, Missed, PeerBusy,
    MissedBusy, Unavailable, Failed,
}

/** The status line's tone: [Danger] for a call the viewer did not pick up. */
enum class FlareCallRecordTone { Neutral, Danger }

/** The one action a call record offers. */
enum class FlareCallRecordAction { Join, CallBack }

/** The status line for the viewer (spec/call-record-vectors.json `rules.status`). A missing [endReason] reads completed. */
fun flareCallRecordStatus(
    scope: FlareCallRecordScope,
    state: FlareCallRecordState,
    viewerIsInitiator: Boolean,
    endReason: FlareCallEndReason? = null,
    durationSeconds: Int? = null,
    joinedCount: Int? = null,
): FlareCallRecordStatus {
    val group = scope == FlareCallRecordScope.Group
    when (state) {
        FlareCallRecordState.Ringing -> return when {
            group -> FlareCallRecordStatus.GroupRinging
            viewerIsInitiator -> FlareCallRecordStatus.WaitingAnswer
            else -> FlareCallRecordStatus.Incoming
        }
        FlareCallRecordState.Ongoing -> return when {
            !group -> FlareCallRecordStatus.InCall
            (joinedCount ?: 0) >= 1 -> FlareCallRecordStatus.GroupOngoing
            else -> FlareCallRecordStatus.GroupInProgress
        }
        FlareCallRecordState.Ended -> Unit
    }
    val reason = endReason ?: FlareCallEndReason.Completed
    if (group) {
        return when (reason) {
            FlareCallEndReason.Completed ->
                if (durationSeconds == null) FlareCallRecordStatus.GroupEnded else FlareCallRecordStatus.GroupEndedDuration
            FlareCallEndReason.Unavailable -> FlareCallRecordStatus.Unavailable
            FlareCallEndReason.Failed -> FlareCallRecordStatus.Failed
            else -> FlareCallRecordStatus.GroupEnded
        }
    }
    return when (reason) {
        FlareCallEndReason.Completed -> FlareCallRecordStatus.Duration
        FlareCallEndReason.Cancelled ->
            if (viewerIsInitiator) FlareCallRecordStatus.CancelledByYou else FlareCallRecordStatus.CancelledByCaller
        FlareCallEndReason.Declined ->
            if (viewerIsInitiator) FlareCallRecordStatus.DeclinedByPeer else FlareCallRecordStatus.DeclinedByYou
        FlareCallEndReason.Missed -> if (viewerIsInitiator) FlareCallRecordStatus.NoAnswer else FlareCallRecordStatus.Missed
        FlareCallEndReason.Busy -> if (viewerIsInitiator) FlareCallRecordStatus.PeerBusy else FlareCallRecordStatus.MissedBusy
        FlareCallEndReason.Unavailable -> FlareCallRecordStatus.Unavailable
        FlareCallEndReason.Failed -> FlareCallRecordStatus.Failed
    }
}

/** A call the viewer did not pick up reads in the danger tone. */
fun flareCallRecordTone(status: FlareCallRecordStatus): FlareCallRecordTone =
    if (status == FlareCallRecordStatus.Missed) FlareCallRecordTone.Danger else FlareCallRecordTone.Neutral

/**
 * The one action the card offers, or null (spec/call-record-vectors.json `rules.action`): join a group call in
 * progress, call back after a 1:1 call; nothing while the plugin is unavailable.
 */
fun flareCallRecordAction(
    scope: FlareCallRecordScope,
    state: FlareCallRecordState,
    canJoin: Boolean,
    canCallBack: Boolean,
    disabled: Boolean = false,
): FlareCallRecordAction? = when {
    disabled -> null
    scope == FlareCallRecordScope.Group && state != FlareCallRecordState.Ended && canJoin -> FlareCallRecordAction.Join
    scope == FlareCallRecordScope.Single && state == FlareCallRecordState.Ended && canCallBack -> FlareCallRecordAction.CallBack
    else -> null
}

/** A call's length: mm:ss under an hour, h:mm:ss from an hour (spec/call-record-vectors.json `duration`). */
fun flareCallDurationLabel(seconds: Int): String {
    val total = seconds.coerceAtLeast(0)
    val hours = total / 3600
    val minutes = (total % 3600) / 60
    val rest = total % 60
    return if (hours > 0) "%d:%02d:%02d".format(hours, minutes, rest) else "%02d:%02d".format(minutes, rest)
}

/** The status line's copy in [strings]. */
fun flareCallRecordStatusText(
    strings: FlareStrings,
    status: FlareCallRecordStatus,
    joinedCount: Int? = null,
    durationSeconds: Int? = null,
): String {
    val duration = flareCallDurationLabel(durationSeconds ?: 0)
    return when (status) {
        FlareCallRecordStatus.WaitingAnswer -> strings.callRecordWaitingAnswer
        FlareCallRecordStatus.Incoming -> strings.callRecordIncoming
        FlareCallRecordStatus.GroupRinging -> strings.callRecordGroupRinging
        FlareCallRecordStatus.InCall -> strings.callRecordInCall
        FlareCallRecordStatus.GroupOngoing -> strings.callRecordGroupOngoing.replace("{n}", "${joinedCount ?: 0}")
        FlareCallRecordStatus.GroupInProgress -> strings.callRecordGroupInProgress
        FlareCallRecordStatus.Duration -> strings.callRecordDuration.replace("{duration}", duration)
        FlareCallRecordStatus.GroupEndedDuration -> strings.callRecordGroupEndedDuration.replace("{duration}", duration)
        FlareCallRecordStatus.GroupEnded -> strings.callRecordGroupEnded
        FlareCallRecordStatus.CancelledByYou -> strings.callRecordCancelledByYou
        FlareCallRecordStatus.CancelledByCaller -> strings.callRecordCancelledByCaller
        FlareCallRecordStatus.DeclinedByPeer -> strings.callRecordDeclinedByPeer
        FlareCallRecordStatus.DeclinedByYou -> strings.callRecordDeclinedByYou
        FlareCallRecordStatus.NoAnswer -> strings.callRecordNoAnswer
        FlareCallRecordStatus.Missed -> strings.callRecordMissed
        FlareCallRecordStatus.PeerBusy -> strings.callRecordPeerBusy
        FlareCallRecordStatus.MissedBusy -> strings.callRecordMissedBusy
        FlareCallRecordStatus.Unavailable -> strings.callRecordUnavailable
        FlareCallRecordStatus.Failed -> strings.callRecordFailed
    }
}

/** Test tag of the card's action button. */
const val CALL_RECORD_ACTION_TAG = "flare-call-record-action"

/**
 * The call record in the chat timeline — the media icon, one viewer-relative status line, the media name and at most
 * one action. Spec: Call/CallRecordCard (`CallRecordCard`); the rules are the shared table
 * spec/call-record-vectors.json ([flareCallRecordStatus], [flareCallRecordTone], [flareCallRecordAction]).
 *
 * Presentational only: the host maps the call plugin's record and the viewer's own facts onto these parameters and
 * owns what [onJoin] and [onCallBack] do. [canJoin] (a group call in progress the viewer is not in) and [canCallBack]
 * (calls available for this conversation) are the host's decisions; [disabled] (the plugin is unavailable) keeps the
 * record and drops the action, and [busy] shows the action in progress without taking another tap.
 *
 * The card is the message's card surface (the kit card shell, at most `componentRichCardWidth` like every card): the
 * timeline draws no bubble around it.
 */
@Composable
fun CallRecordCard(
    media: FlareCallMode,
    scope: FlareCallRecordScope,
    state: FlareCallRecordState,
    viewerIsInitiator: Boolean,
    canJoin: Boolean,
    canCallBack: Boolean,
    modifier: Modifier = Modifier,
    endReason: FlareCallEndReason? = null,
    durationSeconds: Int? = null,
    joinedCount: Int? = null,
    disabled: Boolean = false,
    busy: Boolean = false,
    onJoin: (() -> Unit)? = null,
    onCallBack: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val status = flareCallRecordStatus(scope, state, viewerIsInitiator, endReason, durationSeconds, joinedCount)
    val danger = flareCallRecordTone(status) == FlareCallRecordTone.Danger
    val action = flareCallRecordAction(scope, state, canJoin, canCallBack, disabled)
    val text = flareCallRecordStatusText(strings, status, joinedCount, durationSeconds)
    val mediaText = if (media == FlareCallMode.Video) strings.callRecordVideo else strings.callRecordVoice
    val accent = if (danger) colors.error else colors.primary
    val ink = if (danger) colors.errorText else colors.primaryText
    Box(modifier) {
        FlareMessageCardShell(card = true, quote = null) { fill ->
            Row(fill, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                Box(
                    Modifier.size(FlareSizes.controlHeightMd).clip(CircleShape).background(accent.copy(alpha = FlareOpacity.tintWeak))
                        .clearAndSetSemantics {},
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(flareIconVector(if (media == FlareCallMode.Video) "video" else "phone"), contentDescription = null, tint = ink,
                        modifier = Modifier.size(FlareSizes.iconSizeMd))
                }
                // One node for what the card says; the action names itself.
                Column(
                    Modifier.weight(1f).clearAndSetSemantics {
                        contentDescription = mediaText
                        stateDescription = text
                    },
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
                ) {
                    Text(text, color = if (danger) colors.errorText else colors.textPrimary,
                        fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.Medium,
                        lineHeight = (FlareSizes.fontSizeLg.value * FlareSizes.lineHeightSnug).sp)
                    Text(mediaText, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                if (action != null) {
                    Box(Modifier.testTag(CALL_RECORD_ACTION_TAG)) {
                        Button(
                            label = if (action == FlareCallRecordAction.Join) strings.callRecordJoin else strings.callRecordCallBack,
                            variant = FlareButtonVariant.Secondary,
                            size = FlareControlSize.Sm,
                            loading = busy,
                            onClick = if (action == FlareCallRecordAction.Join) onJoin else onCallBack,
                        )
                    }
                }
            }
        }
    }
}
