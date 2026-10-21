/**
 * Red packet presentation contracts (spec RedPacketCard / RedPacketOpenSheet / RedPacketDetail /
 * RedPacketComposer / RedPacketPayConfirm). The kit only draws: amounts, times and names arrive
 * formatted by the host, and claiming, balances and eligibility stay with the plugin and the SDK.
 */

/** What the current viewer sees on a card: saturated while unopened, dimmed in the other three. */
export type FlareRedPacketState = "unopened" | "claimed" | "finished" | "expired";

/** Phase of the open sheet. `opening` flips the 開 coin; the last four say why nothing opens. */
export type FlareRedPacketOpenState = "ready" | "opening" | "finished" | "expired" | "notEligible" | "error";

/** Packet kinds a host can offer in the composer; a 1:1 conversation only has `normal`. */
export type FlareRedPacketKind = "lucky" | "normal" | "exclusive";

/** One row of the claim list. */
export interface FlareRedPacketClaim {
  id: string;
  name: string;
  avatar?: string;
  /** Claim time, formatted by the host. */
  time: string;
  /** Claimed amount, formatted by the host. */
  amount: string;
  /** Marks the largest share of a finished lucky packet. */
  best: boolean;
}

const FULL_WIDTH_ZERO = 0xff10;
const DECIMAL_POINTS = new Set([".", "．", "。"]);

function asciiDigit(ch: string): string | null {
  if (ch >= "0" && ch <= "9") return ch;
  const code = ch.charCodeAt(0);
  if (code >= FULL_WIDTH_ZERO && code <= FULL_WIDTH_ZERO + 9) return String(code - FULL_WIDTH_ZERO);
  return null;
}

/**
 * Format-only filter for the composer's amount field: digits and one decimal point with at most two
 * decimals, leading zeros folded (`spec/red-packet-vectors.json` → amountInput). Whether the value is in
 * range is the host's call.
 */
export function sanitizeRedPacketAmount(raw: string): string {
  let out = "";
  let point = false;
  let decimals = 0;
  for (const ch of raw) {
    const digit = asciiDigit(ch);
    if (digit != null) {
      if (point) {
        if (decimals >= 2) continue;
        decimals += 1;
      }
      out += digit;
    } else if (DECIMAL_POINTS.has(ch) && !point) {
      point = true;
      out += out ? "." : "0.";
    }
  }
  return out.replace(/^0+(?=\d)/, "");
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
