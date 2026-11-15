/**
 * NotificationAlertSettings contract: a person's notification preferences — quiet hours, what notifications show, and
 * how the phone alerts while another device is in use. The value has the protocol's own shape (minutes after
 * midnight in device local time; weekdays as bits, bit 0 Monday … bit 6 Sunday, 0 every day), so the host passes the
 * user notification settings through. The host reads and writes them; the component shows and reports.
 *
 * The rules are spec/notification-alert-vectors.json, which the four kits run.
 */

/** What a notification shows: the sender and the message, the sender only, or neither. */
export type FlareNotificationPreview = "full" | "senderOnly" | "hidden";

/** How the phone alerts while the person is using another device. */
export type FlareMultiDeviceAlert = "delay" | "immediate" | "badgeOnly";

export interface FlareQuietHours {
  /** Whether quiet hours apply; the times are kept while they are off. */
  enabled: boolean;
  /** Minutes after midnight, 0 to 1439. */
  startMinute: number;
  /** Minutes after midnight; not after the start means the next day (equal is the whole day). */
  endMinute: number;
  /** Bits, bit 0 Monday … bit 6 Sunday; 0 is every day. */
  weekdays: number;
  /** Messages that mention the person still alert. */
  allowMentions: boolean;
}

export interface FlareNotificationAlertPreferences {
  quietHours: FlareQuietHours;
  preview: FlareNotificationPreview;
  multiDevice: FlareMultiDeviceAlert;
}

export const notificationPreviews: readonly FlareNotificationPreview[] = ["full", "senderOnly", "hidden"];
export const multiDeviceAlerts: readonly FlareMultiDeviceAlert[] = ["delay", "immediate", "badgeOnly"];

/** What a person who never chose has: quiet hours off (22:00 to 08:00 every day, mentions allowed), full preview, delay. */
export const defaultNotificationAlertPreferences: FlareNotificationAlertPreferences = Object.freeze({
  quietHours: Object.freeze({ enabled: false, startMinute: 22 * 60, endMinute: 8 * 60, weekdays: 0, allowMentions: true }),
  preview: "full",
  multiDevice: "delay",
}) as FlareNotificationAlertPreferences;

/** Row keys, stable for tests and for a settings page that lists the sections among its own (other keys). */
export const QUIET_HOURS_ROW = "quietHours";
export const QUIET_HOURS_START_ROW = "quietHoursStart";
export const QUIET_HOURS_END_ROW = "quietHoursEnd";
export const QUIET_HOURS_REPEAT_ROW = "quietHoursRepeat";
export const QUIET_HOURS_ALLOW_MENTIONS_ROW = "quietHoursAllowMentions";
export const NOTIFICATION_PREVIEW_ROW = "notificationPreview";
export const MULTI_DEVICE_ROW = "multiDevice";

/** Every day, as bits. 0 means the same. */
export const ALL_WEEKDAYS = 0b1111111;
/** The minute step of the start and end pickers. */
export const QUIET_HOURS_MINUTE_STEP = 5;

const MINUTES_PER_DAY = 24 * 60;

/** A minute of the day as HH:mm, 24-hour; minutes are taken modulo a day. */
export function formatMinuteOfDay(minute: number): string {
  const m = ((Math.round(minute) % MINUTES_PER_DAY) + MINUTES_PER_DAY) % MINUTES_PER_DAY;
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

/** HH:mm as a minute of the day; anything else reads as midnight. */
export function parseMinuteOfDay(text: string): number {
  const [h, m] = text.split(":").map((part) => Number(part));
  if (!Number.isFinite(h) || !Number.isFinite(m)) return 0;
  return (Math.min(23, Math.max(0, h)) * 60) + Math.min(59, Math.max(0, m));
}

/** Whether the end is on the next day: it is not after the start (equal is the whole day). */
export function quietHoursEndsNextDay(quietHours: Pick<FlareQuietHours, "startMinute" | "endMinute">): boolean {
  return quietHours.endMinute <= quietHours.startMinute;
}

/** Whether `day` (0 Monday … 6 Sunday) is in `mask`; 0 is every day. */
export function weekdayIsOn(mask: number, day: number): boolean {
  const days = mask & ALL_WEEKDAYS;
  return days === 0 || (days & (1 << day)) !== 0;
}

/** `mask` with `day` turned on or off. 0 starts from all seven; all seven is written 0; no day left changes nothing. */
export function weekdayToggle(mask: number, day: number, on: boolean): number {
  const days = (mask & ALL_WEEKDAYS) === 0 ? ALL_WEEKDAYS : mask & ALL_WEEKDAYS;
  const next = on ? days | (1 << day) : days & ~(1 << day);
  if (next === 0) return mask;
  return next === ALL_WEEKDAYS ? 0 : next;
}

/** How a weekday mask reads: every day, Monday to Friday, the weekend, or the days in week order. */
export type FlareWeekdaySummary =
  | { kind: "everyDay" }
  | { kind: "weekdays" }
  | { kind: "weekends" }
  | { kind: "days"; days: number[] };

export function weekdaySummary(mask: number): FlareWeekdaySummary {
  const days = mask & ALL_WEEKDAYS;
  if (days === 0 || days === ALL_WEEKDAYS) return { kind: "everyDay" };
  if (days === 0b0011111) return { kind: "weekdays" };
  if (days === 0b1100000) return { kind: "weekends" };
  return { kind: "days", days: [0, 1, 2, 3, 4, 5, 6].filter((day) => (days & (1 << day)) !== 0) };
}
