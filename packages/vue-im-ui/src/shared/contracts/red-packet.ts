/**
 * Red packet presentation contracts (spec RedPacketCard / RedPacketOpenSheet / RedPacketDetail /
 * RedPacketComposer / RedPacketPayConfirm, docs/design/red-packet-v5-roles-and-wallet.md). The kit only draws:
 * claiming, balances, eligibility and who may see which amount stay with the plugin server, which returns
 * nothing a viewer may not see. The rules here are pure and tested against spec/red-packet-vectors.json.
 */
import { flarePluginRenderPattern } from "./plugin-ui";

/**
 * What a card shows (cardState): unopened (领取红包), viewable (查看红包 — the sender's or a non-designated
 * viewer's open packet), claimed, finished, expired, refunded. Saturated while unopened or viewable.
 */
export type FlareRedPacketCardState = "unopened" | "viewable" | "claimed" | "finished" | "expired" | "refunded";

/** The plugin's packet status (public layer). */
export type FlareRedPacketStatus = "open" | "completed" | "expired" | "refunded";

/** Where a tap on the card goes (personal layer): the open sheet, the details, or the not-eligible notice. */
export type FlareRedPacketTapAction = "open" | "details" | "notEligible";

/** Who is looking at the details, as the server decided. */
export type FlareRedPacketViewerRole = "sender" | "claimer" | "eligible" | "ineligible";

/**
 * Phase of the open sheet. `opening` flips the 開 coin; the others say why nothing opens (`refunded`: the packet went
 * back to its sender — PACKET_REFUNDED, or the public status refunded).
 */
export type FlareRedPacketOpenState = "ready" | "opening" | "finished" | "expired" | "refunded" | "notEligible" | "error";

/** Packet kinds a host can offer in the composer; a 1:1 conversation only has `normal`. */
export type FlareRedPacketKind = "lucky" | "normal" | "exclusive";

/** One row of the claim list: the host resolves name and avatar; the kit formats amount and time. */
export interface FlareRedPacketClaim {
  /** Claimant user id; seeds the avatar. */
  id: string;
  name: string;
  avatar?: string;
  /** Claimed amount in minor units (a string of digits). */
  amountMinor: string;
  claimedAtMs: number;
  /** The server's best-luck mark of a finished lucky packet. */
  best: boolean;
}

/** The plugin's details result for one viewer (PacketDetails + PacketView); amounts the viewer may not see are absent. */
export interface FlareRedPacketDetailsView {
  viewerRole: FlareRedPacketViewerRole;
  status: FlareRedPacketStatus;
  kind: FlareRedPacketKind;
  greeting: string;
  currency: string;
  currencyExponent: number;
  totalMinor?: string | null;
  claimedMinor?: string | null;
  refundedMinor?: string | null;
  myAmountMinor?: string | null;
  claimedCount: number;
  shareCount: number;
  createdAtMs: number;
  completedAtMs?: number | null;
  expiresAtMs: number;
  refundedAtMs?: number | null;
  claimsListed: boolean;
}

// ── card ─────────────────────────────────────────────────────────────────

/** The card state from the public layer (status) and the viewer's personal layer (spec cardState). */
export function flareRedPacketCardState(view: {
  status: FlareRedPacketStatus;
  claimedByMe?: boolean;
  tapAction?: FlareRedPacketTapAction;
}): FlareRedPacketCardState {
  if (view.claimedByMe) return "claimed";
  if (view.status === "completed") return "finished";
  if (view.status === "expired") return "expired";
  if (view.status === "refunded") return "refunded";
  return view.tapAction === "details" || view.tapAction === "notEligible" ? "viewable" : "unopened";
}

export type FlareRedPacketCardStatus =
  | "busy" | "statusLabel" | "tapToOpen" | "view" | "claimed" | "finished" | "expired" | "refunded" | "unavailable";

