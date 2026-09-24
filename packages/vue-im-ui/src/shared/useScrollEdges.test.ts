import { describe, expect, it } from "vitest";
import { scrollEdges } from "./useScrollEdges";

describe("scrollEdges", () => {
  it.each([
    ["nothing overflows", { scrollLeft: 0, clientWidth: 300, scrollWidth: 300 }, { start: false, end: false }],
    ["at the start with more to the end", { scrollLeft: 0, clientWidth: 300, scrollWidth: 500 }, { start: false, end: true }],
    ["in the middle", { scrollLeft: 100, clientWidth: 300, scrollWidth: 500 }, { start: true, end: true }],
    ["scrolled to the end", { scrollLeft: 200, clientWidth: 300, scrollWidth: 500 }, { start: true, end: false }],
    // 亚像素:滚到底常常停在 199.5,末端不该因此还亮着。
    ["a sub-pixel short of the end", { scrollLeft: 199.5, clientWidth: 300, scrollWidth: 500 }, { start: true, end: false }],
    ["a sub-pixel past the start", { scrollLeft: 0.5, clientWidth: 300, scrollWidth: 500 }, { start: false, end: true }],
    // RTL 下 scrollLeft 为负;kit 不支持 RTL,但事实不该反过来。
    ["a negative (rtl) offset", { scrollLeft: -100, clientWidth: 300, scrollWidth: 500 }, { start: true, end: true }],
  ])("reports both edges when %s", (_label, metrics, expected) => {
    expect(scrollEdges(metrics)).toEqual(expected);
  });
});
