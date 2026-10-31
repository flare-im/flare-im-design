import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { flareMessages } from "./i18n/messages";
import { flarePluginCountdown, type FlarePluginStrings } from "./contracts/plugin-ui";
import { regenerateAvailability } from "./contracts/invite";
import { flareServerClockOffset, flareServerNow, flareServerNowMs, setFlareServerClockOffset } from "./server-clock";

type Vectors = {
  now: Array<{ id: string; deviceNowMs: number; offsetMs: number | null; expected: number }>;
  countdown: Array<{
    id: string; atMs: number; deviceNowMs: number; offsetMs: number | null;
    zh: string; en: string; refreshMs: number | null; deviceClockZh: string;
  }>;
  regenerate: Array<{
    id: string; canRegenerate: boolean; availableAt: number; deviceNowMs: number; offsetMs: number | null;
    expected: ReturnType<typeof regenerateAvailability>; deviceClockEnabled: boolean;
  }>;
};
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/server-clock-vectors.json"), "utf8")) as Vectors;

function stringsOf(locale: "zh-CN" | "en-US"): FlarePluginStrings {
  const v = (flareMessages[locale] as unknown as { pluginView: Record<string, string> }).pluginView;
  return {
    deadlinePassed: v.deadlinePassed, remaining: v.remaining, dateTime: v.dateTime, dateTimeYear: v.dateTimeYear,
    days: v.days, hours: v.hours, minutes: v.minutes,
  } as FlarePluginStrings;
}
const zh = stringsOf("zh-CN");
const en = stringsOf("en-US");

afterEach(() => {
  setFlareServerClockOffset(null);
  vi.useRealTimers();
});

describe("server clock (spec/server-clock-vectors.json)", () => {
  it.each(vectors.now)("server now: $id", (v) => {
    expect(flareServerNow(v.deviceNowMs, v.offsetMs)).toBe(v.expected);
  });

  it.each(vectors.countdown)("counts down on the server clock: $id", (v) => {
    const now = flareServerNow(v.deviceNowMs, v.offsetMs);
    expect(flarePluginCountdown(v.atMs, now, zh)).toEqual({ text: v.zh, refreshMs: v.refreshMs });
    expect(flarePluginCountdown(v.atMs, now, en).text).toBe(v.en);
    expect(flarePluginCountdown(v.atMs, v.deviceNowMs, zh).text).toBe(v.deviceClockZh);
  });

  it.each(vectors.regenerate)("cools down on the server clock: $id", (v) => {
    expect(regenerateAvailability(v.canRegenerate, v.availableAt, flareServerNow(v.deviceNowMs, v.offsetMs))).toEqual(v.expected);
    expect(regenerateAvailability(v.canRegenerate, v.availableAt, v.deviceNowMs).enabled).toBe(v.deviceClockEnabled);
  });

  it("reads the device clock plus the offset the host handed in", () => {
    vi.useFakeTimers();
    vi.setSystemTime(1_792_634_700_000);
    expect(flareServerNowMs()).toBe(1_792_634_700_000);
    setFlareServerClockOffset(-300_000);
    expect(flareServerClockOffset()).toBe(-300_000);
    expect(flareServerNowMs()).toBe(1_792_634_400_000);
    setFlareServerClockOffset(null);
    expect(flareServerNowMs()).toBe(1_792_634_700_000);
  });

  it("an offset that is not a finite number is no offset", () => {
    for (const bad of [Number.NaN, Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY, "300000" as unknown as number, undefined]) {
      setFlareServerClockOffset(-300_000);
      setFlareServerClockOffset(bad);
      expect(flareServerClockOffset()).toBe(0);
    }
    setFlareServerClockOffset(1_500.9);
    expect(flareServerClockOffset()).toBe(1_500);
    setFlareServerClockOffset(-1_500.9);
    expect(flareServerClockOffset()).toBe(-1_500);
  });
});
