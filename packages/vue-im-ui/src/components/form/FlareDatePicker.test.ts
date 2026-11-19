// @vitest-environment happy-dom
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, type Component } from "vue";
import { afterEach, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareDatePicker from "./FlareDatePicker.vue";
import FlareTimePicker from "./FlareTimePicker.vue";
import FlareAdminModal from "./FlareAdminModal.vue";
import FlareModal from "../general/FlareModal.vue";

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

const active = () => document.activeElement as HTMLElement;
/** A key as the browser sends it: from the focused element, bubbling and cancelable. */
const press = (key: string, shiftKey = false) =>
  active().dispatchEvent(new KeyboardEvent("keydown", { key, shiftKey, bubbles: true, cancelable: true }));
const panelControls = (panel: string) => [...document.querySelectorAll<HTMLElement>(`${panel} button:not([disabled])`)];

it("is usable by keyboard: focus goes into the date panel, Tab stays in it, and a pick or Escape returns to the trigger", async () => {
  const wrapper = inDialog(FlareDatePicker, { modelValue: "2026-12-01" });
  const trigger = wrapper.get(".flare-dp__trigger").element as HTMLButtonElement;
  // Enter or Space on the focused trigger button is its click.
  trigger.focus();
  trigger.click();
  await nextTick();
  await nextTick();
  expect(active().classList.contains("is-selected")).toBe(true);
  expect(active().textContent?.trim()).toBe("1");
  const controls = panelControls(".flare-dp__pop");
  controls.at(-1)!.focus();
  press("Tab");
  expect(active()).toBe(controls[0]);
  press("Tab", true);
  expect(active()).toBe(controls.at(-1));
  [...document.querySelectorAll<HTMLElement>(".flare-cal__day")].find((cell) => cell.textContent?.trim() === "4")!.focus();
  active().click();
  await nextTick();
  expect(wrapper.findComponent(FlareDatePicker).emitted("update:modelValue")?.[0]).toEqual(["2026-12-04"]);
  expect(active()).toBe(trigger);
  trigger.click();
  await nextTick();
  await nextTick();
  // (The panel that closed may still be leaving with its transition.)
  expect([...document.querySelectorAll(".flare-dp__pop")].some((panel) => panel.contains(active()))).toBe(true);
  press("Escape");
  await nextTick();
  expect(active()).toBe(trigger);
  expect(wrapper.find(".is-open").exists()).toBe(false);
});

it("is usable by keyboard: a time is chosen and confirmed from the panel, and focus returns to the trigger", async () => {
  const wrapper = inDialog(FlareTimePicker, { modelValue: "09:30", minuteStep: 30 });
  const trigger = wrapper.get(".flare-tp__trigger").element as HTMLButtonElement;
  trigger.focus();
  trigger.click();
  await nextTick();
  await nextTick();
  expect(active().textContent?.trim()).toBe("09");
  press("Tab");
  active().click(); // 10
  const done = document.querySelector<HTMLElement>(".flare-tp__btn.is-primary")!;
  for (let i = 0; i < 40 && active() !== done; i++) press("Tab");
  expect(active()).toBe(done);
  active().click();
  await nextTick();
  expect(wrapper.findComponent(FlareTimePicker).emitted("update:modelValue")?.[0]).toEqual(["10:30"]);
  expect(active()).toBe(trigger);
});

it("keeps focus in an open panel inside a kit dialog: the dialog's Tab trap does not pull it out", async () => {
  mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h(FlareModal as Component, { open: true, title: "Search" }, () => h(FlareDatePicker as Component, { modelValue: "2026-12-01" }));
      },
    }),
    { attachTo: document.body },
  );
  await nextTick();
  const surface = document.querySelector<HTMLElement>('[role="dialog"]')!;
  surface.querySelector<HTMLButtonElement>(".flare-dp__trigger")!.click();
  await nextTick();
  await nextTick();
  const panel = document.querySelector<HTMLElement>(".flare-dp__pop")!;
  expect(surface.contains(panel)).toBe(false);
  const controls = panelControls(".flare-dp__pop");
  controls.at(-1)!.focus();
  press("Tab");
  expect(active()).toBe(controls[0]);
  press("Tab", true);
  expect(panel.contains(active())).toBe(true);
});

it("in the console's dialog (FlareAdminModal) draws the panel inside the dialog but outside its scrolling body", async () => {
  mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h(FlareAdminModal as Component, { open: true, title: "Edit" }, () => h(FlareDatePicker as Component, { modelValue: "2026-12-01" }));
      },
    }),
    { attachTo: document.body },
  );
  await nextTick();
  await nextTick();
  const surface = document.querySelector<HTMLElement>('[role="dialog"][aria-label="Edit"]')!;
  surface.querySelector<HTMLButtonElement>(".flare-dp__trigger")!.click();
  await nextTick();
  await nextTick();
  const panel = document.querySelector<HTMLElement>(".flare-dp__pop")!;
  // Naive puts it in the modal's own layer: inside the dialog (its focus scope), not inside
  // `.flare-admin-modal__body`, the one element with an overflow rule, so nothing clips it.
  expect(surface.contains(panel)).toBe(true);
  expect(surface.querySelector(".flare-admin-modal__body")!.contains(panel)).toBe(false);
  expect(panel.contains(active())).toBe(true);
});
