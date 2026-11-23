// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareDocumentSlot from "./FlareDocumentSlot.vue";

function render(props: Record<string, unknown>, locale: "zh-CN" | "en-US" = "zh-CN") {
  const events: string[] = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareDocumentSlot, { label: "证件正面", side: "front", ...props, onCapture: () => events.push("capture"), onRetry: () => events.push("retry") });
    },
  }));
  return { wrapper, events, button: wrapper.get("button.flare-doc-slot") };
}

describe("FlareDocumentSlot (docs/plugin-experience.md §6.3)", () => {
  it("is one button that captures from an empty slot, reading label then what a tap does", async () => {
    const { wrapper, events, button } = render({});
    expect(wrapper.findAll("button")).toHaveLength(1);
    expect(button.attributes("aria-label")).toBe("证件正面，点击拍摄");
    expect(button.attributes("data-slot-state")).toBe("empty");
    expect(button.find(".flare-doc-slot__sketch").exists()).toBe(true);
    expect(button.text()).toContain("点击拍摄");
    await button.trigger("click");
    expect(events).toEqual(["capture"]);
  });

  it("draws the outline of its side", () => {
    for (const side of ["front", "back", "holding"] as const) {
      const { button } = render({ side });
      expect(button.classes()).toContain(`is-${side}`);
      expect(button.find(".flare-doc-slot__card").exists()).toBe(side === "holding");
    }
  });

  it("covers the slot with the captured photo, marks it done and retakes on a tap", async () => {
    const { events, button } = render({ state: "captured", imageUrl: "blob:front" });
    expect(button.get("img").attributes("src")).toBe("blob:front");
    expect(button.find(".flare-doc-slot__badge").exists()).toBe(true);
    expect(button.get(".flare-doc-slot__strip").text()).toBe("重拍");
    expect(button.attributes("aria-label")).toBe("证件正面，已拍摄，点按重拍");
    await button.trigger("click");
    expect(events).toEqual(["capture"]);
  });

  it("shows upload progress and takes no tap meanwhile", async () => {
    const { events, button } = render({ state: "uploading", imageUrl: "blob:front", progress: 42.4 }, "en-US");
    expect(button.find(".flare-doc-slot__ring").exists()).toBe(true);
    expect(button.text()).toContain("Uploading 42%");
    expect(button.attributes("aria-busy")).toBe("true");
    expect(button.attributes("disabled")).toBeDefined();
    await button.trigger("click");
    expect(events).toEqual([]);
  });

  it("retries a failed upload", async () => {
    const { events, button } = render({ state: "failed" });
    expect(button.classes()).toContain("is-failed");
    expect(button.attributes("aria-label")).toBe("证件正面，上传失败，点按重试");
    await button.trigger("click");
    expect(events).toEqual(["retry"]);
  });

  it("locks while the form submits", async () => {
    const { events, button } = render({ disabled: true });
    expect(button.attributes("disabled")).toBeDefined();
    await button.trigger("click");
    expect(events).toEqual([]);
  });
});
