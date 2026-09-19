// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import ComposerUploadStrip from "./ComposerUploadStrip.vue";

function setup(props: Record<string, unknown>) {
  const host = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); return () => h(ComposerUploadStrip as Component, props); } }));
  return host.findComponent(ComposerUploadStrip);
}

describe("ComposerUploadStrip", () => {
  it("renders host upload state and reports retry / remove intents", async () => {
    const strip = setup({ items: [
      { id: "a", name: "photo.png", progress: 0.4, state: "uploading" },
      { id: "b", name: "deck.pdf", state: "failed" },
      { id: "c", name: "done.mov", state: "ready" },
    ] });
    expect(strip.findAll("progress")).toHaveLength(2);
    expect(strip.text()).toContain("上传失败");
    expect(strip.text()).toContain("可以发送");
    await strip.get('[aria-label="重试上传"]').trigger("click");
    await strip.findAll('[aria-label="移除附件"]')[2].trigger("click");
    expect(strip.emitted("retry")).toEqual([["b"]]);
    expect(strip.emitted("remove")).toEqual([["c"]]);
  });

  it("freezes its controls while the composer is blocked", () => {
    const strip = setup({ items: [{ id: "a", name: "a.png", state: "failed" }], blocked: true });
    expect(strip.get('[aria-label="重试上传"]').attributes("disabled")).toBeDefined();
    expect(strip.get('[aria-label="移除附件"]').attributes("disabled")).toBeDefined();
  });
});
