// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareSegmentedControl from "./FlareSegmentedControl.vue";

/**
 * A segmented control is a tab list: exactly one segment is selected, and a screen reader is told
 * which one through `aria-selected`, not through a colour. Release criterion §1 (component tests).
 */
describe("FlareSegmentedControl", () => {
  const options = ["全部", "未读", "@我"];

  it("renders one tab per option inside a tab list", () => {
    const wrapper = mount(FlareSegmentedControl, { props: { options } });
    expect(wrapper.attributes("role")).toBe("tablist");
    const tabs = wrapper.findAll('[role="tab"]');
    expect(tabs.map((tab) => tab.text())).toEqual(options);
  });

  it("marks the selected segment for a screen reader, not only for the eye", () => {
    const wrapper = mount(FlareSegmentedControl, { props: { options, modelValue: 1 } });
    const tabs = wrapper.findAll('[role="tab"]');
    expect(tabs.map((tab) => tab.attributes("aria-selected"))).toEqual(["false", "true", "false"]);
    expect(tabs[1].classes()).toContain("is-active");
  });

  it("reports a pick twice — as the model and as an event — so either wiring works", async () => {
    const wrapper = mount(FlareSegmentedControl, { props: { options, modelValue: 0 } });
    await wrapper.findAll('[role="tab"]')[2].trigger("click");
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([2]);
    expect(wrapper.emitted("change")?.[0]).toEqual([2]);
  });

  it("selects the first segment when the host says nothing", () => {
    const wrapper = mount(FlareSegmentedControl, { props: { options } });
    expect(wrapper.findAll('[role="tab"]')[0].attributes("aria-selected")).toBe("true");
  });

  it("keeps long translated labels available and navigates with the keyboard", async () => {
    const labels = ["Normal red packet", "Lucky red packet", "Exclusive red packet"];
    const wrapper = mount(FlareSegmentedControl, { props: { options: labels }, attachTo: document.body });
    const tabs = wrapper.findAll('[role="tab"]');
    expect(tabs.map(tab => tab.attributes("title"))).toEqual(labels);
    await tabs[0].trigger("keydown", { key: "ArrowRight" });
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([1]);
    expect(document.activeElement).toBe(tabs[1].element);
    await tabs[1].trigger("keydown", { key: "End" });
    expect(wrapper.emitted("update:modelValue")?.[1]).toEqual([2]);
    expect(document.activeElement).toBe(tabs[2].element);
    wrapper.unmount();
  });

  it("keeps arrow navigation in reading order in RTL", async () => {
    const wrapper = mount(FlareSegmentedControl, { props: { options }, attrs: { dir: "rtl" } });
    await wrapper.findAll('[role="tab"]')[0].trigger("keydown", { key: "ArrowRight" });
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([2]);
    wrapper.unmount();
  });

  it("draws nothing but the list when there are no options", () => {
    const wrapper = mount(FlareSegmentedControl, { props: { options: [] } });
    expect(wrapper.findAll('[role="tab"]')).toHaveLength(0);
    expect(wrapper.attributes("role")).toBe("tablist");
  });

  it("takes an optional accent for the selected label and otherwise keeps the brand", () => {
    expect(mount(FlareSegmentedControl, { props: { options } }).attributes("style")).toBeUndefined();
    const tinted = mount(FlareSegmentedControl, { props: { options, accent: "var(--flare-color-red-packet-accent)" } });
    expect(tinted.attributes("style")).toContain("--flare-segmented-accent: var(--flare-color-red-packet-accent)");
  });
});
