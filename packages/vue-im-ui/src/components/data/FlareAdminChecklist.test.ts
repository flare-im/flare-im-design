// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import FlareAdminChecklist from "./FlareAdminChecklist.vue";

const items = [
  { id: "a", title: "容量", status: "pass", statusText: "通过" },
  { id: "b", title: "证书", status: "unknown", statusText: "未知", description: "尚无探测结果" },
  { id: "c", title: "镜像", status: "fail", statusText: "未通过", details: ["只有 1 个", "同一云厂商"] },
] as const;

describe("FlareAdminChecklist", () => {
  it("keeps every state apart in words and in class, without an interactive role", () => {
    const list = mount(FlareAdminChecklist, { props: { label: "发布校验", items } });
    expect(list.get("ul").attributes("aria-label")).toBe("发布校验");
    const rows = list.findAll(".flare-admin-checklist__item");
    expect(rows.map((row) => row.get(".flare-admin-checklist__status").text())).toEqual([
      "通过",
      "未知",
      "未通过",
    ]);
    expect(rows[1]!.classes()).toContain("flare-admin-checklist__item--unknown");
    expect(rows[2]!.classes()).toContain("flare-admin-checklist__item--fail");
    expect(list.find("button").exists()).toBe(false);
  });
  it("draws the reason and the findings only when there are any", () => {
    const list = mount(FlareAdminChecklist, { props: { label: "发布校验", items } });
    const rows = list.findAll(".flare-admin-checklist__item");
    expect(rows[0]!.find(".flare-admin-checklist__description").exists()).toBe(false);
    expect(rows[1]!.get(".flare-admin-checklist__description").text()).toBe("尚无探测结果");
    expect(rows[2]!.findAll(".flare-admin-checklist__details li")).toHaveLength(2);
  });
});
