// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlarePluginForm from "./FlarePluginForm.vue";
import FlareDatePicker from "./FlareDatePicker.vue";
import FlareTimePicker from "./FlareTimePicker.vue";

enableAutoUnmount(afterEach);
afterEach(() => {
  document.body.innerHTML = "";
});

it("saves a date picked without a time as 00:00 that day, shows that time, and clears both with the date", async () => {
  const submits: Record<string, unknown>[] = [];
  const wrapper = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () =>
          h(FlarePluginForm as never, {
            inputs: [{ id: "startsAtMs", kind: "datetime", label: "开始时间" }],
            onSubmit: (values: Record<string, unknown>) => submits.push(values),
          });
      },
    }),
  );
  const form = () => wrapper.findComponent(FlarePluginForm).vm as unknown as { submit(): void };
  wrapper.findComponent(FlareDatePicker).vm.$emit("update:modelValue", "2026-12-04");
  await flushPromises();
  expect(wrapper.findComponent(FlareTimePicker).props("modelValue")).toBe("00:00");
  form().submit();
  expect(submits).toEqual([{ startsAtMs: new Date(2026, 11, 4, 0, 0).getTime() }]);

  wrapper.findComponent(FlareTimePicker).vm.$emit("update:modelValue", "09:30");
  await flushPromises();
  form().submit();
  expect(submits[1]).toEqual({ startsAtMs: new Date(2026, 11, 4, 9, 30).getTime() });

  wrapper.findComponent(FlareDatePicker).vm.$emit("update:modelValue", "");
  await flushPromises();
  expect(wrapper.findComponent(FlareTimePicker).props("modelValue")).toBe("");
  form().submit();
  expect(submits[2]).toEqual({});
});
