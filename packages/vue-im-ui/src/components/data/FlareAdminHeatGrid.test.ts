// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import FlareAdminHeatGrid from "./FlareAdminHeatGrid.vue";

const props = {
  label: "可用率",
  rowHeader: "接入点",
  rows: [
    { key: "ap-a", label: "ap-a" },
    { key: "ap-b", label: "ap-b" },
  ],
  columns: [
    { key: "cn", label: "华东" },
    { key: "us", label: "美西" },
  ],
  cells: [
    { row: "ap-a", column: "cn", text: "99.9%", tone: "good", detail: "1200 次" },
    { row: "ap-a", column: "us", text: "97.0%", tone: "warn" },
    { row: "ap-b", column: "cn", text: "0.0%", tone: "bad" },
  ],
  emptyText: "暂无数据",
} as const;

describe("FlareAdminHeatGrid", () => {
  it("is a table with row and column headers", () => {
    const grid = mount(FlareAdminHeatGrid, { props });
    expect(grid.get("table").attributes("aria-label")).toBe("可用率");
    expect(grid.findAll('th[scope="col"]').map((cell) => cell.text())).toEqual([
      "接入点",
      "华东",
      "美西",
    ]);
    expect(grid.findAll('th[scope="row"]').map((cell) => cell.text())).toEqual(["ap-a", "ap-b"]);
  });
  it("places each reading on its pair and tints it by tone", () => {
    const cells = mount(FlareAdminHeatGrid, { props }).findAll("td");
    expect(cells.map((cell) => cell.text())).toEqual(["99.9%", "97.0%", "0.0%", "暂无数据"]);
    expect(cells[0]!.classes()).toContain("flare-admin-heat-grid__cell--good");
    expect(cells[0]!.attributes("title")).toBe("1200 次");
    expect(cells[2]!.classes()).toContain("flare-admin-heat-grid__cell--bad");
  });
  it("draws a missing pair as no data, never as a zero", () => {
    const empty = mount(FlareAdminHeatGrid, { props }).findAll("td")[3]!;
    expect(empty.text()).toBe("暂无数据");
    expect(empty.classes()).toContain("flare-admin-heat-grid__cell--empty");
  });
});
