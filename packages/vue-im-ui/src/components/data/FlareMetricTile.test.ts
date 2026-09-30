// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { defineComponent, h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import FlareMetricTile from "./FlareMetricTile.vue";

function mountTile(props: Record<string, unknown>, locale: FlareLocale = "zh-CN") {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareMetricTile as Component, props);
    },
  }));
  return host.findComponent(FlareMetricTile);
}

const spoken = (tile: ReturnType<typeof mountTile>) => tile.findAll(".flare-metric-tile__spoken").map((node) => node.text());

describe("FlareMetricTile", () => {
  it("is a group named by its label, with the value formatted in the kit's language", () => {
    const tile = mountTile({ label: "用户总数", value: 12480, unit: "人", caption: "上限 20,000" });
    const group = tile.get("[role=group]");
    expect(tile.get(`#${group.attributes("aria-labelledby")}`).text()).toBe("用户总数");
    expect(tile.get(".flare-metric-tile__number").text()).toBe("12,480");
    expect(tile.get(".flare-metric-tile__unit").text()).toBe("人");
    expect(tile.get(".flare-metric-tile__caption").text()).toBe("上限 20,000");
    expect(group.attributes("aria-busy")).toBeUndefined();
    expect(tile.find(".flare-metric-tile__delta").exists()).toBe(false);
  });

  it("shows a string as it is and abbreviates a number on request", () => {
    expect(mountTile({ label: "版本", value: "v2.0" }).get(".flare-metric-tile__number").text()).toBe("v2.0");
    expect(mountTile({ label: "消息量", value: 12480, compact: true }).get(".flare-metric-tile__number").text()).toBe("1.2万");
    expect(mountTile({ label: "Messages", value: 12480, compact: true }, "en-US").get(".flare-metric-tile__number").text()).toBe("12.5K");
  });

  it("draws no data as a dash that is read as no data — never as a 0", () => {
    for (const value of [null, "", Number.NaN]) {
      const tile = mountTile({ label: "今日消息量", value });
      const number = tile.get(".flare-metric-tile__number");
      expect(number.text()).toBe("—");
      expect(number.attributes("aria-hidden")).toBe("true");
      expect(spoken(tile)).toEqual(["暂无数据"]);
      expect(tile.text()).not.toContain("0");
    }
    // Zero is a reading, not an absence.
    expect(mountTile({ label: "冻结用户", value: 0 }).get(".flare-metric-tile__number").text()).toBe("0");
  });

  it("signs the change, marks its direction, and says it in words", () => {
    const up = mountTile({ label: "用户总数", value: 12480, delta: 3.2, deltaUnit: "%" });
    const delta = up.get(".flare-metric-tile__delta");
    expect(delta.attributes("data-trend")).toBe("up");
    expect(delta.get("span[aria-hidden=true]").text()).toBe("+3.2%");
    expect(delta.find("svg[aria-hidden=true]").exists()).toBe(true);
    expect(spoken(up)).toEqual(["增加 3.2%"]);

    const down = mountTile({ label: "注册", value: 86, delta: -12 });
    expect(down.get(".flare-metric-tile__delta").attributes("data-trend")).toBe("down");
    expect(down.get(".flare-metric-tile__delta span[aria-hidden=true]").text()).toBe("-12");
    expect(spoken(down)).toEqual(["减少 12"]);

    const flat = mountTile({ label: "注册", value: 86, delta: 0 });
    expect(flat.get(".flare-metric-tile__delta").attributes("data-trend")).toBe("flat");
    expect(flat.find(".flare-metric-tile__caret").exists()).toBe(false);
    expect(spoken(flat)).toEqual(["持平"]);
  });

  it("judges the change only when the host says which way is good", () => {
    const sentiment = (props: Record<string, unknown>) => mountTile({ label: "x", value: 1, ...props }).get(".flare-metric-tile__delta").attributes("data-sentiment");
    expect(sentiment({ delta: 5 })).toBe("neutral");
    expect(sentiment({ delta: 5, polarity: "higher-is-better" })).toBe("positive");
    expect(sentiment({ delta: -5, polarity: "higher-is-better" })).toBe("negative");
    expect(sentiment({ delta: 5, polarity: "lower-is-better" })).toBe("negative");
    expect(sentiment({ delta: -5, polarity: "lower-is-better" })).toBe("positive");
    expect(sentiment({ delta: 0, polarity: "lower-is-better" })).toBe("neutral");
  });

  it("speaks English and English digits under an English kit", () => {
    const tile = mountTile({ label: "Users", value: 12480, delta: -1500 }, "en-US");
    expect(tile.get(".flare-metric-tile__number").text()).toBe("12,480");
    expect(spoken(tile)).toEqual(["down 1,500"]);
    expect(spoken(mountTile({ label: "Users", value: null }, "en-US"))).toEqual(["No data"]);
    expect(spoken(mountTile({ label: "Users", value: 1, delta: 0 }, "en-US"))).toEqual(["unchanged"]);
    expect(mountTile({ label: "Users", value: 12480.5, locale: "de-DE" }, "en-US").get(".flare-metric-tile__number").text()).toBe("12.480,5");
  });

  it("holds the value's place while loading and says so", () => {
    const tile = mountTile({ label: "用户总数", value: 12480, delta: 3, caption: "上限 20,000", loading: true });
    expect(tile.get("[role=group]").attributes("aria-busy")).toBe("true");
    expect(tile.find(".flare-metric-tile__number").exists()).toBe(false);
    expect(tile.find(".flare-metric-tile__foot").exists()).toBe(false);
    expect(spoken(tile)).toEqual(["正在加载"]);
  });

  it("draws its own surface unless told it sits on one", () => {
    expect(mountTile({ label: "x", value: 1 }).classes()).toContain("flare-metric-tile--card");
    expect(mountTile({ label: "x", value: 1, appearance: "plain" }).classes()).toContain("flare-metric-tile--plain");
  });
});

describe("FlareMetricTile in dark mode", () => {
  it("paints only with theme tokens, each of which dark mode redefines", () => {
    const source = readFileSync(resolve(__dirname, "FlareMetricTile.vue"), "utf8");
    const tokens = readFileSync(resolve(__dirname, "../../../../../tokens/dist/tokens.css"), "utf8");
    const dark = /\[data-flare-theme="dark"\]\s*\{([^}]*)\}/.exec(tokens)?.[1] ?? "";
    const style = source.slice(source.indexOf("<style"));
    const colours = [...new Set([...style.matchAll(/var\((--flare-color-[\w-]+)\)/g)].map((match) => match[1]))];
    expect(colours.length).toBeGreaterThan(4);
    for (const token of colours) expect(dark, `${token} has no dark value`).toContain(`${token}:`);
    expect(source).not.toMatch(/#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(/);
    // The caret takes the change's colour from the text, so it follows the theme with it.
    expect(style).toMatch(/__caret \{[^}]*fill: currentColor/);
  });
});
