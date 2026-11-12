import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flareMessages } from "../i18n/messages";
import {
  flarePluginBannerTone,
  flarePluginChartHasPoints,
  flarePluginCheckInput,
  flarePluginCompareDecimal,
  flarePluginDonutSlices,
  flarePluginDraftValue,
  flarePluginFlatBlocks,
  flarePluginFormatText,
  flarePluginFormValues,
  flarePluginHeroTone,
  flarePluginImageRatio,
  flarePluginIsUpload,
  flarePluginMoneyAmount,
  flarePluginQrExpired,
  flarePluginQrRefreshMs,
  flarePluginStepState,
  flarePluginTrendDirection,
  flarePluginUnavailableKey,
  flarePluginUpgradeMode,
  type FlarePluginBlock,
  type FlarePluginChartSeries,
  type FlarePluginFormat,
  type FlarePluginInput,
  type FlarePluginUnavailableReason,
  type FlarePluginUpgradeStatus,
} from "./plugin-ui";
import { PLUGIN_UI_VOCABULARY } from "./plugin-ui-vocabulary";

type Units = { days: string; hours: string; minutes: string; seconds: string; countUnits: string };
type Vectors = {
  unavailableReasons: Array<{ reason: FlarePluginUnavailableReason; key: string; zh: string; en: string }>;
  formats2: {
    strings: { zh: Units; en: Units };
    cases: Array<{ format: FlarePluginFormat; text: string; zh: string; en: string }>;
  };
  blocks2: {
    steps: Array<{ state: string; expect: string }>;
    trend: Array<{ direction: string; expect: string }>;
    bannerTone: Array<{ tone: string; expect: string }>;
    heroTone: Array<{ tone: string; expect: string }>;
    imageRatio: Array<{ aspect: string; expect: number }>;
    qr: Array<{ expiresAtMs: number | null; nowMs: number; expired: boolean; refreshMs: number | null }>;
    donut: Array<{ values: number[]; expect: Array<{ index: number; start: number; sweep: number }> }>;
    flatten: { blocks: FlarePluginBlock[]; expect: Array<{ kind: string; section?: number }> };
    chartHasPoints: Array<{ series: FlarePluginChartSeries[]; expect: boolean }>;
  };
  moneyInput: {
    input: FlarePluginInput;
    normalize: Array<{ typed: string; expect: string }>;
    check: Array<{ input?: FlarePluginInput; draft: string; expect: string | null }>;
    values: Array<{ draft: string; expect: Record<string, string> | null }>;
    drafts: Array<{ value: unknown; expect: string }>;
    compare: Array<{ a: string; b: string; expect: number }>;
  };
  upgradeNotice: Array<{ status: FlarePluginUpgradeStatus | null; canUpdate: boolean; expect: string }>;
};
const vectors = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8"),
) as Vectors;
const source = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../../spec/plugin-ui-vocabulary.json"), "utf8"),
) as { vocabulary: Record<string, unknown>; kits: Record<string, { omit: Record<string, string[]> }> };

describe("plugin vocabulary 2 formats (spec formats2)", () => {
  for (const locale of ["zh", "en"] as const) {
    const units = vectors.formats2.strings[locale];
    it.each(vectors.formats2.cases)(`writes $format.kind $text in ${locale}`, (c) => {
      const text = flarePluginFormatText(c.text, c.format, {
        nowMs: 0,
        strings: { dateTime: "", dateTimeYear: "", ...units },
        unavailable: "",
      });
      expect(text).toBe(c[locale]);
    });
  }
  it("keeps the text without the units", () => {
    expect(
      flarePluginFormatText("12345", { kind: "count", count: 12345 }, { nowMs: 0, strings: { dateTime: "", dateTimeYear: "" }, unavailable: "" }),
    ).toBe("12345");
  });
  it("matches the kit copy for the units", () => {
    for (const locale of ["zh", "en"] as const) {
      const messages = flareMessages[locale === "zh" ? "zh-CN" : "en-US"] as unknown as {
        pluginView: Record<string, string>;
      };
      const units = vectors.formats2.strings[locale];
      expect(messages.pluginView.countUnits).toBe(units.countUnits);
      expect(messages.pluginView.seconds).toBe(units.seconds);
      expect(messages.pluginView.days).toBe(units.days);
      expect(messages.pluginView.hours).toBe(units.hours);
      expect(messages.pluginView.minutes).toBe(units.minutes);
    }
  });
});

