// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { defineComponent, h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import FlareChartCard from "./FlareChartCard.vue";
import type { FlareChartPoint } from "./chart-geometry";

function mountChart(props: Record<string, unknown>, locale: FlareLocale = "zh-CN", slots: Record<string, () => unknown> = {}) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareChartCard as Component, props, slots);
    },
  }));
  return host.findComponent(FlareChartCard);
}

const week: FlareChartPoint[] = [
  { label: "9/24", value: 1200 },
  { label: "9/25", value: 980 },
  { label: "9/26", value: null },
  { label: "9/27", value: 1534 },
];

describe("FlareChartCard", () => {
  it("names the plot role=img with a numeric summary and carries every reading as text", () => {
    const card = mountChart({ title: "每日活跃", points: week, unit: "人" });
    const section = card.get("section");
    expect(card.get(`#${section.attributes("aria-labelledby")}`).text()).toBe("每日活跃");

    const plot = card.get("svg");
    expect(plot.attributes("role")).toBe("img");
    expect(plot.attributes("aria-label")).toBe("每日活跃，4 个数据点，从 9/24 到 9/27。最小 980 人，最大 1,534 人，最新 1,534 人。");

    // The table only assistive technology reads: every label with its value, a gap as "no data".
    const rows = card.findAll("table tbody tr").map((row) => [row.get("th").text(), row.get("td").text()]);
    expect(rows).toEqual([["9/24", "1,200 人"], ["9/25", "980 人"], ["9/26", "无数据"], ["9/27", "1,534 人"]]);
    expect(card.get("table caption").text()).toBe("每日活跃");

    // The scale and the axis labels are the sighted half; they are hidden from assistive technology.
    expect(card.get(".flare-chart-card__scale").attributes("aria-hidden")).toBe("true");
    expect(card.get(".flare-chart-card__labels").attributes("aria-hidden")).toBe("true");
    expect(card.findAll(".flare-chart-card__labels span").map((label) => label.text())).toEqual(["9/24", "9/27"]);

    // Hover titles, one per slot, gap included.
    expect(card.findAll(".flare-chart-card__slots title").map((title) => title.text())).toEqual([
      "9/24：1,200 人", "9/25：980 人", "9/26：无数据", "9/27：1,534 人",
    ]);
    // A missing reading has no bar.
    expect(card.findAll(".flare-chart-card__bars rect")).toHaveLength(3);
  });

  it("draws the empty text, not an empty axis, when there is no reading", () => {
    for (const points of [[], [{ label: "9/24", value: null }]]) {
      const card = mountChart({ title: "群组总数", points });
      expect(card.find("svg").exists()).toBe(false);
      expect(card.find("table").exists()).toBe(false);
      expect(card.get(".flare-chart-card__empty").text()).toBe("暂无数据");
    }
    expect(mountChart({ title: "群组总数", points: [], emptyText: "还没有用量数据" }).get(".flare-chart-card__empty").text()).toBe("还没有用量数据");
  });

  it("draws a single reading as one bar, or as one dot on a line chart", () => {
    const one = [{ label: "今天", value: 7 }];
    const bar = mountChart({ title: "新增", points: one });
    expect(bar.findAll(".flare-chart-card__bars rect")).toHaveLength(1);
    expect(bar.get("svg").attributes("aria-label")).toBe("新增，1 个数据点：今天 7。");
    expect(bar.get(".flare-chart-card__labels").classes()).toContain("is-single");

    const line = mountChart({ title: "新增", points: one, kind: "line" });
    expect(line.find(".flare-chart-card__stroke").exists()).toBe(false);
    expect(line.findAll(".flare-chart-card__dot")).toHaveLength(1);
    expect(line.get(".flare-chart-card__dot").attributes("d")).toMatch(/^M50 [\d.]+ L50 [\d.]+$/);
  });

  it("draws an all-zero series on the zero line alone, with no NaN anywhere", () => {
    const zeros = [{ label: "a", value: 0 }, { label: "b", value: 0 }, { label: "c", value: 0 }];
    for (const kind of ["bar", "line"]) {
      const card = mountChart({ title: "撤回", points: zeros, kind });
      expect(card.html()).not.toMatch(/NaN|Infinity/);
      expect(card.findAll(".flare-chart-card__grid line")).toHaveLength(1);
      expect(card.findAll(".flare-chart-card__tick").map((tick) => tick.text())).toEqual(["0"]);
      expect(card.get("svg").attributes("aria-label")).toBe("撤回，3 个数据点，从 a 到 c。最小 0，最大 0，最新 0。");
    }
    const bars = mountChart({ title: "撤回", points: zeros }).findAll(".flare-chart-card__bars rect");
    expect(bars.map((bar) => bar.attributes("height"))).toEqual(["0", "0", "0"]);
  });

  it("speaks the kit's language: summary, table and digits follow the locale", () => {
    const card = mountChart({ title: "Daily active", points: week, unit: "%" }, "en-US");
    expect(card.get("svg").attributes("aria-label")).toBe("Daily active, 4 points from 9/24 to 9/27. Lowest 980%, highest 1,534%, latest 1,534%.");
    expect(card.findAll("table thead th").map((cell) => cell.text())).toEqual(["Label", "Value"]);
    expect(card.findAll("table tbody td")[2].text()).toBe("no data");
    // A lone-symbol unit also marks the scale; the scale abbreviates.
    expect(card.findAll(".flare-chart-card__tick").map((tick) => tick.text())).toEqual(["2K%", "1K%", "0%"]);
    expect(mountChart({ title: "空", points: [] }, "en-US").get(".flare-chart-card__empty").text()).toBe("No data yet");
    // `locale` overrides the kit's language for the digits only.
    const german = mountChart({ title: "Daily active", points: week, locale: "de-DE" }, "en-US");
    expect(german.findAll("table tbody td")[3].text()).toBe("1.534");
  });

  it("holds the plot's place while loading and says so", () => {
    const card = mountChart({ title: "每日活跃", points: week, loading: true });
    expect(card.get("section").attributes("aria-busy")).toBe("true");
    expect(card.find("svg").exists()).toBe(false);
    expect(card.get(".flare-chart-card__placeholder").attributes("aria-hidden")).toBe("true");
    expect(card.get(".flare-chart-card__state").text()).toBe("正在加载");
    expect(mountChart({ title: "每日活跃", points: week }).get("section").attributes("aria-busy")).toBeUndefined();
  });

  it("puts the host's controls in the header and its note under the plot", () => {
    const card = mountChart({ title: "每日活跃", points: week }, "zh-CN", {
      extra: () => h("button", { type: "button" }, "导出"),
      footer: () => "采集时间 08:00",
    });
    expect(card.get(".flare-chart-card__extra button").text()).toBe("导出");
    expect(card.get("footer").text()).toBe("采集时间 08:00");
    expect(mountChart({ title: "每日活跃", points: week }).find(".flare-chart-card__extra").exists()).toBe(false);
  });

  it("maps the tone to a series colour class and a line chart to stroke, area and latest dot", () => {
    const card = mountChart({ title: "在线", points: week, kind: "line", tone: "success" });
    expect(card.get("section").classes()).toContain("flare-chart-card--success");
    expect(card.get("section").attributes("data-kind")).toBe("line");
    expect(card.get(".flare-chart-card__stroke").attributes("d")).toMatch(/^M12\.5 [\d.]+ L37\.5 [\d.]+$/);
    expect(card.find(".flare-chart-card__area").exists()).toBe(true);
    // The run after the gap is one reading long, and it is also the latest: one dot.
    expect(card.findAll(".flare-chart-card__dot")).toHaveLength(1);
  });
});

