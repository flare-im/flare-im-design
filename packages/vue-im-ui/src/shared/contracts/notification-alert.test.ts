import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  defaultNotificationAlertPreferences,
  formatMinuteOfDay,
  parseMinuteOfDay,
  quietHoursEndsNextDay,
  weekdayIsOn,
  weekdaySummary,
  weekdayToggle,
} from "./notification-alert";

/**
 * The shared table (`spec/notification-alert-vectors.json`) behind NotificationAlertSettings: times, the next-day end,
 * the weekday picks and their summary. The Flutter, SwiftUI and Compose kits run the same file; the words of the
 * summary and the end are checked in the component's test.
 */
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/notification-alert-vectors.json"), "utf8")) as {
  time: { minute: number; text: string }[];
  end: { start: number; end: number; nextDay: boolean }[];
  weekdayToggle: { mask: number; day: number; on: boolean; result: number }[];
  weekdayOn: { mask: number; day: number; on: boolean }[];
  summary: { mask: number; kind: string }[];
};

describe("notification alert rules", () => {
  it.each(table.time)("reads minute $minute as $text", ({ minute, text }) => {
    expect(formatMinuteOfDay(minute)).toBe(text);
    if (minute < 1440) expect(parseMinuteOfDay(text)).toBe(minute);
  });

  it.each(table.end)("ends on the next day from $start to $end: $nextDay", ({ start, end, nextDay }) => {
    expect(quietHoursEndsNextDay({ startMinute: start, endMinute: end })).toBe(nextDay);
  });

  it.each(table.weekdayToggle)("turns day $day of $mask to $on: $result", ({ mask, day, on, result }) => {
    expect(weekdayToggle(mask, day, on)).toBe(result);
  });

  it.each(table.weekdayOn)("day $day is in $mask: $on", ({ mask, day, on }) => {
    expect(weekdayIsOn(mask, day)).toBe(on);
  });

  it.each(table.summary)("summarises $mask as $kind", ({ mask, kind }) => {
    expect(weekdaySummary(mask).kind).toBe(kind);
  });

  it("starts with quiet hours off from 22:00 to 08:00 every day, full preview and a delay", () => {
    expect(defaultNotificationAlertPreferences).toEqual({
      quietHours: { enabled: false, startMinute: 1320, endMinute: 480, weekdays: 0, allowMentions: true },
      preview: "full",
      multiDevice: "delay",
    });
  });
});