/** Which copy the status line shows (spec card): busy, the host's label, then the state; disabled says unavailable. */
export function flareRedPacketCardStatus(input: {
  state: FlareRedPacketCardState;
  busy?: boolean;
  disabled?: boolean;
  statusLabel?: string | null;
}): FlareRedPacketCardStatus {
  if (input.busy) return "busy";
  if (input.statusLabel != null) return "statusLabel";
  switch (input.state) {
    case "viewable": return "view";
    case "claimed": return "claimed";
    case "finished": return "finished";
    case "expired": return "expired";
    case "refunded": return "refunded";
    default: return input.disabled ? "unavailable" : "tapToOpen";
  }
}

/** A spent card fades: claimed, finished, expired, refunded. */
export function flareRedPacketCardDimmed(state: FlareRedPacketCardState): boolean {
  return state === "claimed" || state === "finished" || state === "expired" || state === "refunded";
}

/** The kind badge and the exclusive recipient line (spec cardBadge). */
export function flareRedPacketCardBadge(kind: FlareRedPacketKind, recipientName?: string): {
  badge: "lucky" | "exclusive" | null;
  recipient: string | null;
} {
  const name = recipientName?.trim();
  if (kind === "lucky") return { badge: "lucky", recipient: null };
  if (kind === "exclusive") return { badge: "exclusive", recipient: name || null };
  return { badge: null, recipient: null };
}

/**
 * Which keys the open sheet offers (spec openSheet, openSheetRefunded): 開 while it can open; details only for
 * finished, expired and refunded, and only when the viewer may see them.
 */
export function flareRedPacketOpenSheetKeys(state: FlareRedPacketOpenState, canViewDetails = true): { coin: boolean; details: boolean } {
  return {
    coin: state === "ready" || state === "opening" || state === "error",
    details: (state === "finished" || state === "expired" || state === "refunded") && canViewDetails,
  };
}

// ── amounts ──────────────────────────────────────────────────────────────

const SYMBOLS: Readonly<Record<string, string>> = { CNY: "¥", JPY: "¥", USD: "$", EUR: "€", GBP: "£", HKD: "HK$" };

/**
 * A minor-unit amount as text with exactly `exponent` fraction digits, by string arithmetic (no floating point, no
 * grouping): "888", 2 → "8.88". Anything but ASCII digits is no amount (null). spec/red-packet-vectors.json amount.
 */
export function flareRedPacketAmountText(minor: string | null | undefined, exponent: number): string | null {
  if (typeof minor !== "string" || !/^\d+$/.test(minor) || !Number.isInteger(exponent) || exponent < 0 || exponent > 12) return null;
  const digits = minor.replace(/^0+(?=\d)/, "");
  const scale = Math.max(0, Math.floor(exponent));
  if (scale === 0) return digits;
  const padded = digits.padStart(scale + 1, "0");
  return `${padded.slice(0, -scale)}.${padded.slice(-scale)}`;
}

/** The amount with its currency: a symbol from the table, else "{CODE} {text}". */
export function flareRedPacketMoney(minor: string | null | undefined, exponent: number, currency: string): string | null {
  const text = flareRedPacketAmountText(minor, exponent);
  if (text === null) return null;
  const code = currency.trim().toUpperCase();
  const symbol = SYMBOLS[code];
  return symbol ? `${symbol}${text}` : `${code} ${text}`;
}

// ── details ──────────────────────────────────────────────────────────────

/** The copy the detail rules need; the component fills it from the active locale. */
export interface FlareRedPacketDetailStrings {
  summarySender: string;
  summaryCompleted: string;
  summaryCount: string;
  refundAt: string;
  refundedNote: string;
  missed: string;
  expired: string;
  notEligible: string;
  notEligibleName: string;
  durationSeconds: string;
  durationMinutes: string;
  durationHours: string;
  durationDays: string;
  /** Plugin view date-time patterns (pluginView.dateTime / dateTimeYear). */
  dateTime: string;
  dateTimeYear: string;
}

export interface FlareRedPacketDetailTexts {
  /** The viewer's own amount, drawn large, with the deposited line under it. */
  amount: string | null;
  headline: string | null;
  summary: string | null;
  /** Draw the claim list. */
  claims: boolean;
  note: string | null;
}

const fill = (template: string, values: Record<string, string | number>) =>
  template.replace(/\{(\w+)\}/g, (match, key: string) => (key in values ? String(values[key]) : match));

