import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flareMessages } from "../i18n/messages";
import {
  flarePluginBadgeTone,
  flarePluginChoiceCap,
  flarePluginChoiceCapped,
  flarePluginPageState,
  flarePluginRowsOnce,
  flarePluginWithinCap,
  flarePluginCheckForm,
  flarePluginCountdown,
  flarePluginDraft,
  flarePluginFallbackName,
  flarePluginFilterInputs,
  flarePluginFormValues,
  flarePluginNextCursor,
  flarePluginIssueText,
  flarePluginTimeText,
  type FlarePluginChoicesBlock,
  type FlarePluginFormError,
  type FlarePluginRow,
  type FlarePluginInput,
  type FlarePluginStrings,
  type FlarePluginViewModel,
} from "./plugin-ui";

type Vectors = {
  nowMs: number;
  fallbackNames: Array<{ userId: string; name: string }>;
  time: Array<{ name: string; atMs: number; endMs: number | null; utcOffsetMinutes: number; zh: string; en: string }>;
  countdown: Array<{ name: string; atMs: number; nowMs: number; zh: string; en: string; refreshMs: number | null }>;
  form: {
    inputs: FlarePluginInput[];
    cases: Array<{ name: string; values: Record<string, unknown>; clientErrors: FlarePluginFormError[]; submitted: Record<string, unknown> | null }>;
    hostErrors: Array<{ error: FlarePluginFormError; zh: string; en: string }>;
  };
};
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as Vectors;

/** The strings the components build, read from the built-in catalogs. */
function stringsOf(locale: "zh-CN" | "en-US"): FlarePluginStrings {
  const tree = flareMessages[locale] as unknown as { pluginView: Record<string, string>; pluginForm: Record<string, string> };
  const v = tree.pluginView;
  const f = tree.pluginForm;
  return {
    deadlinePassed: v.deadlinePassed, remaining: v.remaining, dateTime: v.dateTime, dateTimeYear: v.dateTimeYear,
    days: v.days, hours: v.hours, minutes: v.minutes,
    required: f.required, tooLong: f.tooLong, outOfRange: f.outOfRange, tooFewItems: f.tooFewItems,
    tooManyItems: f.tooManyItems, duplicateItem: f.duplicateItem, invalid: f.invalid,
  };
}
const zh = stringsOf("zh-CN");
const en = stringsOf("en-US");

describe("plugin view rules (spec/plugin-view-vectors.json)", () => {
  it.each(vectors.time.map((v) => [v.name, v] as const))("formats time blocks: %s", (_, v) => {
    expect(flarePluginTimeText(v.atMs, v.endMs, vectors.nowMs, zh, v.utcOffsetMinutes)).toBe(v.zh);
    expect(flarePluginTimeText(v.atMs, v.endMs, vectors.nowMs, en, v.utcOffsetMinutes)).toBe(v.en);
  });

  it.each(vectors.countdown.map((v) => [v.name, v] as const))("counts down: %s", (_, v) => {
    expect(flarePluginCountdown(v.atMs, v.nowMs, zh)).toEqual({ text: v.zh, refreshMs: v.refreshMs });
    expect(flarePluginCountdown(v.atMs, v.nowMs, en).text).toBe(v.en);
  });

  it("names an unresolved user by the last 4 characters of the id", () => {
    for (const v of vectors.fallbackNames) expect(flarePluginFallbackName(v.userId)).toBe(v.name);
  });

  it.each(vectors.form.cases.map((v) => [v.name, v] as const))("checks and cleans a form: %s", (_, v) => {
    const draft = flarePluginDraft(vectors.form.inputs, v.values);
    expect(flarePluginCheckForm(vectors.form.inputs, draft)).toEqual(v.clientErrors);
    if (v.submitted) expect(flarePluginFormValues(vectors.form.inputs, draft)).toEqual(v.submitted);
  });

  it("words the core SDK's form errors", () => {
    for (const { error, zh: zhText, en: enText } of vectors.form.hostErrors) {
      const input = vectors.form.inputs.find((i) => i.id === error.input);
      expect(flarePluginIssueText(error.issue, input, zh)).toBe(zhText);
      expect(flarePluginIssueText(error.issue, input, en)).toBe(enText);
    }
  });
});

