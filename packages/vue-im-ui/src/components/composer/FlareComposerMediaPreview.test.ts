// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
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
  // 走组件库自己的模态面:手机是底部面板、桌面是居中弹窗,scrim / Escape / 平台返回键
  // 都从 FlareBottomSheet 的一个 close 出来。
  it("closes through the same cancel callback for the surface's dismiss action", async () => {
    const wrapper = setup();
    await flushPromises();
    wrapper.findComponent(FlareBottomSheet).vm.$emit("close");
    expect(wrapper.emitted("cancel")).toEqual([[]]);
    expect(wrapper.emitted("update:show")).toEqual([[false]]);
  });
  it("blocks dismissal and duplicate submits while sending", async () => {
    const wrapper = setup({ loading: true });
    await flushPromises();
    expect(wrapper.findComponent(FlareBottomSheet).props("dismissible")).toBe(false);
    wrapper.findComponent(FlareBottomSheet).vm.$emit("close");
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
