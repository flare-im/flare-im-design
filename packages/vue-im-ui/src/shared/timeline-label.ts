/**
 * Locale-aware time labels shared by the timeline, the message bubble, the
 * conversation row and host lists. Every label follows the given locale's own
 * conventions; nothing here assumes Chinese or English ordering.
 */

function sameDay(left: Date, right: Date): boolean {
  return left.getDate() === right.getDate() && left.getMonth() === right.getMonth() && left.getFullYear() === right.getFullYear();
}

// Building an Intl.DateTimeFormat costs far more than formatting with one, and a timeline asks
// for a label per bubble; keep one formatter per locale and shape.
const formatters = new Map<string, Intl.DateTimeFormat>();
function formatter(locale: string, shape: "time" | "day" | "date"): Intl.DateTimeFormat {
  const key = `${shape}\u0000${locale}`;
  let cached = formatters.get(key);
  if (!cached) {
    if (shape === "time") {
      // 24-hour locales keep two-digit hours (09:05); 12-hour locales drop the zero (9:05 AM).
      const hourCycle = new Intl.DateTimeFormat(locale, { hour: "numeric" }).resolvedOptions().hourCycle;
      const hour = hourCycle === "h23" || hourCycle === "h24" ? "2-digit" : "numeric";
      cached = new Intl.DateTimeFormat(locale, { hour, minute: "2-digit" });
    } else {
      cached = new Intl.DateTimeFormat(locale, shape === "day" ? { month: "numeric", day: "numeric" } : { year: "numeric", month: "numeric", day: "numeric" });
    }
    formatters.set(key, cached);
  }
  return cached;
}

function isYesterday(date: Date, now: Date): boolean {
  const yesterday = new Date(now);
  yesterday.setDate(now.getDate() - 1);
  return sameDay(date, yesterday);
}

/** Hour and minute in the locale's convention: 09:05 in 24-hour locales, 9:05 AM in 12-hour ones. */
export function formatMessageTime(timestamp: number, locale: string): string {
  return formatter(locale, "time").format(new Date(timestamp));
}

function formatDay(date: Date, locale: string, now: Date): string {
  return formatter(locale, date.getFullYear() === now.getFullYear() ? "day" : "date").format(date);
}

/**
 * The time beside a conversation: the time today, `yesterday` (the host's localized
 * word) the day before, the month and day earlier this year, the full date before that.
 */
export function formatConversationTime(timestamp: number, locale: string, yesterday: string, now: number = Date.now()): string {
  const date = new Date(timestamp);
  const today = new Date(now);
  if (sameDay(date, today)) return formatMessageTime(timestamp, locale);
  if (isYesterday(date, today)) return yesterday;
  return formatDay(date, locale, today);
}

/**
 * How long ago, for feeds such as moments and comments: seconds read as "now", then
 * minutes, hours and days up to a week, then the date.
 */
export function formatRelativeTime(timestamp: number, locale: string, now: number = Date.now()): string {
  const elapsed = Math.max(0, now - timestamp);
  const relative = new Intl.RelativeTimeFormat(locale, { numeric: "auto" });
  if (elapsed < 60_000) return relative.format(0, "second");
  if (elapsed < 3_600_000) return relative.format(-Math.floor(elapsed / 60_000), "minute");
  if (elapsed < 86_400_000) return relative.format(-Math.floor(elapsed / 3_600_000), "hour");
  if (elapsed < 7 * 86_400_000) return relative.format(-Math.floor(elapsed / 86_400_000), "day");
  return formatDay(new Date(timestamp), locale, new Date(now));
}

/**
 * Label of a timeline date separator. Every bubble already shows its own time, so separators
 * mark days only: the host's localized "today" and "yesterday", then the locale's date (with
 * the year when it differs). Absolute, so a separator never goes stale while the chat is open.
 */
export function timelineDateLabel(
  timestamp: number,
  locale: string,
  labels: { today: string; yesterday: string },
  now: number = Date.now(),
): string {
  const date = new Date(timestamp);
  const today = new Date(now);
  if (sameDay(date, today)) return labels.today;
  if (isYesterday(date, today)) return labels.yesterday;
  return formatDay(date, locale, today);
}

/** True when a date separator belongs before `current`: the first message, or a new day. */
export function startsTimelineDay(previous: number, current: number): boolean {
  if (!current) return false;
  if (!previous) return true;
  return !sameDay(new Date(previous), new Date(current));
}
