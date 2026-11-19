// @vitest-environment happy-dom
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, type Component } from "vue";
import { afterEach, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareDatePicker from "./FlareDatePicker.vue";
import FlareTimePicker from "./FlareTimePicker.vue";

enableAutoUnmount(afterEach);
afterEach(() => {
  document.body.innerHTML = "";
});

/** A picker inside a clipping box, as in a dialog body that scrolls. */
function inDialog(picker: Component, props: Record<string, unknown>) {
  return mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h("div", { class: "dialog", style: "overflow: auto; height: 80px" }, [h(picker, props)]);
      },
    }),
    { attachTo: document.body },
  );
}

it.each([
  ["date", FlareDatePicker, ".flare-dp__trigger", ".flare-dp__pop", ".flare-cal__nav"],
  ["time", FlareTimePicker, ".flare-tp__trigger", ".flare-tp__pop", ".flare-tp__cell"],
] as const)("draws the %s panel outside a dialog's overflow, and a click in it is not outside", async (_, picker, trigger, panel, inside) => {
  const wrapper = inDialog(picker, { modelValue: "" });
  await wrapper.get(trigger).trigger("click");
  await nextTick();
  const shown = document.querySelector<HTMLElement>(panel);
  expect(shown).not.toBeNull();
  expect(wrapper.get(".dialog").element.contains(shown)).toBe(false);
  shown!.querySelector<HTMLElement>(inside)!.click();
  await nextTick();
  expect(wrapper.find(".is-open").exists()).toBe(true);
  document.body.click();
  await nextTick();
  expect(wrapper.find(".is-open").exists()).toBe(false);
});

it("picks a day from the drawn-out panel and closes", async () => {
  const wrapper = inDialog(FlareDatePicker, { modelValue: "2026-12-01" });
  await wrapper.get(".flare-dp__trigger").trigger("click");
  await nextTick();
  const day = [...document.querySelectorAll<HTMLElement>(".flare-cal__day")].find((cell) => cell.textContent?.trim() === "4");
  day!.click();
  await nextTick();
  expect(wrapper.findComponent(FlareDatePicker).emitted("update:modelValue")?.[0]).toEqual(["2026-12-04"]);
  expect(wrapper.find(".is-open").exists()).toBe(false);
});