interface WallClock { year: number; month: number; day: number; hour: number; minute: number }
function wallClock(ms: number, utcOffsetMinutes?: number): WallClock {
  const d = new Date(utcOffsetMinutes === undefined ? ms : ms + utcOffsetMinutes * 60_000);
  return utcOffsetMinutes === undefined
    ? { year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate(), hour: d.getHours(), minute: d.getMinutes() }
    : { year: d.getUTCFullYear(), month: d.getUTCMonth() + 1, day: d.getUTCDate(), hour: d.getUTCHours(), minute: d.getUTCMinutes() };
}

/** A time as the red packet pages write it: HH:mm today, else the date-time pattern (with the year in another year). */
export function flareRedPacketTime(
  ms: number,
  nowMs: number,
  strings: Pick<FlareRedPacketDetailStrings, "dateTime" | "dateTimeYear">,
  utcOffsetMinutes?: number,
): string {
  const at = wallClock(ms, utcOffsetMinutes);
  const now = wallClock(nowMs, utcOffsetMinutes);
  if (at.year === now.year && at.month === now.month && at.day === now.day) return flarePluginRenderPattern("HH:mm", at);
  return flarePluginRenderPattern(at.year === now.year ? strings.dateTime : strings.dateTimeYear, at);
}

/** How long it took: whole seconds, minutes, hours or days (spec detail.rules.duration). */
export function flareRedPacketDuration(ms: number, strings: FlareRedPacketDetailStrings): string {
  const s = Math.max(0, Math.floor(ms / 1000));
  if (s < 60) return fill(strings.durationSeconds, { n: s });
  if (s < 3600) return fill(strings.durationMinutes, { n: Math.floor(s / 60) });
  if (s < 86_400) return fill(strings.durationHours, { n: Math.floor(s / 3600) });
  return fill(strings.durationDays, { n: Math.floor(s / 86_400) });
}

/**
 * What RedPacketDetail draws for this viewer (spec detail): only the fields the server returned. The sender is the
 * only one who ever receives totals, so everyone else gets the count line.
 */
export function flareRedPacketDetailTexts(
  details: FlareRedPacketDetailsView,
  context: { designatedName?: string; nowMs: number; utcOffsetMinutes?: number },
  strings: FlareRedPacketDetailStrings,
): FlareRedPacketDetailTexts {
  const money = (minor: string | null | undefined) => flareRedPacketMoney(minor, details.currencyExponent, details.currency);
  const time = (ms: number) => flareRedPacketTime(ms, context.nowMs, strings, context.utcOffsetMinutes);
  const role = details.viewerRole;
  const spent = details.status === "expired" || details.status === "refunded";
  const name = context.designatedName?.trim();
  let headline: string | null = null;
  if (role === "ineligible") headline = name ? fill(strings.notEligibleName, { name }) : strings.notEligible;
  else if (role === "eligible" && details.status === "completed") headline = strings.missed;
  else if (role === "eligible" && spent) headline = strings.expired;

  let summary: string | null = null;
  if (!(role === "ineligible" || (role === "eligible" && spent))) {
    const total = money(details.totalMinor);
    const claimed = money(details.claimedMinor);
    const counts = { claimed: details.claimedCount, shares: details.shareCount };
    if (details.status === "completed" && total && typeof details.completedAtMs === "number") {
      summary = fill(strings.summaryCompleted, {
        shares: details.shareCount,
        totalMoney: total,
        duration: flareRedPacketDuration(details.completedAtMs - details.createdAtMs, strings),
      });
    } else if (total && claimed) {
      summary = fill(strings.summarySender, { ...counts, claimedMoney: claimed, totalMoney: total });
    } else {
      summary = fill(strings.summaryCount, counts);
    }
  }

  let note: string | null = null;
  if (role === "sender" && details.status === "open" && details.expiresAtMs) {
    note = fill(strings.refundAt, { time: time(details.expiresAtMs) });
  } else if (role === "sender" && spent) {
    const refunded = flareRedPacketAmountText(details.refundedMinor, details.currencyExponent);
    if (refunded !== null && /[1-9]/.test(refunded)) {
      const at = typeof details.refundedAtMs === "number" ? time(details.refundedAtMs) : "";
      note = fill(strings.refundedNote, { money: money(details.refundedMinor) ?? "", time: at }).replace(/ · $/, "");
    }
  }

  return { amount: money(details.myAmountMinor), headline, summary, claims: details.claimsListed, note };
}

