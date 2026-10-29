// Audio / video call data contracts.

export type FlareCallMode = "audio" | "video";
export type FlareCallState = "calling" | "ringing" | "connected" | "reconnecting" | "failed";

/** One participant in a group (multi-party) call. */
export interface FlareCallParticipant {
  id: string;
  name: string;
  avatarUrl?: string;
  /** Their mic is muted. */
  muted?: boolean;
  /** Their camera is off (audio-only tile / avatar shown). */
  cameraOff?: boolean;
  /** Currently speaking — drives the speaking ring. */
  speaking?: boolean;
  /** This tile is the local user. */
  isSelf?: boolean;
}

// ── Call record card (FlareCallRecordCard) ──────────────────────────────
// The call record in the chat timeline. Every fact is viewer-relative and comes from the host; the rules below are
// the shared table spec/call-record-vectors.json, which the four kits run.

export type FlareCallRecordScope = "single" | "group";
export type FlareCallRecordState = "ringing" | "ongoing" | "ended";
export type FlareCallEndReason = "completed" | "cancelled" | "declined" | "missed" | "busy" | "unavailable" | "failed";
/** The status line a call record shows (spec/call-record-vectors.json `rules.status`). */
export type FlareCallRecordStatus =
  | "waitingAnswer"
  | "incoming"
  | "groupRinging"
  | "inCall"
  | "groupOngoing"
  | "groupInProgress"
  | "duration"
  | "groupEndedDuration"
  | "groupEnded"
  | "cancelledByYou"
  | "cancelledByCaller"
  | "declinedByPeer"
  | "declinedByYou"
  | "noAnswer"
  | "missed"
  | "peerBusy"
  | "missedBusy"
  | "unavailable"
  | "failed";
export type FlareCallRecordTone = "neutral" | "danger";
export type FlareCallRecordAction = "join" | "callBack";

/** What the card reads. */
export interface FlareCallRecordFacts {
  media: FlareCallMode;
  scope: FlareCallRecordScope;
  state: FlareCallRecordState;
  endReason?: FlareCallEndReason;
  durationSeconds?: number;
  joinedCount?: number;
  viewerIsInitiator: boolean;
  /** The host decided the viewer may join (a group call in progress the viewer is not in). */
  canJoin: boolean;
  /** The host decided the viewer may call back (calls available for this conversation). */
  canCallBack: boolean;
  /** The plugin is unavailable: no action. */
  disabled?: boolean;
}

/** The status line for [facts] (spec/call-record-vectors.json `rules.status`). */
export function flareCallRecordStatus(facts: FlareCallRecordFacts): FlareCallRecordStatus {
  const initiator = facts.viewerIsInitiator;
  if (facts.state === "ringing") {
    if (facts.scope === "group") return "groupRinging";
    return initiator ? "waitingAnswer" : "incoming";
  }
  if (facts.state === "ongoing") {
    if (facts.scope === "single") return "inCall";
    return (facts.joinedCount ?? 0) >= 1 ? "groupOngoing" : "groupInProgress";
  }
  const reason = facts.endReason ?? "completed";
  if (facts.scope === "group") {
    if (reason === "completed") return facts.durationSeconds == null ? "groupEnded" : "groupEndedDuration";
    if (reason === "unavailable" || reason === "failed") return reason;
    return "groupEnded";
  }
  switch (reason) {
    case "completed":
      return "duration";
    case "cancelled":
      return initiator ? "cancelledByYou" : "cancelledByCaller";
    case "declined":
      return initiator ? "declinedByPeer" : "declinedByYou";
    case "missed":
      return initiator ? "noAnswer" : "missed";
    case "busy":
      return initiator ? "peerBusy" : "missedBusy";
    default:
      return reason;
  }
}

/** A call the viewer did not pick up reads in the danger tone; everything else is neutral. */
export function flareCallRecordTone(status: FlareCallRecordStatus): FlareCallRecordTone {
  return status === "missed" ? "danger" : "neutral";
}

/** The one action the card offers, or null (spec/call-record-vectors.json `rules.action`). */
export function flareCallRecordAction(facts: FlareCallRecordFacts): FlareCallRecordAction | null {
  if (facts.disabled) return null;
  if (facts.scope === "group" && facts.state !== "ended" && facts.canJoin) return "join";
  if (facts.scope === "single" && facts.state === "ended" && facts.canCallBack) return "callBack";
  return null;
}

/** A call's length: mm:ss under an hour, h:mm:ss from an hour (spec/call-record-vectors.json `duration`). */
export function flareCallDurationLabel(seconds: number): string {
  const total = Math.max(0, Math.floor(Number.isFinite(seconds) ? seconds : 0));
  const two = (value: number) => String(value).padStart(2, "0");
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const rest = total % 60;
  return hours > 0 ? `${hours}:${two(minutes)}:${two(rest)}` : `${two(minutes)}:${two(rest)}`;
}
