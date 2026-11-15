// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import PluginRowsBlock from "./PluginRowsBlock.vue";
import PluginEntriesBlock from "./PluginEntriesBlock.vue";
import PluginHeroBlock from "./blocks/PluginHeroBlock.vue";
import {
  FLARE_PLUGIN_MASKED_VALUE,
  flarePluginRowDayHeadings,
  type FlarePluginStrings,
} from "../../../shared/contracts/plugin-ui";

const strings = { dateTime: "M月d日 HH:mm", dateTimeYear: "y年M月d日 HH:mm" } as FlarePluginStrings;
const labels = { today: "今天", yesterday: "昨天" };
// 2026-11-13 12:00 UTC; the tests read wall clocks at UTC.
const now = Date.UTC(2026, 10, 13, 12);
const at = (day: number, hour = 9) => Date.UTC(2026, 10, day, hour);

describe("what the account renderer showed, in plain blocks", () => {
  it("heads the rows of each day once: today, yesterday, then the date", () => {
    const block = {
      groupByDay: true,
      columns: [{ label: "金额", format: "text" as const }, { label: "时间", format: "time" as const }],
      rows: [at(13, 10), at(13, 8), at(12), at(3), Date.UTC(2025, 0, 2)].map((ms, i) => ({
        key: String(i), actions: [], cells: [{ text: "+1.00" }, { text: "", timeMs: ms }],
      })),
    };
    expect(flarePluginRowDayHeadings(block, now, strings, labels, 0)).toEqual([
      "今天", undefined, "昨天", "11月3日", "2025年1月2日",
    ]);
    expect(flarePluginRowDayHeadings({ ...block, groupByDay: false }, now, strings, labels, 0))
      .toEqual([undefined, undefined, undefined, undefined, undefined]);
    expect(flarePluginRowDayHeadings(block, now, { dateTime: "MMM d, HH:mm", dateTimeYear: "MMM d, y, HH:mm" }, labels, 0)[3])
      .toBe("Nov 3");
  });

  it("reads the shared day-heading facts", () => {
    const spec = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec/plugin-view-vectors.json"), "utf8"));
    const facts = spec.rowDays as { utcOffsetMinutes: number; timesMs: Array<number | null>; zh: Array<string | null>; en: Array<string | null> };
    const block = {
      groupByDay: true,
      columns: [{ label: "金额", format: "text" as const }, { label: "时间", format: "time" as const }],
      rows: facts.timesMs.map((ms, i) => ({ key: String(i), actions: [], cells: [{ text: "1" }, { text: "", ...(ms === null ? {} : { timeMs: ms }) }] })),
    };
    const read = (patterns: { dateTime: string; dateTimeYear: string }, labels: { today: string; yesterday: string }) =>
      flarePluginRowDayHeadings(block, spec.nowMs, patterns, labels, facts.utcOffsetMinutes).map((h) => h ?? null);
    expect(read(strings, labels)).toEqual(facts.zh);
    expect(read({ dateTime: "MMM d, HH:mm", dateTimeYear: "MMM d, y, HH:mm" }, { today: "Today", yesterday: "Yesterday" })).toEqual(facts.en);
  });

  it("draws a day heading before the first row of each day in a page list", () => {
    const host = mount(PluginRowsBlock, { props: {
      layout: "list", busy: false, strings,
      block: { kind: "rows", source: "history", groupByDay: true, actions: [],
        columns: [{ label: "金额", format: "text" }, { label: "时间", format: "time" }],
        rows: [{ key: "a", actions: [], cells: [{ text: "+1.00" }, { text: "", timeMs: Date.now() }] },
               { key: "b", actions: [], cells: [{ text: "-2.00" }, { text: "", timeMs: Date.now() }] }] },
    } });
    expect(host.findAll("[data-row-day]")).toHaveLength(1);
    expect(host.findAll("[data-row-key]")).toHaveLength(2);
    host.unmount();
  });

  it("shows an entry's time after its text", () => {
    const host = mount(PluginEntriesBlock, { props: {
      userOf: () => ({ name: "Bob" }),
      timeText: (ms: number) => `t${ms}`,
      block: { kind: "entries", numbered: false, total: 2, more: false, items: [
        { index: 1, text: "5.00", userId: "bob", timeMs: 7 },
        { index: 2, text: "3.00", userId: "carol" },
      ] },
    } });
    const times = host.findAll("[data-entry-time]");
    expect(times).toHaveLength(1);
    expect(times[0].text()).toBe("t7");
    host.unmount();
  });

  it("hides a maskable hero's value behind its eye, and only a maskable one", async () => {
    const host = mount(PluginHeroBlock, { props: {
      block: { kind: "hero", label: "可用余额", value: "12.00", amount: true, tone: "brand", maskable: true },
    } });
    expect(host.get("[data-hero-value]").text()).toBe("12.00");
    await host.get("[data-hero-mask]").trigger("click");
    expect(host.get("[data-hero-value]").text()).toBe(FLARE_PLUGIN_MASKED_VALUE);
    await host.get("[data-hero-mask]").trigger("click");
    expect(host.get("[data-hero-value]").text()).toBe("12.00");
    host.unmount();
    const plain = mount(PluginHeroBlock, { props: {
      block: { kind: "hero", label: "可用余额", value: "12.00", amount: true, tone: "brand" },
    } });
    expect(plain.find("[data-hero-mask]").exists()).toBe(false);
    plain.unmount();
  });
});