describe("plugin vocabulary 2 blocks (spec blocks2)", () => {
  it.each(vectors.blocks2.steps)("draws step state $state as $expect", (c) => expect(flarePluginStepState(c.state)).toBe(c.expect));
  it.each(vectors.blocks2.trend)("draws trend $direction as $expect", (c) => expect(flarePluginTrendDirection(c.direction)).toBe(c.expect));
  it.each(vectors.blocks2.bannerTone)("draws banner tone $tone as $expect", (c) => expect(flarePluginBannerTone(c.tone)).toBe(c.expect));
  it.each(vectors.blocks2.heroTone)("draws hero tone $tone as $expect", (c) => expect(flarePluginHeroTone(c.tone)).toBe(c.expect));
  it.each(vectors.blocks2.imageRatio)("frames aspect $aspect", (c) => expect(flarePluginImageRatio(c.aspect)).toBeCloseTo(c.expect, 12));
  it.each(vectors.blocks2.qr)("expires a code at $expiresAtMs seen at $nowMs", (c) => {
    const block = c.expiresAtMs === null ? {} : { expiresAtMs: c.expiresAtMs };
    expect(flarePluginQrExpired(block, c.nowMs)).toBe(c.expired);
    expect(flarePluginQrRefreshMs(block, c.nowMs)).toBe(c.refreshMs);
  });
  it.each(vectors.blocks2.donut)("slices a donut of $values", (c) => {
    const slices = flarePluginDonutSlices(c.values.map((value) => ({ value })));
    expect(slices.map((s) => s.index)).toEqual(c.expect.map((s) => s.index));
    slices.forEach((slice, i) => {
      expect(slice.start).toBeCloseTo(c.expect[i].start, 12);
      expect(slice.sweep).toBeCloseTo(c.expect[i].sweep, 12);
    });
  });
  it("puts a section's children after its heading", () => {
    const flat = flarePluginFlatBlocks(vectors.blocks2.flatten.blocks).map((item) => ({
      kind: item.block.kind,
      ...(item.section === undefined ? {} : { section: item.section }),
    }));
    expect(flat).toEqual(vectors.blocks2.flatten.expect);
  });
  it.each(vectors.blocks2.chartHasPoints)("says whether a chart has points", (c) =>
    expect(flarePluginChartHasPoints({ series: c.series })).toBe(c.expect));
});

describe("plugin money, image and document inputs (spec moneyInput)", () => {
  const money = vectors.moneyInput.input;
  it.each(vectors.moneyInput.normalize)("normalizes '$typed'", (c) => expect(flarePluginMoneyAmount(c.typed)).toBe(c.expect));
  it.each(vectors.moneyInput.check)("checks '$draft'", (c) => expect(flarePluginCheckInput(c.input ?? money, c.draft)).toBe(c.expect));
  it.each(vectors.moneyInput.values)("submits '$draft'", (c) => {
    const values = flarePluginFormValues([money], { [money.id]: c.draft });
    expect(values[money.id] ?? null).toEqual(c.expect);
  });
  it.each(vectors.moneyInput.drafts)("drafts $value", (c) => {
    expect(flarePluginDraftValue(money, c.value === null ? {} : { [money.id]: c.value })).toBe(c.expect);
  });
  it.each(vectors.moneyInput.compare)("orders $a and $b", (c) => expect(flarePluginCompareDecimal(c.a, c.b)).toBe(c.expect));
  it("treats image and document like file", () => {
    for (const kind of ["file", "image", "document"] as const) {
      expect(flarePluginIsUpload(kind)).toBe(true);
      const input: FlarePluginInput = { id: "photo", kind, label: "Photo", required: true };
      expect(flarePluginCheckInput(input, null)).toBe("required");
      expect(flarePluginCheckInput(input, { fileId: "f_1" })).toBeNull();
      expect(flarePluginFormValues([input], { photo: { fileId: "f_1" } })).toEqual({ photo: { fileId: "f_1" } });
      expect(flarePluginDraftValue(input, { photo: { fileId: "f_1", url: "https://x" } })).toBeNull();
    }
    expect(flarePluginIsUpload("text")).toBe(false);
  });
});

describe("plugin upgrade notice (spec upgradeNotice)", () => {
  it.each(vectors.upgradeNotice)("shows $expect", (c) => expect(flarePluginUpgradeMode(c.status, c.canUpdate)).toBe(c.expect));
  it("has copy for upgrade_required", () => {
    const entry = vectors.unavailableReasons.find((r) => r.reason === "upgrade_required")!;
    const key = flarePluginUnavailableKey(entry.reason);
    expect(key).toBe("pluginView.unavailable.upgradeRequired");
    const zh = flareMessages["zh-CN"] as unknown as { pluginView: { unavailable: Record<string, string> } };
    const en = flareMessages["en-US"] as unknown as { pluginView: { unavailable: Record<string, string> } };
    expect(zh.pluginView.unavailable.upgradeRequired).toBe(entry.zh);
    expect(en.pluginView.unavailable.upgradeRequired).toBe(entry.en);
  });
});

describe("PLUGIN_UI_VOCABULARY", () => {
  it("is the shared vocabulary without the Vue kit's omissions", () => {
    const omit = source.kits.vue.omit;
    for (const set of ["blocks", "inputs", "formats", "actions", "native", "renderers", "kinds"] as const) {
      const expected = (source.vocabulary[set] as string[]).filter((name) => !(omit[set] ?? []).includes(name)).sort();
      expect([...PLUGIN_UI_VOCABULARY[set]]).toEqual(expected);
    }
    expect(PLUGIN_UI_VOCABULARY.version).toBe(source.vocabulary.version);
  });
  it("names every block the view draws", () => {
    for (const kind of ["section", "stats", "chart", "image", "qr", "hero", "steps", "banner", "timeline"])
      expect(PLUGIN_UI_VOCABULARY.blocks).toContain(kind);
  });
});
