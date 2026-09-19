// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareTimePicker from "./FlareTimePicker.vue";

function render(props: Record<string, unknown> = {}) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareTimePicker, props);
    },
  }), { attachTo: document.body });
}

/**
 * Two listboxes and a confirm: the value only changes when the person says done, minutes snap to the
 * step the host asked for, and a disabled picker does not open. Release criterion §1.
 */
describe("FlareTimePicker", () => {
  it("shows the placeholder until there is a value", () => {
    const wrapper = render({ placeholder: "选择时间" });
    const shown = wrapper.find(".flare-tp__value");
    expect(shown.text()).toBe("选择时间");
    expect(shown.classes()).toContain("is-placeholder");
  });

  it("shows the value the host holds", () => {
    const wrapper = render({ modelValue: "09:30" });
    expect(wrapper.find(".flare-tp__value").text()).toBe("09:30");
    expect(wrapper.find(".flare-tp__value").classes()).not.toContain("is-placeholder");
  });

  it("opens two named listboxes, hours and minutes", async () => {
    const wrapper = render();
    await wrapper.find(".flare-tp__trigger").trigger("click");
    const columns = wrapper.findAll('[role="listbox"]');
    expect(columns).toHaveLength(2);
    expect(columns.map((c) => c.attributes("aria-label"))).toEqual(["时", "分"]);
    expect(columns[0].findAll(".flare-tp__cell")).toHaveLength(24);
  });

  it("offers only the minutes the step allows", async () => {
    const wrapper = render({ minuteStep: 15 });
    await wrapper.find(".flare-tp__trigger").trigger("click");
    const minutes = wrapper.findAll('[role="listbox"]')[1].findAll(".flare-tp__cell").map((c) => c.text());
    expect(minutes).toEqual(["00", "15", "30", "45"]);
  });

  it("snaps an off-step value onto a cell when it opens", async () => {
    const wrapper = render({ modelValue: "08:37", minuteStep: 15 });
    await wrapper.find(".flare-tp__trigger").trigger("click");
    const selected = wrapper.findAll('[role="listbox"]')[1].findAll(".is-selected").map((c) => c.text());
    expect(selected).toEqual(["30"]);
  });

  it("changes nothing until done is pressed, and cancel leaves the value alone", async () => {
    const wrapper = render({ modelValue: "09:30" });
    await wrapper.find(".flare-tp__trigger").trigger("click");
    await wrapper.findAll('[role="listbox"]')[0].findAll(".flare-tp__cell")[11].trigger("click");
    const picker = wrapper.findComponent(FlareTimePicker);
    expect(picker.emitted("update:modelValue")).toBeUndefined();

    await wrapper.findAll(".flare-tp__btn")[0].trigger("click");
    expect(picker.emitted("update:modelValue")).toBeUndefined();
    expect(picker.emitted("change")).toBeUndefined();
  });

  it("reports the picked time as HH:MM, twice, once done is pressed", async () => {
    const wrapper = render({ modelValue: "09:30", minuteStep: 30 });
    await wrapper.find(".flare-tp__trigger").trigger("click");
    await wrapper.findAll('[role="listbox"]')[0].findAll(".flare-tp__cell")[7].trigger("click");
    await wrapper.findAll('[role="listbox"]')[1].findAll(".flare-tp__cell")[1].trigger("click");
    await wrapper.findAll(".flare-tp__btn")[1].trigger("click");
    const picker = wrapper.findComponent(FlareTimePicker);
    expect(picker.emitted("update:modelValue")?.[0]).toEqual(["07:30"]);
    expect(picker.emitted("change")?.[0]).toEqual(["07:30"]);
  });

  it("does not open when it is disabled", async () => {
    const wrapper = render({ disabled: true });
    await wrapper.find(".flare-tp__trigger").trigger("click");
    await nextTick();
    expect(wrapper.findAll('[role="listbox"]')).toHaveLength(0);
    expect(wrapper.find(".flare-tp").classes()).toContain("is-disabled");
  });
});
