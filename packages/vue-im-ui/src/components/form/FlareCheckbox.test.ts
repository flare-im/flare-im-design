// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareCheckbox from "./FlareCheckbox.vue";

describe("FlareCheckbox", () => {
  it("toggles exactly once when the label text is clicked", async () => {
    const wrapper = mount(FlareCheckbox, { props: { label: "Mute", modelValue: false }, attachTo: document.body });
    // The <label> forwards a click on its text to the checkbox button; the span must not toggle on its own.
    await wrapper.get(".flare-checkbox__label").trigger("click");
    expect(wrapper.emitted("change")).toEqual([[true]]);
    expect(wrapper.get("[role=checkbox]").attributes("aria-checked")).toBe("true");
    wrapper.unmount();
  });

  it("toggles once when the box itself is clicked", async () => {
    const wrapper = mount(FlareCheckbox, { props: { label: "Mute", modelValue: true } });
    await wrapper.get("[role=checkbox]").trigger("click");
    expect(wrapper.emitted("change")).toEqual([[false]]);
  });

  it("names a box without a visible label through ariaLabel", () => {
    const wrapper = mount(FlareCheckbox, { props: { ariaLabel: "Select Ann" } });
    const box = wrapper.get("[role=checkbox]");
    expect(box.attributes("aria-label")).toBe("Select Ann");
    expect(wrapper.find(".flare-checkbox__label").exists()).toBe(false);
    // The root label element does not carry the name.
    expect(wrapper.attributes("aria-label")).toBeUndefined();
  });
});
