// @vitest-environment happy-dom
import { h } from "vue";
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import FlareAdminSection from "./FlareAdminSection.vue";

describe("FlareAdminSection", () => {
  it("names a plain group without inventing interactive controls", () => {
    const wrapper = mount(FlareAdminSection, { props: { title: "Limits", description: "Current app only" } });
    expect(wrapper.element.tagName).toBe("SECTION");
    expect(wrapper.attributes("aria-labelledby")).toBe(wrapper.get("h3").attributes("id"));
    expect(wrapper.text()).toContain("Current app only");
    expect(wrapper.find("summary").exists()).toBe(false);
    wrapper.unmount();
  });
  it("keeps the same draft input while native disclosure opens, closes and is controlled", async () => {
    const wrapper = mount(FlareAdminSection, {
      props: { title: "Advanced JSON", collapsible: true },
      slots: { default: () => h("textarea", { value: "{\"amount\":\"1000000000000\"}" }) },
    });
    const field = wrapper.get("textarea").element;
    const details = wrapper.element as HTMLDetailsElement;
    details.open = true;
    await wrapper.trigger("toggle");
    expect(wrapper.emitted("update:open")?.[0]).toEqual([true]);
    await wrapper.setProps({ open: true });
    details.open = false;
    await wrapper.trigger("toggle");
    expect(wrapper.emitted("update:open")?.at(-1)).toEqual([false]);
    await wrapper.setProps({ open: false });
    expect(wrapper.get("textarea").element).toBe(field);
    expect(field.value).toBe('{"amount":"1000000000000"}');
    wrapper.unmount();
  });
});