describe("FlareChartCard in dark mode", () => {
  const source = readFileSync(resolve(__dirname, "FlareChartCard.vue"), "utf8");
  const tokens = readFileSync(resolve(__dirname, "../../../../../tokens/dist/tokens.css"), "utf8");
  const dark = /\[data-flare-theme="dark"\]\s*\{([^}]*)\}/.exec(tokens)?.[1] ?? "";

  it("paints only with theme tokens, each of which dark mode redefines", () => {
    const style = source.slice(source.indexOf("<style"));
    const colours = [...new Set([...style.matchAll(/var\((--flare-color-[\w-]+)\)/g)].map((match) => match[1]))];
    expect(colours.length).toBeGreaterThan(5);
    for (const token of colours) expect(dark, `${token} has no dark value`).toContain(`${token}:`);
    // No literal colour anywhere in the component — not in the style, not on an SVG node.
    expect(source).not.toMatch(/#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(/);
    expect(source).not.toMatch(/\s(?:fill|stroke)="/);
  });

  // WCAG 1.4.11: the series is a graphic the reader needs, so it clears 3:1 against the card in every
  // brand, light and dark. Fill tokens such as --flare-color-primary do not (1.80–2.66:1 in dark).
  it("draws every tone's series at 3:1 or more against the card, in every brand and both modes", () => {
    const blocks = [...tokens.matchAll(/([^{}]+)\{([^}]*)\}/g)].map((match) => ({
      // The last line of the prelude: the first block is preceded by the generator's banner comment.
      selector: match[1].trim().split("\n").pop()?.trim() ?? "",
      vars: Object.fromEntries([...match[2].matchAll(/(--[\w-]+):\s*([^;]+);/g)].map((decl) => [decl[1], decl[2].trim()])),
    }));
    const block = (selector: string) => blocks.find((entry) => entry.selector === selector)?.vars ?? {};
    const rgb = (value: string, under?: number[]): number[] => {
      const hex = /^#([0-9a-f]{6})$/i.exec(value);
      if (hex) return [0, 2, 4].map((i) => parseInt(hex[1].slice(i, i + 2), 16));
      const rgba = /^rgba?\(([^)]+)\)$/.exec(value);
      if (!rgba) throw new Error(`unreadable colour ${value}`);
      const [r, g, b, a = 1] = rgba[1].split(",").map((part) => Number(part.trim()));
      return [r, g, b].map((channel, i) => channel * a + (under ? under[i] * (1 - a) : 255 * (1 - a)));
    };
    const luminance = (channels: number[]) => {
      const [r, g, b] = channels.map((c) => c / 255).map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    };
    const contrast = (a: number[], b: number[]) => {
      const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
      return (hi + 0.05) / (lo + 0.05);
    };
    const series = [...source.matchAll(/--flare-chart-card-series:\s*var\((--flare-color-[\w-]+)\)/g)].map((match) => match[1]);
    expect(series).toHaveLength(6);
    const brands = ["", ...[...tokens.matchAll(/^\[data-flare-brand="(\w+)"\] \{/gm)].map((match) => match[1])];
    expect(brands.length).toBeGreaterThan(1);
    const failures: string[] = [];
    for (const brand of brands) {
      for (const mode of ["light", "dark"]) {
        const vars = {
          ...block(":root"),
          ...(mode === "dark" ? block('[data-flare-theme="dark"]') : {}),
          ...(brand ? block(`[data-flare-brand="${brand}"]`) : {}),
          ...(brand && mode === "dark" ? block(`[data-flare-brand="${brand}"][data-flare-theme="dark"]`) : {}),
        };
        const surface = rgb(vars["--flare-color-bg-primary"]);
        for (const token of series) {
          const ratio = contrast(rgb(vars[token], surface), surface);
          if (ratio < 3) failures.push(`${brand || "base"}/${mode} ${token} ${ratio.toFixed(2)}:1`);
        }
      }
    }
    expect(failures).toEqual([]);
  });

  it("renders under a dark theme root with every mark coloured by class, not by attribute", () => {
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h("div", { "data-flare-theme": "dark" }, [h(FlareChartCard as Component, { title: "每日活跃", points: week, kind: "line" })]);
      },
    }));
    const marks = host.findAll("svg rect, svg path, svg line");
    expect(marks.length).toBeGreaterThan(0);
    for (const mark of marks) {
      expect(mark.attributes("fill")).toBeUndefined();
      expect(mark.attributes("stroke")).toBeUndefined();
      expect(mark.attributes("style")).toBeUndefined();
    }
  });
});
