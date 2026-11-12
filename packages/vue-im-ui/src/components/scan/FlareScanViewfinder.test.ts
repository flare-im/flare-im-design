// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareScanViewfinder from "./FlareScanViewfinder.vue";

it("offers an explicit retry for a paused capture", async () => {
  const retry = vi.fn();
  const wrapper = mount(defineComponent({ setup() { useFlareI18nProvider("en-US"); return () => h(FlareScanViewfinder, { state: "paused", capabilities: { live: true, album: false, paste: false, myCode: false, torch: false }, onRetry: retry }); } }));
  const button = wrapper.findAll("button").find(item => item.text() === "Retry")!;
  await button.trigger("click"); expect(retry).toHaveBeenCalledOnce(); wrapper.unmount();
});

 it("distinguishes image processing failure from a successful empty image and keeps retry/choose-image", async () => {
  const retry = vi.fn(), pick = vi.fn();
  const wrapper = mount(defineComponent({ setup() { useFlareI18nProvider("en-US"); return () => h(FlareScanViewfinder, { state: "imageError", capabilities: { live: false, album: true, paste: false, myCode: false, torch: false }, onRetry: retry, onPickImage: pick }); } }));
  expect(wrapper.text()).toContain("Could not read this image");
  expect(wrapper.text()).not.toContain("No QR code found"); expect(wrapper.text()).not.toContain("Camera unavailable");
  await wrapper.findAll("button").find(button => button.text() === "Retry")!.trigger("click");
  await wrapper.findAll("button").find(button => button.text() === "Choose image")!.trigger("click");
  expect(retry).toHaveBeenCalledOnce(); expect(pick).toHaveBeenCalledOnce(); wrapper.unmount();
});
