import { describe, expect, it } from "vitest";
import {
  chartAreaPath,
  chartBars,
  chartDomain,
  chartLinePath,
  chartMarkers,
  chartReadings,
  chartSegments,
  chartSlots,
  chartTicks,
  chartY,
  formatChartNumber,
  niceCeil,
  withUnit,
  type FlareChartPoint,
} from "./chart-geometry";

const series = (...values: (number | null)[]): FlareChartPoint[] => values.map((value, index) => ({ label: `d${index + 1}`, value }));
const finite = (numbers: number[]) => numbers.every((n) => Number.isFinite(n));

describe("chart scale", () => {
  it("rounds the top of the scale up to 1, 2, 2.5 or 5 × 10ⁿ", () => {
    expect([1, 3, 7, 12, 25, 26, 99, 104, 1234, 0.3].map(niceCeil)).toEqual([1, 5, 10, 20, 25, 50, 100, 200, 2000, 0.5]);
    expect(niceCeil(0)).toBe(0);
    expect(niceCeil(Number.NaN)).toBe(0);
  });

  it("gives an empty or all-zero series a unit band over a bottom zero line — nothing divides by zero", () => {
    for (const readings of [[], [0], [0, 0, 0]]) {
      const domain = chartDomain(readings);
      expect(domain).toEqual({ min: 0, max: 1, flat: true });
      expect(chartY(0, domain)).toBe(100);
      expect(chartTicks(domain)).toEqual([{ value: 0, y: 100 }]);
    }
  });

  it("keeps zero in range and puts it inside the plot when readings go negative", () => {
    const domain = chartDomain([8, -3]);
    expect(domain).toEqual({ min: -5, max: 10, flat: false });
    expect(chartTicks(domain).map((tick) => tick.value)).toEqual([10, 0, -5]);
    expect(chartY(0, domain)).toBeCloseTo(66.667, 2);
  });
});

describe("chart geometry", () => {
  it("draws nothing for no points", () => {
    expect(chartSlots(0)).toEqual([]);
    const domain = chartDomain([]);
    expect(chartBars([], domain)).toEqual([]);
    expect(chartSegments([], domain)).toEqual([]);
    expect(chartLinePath([])).toBe("");
    expect(chartMarkers([])).toEqual([]);
  });

  it("draws one point as one centred bar no wider than the cap, and as one dot", () => {
    const points = series(42);
    const domain = chartDomain(chartReadings(points));
    const [bar] = chartBars(points, domain);
    expect(bar.width).toBe(12);
    expect(bar.x + bar.width / 2).toBe(50);
    expect(bar.y).toBeCloseTo(chartY(42, domain));
    expect(bar.y + bar.height).toBe(100);
    const segments = chartSegments(points, domain);
    // A lone reading has no line and no area — only the dot shows it.
    expect(chartLinePath(segments)).toBe("");
    expect(chartAreaPath(segments, domain)).toBe("");
    expect(chartMarkers(segments)).toEqual([{ index: 0, x: 50, y: chartY(42, domain) }]);
  });

  it("draws an all-zero series flat on the zero line with finite coordinates", () => {
    const points = series(0, 0, 0);
    const domain = chartDomain(chartReadings(points));
    const bars = chartBars(points, domain);
    expect(bars).toHaveLength(3);
    for (const bar of bars) {
      expect(bar.height).toBe(0);
      expect(bar.y).toBe(100);
      expect(finite([bar.x, bar.y, bar.width, bar.height])).toBe(true);
    }
    expect(chartLinePath(chartSegments(points, domain))).toBe("M16.667 100 L50 100 L83.333 100");
  });

  it("leaves a gap for a missing reading instead of drawing a zero", () => {
    const points = series(4, 6, null, 5, null, 2);
    const domain = chartDomain(chartReadings(points));
    expect(chartReadings(points)).toEqual([4, 6, 5, 2]);
    expect(chartBars(points, domain).map((bar) => bar.index)).toEqual([0, 1, 3, 5]);
    const segments = chartSegments(points, domain);
    expect(segments.map((segment) => segment.map((vertex) => vertex.index))).toEqual([[0, 1], [3], [5]]);
    // Two runs of one reading get a dot each (5 is also isolated); the last is also the latest.
    expect(chartMarkers(segments).map((vertex) => vertex.index)).toEqual([3, 5]);
    expect(chartLinePath(segments).match(/M/g)).toHaveLength(1);
  });

  it("closes the area down to the zero line and hangs negative bars from it", () => {
    const points = series(10, -5);
    const domain = chartDomain(chartReadings(points));
    const zero = chartY(0, domain);
    const [up, down] = chartBars(points, domain);
    expect(up.y + up.height).toBeCloseTo(zero);
    expect(down.y).toBeCloseTo(zero);
    expect(chartAreaPath(chartSegments(points, domain), domain)).toMatch(/L75 66\.667 L25 66\.667 Z$/);
  });
});

describe("chart numbers", () => {
  it("formats per locale, abbreviates on request and signs a change", () => {
    expect(formatChartNumber(12480, "zh-CN")).toBe("12,480");
    expect(formatChartNumber(12480, "de-DE")).toBe("12.480");
    expect(formatChartNumber(12480, "zh-CN", { compact: true })).toBe("1.2万");
    expect(formatChartNumber(12480, "en-US", { compact: true })).toBe("12.5K");
    expect(formatChartNumber(3.2, "en-US", { signed: true })).toBe("+3.2");
    expect(formatChartNumber(-12, "en-US", { signed: true })).toBe("-12");
    expect(formatChartNumber(0, "en-US", { signed: true })).toBe("0");
    expect(formatChartNumber(1 / 3, "en-US")).toBe("0.33");
  });

  it("falls back to the runtime's digits for a tag Intl does not accept", () => {
    expect(() => formatChartNumber(5, "not a locale!")).not.toThrow();
    expect(formatChartNumber(5, "not a locale!")).toBe("5");
  });

  it("puts a lone symbol on the number and a word after a space", () => {
    expect(withUnit("12", "%")).toBe("12%");
    expect(withUnit("12", "人")).toBe("12 人");
    expect(withUnit("12", "users")).toBe("12 users");
    expect(withUnit("12")).toBe("12");
  });
});
