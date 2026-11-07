/**
 * The connection notice: what an app shell tells the user about its IM connection, decided here so that
 * every app says the same thing at the same moment. The host hands in the core SDK's connection status
 * (the `connection://status` event) as it arrives; the tracker turns it into what the banner shows over
 * time. Rules and their table: `spec/connection-notice-vectors.json`, run by all four kits.
 *
 * - idle and online show nothing (a poor-quality line is the diagnostics page's business, not a banner);
 * - connecting, reconnecting, waitingForNetwork, serviceUnavailable and actionRequired show at once;
 * - syncing shows once it has lasted 1 s and switching once it has lasted 2 s, so a quick sync or a quick
 *   line switch never flashes a banner; until then a banner that was already up keeps what it showed;
 * - a reconnecting banner stays up at least 1.5 s, so a drop that heals at once does not flash either;
 * - reconnecting counts down to the next attempt and offers to retry now, serviceUnavailable offers
 *   diagnostics, and actionRequired offers the way back its reason needs (sign in again, update).
 */
export type FlareConnectionPhase =
  | "idle"
  | "connecting"
  | "syncing"
  | "online"
  | "switching"
  | "reconnecting"
  | "waitingForNetwork"
  | "serviceUnavailable"
  | "actionRequired";

export type FlareConnectionQuality = "good" | "poor";

/** Why the core stopped and waits for the user (actionRequired): the reasons the notice has words for. */
export type FlareConnectionActionReason = "kicked" | "expired" | "upgradeRequired" | "tenantUnavailable";

const ACTION_REASONS: ReadonlySet<string> = new Set<FlareConnectionActionReason>([
  "kicked", "expired", "upgradeRequired", "tenantUnavailable",
]);

/**
 * The actionRequired reason the notice speaks for `reason`, the SDK's string as it arrives: one of the four it has
 * words for, and expired for anything else (none, or one a newer core added).
 */
export function flareConnectionActionReason(reason: string | null | undefined): FlareConnectionActionReason {
  return reason && ACTION_REASONS.has(reason) ? (reason as FlareConnectionActionReason) : "expired";
}

/** The core SDK's connection status, as the host receives it from `connection://status`. */
export interface FlareConnectionStatus {
  phase: FlareConnectionPhase;
  /** online: the line's quality. Neither value shows a banner. */
  quality?: FlareConnectionQuality;
  /** syncing: how far the catch-up has come, 0 to 1. */
  progress?: number;
  /** reconnecting: when the next attempt starts, epoch milliseconds on the device clock. */
  nextRetryAt?: number;
  /** reconnecting: which attempt this is. Not shown. */
  attempt?: number;
  /**
   * Why, as the SDK reports it: actionRequired names kicked, expired, upgradeRequired or tenantUnavailable, and
   * switching names its own (failure, drain, failback, manual, manifest). Any string is taken. Only the four
   * actionRequired reasons have words; any other actionRequired reason, or none, reads as expired, and the other
   * phases do not read it.
   */
  reason?: FlareConnectionActionReason | (string & {});
  /** The SDK runs with development endpoints: the notice wears a 开发模式 badge in every phase. */
  developmentMode?: boolean;
}

/** The message a visible banner says (an i18n key under `connection.`). */
export type FlareConnectionNoticeText =
  | "connecting"
  | "syncing"
  | "switching"
  | "reconnecting"
  | "waitingForNetwork"
  | "serviceUnavailable"
  | FlareConnectionActionReason;

/** The action a visible banner offers; the host performs it. */
export type FlareConnectionNoticeAction = "retry" | "signIn" | "update" | "diagnose";

export type FlareConnectionNoticeTone = "info" | "warning" | "danger";

/** What the notice shows at one moment. */
export interface FlareConnectionNoticeModel {
  visible: boolean;
  text: FlareConnectionNoticeText | null;
  tone: FlareConnectionNoticeTone | null;
  /** An attempt or a recovery is under way. */
  pulse: boolean;
  /** reconnecting: whole seconds to the next attempt, rounded up. */
  countdown: number | null;
  /** syncing: 0 to 1. */
  progress: number | null;
  action: FlareConnectionNoticeAction | null;
  /** Draw the development mode badge. */
  badge: boolean;
}

export const FLARE_CONNECTION_SYNCING_DELAY_MS = 1000;
export const FLARE_CONNECTION_SWITCHING_DELAY_MS = 2000;
export const FLARE_CONNECTION_RECONNECTING_MIN_SHOWN_MS = 1500;

type Shown = Pick<FlareConnectionNoticeModel, "text" | "tone" | "pulse">;

const HIDDEN: Omit<FlareConnectionNoticeModel, "badge"> = {
  visible: false, text: null, tone: null, pulse: false, countdown: null, progress: null, action: null,
};

function shown(text: FlareConnectionNoticeText, tone: FlareConnectionNoticeTone, pulse: boolean,
  extra: Partial<Pick<FlareConnectionNoticeModel, "countdown" | "progress" | "action">> = {}): Omit<FlareConnectionNoticeModel, "badge"> {
  return { ...HIDDEN, visible: true, text, tone, pulse, ...extra };
}

