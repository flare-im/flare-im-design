// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, reactive, type Component } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import NButton from "../general/FlareButton.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import NInput from "../form/FlareTextarea.vue";
import Preview from "./FlareComposerMediaPreview.vue";
import FlareMediaUpload from "../media/FlareMediaUpload.vue";
import ImagePreviewModal from "../message-preview/ImagePreviewModal.vue";
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
  it("shows a single image with a caption field and optional remove action", async () => {
    const wrapper = setup({ kind: "image", onRemove: () => {}, items: [
      { id: "photo", kind: "image", name: "photo.png", previewUrl: "blob:photo" },
    ] });
    await flushPromises();
    expect(wrapper.getComponent(FlareBottomSheet).props("title")).toBe("发送图片");
    const input = wrapper.getComponent(NInput).get("textarea");
    expect(input.attributes("placeholder")).toBe("添加图片说明");
    expect(input.attributes("aria-label")).toBe("说明");
    expect(input.element.labels).toHaveLength(0);
    expect(document.body.textContent).not.toContain("可选");
    await wrapper.getComponent(FlareIconButton).trigger("click");
    expect(wrapper.emitted("remove")).toEqual([["photo"]]);
  });
  it("restores a video caption when a failed send reopens the confirmation", async () => {
    const props = reactive({ kind: "video", show: false, initialDescription: "", error: "", onRemove: () => {}, items: [
      { id: "clip", kind: "video", name: "clip.mp4", previewUrl: "blob:clip" },
    ] });
    const wrapper = setup(props);
    props.initialDescription = "已填写的说明";
    props.error = "发送失败";
    props.show = true;
    await flushPromises();
    expect(wrapper.getComponent(FlareBottomSheet).props("title")).toBe("发送视频");
    expect(document.querySelector("video")?.getAttribute("src")).toBe("blob:clip");
    expect(document.body.textContent).toContain(props.error);
    expect(wrapper.getComponent(NInput).get("textarea").element.value).toBe(props.initialDescription);
    await wrapper.getComponent(FlareIconButton).trigger("click");
    expect(wrapper.emitted("remove")).toEqual([["clip"]]);
  });
  it("omits the caption field and value when the host disables descriptions", async () => {
    const wrapper = setup({ showDescription: false, initialDescription: "previous caption", onRemove: () => {} });
    await flushPromises();
    expect(wrapper.findComponent(NInput).exists()).toBe(false);
    await wrapper.findAllComponents(NButton).at(-1)!.trigger("click");
    expect(wrapper.emitted("submit")).toEqual([[""]]);
    await wrapper.getComponent(FlareIconButton).trigger("click");
    expect(wrapper.emitted("remove")).toEqual([["file-1"]]);
  });
  it("uses the shared grid and forwards optional removal without changing the host's files", async () => {
    const remove = () => {};
    const wrapper = setup({ kind: "imageGroup", onRemove: remove, items: [
      { id: "photo", kind: "image", name: "photo.png", previewUrl: "blob:host-owned" },
    ] });
    const grid = wrapper.getComponent(FlareMediaUpload);
    expect(grid.props("showPicker")).toBe(false);
    grid.vm.$emit("remove", "photo");
    expect(wrapper.emitted("remove")).toEqual([["photo"]]);
    expect(wrapper.props("items")).toHaveLength(1);
    const sending = setup({ kind: "imageGroup", loading: true, onRemove: remove, items: [
      { id: "photo", kind: "image", name: "photo.png", previewUrl: "blob:host-owned" },
    ] });
    expect(sending.getComponent(FlareMediaUpload).props("disabled")).toBe(true);
  });
  it("previews a selected image and returns to the unchanged attachment confirmation", async () => {
    const wrapper = setup({ kind: "imageGroup", items: [
      { id: "one", kind: "image", name: "one.png", previewUrl: "blob:one" },
      { id: "two", kind: "image", name: "two.png", previewUrl: "blob:two" },
    ] });
    await flushPromises();
    wrapper.getComponent(FlareMediaUpload).vm.$emit("preview", "one");
    await flushPromises();
    const viewer = wrapper.getComponent(ImagePreviewModal);
    expect(viewer.props()).toMatchObject({ imageSrc: "blob:one", galleryCount: 2 });
    viewer.vm.$emit("next"); await flushPromises();
    expect(viewer.props("imageSrc")).toBe("blob:two");
    viewer.vm.$emit("update:show", false); await flushPromises();
    expect(wrapper.findComponent(ImagePreviewModal).exists()).toBe(false);
    expect(wrapper.getComponent(FlareBottomSheet).props("open")).toBe(true);
    expect(wrapper.props("items")).toHaveLength(2);
    expect(wrapper.emitted("submit")).toBeUndefined();
  });
});
