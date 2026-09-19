// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import EmojiStickerPicker from "./index.vue";

function mountPicker(locale: "zh-CN" | "en-US", props: Record<string, unknown> = {}) {
  return mount(defineComponent({ setup() {
    useFlareI18nProvider(locale);
    return () => h(EmojiStickerPicker as Component, { activeTab: "emoji", ...props });
  } }), { attachTo: document.body });
}

describe("EmojiStickerPicker", () => {
  it("speaks the provider locale in headings, tabs and the send button", () => {
    const host = mountPicker("zh-CN", { canSend: true });
    expect(host.get("section.composer-emoji-sticker-panel").attributes("aria-label")).toBe("表情与贴纸");
    expect(host.findAll(".section-heading").map((heading) => heading.text())).toContain("所有表情");
    expect(host.get(".panel-send-btn").text()).toBe("发送");
    const emojiTab = host.get("button.tab-btn");
    expect(emojiTab.attributes("aria-label")).toBe("表情");
    expect(emojiTab.attributes("aria-pressed")).toBe("true");
    expect(host.html()).not.toMatch(/Frequently used|Default emoji|More emoji|Sticker packs/);
    host.unmount();
  });

  it("names every emoji cell by its localized label rather than the asset key", () => {
    const host = mountPicker("en-US");
    const cells = host.findAll(".asset-grid--emoji button.asset-cell");
    expect(cells.length).toBeGreaterThan(0);
    for (const cell of cells.slice(0, 5)) {
      const name = cell.attributes("aria-label") ?? "";
      expect(name).not.toBe("");
      expect(name).not.toMatch(/_/);
    }
    host.unmount();
  });

  it("renders only controls that do something", () => {
    const host = mountPicker("zh-CN");
    for (const button of host.findAll(".panel-tabbar button")) {
      expect(button.attributes("aria-label") || button.text()).toBeTruthy();
    }
    expect(host.find(".tab-btn--plus").exists()).toBe(false);
    host.unmount();
  });
});