describe("admin filters and detail paging (spec/plugin-view-vectors.json filterInputs, detailPaging)", () => {
  const raw = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as {
    filterInputs: { inputs: string[]; cases: Array<{ name: string; filters: string[] | null; expect: string[] }> };
  };
  const inputs = raw.filterInputs.inputs.map((id) => ({ id, kind: "text", label: id }) as FlarePluginInput);
  it.each(raw.filterInputs.cases.map((c) => [c.name, c] as const))("filters: %s", (_, c) => {
    const rows = { kind: "rows", source: "list", columns: [], rows: [], actions: [], ...(c.filters ? { filters: c.filters } : {}) };
    const view = { available: true, title: "", fields: [], actions: [], inputs, blocks: [rows] } as unknown as FlarePluginViewModel;
    expect(flarePluginFilterInputs(view).map((input) => input.id)).toEqual(c.expect);
  });
  it("treats an absent or blank cursor as the last page", () => {
    const view = { available: true, title: "", fields: [], actions: [] } as FlarePluginViewModel;
    expect(flarePluginNextCursor(view)).toBeUndefined();
    expect(flarePluginNextCursor({ ...view, nextCursor: "  " })).toBeUndefined();
    expect(flarePluginNextCursor({ ...view, nextCursor: "page-2" })).toBe("page-2");
    expect(flarePluginNextCursor(undefined)).toBeUndefined();
  });
});

describe("badges, the choices cap and pages", () => {
  it("draws a badge tone it does not know as neutral", () => {
    expect(["neutral", "info", "success", "warning", "danger"].map(flarePluginBadgeTone)).toEqual(["neutral", "info", "success", "warning", "danger"]);
    expect([undefined, "accent", 3].map(flarePluginBadgeTone)).toEqual(["neutral", "neutral", "neutral"]);
  });
  it("caps only a multiple choice with a positive whole limit", () => {
    const block = (multiple: boolean, maxSelections?: number) =>
      ({ kind: "choices", options: [], multiple, voted: false, closed: false, showResults: false, inputName: "s", maxSelections }) as FlarePluginChoicesBlock;
    expect([block(true, 2), block(false, 2), block(true, 0), block(true, 1.5), block(true)].map(flarePluginChoiceCap)).toEqual([2, undefined, undefined, undefined, undefined]);
    expect(flarePluginChoiceCapped(block(true, 2), [0, 1], 2)).toBe(true);
    expect(flarePluginChoiceCapped(block(true, 2), [0, 1], 1)).toBe(false);
    expect(flarePluginChoiceCapped(block(true, 2), [0], 2)).toBe(false);
    expect(flarePluginChoiceCapped(block(false, 2), [0, 1], 2)).toBe(false);
    expect(flarePluginWithinCap(block(true, 2), [0, 1, 2])).toBe(false);
    expect(flarePluginWithinCap(block(true), [0, 1, 2])).toBe(true);
  });
  it("keeps the first row of a repeated key", () => {
    const row = (key: string, text: string) => ({ key, cells: [{ text }], actions: [] }) as FlarePluginRow;
    expect(flarePluginRowsOnce([row("a", "1"), row("b", "2"), row("a", "3")]).map((r) => r.cells[0].text)).toEqual(["1", "2"]);
  });
  it("tells a page's state from what the host passes", () => {
    const view = { available: true, title: "", fields: [], actions: [] } as FlarePluginViewModel;
    expect(flarePluginPageState(undefined, true, undefined)).toBe("loading");
    expect(flarePluginPageState(undefined, false, undefined)).toBe("loading");
    expect(flarePluginPageState(undefined, true, "x")).toBe("loading");
    expect(flarePluginPageState(undefined, false, "x")).toBe("error");
    expect(flarePluginPageState(view, false, "x")).toBe("loaded");
    expect(flarePluginPageState({ ...view, available: false }, false, undefined)).toBe("unavailable");
  });
});
