// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, reactive } from "vue";
import FlarePluginForm from "./FlarePluginForm.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

let wrapper: ReturnType<typeof mount> | undefined;
afterEach(() => { wrapper?.unmount(); document.body.innerHTML = ""; });
describe("plugin page form", () => {
  it('focuses the first invalid field on submit and on a host rejection without clearing the draft', async () => {
    const state = reactive({ errors: [] as Array<{ input: string; issue: 'unknown' }> });
    wrapper = mount(defineComponent({ setup() { useFlareI18nProvider('zh-CN'); return () => h(FlarePluginForm, { inputs: [{ id: 'name', kind: 'text', label: 'Name', required: true }, { id: 'code', kind: 'text', label: 'Code', required: true }], ...state }); } }), { attachTo: document.body });
    const inputs = wrapper.findAll('input');
    await wrapper.get('[data-form-submit]').trigger('click');
    await flushPromises();
    expect(document.activeElement).toBe(inputs[0].element);
    await inputs[0].setValue('Sample');
    await wrapper.get('[data-form-submit]').trigger('click');
    await flushPromises();
    expect(document.activeElement).toBe(inputs[1].element);
    await inputs[1].setValue('Draft');
    state.errors = [{ input: 'name', issue: 'unknown' }];
    await flushPromises();
    expect(document.activeElement).toBe(inputs[0].element);
    expect((inputs[1].element as HTMLInputElement).value).toBe('Draft');
  });
  it("focuses the primary field, retains its draft after failure and locks controls during submission", async () => {
    const state = reactive({ busy: false, error: "" });
    wrapper = mount(defineComponent({
      setup() { useFlareI18nProvider("zh-CN"); return () => h(FlarePluginForm, { inputs: [{ id: "title", kind: "text", label: "标题", required: true }], layout: "page", autofocus: true, ...state }); },
    }), { attachTo: document.body });
    const form = wrapper.getComponent(FlarePluginForm);
    await flushPromises();
    const input = form.get("input");
    expect(document.activeElement).toBe(input.element);
    await input.setValue("设计评审");
    state.busy = true;
    await nextTick();
    expect(form.get("fieldset").attributes("disabled")).toBeDefined();
    expect(form.get('[data-form-cancel]').attributes("disabled")).toBeDefined();
    state.busy = false;
    state.error = "请重试";
    await nextTick();
    expect((input.element as HTMLInputElement).value).toBe("设计评审");
    expect(form.get('[role="alert"]').text()).toBe("请重试");
    // R6: a form-level error is the kit's danger banner, right above submit.
    expect(form.get('[role="alert"]').classes()).toContain("flare-status-banner--danger");
    expect(form.get('[role="alert"]').element.nextElementSibling?.classList.contains("flare-plugin-form__actions")).toBe(true);
    await form.get('[data-form-submit]').trigger("click");
    expect(form.emitted("submit")?.at(-1)).toEqual([{ title: "设计评审" }]);
  });
});
