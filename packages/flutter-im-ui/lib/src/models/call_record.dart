import '../tokens/flare_strings.dart';

/// A call record's conversation kind. Spec: dataTypes `FlareCallRecordScope`.
enum FlareCallRecordScope { single, group }

/// Where the recorded call is. Spec: dataTypes `FlareCallRecordState`.
enum FlareCallRecordState { ringing, ongoing, ended }

/// Why an ended call ended. Spec: dataTypes `FlareCallEndReason`.
enum FlareCallEndReason {
  completed,
  cancelled,
  declined,
  missed,
  busy,
  unavailable,
  failed,
}

/// The status line a call record shows, viewer-relative
/// (`spec/call-record-vectors.json` → rules.status).
enum FlareCallRecordStatus {
  waitingAnswer,
  incoming,
  groupRinging,
  inCall,
  groupOngoing,
  groupInProgress,
  duration,
  groupEndedDuration,
  groupEnded,
  cancelledByYou,
  cancelledByCaller,
  declinedByPeer,
  declinedByYou,
  noAnswer,
  missed,
  peerBusy,
  missedBusy,
  unavailable,
  failed,
}

/// The status line's tone: [danger] for a call the viewer did not pick up.
enum FlareCallRecordTone { neutral, danger }

/// The one action a call record offers.
enum FlareCallRecordAction { join, callBack }

/// The status line for the viewer (`spec/call-record-vectors.json` →
/// rules.status). A missing [endReason] reads completed.
FlareCallRecordStatus flareCallRecordStatus({
  required FlareCallRecordScope scope,
  required FlareCallRecordState state,
  required bool viewerIsInitiator,
  FlareCallEndReason? endReason,
  int? durationSeconds,
  int? joinedCount,
}) {
  final group = scope == FlareCallRecordScope.group;
  switch (state) {
    case FlareCallRecordState.ringing:
      if (group) return FlareCallRecordStatus.groupRinging;
      return viewerIsInitiator
          ? FlareCallRecordStatus.waitingAnswer
          : FlareCallRecordStatus.incoming;
    case FlareCallRecordState.ongoing:
      if (!group) return FlareCallRecordStatus.inCall;
      return (joinedCount ?? 0) >= 1
          ? FlareCallRecordStatus.groupOngoing
          : FlareCallRecordStatus.groupInProgress;
    case FlareCallRecordState.ended:
      break;
  }
  final reason = endReason ?? FlareCallEndReason.completed;
  if (group) {
    return switch (reason) {
      FlareCallEndReason.completed =>
        durationSeconds == null
            ? FlareCallRecordStatus.groupEnded
            : FlareCallRecordStatus.groupEndedDuration,
      FlareCallEndReason.unavailable => FlareCallRecordStatus.unavailable,
      FlareCallEndReason.failed => FlareCallRecordStatus.failed,
      _ => FlareCallRecordStatus.groupEnded,
    };
  }
  return switch (reason) {
    FlareCallEndReason.completed => FlareCallRecordStatus.duration,
    FlareCallEndReason.cancelled =>
      viewerIsInitiator
          ? FlareCallRecordStatus.cancelledByYou
          : FlareCallRecordStatus.cancelledByCaller,
    FlareCallEndReason.declined =>
      viewerIsInitiator
          ? FlareCallRecordStatus.declinedByPeer
          : FlareCallRecordStatus.declinedByYou,
    FlareCallEndReason.missed =>
      viewerIsInitiator
          ? FlareCallRecordStatus.noAnswer
          : FlareCallRecordStatus.missed,
    FlareCallEndReason.busy =>
      viewerIsInitiator
          ? FlareCallRecordStatus.peerBusy
          : FlareCallRecordStatus.missedBusy,
    FlareCallEndReason.unavailable => FlareCallRecordStatus.unavailable,
    FlareCallEndReason.failed => FlareCallRecordStatus.failed,
  };
}

/// A call the viewer did not pick up reads in the danger tone.
FlareCallRecordTone flareCallRecordTone(FlareCallRecordStatus status) =>
    status == FlareCallRecordStatus.missed
    ? FlareCallRecordTone.danger
    : FlareCallRecordTone.neutral;

/// The one action the card offers, or null (`spec/call-record-vectors.json`
/// → rules.action): join a group call in progress, call back after a 1:1
/// call; nothing while the plugin is unavailable.
FlareCallRecordAction? flareCallRecordAction({
  required FlareCallRecordScope scope,
  required FlareCallRecordState state,
  required bool canJoin,
  required bool canCallBack,
  bool disabled = false,
}) {
  if (disabled) return null;
  if (scope == FlareCallRecordScope.group &&
      state != FlareCallRecordState.ended &&
      canJoin) {
    return FlareCallRecordAction.join;
  }
  if (scope == FlareCallRecordScope.single &&
      state == FlareCallRecordState.ended &&
      canCallBack) {
    return FlareCallRecordAction.callBack;
  }
  return null;
}

/// A call's length: mm:ss under an hour, h:mm:ss from an hour
/// (`spec/call-record-vectors.json` → duration). Negative reads 0.
String flareCallDurationLabel(int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  String two(int value) => value.toString().padLeft(2, '0');
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final rest = total % 60;
  return hours > 0
      ? '$hours:${two(minutes)}:${two(rest)}'
      : '${two(minutes)}:${two(rest)}';
}

/// The status line's copy in [strings].
String flareCallRecordStatusText(
  FlareStrings strings,
  FlareCallRecordStatus status, {
  int? joinedCount,
  int? durationSeconds,
}) {
  final duration = flareCallDurationLabel(durationSeconds ?? 0);
  return switch (status) {
    FlareCallRecordStatus.waitingAnswer => strings.callRecordWaitingAnswer,
    FlareCallRecordStatus.incoming => strings.callRecordIncoming,
    FlareCallRecordStatus.groupRinging => strings.callRecordGroupRinging,
    FlareCallRecordStatus.inCall => strings.callRecordInCall,
    FlareCallRecordStatus.groupOngoing =>
      strings.callRecordGroupOngoing.replaceAll('{n}', '${joinedCount ?? 0}'),
    FlareCallRecordStatus.groupInProgress => strings.callRecordGroupInProgress,
    FlareCallRecordStatus.duration => strings.callRecordDuration.replaceAll(
      '{duration}',
      duration,
    ),
    FlareCallRecordStatus.groupEndedDuration =>
      strings.callRecordGroupEndedDuration.replaceAll('{duration}', duration),
    FlareCallRecordStatus.groupEnded => strings.callRecordGroupEnded,
    FlareCallRecordStatus.cancelledByYou => strings.callRecordCancelledByYou,
    FlareCallRecordStatus.cancelledByCaller =>
      strings.callRecordCancelledByCaller,
    FlareCallRecordStatus.declinedByPeer => strings.callRecordDeclinedByPeer,
    FlareCallRecordStatus.declinedByYou => strings.callRecordDeclinedByYou,
    FlareCallRecordStatus.noAnswer => strings.callRecordNoAnswer,
    FlareCallRecordStatus.missed => strings.callRecordMissed,
    FlareCallRecordStatus.peerBusy => strings.callRecordPeerBusy,
    FlareCallRecordStatus.missedBusy => strings.callRecordMissedBusy,
    FlareCallRecordStatus.unavailable => strings.callRecordUnavailable,
    FlareCallRecordStatus.failed => strings.callRecordFailed,
  };
}
