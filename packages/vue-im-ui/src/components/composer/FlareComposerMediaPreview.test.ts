// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import { NModal } from "naive-ui";
import NButton from "../general/FlareButton.vue";
import NInput from "../form/FlareTextarea.vue";
import Preview from "./FlareComposerMediaPreview.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

const wrappers: ReturnType<typeof mount>[] = [];
function setup(props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(Preview as Component, {
        show: true, kind: "file", items: [{ id: "file-1", kind: "file", name: "review.pdf", size: 1024 }], ...props,
      });
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(Preview);
}
afterEach(() => wrappers.splice(0).forEach(wrapper => wrapper.unmount()));

describe("shared media composer preview", () => {
  it("submits a trimmed caption without taking ownership of uploads", async () => {
    const wrapper = setup();
    await flushPromises();
    wrapper.findComponent(NInput).vm.$emit("update:modelValue", "  review caption  ");
    await wrapper.findAllComponents(NButton).at(-1)!.trigger("click");
    expect(wrapper.emitted("submit")).toEqual([["review caption"]]);
    expect(wrapper.emitted("update:show")).toBeUndefined();
    expect(document.body.textContent).toContain("发送附件");
    expect(document.body.textContent).not.toContain("composer.");
  });
  it("closes through the same cancel callback for the modal dismiss action", async () => {
    const wrapper = setup();
    await flushPromises();
    wrapper.findComponent(NModal).vm.$emit("update:show", false);
    expect(wrapper.emitted("cancel")).toEqual([[]]);
    expect(wrapper.emitted("update:show")).toEqual([[false]]);
  });
  it("blocks dismissal and duplicate submits while sending", async () => {
    const wrapper = setup({ loading: true });
    await flushPromises();
    expect(wrapper.findComponent(NModal).props("maskClosable")).toBe(false);
    expect(wrapper.findComponent(NModal).props("closeOnEsc")).toBe(false);
    wrapper.findComponent(NModal).vm.$emit("update:show", false);
    wrapper.findAllComponents(NButton).at(-1)!.vm.$emit("click");
    expect(wrapper.emitted("cancel")).toBeUndefined();
    expect(wrapper.emitted("submit")).toBeUndefined();
  });
  it("disables submission for an empty selection", async () => {
    const wrapper = setup({ items: [] });
    await flushPromises();
    expect(wrapper.findAllComponents(NButton).at(-1)!.props("disabled")).toBe(true);
    wrapper.findAllComponents(NButton).at(-1)!.vm.$emit("click");
    expect(wrapper.emitted("submit")).toBeUndefined();
  });
});
