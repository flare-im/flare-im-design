// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareForwardPicker from "./FlareForwardPicker.vue";

describe("embedded forward selection", () => {
  it("keeps search, controlled single selection and busy state inside a host form", async () => {
    const state = reactive({ busy: false, modelValue: ["a"], targets: [{ id: "a", name: "Alice" }, { id: "b", name: "Bob" }] });
    const host = mount(defineComponent({ setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareForwardPicker, { ...state, embedded: true, multiple: false,
        "onUpdate:modelValue": (ids: string[]) => { state.modelValue = ids; } });
    } }));
    expect(host.find("header").exists()).toBe(false);
    expect(host.find("footer").exists()).toBe(false);
    await host.get("input").setValue("Bob");
    expect(host.findAll(".flare-forward-picker__row")).toHaveLength(1);
    await host.get(".flare-forward-picker__row").trigger("click");
    expect(state.modelValue).toEqual(["b"]);
    state.busy = true;
    await nextTick();
    expect(host.get("input").attributes("disabled")).toBeDefined();
    expect(host.get(".flare-forward-picker__row").attributes("disabled")).toBeDefined();
    state.targets = [{ id: "a", name: "Alice" }];
    await nextTick();
    expect(state.modelValue).toEqual([]);
    host.unmount();
  });
});
