// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import FlareFilterTabs from "./FlareFilterTabs.vue";

const options = [
  { value: "all", label: "全部" },
  { value: "unread", label: "未读", badge: 3 },
];

describe("FlareFilterTabs", () => {
  it("reports the picked value through the model and the change event", async () => {
    const tabs = mount(FlareFilterTabs, { props: { options, modelValue: "all" } });
    const buttons = tabs.findAll(".flare-filter-tab");
    expect(buttons.map((b) => b.attributes("aria-selected"))).toEqual(["true", "false"]);
    await buttons[1].trigger("click");
    expect(tabs.emitted("update:modelValue")).toEqual([["unread"]]);
    expect(tabs.emitted("change")).toEqual([["unread"]]);
    tabs.unmount();
  });

  it("carries the appearance on the root so a resident row can drop the chips", () => {
    // 默认是药丸。一条常驻在列表顶上的筛选用 quiet：摆成一排带底色的药丸时，
    // 它会和上面的搜索框叠成两排同色圆角，一屏里最先看见的是几块灰底而不是列表。
    // filled / quiet 与 FlareSearchBar 是同一套词 —— 两边问的是同一个问题。
    const filled = mount(FlareFilterTabs, { props: { options, modelValue: "all" } });
    expect(filled.classes()).toContain("flare-filter-tabs--filled");
    expect(filled.classes()).not.toContain("flare-filter-tabs--quiet");
    const quiet = mount(FlareFilterTabs, { props: { options, modelValue: "all", appearance: "quiet" } });
    expect(quiet.classes()).toContain("flare-filter-tabs--quiet");
    // 选中仍然是颜色 + 字重 + 下划线三重表达，不只靠颜色：这里锁住带上选中类这一步。
    expect(quiet.findAll(".flare-filter-tab")[0].classes()).toContain("flare-filter-tab--active");
    filled.unmount();
    quiet.unmount();
  });
  it("carries a compact size for the assistive filter row, without shrinking the hit area", () => {
    // 搜索页那一排是「辅助条件」,不是一排大按钮:默认尺寸在那里一颗 48 高、两排就吃掉
    // 近百像素。sm 把**视觉**盒子收到 30,命中区靠 ::after 撑回触达区(与 FlareButton 同一套)。
    const md = mount(FlareFilterTabs, { props: { options, modelValue: "all" } });
    expect(md.classes()).toContain("flare-filter-tabs--size-md");
    const sm = mount(FlareFilterTabs, { props: { options, modelValue: "all", size: "sm" } });
    expect(sm.classes()).toContain("flare-filter-tabs--size-sm");
    expect(sm.classes()).not.toContain("flare-filter-tabs--size-md");
    // 选中仍然由类表达,尺寸不影响状态。
    expect(sm.findAll(".flare-filter-tab")[0].classes()).toContain("flare-filter-tab--active");
    md.unmount();
    sm.unmount();
  });
});
