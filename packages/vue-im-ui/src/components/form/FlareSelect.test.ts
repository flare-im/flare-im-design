// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareSelect from "./FlareSelect.vue";

describe("FlareSelect", () => {
  it("exposes the field title and popup state on its trigger", async () => {
    const wrapper = mount(FlareSelect, {
      props: {
        title: "Brand theme",
        options: [{ value: "violet", label: "Violet" }],
        modelValue: "violet",
      },
    });

    const trigger = wrapper.get("button.flare-select__trigger");
    expect(trigger.attributes("aria-label")).toBe("Brand theme");
    expect(trigger.attributes("aria-expanded")).toBe("false");
    await trigger.trigger("click");
    expect(trigger.attributes("aria-expanded")).toBe("true");
  });
});
