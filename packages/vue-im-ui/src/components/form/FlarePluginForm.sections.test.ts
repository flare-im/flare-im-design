// @vitest-environment happy-dom
import { mount, flushPromises } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, expect, it } from "vitest";
import FlareSelect from "./FlareSelect.vue";
import FlarePluginForm from "./FlarePluginForm.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlarePluginInput } from "../../shared/contracts/plugin-ui";

afterEach(() => { document.body.innerHTML = ""; });

it("groups visible fields once, preserves unlisted inputs and validates the same typed submission", async () => {
  const inputs: FlarePluginInput[] = [
    { id: "title", kind: "text", label: "标题", required: true },
    { id: "beneficiary", kind: "select", label: "受益人", default: "self", choices: [{ value: "self", label: "本人" }, { value: "inviter", label: "上级" }] },
    { id: "level", kind: "number", label: "层级", default: 2, min: 1, max: 20, showWhen: { field: "beneficiary", anyOf: ["inviter"] } },
    { id: "memo", kind: "textarea", label: "说明" },
  ];
  const wrapper = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlarePluginForm, { inputs, columns: 2, selectPresentation: "dropdown", sections: [
      { id: "basic", title: "基本信息", fields: ["title", "beneficiary"] },
      { id: "count", title: "计数规则", fields: ["title", "level"] },
      { id: "empty", title: "空分组", fields: ["absent"] },
    ] });
  } }));
  const form = wrapper.findComponent(FlarePluginForm);
  expect(form.findAll('[data-input-id="title"]')).toHaveLength(1);
  expect(form.find('[data-input-id="memo"]').exists()).toBe(true);
  expect(form.findAll('section[role="group"]')).toHaveLength(1);
  await form.find("form").trigger("submit");
  expect(form.emitted("submit")).toBeUndefined();
  await form.find('[data-input-id="title"] input').setValue("实名奖励");
  form.findComponent(FlareSelect).vm.$emit("update:modelValue", "inviter");
  await flushPromises();
  expect(form.findAll('section[role="group"]')).toHaveLength(2);
  expect(form.findAll('[data-input-id="title"]')).toHaveLength(1);
  expect(form.find('[data-input-id="level"]').exists()).toBe(true);
  await form.find('[data-input-id="level"] input').setValue("3");
  await form.find("form").trigger("submit");
  expect(form.emitted("submit")?.at(-1)?.[0]).toMatchObject({ title: "实名奖励", beneficiary: "inviter", level: 3 });
  wrapper.unmount();
});
