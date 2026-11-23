// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { setFlareRuntimeLocale } from "../../shared/i18n/messages";
import ImagePreviewModal from "./ImagePreviewModal.vue";

afterEach(() => setFlareRuntimeLocale('zh-CN'));

describe("image preview opened from a thumbnail", () => {
  it("names the viewer and localizes loading, failure and retry without overriding host copy", async () => {
    setFlareRuntimeLocale('zh-CN');
    const wrapper = mount(ImagePreviewModal, { attachTo: document.body, props: { show: true, imageSrc: '', loading: true } });
    try {
      await flushPromises();
      const surface = () => document.querySelector<HTMLElement>('.image-preview-modal')!;
      expect(surface().getAttribute('aria-label')).toBe('图片');
      expect(surface().querySelector('[role=status]')?.textContent).toContain('加载中');
      await wrapper.setProps({ loading: false, imageSrc: 'https://invalid.example/image.png', alt: '产品草图' });
      surface().querySelector('img')!.dispatchEvent(new Event('error'));
      await flushPromises();
      expect(surface().getAttribute('aria-label')).toBe('产品草图');
      expect(surface().querySelector('[role=alert]')?.textContent).toContain('图片加载失败');
      expect(surface().querySelector('button.image-preview-modal__retry')?.textContent).toBe('重试');
      (surface().querySelector('button.image-preview-modal__retry') as HTMLButtonElement).click();
      expect(wrapper.emitted('retry')).toEqual([[]]);
      await wrapper.setProps({ imageSrc: '', loading: true, loadingText: 'Host loading' });
      expect(surface().querySelector('[role=status]')?.textContent).toContain('Host loading');
    } finally { wrapper.unmount(); }
  });

  it("uses English defaults when the runtime locale is English", async () => {
    setFlareRuntimeLocale('en-US');
    const wrapper = mount(ImagePreviewModal, { attachTo: document.body, props: { show: true, imageSrc: '', loading: false } });
    try {
      await flushPromises();
      expect(document.querySelector('.image-preview-modal')?.getAttribute('aria-label')).toBe('Image');
      expect(document.querySelector('.image-preview-modal [role=alert]')?.textContent).toContain('Image failed to load');
    } finally { wrapper.unmount(); }
  });

  it("focuses an initially open viewer and owns gallery keys and Escape", async () => {
    const wrapper = mount(ImagePreviewModal, { attachTo: document.body, props: {
      show: true, imageSrc: "blob:host-owned", galleryIndex: 0, galleryCount: 2,
    } });
    try {
      await flushPromises();
      expect(document.activeElement?.classList.contains("image-preview-modal__viewport")).toBe(true);
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }));
      expect(wrapper.emitted("next")).toEqual([[]]);
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
      expect(wrapper.emitted("update:show")).toEqual([[false]]);
    } finally { wrapper.unmount(); }
  });
});
