// Pure date-range logic behind SearchDateRangeFilter. The component only renders;
// every conversion between a local calendar date ("YYYY-MM-DD", the shape every
// Flare DatePicker speaks) and the inclusive UTC epoch milliseconds of
// `FlareSearchTimeRange` happens here, explicitly, so all four platforms agree.
//
// Conventions (identical on Vue / Flutter / SwiftUI / Compose):
// - `from` is the **start of that day**, 00:00:00.000 local.
// - `to` is the **end of that day**, 23:59:59.999 local — the range is inclusive
//   on both ends, so a single day yields a 86_399_999 ms span, never 0.
// - `tzOffsetMinutes` is minutes **east of UTC** (UTC+8 → 480, UTC-5 → -300).
//   Note that JavaScript's `Date#getTimezoneOffset()` has the opposite sign:
//   pass `-new Date().getTimezoneOffset()`. Omitting it uses the host's own
//   zone for that calendar date (DST-correct, because the platform resolves it).
import {
  sameSearchTimeRange,
  type FlareSearchRangeOption,
  type FlareSearchTimeRange,
} from './search-panel';

/** The two local date strings a pair of DatePickers is bound to; '' means unset. */
export interface FlareSearchDateDraft {
  from: string;
  to: string;
}

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const MAX_SAFE = Number.MAX_SAFE_INTEGER;

/** Strict "YYYY-MM-DD" parse; rejects 2026-13-01 and 2026-02-30 alike. */
function dateParts(date: string): [number, number, number] | null {
  const match = DATE_PATTERN.exec(date.trim());
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  const probe = new Date(Date.UTC(2000, month - 1, day));
  if (probe.getUTCMonth() !== month - 1 || probe.getUTCDate() !== day) return null;
  const real = new Date(Date.UTC(year, month - 1, day));
  real.setUTCFullYear(year);
  if (real.getUTCMonth() !== month - 1 || real.getUTCDate() !== day) return null;
  return [year, month, day];
}

function pad(value: number, width = 2): string {
  return String(value).padStart(width, '0');
}

function atLocalTime(
  date: string,
  hour: number, minute: number, second: number, millis: number,
  tzOffsetMinutes?: number,
): number | null {
  const parts = dateParts(date);
  if (!parts) return null;
  const [year, month, day] = parts;
  if (tzOffsetMinutes === undefined) {
    const local = new Date(year, month - 1, day, hour, minute, second, millis);
    local.setFullYear(year);
    const time = local.getTime();
    return Number.isFinite(time) ? time : null;
  }
  if (!Number.isFinite(tzOffsetMinutes)) return null;
  const utc = Date.UTC(year, month - 1, day, hour, minute, second, millis);
  const real = new Date(utc);
  real.setUTCFullYear(year);
  const time = real.getTime() - tzOffsetMinutes * 60_000;
  return Number.isFinite(time) ? time : null;
}

/** Inclusive lower bound: 00:00:00.000 of `date`. `null` when the string is not a real date. */
export function dayStartMs(date: string, tzOffsetMinutes?: number): number | null {
  return atLocalTime(date, 0, 0, 0, 0, tzOffsetMinutes);
}

/** Inclusive upper bound: 23:59:59.999 of `date`. `null` when the string is not a real date. */
export function dayEndMs(date: string, tzOffsetMinutes?: number): number | null {
  return atLocalTime(date, 23, 59, 59, 999, tzOffsetMinutes);
}

/** An epoch value the wire contract accepts: a non-negative safe integer. */
function usableTime(time: number | null): time is number {
  return time !== null && Number.isSafeInteger(time) && time >= 0 && time <= MAX_SAFE;
}

/**
 * Build the range two DatePickers describe. Both blank is *unrestricted* (`{}`),
 * not an error. `null` means the host must not submit: an unparsable date, a date
 * before the epoch, or `from` after `to`.
 */
export function rangeFromDates(
  from: string, to: string, tzOffsetMinutes?: number,
): FlareSearchTimeRange | null {
  let fromTime: number | undefined;
  let toTime: number | undefined;
  if (from.trim() !== '') {
    const parsed = dayStartMs(from, tzOffsetMinutes);
    if (!usableTime(parsed)) return null;
    fromTime = parsed;
  }
  if (to.trim() !== '') {
    const parsed = dayEndMs(to, tzOffsetMinutes);
    if (!usableTime(parsed)) return null;
    toTime = parsed;
  }
  if (fromTime !== undefined && toTime !== undefined && fromTime > toTime) return null;
  const range: FlareSearchTimeRange = {};
  if (fromTime !== undefined) range.fromTime = fromTime;
  if (toTime !== undefined) range.toTime = toTime;
  return range;
}

function dateStringOf(time: number | undefined, tzOffsetMinutes?: number): string {
  if (time === undefined || !Number.isSafeInteger(time) || time < 0) return '';
  if (tzOffsetMinutes === undefined) {
    const local = new Date(time);
    return `${pad(local.getFullYear(), 4)}-${pad(local.getMonth() + 1)}-${pad(local.getDate())}`;
  }
  const shifted = new Date(time + tzOffsetMinutes * 60_000);
  return `${pad(shifted.getUTCFullYear(), 4)}-${pad(shifted.getUTCMonth() + 1)}-${pad(shifted.getUTCDate())}`;
}

/** Fill the DatePickers back from a range; an absent bound stays ''. */
export function datesFromRange(
  range: FlareSearchTimeRange, tzOffsetMinutes?: number,
): FlareSearchDateDraft {
  return {
    from: dateStringOf(range.fromTime, tzOffsetMinutes),
    to: dateStringOf(range.toTime, tzOffsetMinutes),
  };
}

/** Neither bound set — the "no time limit" state. */
export function unrestrictedRange(range: FlareSearchTimeRange): boolean {
  return range.fromTime === undefined && range.toTime === undefined;
}

/**
 * Which preset chip is selected. Matching is by value (`sameSearchTimeRange`), not by
 * id, because a host may rebuild its option objects on every render.
 */
export function matchedOptionId(
  value: FlareSearchTimeRange, options: readonly FlareSearchRangeOption[],
): string | null {
  for (const option of options) {
    if (sameSearchTimeRange(value, option)) return option.id;
  }
  return null;
}

/**
 * Whether the custom start/end area is expanded: never without `allowCustom`,
 * always when the host forces it, otherwise whenever the current value is a real
 * range that no preset covers (so a restored filter shows its own dates).
 */
export function shouldOpenCustomRange(
  value: FlareSearchTimeRange,
  options: readonly FlareSearchRangeOption[],
  allowCustom: boolean,
  customActive = false,
): boolean {
  if (!allowCustom) return false;
  if (customActive) return true;
  return !unrestrictedRange(value) && matchedOptionId(value, options) === null;
}