function delayOf(phase: FlareConnectionPhase): number | null {
  if (phase === "syncing") return FLARE_CONNECTION_SYNCING_DELAY_MS;
  if (phase === "switching") return FLARE_CONNECTION_SWITCHING_DELAY_MS;
  return null;
}

/** Whole seconds to `nextRetryAt`, rounded up; null without one or once it has passed. */
export function flareConnectionCountdown(nextRetryAt: number | undefined, nowMs: number): number | null {
  if (nextRetryAt === undefined || nextRetryAt === null) return null;
  const remaining = nextRetryAt - nowMs;
  return remaining > 0 ? Math.ceil(remaining / 1000) : null;
}

const ACTION_BY_REASON: Record<FlareConnectionActionReason, FlareConnectionNoticeAction | null> = {
  kicked: "signIn",
  expired: "signIn",
  upgradeRequired: "update",
  tenantUnavailable: null,
};

/** Tracks the status over time and answers what the notice shows. One per notice. */
export class FlareConnectionNoticeTracker {
  private status: FlareConnectionStatus | null = null;
  private phaseSince = 0;
  private lastShown: Shown | null = null;
  private holdUntil: number | null = null;

  /** A status arrived at `nowMs`. The same phase again replaces its fields without restarting its clock. */
  observe(status: FlareConnectionStatus, nowMs: number): void {
    if (this.status === null || this.status.phase !== status.phase) {
      const outgoing = this.present(nowMs);
      this.lastShown = outgoing.visible ? { text: outgoing.text, tone: outgoing.tone, pulse: outgoing.pulse } : null;
      this.phaseSince = nowMs;
      if (status.phase === "reconnecting") this.holdUntil = nowMs + FLARE_CONNECTION_RECONNECTING_MIN_SHOWN_MS;
      else if (status.phase === "idle" || status.phase === "actionRequired") this.holdUntil = null;
    }
    this.status = { ...status };
  }

  /** What the notice shows at `nowMs`. */
  present(nowMs: number): FlareConnectionNoticeModel {
    const status = this.status;
    if (!status) return { ...HIDDEN, badge: false };
    const badge = status.developmentMode === true;
    if (status.phase === "idle") return { ...HIDDEN, badge };
    const base = this.base(status, nowMs);
    if (base.visible) return { ...base, badge };
    if (this.lastShown && (this.belowDelay(status, nowMs) || this.held(nowMs))) {
      return { ...HIDDEN, visible: true, ...this.lastShown, badge };
    }
    return { ...HIDDEN, badge };
  }

  /** The next moment the presentation can change without a new status; null when it cannot. */
  nextChangeAt(nowMs: number): number | null {
    const status = this.status;
    if (!status || status.phase === "idle") return null;
    const candidates: number[] = [];
    const delay = delayOf(status.phase);
    if (delay !== null && nowMs < this.phaseSince + delay) candidates.push(this.phaseSince + delay);
    if (status.phase === "reconnecting") {
      const countdown = flareConnectionCountdown(status.nextRetryAt, nowMs);
      if (countdown !== null) candidates.push(status.nextRetryAt! - (countdown - 1) * 1000);
    }
    if (this.lastShown && this.held(nowMs) && !this.base(status, nowMs).visible) candidates.push(this.holdUntil!);
    return candidates.length ? Math.min(...candidates) : null;
  }

  private belowDelay(status: FlareConnectionStatus, nowMs: number): boolean {
    const delay = delayOf(status.phase);
    return delay !== null && nowMs - this.phaseSince < delay;
  }

  private held(nowMs: number): boolean {
    return this.holdUntil !== null && nowMs < this.holdUntil;
  }

  private base(status: FlareConnectionStatus, nowMs: number): Omit<FlareConnectionNoticeModel, "badge"> {
    switch (status.phase) {
      case "idle":
      case "online":
        return HIDDEN;
      case "connecting":
        return shown("connecting", "info", true);
      case "syncing":
        if (this.belowDelay(status, nowMs)) return HIDDEN;
        return shown("syncing", "info", true, {
          progress: typeof status.progress === "number" ? Math.min(1, Math.max(0, status.progress)) : null,
        });
      case "switching":
        return this.belowDelay(status, nowMs) ? HIDDEN : shown("switching", "info", true);
      case "reconnecting":
        return shown("reconnecting", "warning", true, {
          countdown: flareConnectionCountdown(status.nextRetryAt, nowMs),
          action: "retry",
        });
      case "waitingForNetwork":
        return shown("waitingForNetwork", "warning", false);
      case "serviceUnavailable":
        return shown("serviceUnavailable", "warning", true, { action: "diagnose" });
      case "actionRequired": {
        const reason = flareConnectionActionReason(status.reason);
        return shown(reason, "danger", false, { action: ACTION_BY_REASON[reason] });
      }
    }
  }
}
