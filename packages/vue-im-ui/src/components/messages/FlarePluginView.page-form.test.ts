// @vitest-environment happy-dom
import { afterEach, expect, it } from "vitest";
import { defineComponent, h, reactive } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlarePluginView from "./FlarePluginView.vue";
import FlarePluginForm from "../form/FlarePluginForm.vue";
import type { FlarePluginViewModel } from "../../shared/contracts/plugin-ui";

afterEach(() => { document.body.innerHTML = ""; });
it("opens a grouped long admin form in the shared drawer with a bounded field layout", async () => {
  const inputs = Array.from({ length: 7 }, (_, i) => ({ id: `field${i}`, kind: "text" as const, label: `字段 ${i}` }));
  const sections = [{ id: "basic", title: "基本信息", fields: ["field0", "field1"] }, { id: "reward", title: "奖励配置", fields: inputs.slice(2).map(i => i.id) }];
  const view: FlarePluginViewModel = { available: true, title: "任务", fields: [], inputs, actions: [{ id: "create", label: "新建任务", form: inputs.map(i => i.id) }] };
  const wrapper = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlarePluginView, { view, presentation: "admin", formSections: () => sections });
  } }), { attachTo: document.body });
  await wrapper.find('button[data-action-id="create"]').trigger("click");
  await flushPromises();
  expect(document.body.querySelector('[data-flare-presentation="drawer"]')).not.toBeNull();
  expect((document.body.querySelector('[data-flare-presentation="drawer"]') as HTMLElement).style.getPropertyValue("--flare-drawer-width")).toBe("calc(var(--flare-size-component-form-column-width) + 4 * var(--flare-size-spacing-lg))");
  expect(wrapper.getComponent(FlarePluginForm).props()).toMatchObject({ layout: "page", columns: 2, sections, selectPresentation: "dropdown" });
  wrapper.unmount();
});
it("keeps a page action form and its draft after a rejection, with the action's own submit label", async () => {
  const state = reactive({ busyActionId: undefined as string | undefined, error: "", settleToken: 0 });
  const actions: unknown[] = [];
  const view: FlarePluginViewModel = {
    available: true, title: "账户", fields: [], inputs: [{ id: "name", kind: "text", label: "户名", required: true }],
    actions: [{ id: "save", label: "保存收款方式", form: ["name"] }],
  };
  const wrapper = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlarePluginView, { ...state, formPresentation: "page", formSections: () => undefined, view, onAction: (...args: unknown[]) => actions.push(args) });
  } }), { attachTo: document.body });
  await wrapper.find('button[data-action-id="save"]').trigger("click"); await flushPromises();
  const form = wrapper.getComponent(FlarePluginForm);
  expect(form.props()).toMatchObject({ layout: "page", autofocus: true, selectPresentation: "dropdown", submitLabel: "保存收款方式" });
  expect((document.body.querySelector('[data-flare-presentation="drawer"]') as HTMLElement).style.getPropertyValue("--flare-drawer-width")).toBe("");
  const field = document.body.querySelector('input')!;
  field.value = "示例户名"; field.dispatchEvent(new Event("input", { bubbles: true })); await flushPromises();
  form.vm.$emit("submit", { name: "示例户名" }); state.busyActionId = "save"; await flushPromises();
  form.vm.$emit("cancel"); await flushPromises(); expect(wrapper.findComponent(FlarePluginForm).exists()).toBe(true);
  state.error = "服务暂不可用"; state.settleToken++; state.busyActionId = undefined; await flushPromises();
  expect(document.body.querySelector('input')?.value).toBe("示例户名");
  expect(wrapper.findComponent(FlarePluginForm).exists()).toBe(true);
  expect(actions).toHaveLength(1);
  wrapper.unmount();
});