/** One claim row's amount and time. */
export function flareRedPacketClaimTexts(
  claim: FlareRedPacketClaim,
  currency: string,
  currencyExponent: number,
  nowMs: number,
  strings: Pick<FlareRedPacketDetailStrings, "dateTime" | "dateTimeYear">,
  utcOffsetMinutes?: number,
): { amount: string | null; time: string } {
  return {
    amount: flareRedPacketMoney(claim.amountMinor, currencyExponent, currency),
    time: flareRedPacketTime(claim.claimedAtMs, nowMs, strings, utcOffsetMinutes),
  };
}

// ── composer ─────────────────────────────────────────────────────────────

const FULL_WIDTH_ZERO = 0xff10;
const DECIMAL_POINTS = new Set([".", "．", "。"]);

function asciiDigit(ch: string): string | null {
  if (ch >= "0" && ch <= "9") return ch;
  const code = ch.charCodeAt(0);
  if (code >= FULL_WIDTH_ZERO && code <= FULL_WIDTH_ZERO + 9) return String(code - FULL_WIDTH_ZERO);
  return null;
}

/** A currency exponent as the composer uses it: a whole number of decimals, 0..12 (anything else is 2). */
export function flareRedPacketExponent(exponent: number | null | undefined): number {
  return typeof exponent === "number" && Number.isFinite(exponent) ? Math.min(12, Math.max(0, Math.floor(exponent))) : 2;
}

/**
 * Format-only filter for the composer's amount field: digits and one decimal point with at most `exponent`
 * decimals (none at all, the point dropped, when the currency has no minor unit), leading zeros folded
 * (`spec/red-packet-vectors.json` → amountInput, amountInputExponent). Whether the value is in range is the
 * host's call.
 */
export function sanitizeRedPacketAmount(raw: string, exponent = 2): string {
  const scale = flareRedPacketExponent(exponent);
  let out = "";
  let point = false;
  let decimals = 0;
  for (const ch of raw) {
    const digit = asciiDigit(ch);
    if (digit != null) {
      if (point) {
        if (decimals >= scale) continue;
        decimals += 1;
      }
      out += digit;
    } else if (DECIMAL_POINTS.has(ch) && !point && scale > 0) {
      point = true;
      out += out ? "." : "0.";
    }
  }
  return out.replace(/^0+(?=\d)/, "");
}

/**
 * The composer's amount text in minor units — a string of digits, by integer arithmetic, never floating point
 * ("8.8", 2 → "880"; spec amountMinor). Null while the text is not an amount: empty, a lone point, more decimals
 * than the exponent allows, or anything but ASCII digits and one point.
 */
export function flareRedPacketAmountMinor(text: string, exponent: number): string | null {
  const scale = flareRedPacketExponent(exponent);
  const match = /^(\d*)(?:\.(\d*))?$/.exec(text.trim());
  if (!match) return null;
  const whole = match[1] ?? "";
  const fraction = match[2];
  if (fraction !== undefined && scale === 0) return null;
  if (!whole && !fraction) return null;
  if ((fraction ?? "").length > scale) return null;
  const digits = `${whole}${(fraction ?? "").padEnd(scale, "0")}`.replace(/^0+(?=\d)/, "");
  return digits || "0";
}

/** Digits only, at most three, as a number; empty is 0 (`spec/red-packet-vectors.json` → countInput). */
export function sanitizeRedPacketCount(raw: string): number {
  let digits = "";
  for (const ch of raw) {
    const digit = asciiDigit(ch);
    if (digit == null || digits.length >= 3 || (digit === "0" && !digits)) continue;
    digits += digit;
  }
  return digits ? Number(digits) : 0;
}
