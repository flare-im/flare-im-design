// Audio / video call data contracts.

export type FlareCallMode = "audio" | "video";
export type FlareCallState = "calling" | "ringing" | "connected";

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
