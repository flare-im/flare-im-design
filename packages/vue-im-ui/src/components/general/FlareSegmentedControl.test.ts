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

  it("draws nothing but the list when there are no options", () => {
    const wrapper = mount(FlareSegmentedControl, { props: { options: [] } });
    expect(wrapper.findAll('[role="tab"]')).toHaveLength(0);
    expect(wrapper.attributes("role")).toBe("tablist");
  });
});
