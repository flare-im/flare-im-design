/**
 * Invite contracts — pure logic shared by the four platforms behind the
 * registration form's invite-code field (InviteCodeField) and the "my invite"
 * card (MyInvitePanel). Vectors: spec/invite-vectors.json.
 *
 * The host owns the network: it runs the pre-check, fetches the code, the stats
 * and the invitees, and performs copy / share / regenerate. Nothing here has a
 * side effect, and nothing here invents a rule the server does not have: the
 * alphabet is Crockford base32 without I / L / O / U, so what a person types is
 * corrected the way the server would read it (O→0, I/L→1) before it is shown.
 */

/** Tenant invite mode: `off` hides the field, `optional` and `required` show it. */
export type FlareInviteCodeMode = "off" | "optional" | "required";

/** Result of the host's pre-check for one code. */
export interface FlareInviteCodeCheckResult {
  valid: boolean;
  /** Masked display name of the inviter the code resolves to. */
  inviterDisplayName?: string;
}

/** The InviteCodeField state vector. */
export type FlareInviteCodeFieldState =
  | "off"
  | "idle"
  | "typing"
  | "checking"
  | "valid"
  | "invalid"
  | "disabled";

/** Referral counts per depth for the current person. */
export interface FlareReferralStats {
  direct: number;
  l2: number;
  l3: number;
  total: number;
}

/** One person invited directly by the current person. */
export interface FlareInvitee {
  userId: string;
  displayName: string;
  avatarUrl?: string;
  /** Registration time, epoch milliseconds. */
  joinedAt: number;
}

export const FLARE_INVITE_CODE_DEFAULT_LENGTH = 6;

/**
 * What the server would read from what the person typed or pasted: whitespace
 * and separators dropped, uppercased, O→0 and I/L→1 (the alphabet has none of
 * them), cut to `length`. Idempotent, so it can run on every keystroke.
 */
export function normalizeInviteCode(raw: string | null | undefined, length = FLARE_INVITE_CODE_DEFAULT_LENGTH): string {
  const cap = Number.isFinite(length) && length > 0 ? Math.floor(length) : FLARE_INVITE_CODE_DEFAULT_LENGTH;
  let out = "";
  for (const ch of String(raw ?? "").toUpperCase()) {
    if (out.length >= cap) break;
    if (ch === "O") out += "0";
    else if (ch === "I" || ch === "L") out += "1";
    else if (/[0-9A-Z]/.test(ch)) out += ch;
    // separators, punctuation and whitespace are dropped
  }
  return out;
}

export interface FlareInviteCodeFieldInput {
  mode: FlareInviteCodeMode;
  value: string;
  length?: number;
  checking?: boolean;
  checkResult?: FlareInviteCodeCheckResult | null;
  error?: string | null;
  disabled?: boolean;
}

/**
 * One state at a time, in priority order: `off` beats everything (nothing is
 * drawn), `disabled` beats what the host says about the value, a host `error`
 * beats a check result, an in-flight check beats a stale result, then the result
 * itself, then whether anything has been typed.
 */
export function inviteCodeFieldState(input: FlareInviteCodeFieldInput): FlareInviteCodeFieldState {
  if (input.mode === "off") return "off";
  if (input.disabled) return "disabled";
  if (input.error) return "invalid";
  if (input.checking) return "checking";
  if (input.checkResult) return input.checkResult.valid ? "valid" : "invalid";
  return input.value ? "typing" : "idle";
}

/**
 * The code the host should pre-check for the current value, or `null` when no
 * request should be made: a partial code is never sent (it can only be invalid),
 * a disabled or hidden field never asks.
 */
export function inviteCodeToCheck(input: {
  value: string;
  length?: number;
  mode?: FlareInviteCodeMode;
  disabled?: boolean;
}): string | null {
  if (input.mode === "off" || input.disabled) return null;
  const length = input.length ?? FLARE_INVITE_CODE_DEFAULT_LENGTH;
  const code = normalizeInviteCode(input.value, length);
  return code.length === length ? code : null;
}

/** Delay between the last keystroke and the `check` event. */
export const FLARE_INVITE_CHECK_DEBOUNCE_MS = 400;

export type FlareReferralDepth = "direct" | "l2" | "l3" | "total";

/**
 * Which rows the panel lists for `stats`, honouring the tenant's visibility
 * depth (1–3, clamped). `total` is always the last row once stats exist.
 */
export function referralDepthRows(stats: FlareReferralStats | null | undefined, maxDepthShown = 3): FlareReferralDepth[] {
  if (!stats) return [];
  const depth = Math.min(3, Math.max(1, Math.floor(Number.isFinite(maxDepthShown) ? maxDepthShown : 3)));
  const rows: FlareReferralDepth[] = ["direct"];
  if (depth >= 2) rows.push("l2");
  if (depth >= 3) rows.push("l3");
  rows.push("total");
  return rows;
}

export type FlareInviteCooldownUnit = "minute" | "hour" | "day";

export interface FlareInviteCooldown {
  unit: FlareInviteCooldownUnit;
  count: number;
}

export interface FlareRegenerateAvailability {
  /** The control is drawn at all (the tenant allows regenerating). */
  shown: boolean;
  /** The control can be pressed now. */
  enabled: boolean;
  /** Time left before it can, in the coarsest whole unit that is not zero; `null` when none. */
  remaining: FlareInviteCooldown | null;
}

/**
 * Whether regenerating is offered, and if so whether it is still cooling down.
 * The remaining time rounds *up* — "1 minute" for ten seconds, "2 hours" for an
 * hour and a second — so the control never re-enables before the server would.
 */
export function regenerateAvailability(
  canRegenerate: boolean | undefined,
  availableAt: number | null | undefined,
  now: number,
): FlareRegenerateAvailability {
  if (!canRegenerate) return { shown: false, enabled: false, remaining: null };
  const remainingMs = typeof availableAt === "number" && Number.isFinite(availableAt) ? availableAt - now : 0;
  if (remainingMs <= 0) return { shown: true, enabled: true, remaining: null };
  const minute = 60_000;
  const hour = 60 * minute;
  const day = 24 * hour;
  const remaining: FlareInviteCooldown =
    remainingMs < hour
      ? { unit: "minute", count: Math.max(1, Math.ceil(remainingMs / minute)) }
      : remainingMs < day
        ? { unit: "hour", count: Math.ceil(remainingMs / hour) }
        : { unit: "day", count: Math.ceil(remainingMs / day) };
  return { shown: true, enabled: false, remaining };
}

/** `YYYY-MM-DD` for a calendar date — the same on every platform, in the device's calendar. */
export function formatInviteJoinedDate(year: number, month: number, day: number): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${year}-${pad(month)}-${pad(day)}`;
}

/** `YYYY-MM-DD` of an epoch-millisecond instant in the device's time zone. */
export function inviteJoinedDateLabel(epochMs: number): string {
  const date = new Date(epochMs);
  return formatInviteJoinedDate(date.getFullYear(), date.getMonth() + 1, date.getDate());
}
