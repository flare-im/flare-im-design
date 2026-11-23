// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareSlider from "./FlareSlider.vue";

describe("an accessible media slider", () => {
  it("names the playback range and exposes seek and settled values", async () => {
    const wrapper = mount(defineComponent({ setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareSlider, { max: 13000, modelValue: 1000, ariaLabel: "试听进度", ariaValueText: "1 / 13 秒" });
    } }));
    const range = wrapper.get('input[type="range"]');
    expect(range.attributes("aria-label")).toBe("试听进度");
    expect(range.attributes("aria-valuetext")).toBe("1 / 13 秒");
    await range.setValue("7000");
    const slider = wrapper.getComponent(FlareSlider);
    expect(slider.emitted("update:modelValue")?.[0]).toEqual([7000]);
    expect(slider.emitted("change")?.[0]).toEqual([7000]);
    wrapper.unmount();
  });
});
