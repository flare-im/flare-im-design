// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import FlareCodeBlock from "./FlareCodeBlock.vue";

const payload = JSON.stringify({ server_id: "m_1", attributes: { "x-trace": "abc" } }, null, 2);

function mountBlock(props: Record<string, unknown>, locale: FlareLocale = "zh-CN") {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareCodeBlock as Component, props);
    },
  }));
  return host.findComponent(FlareCodeBlock);
}

afterEach(() => vi.unstubAllGlobals());

describe("FlareCodeBlock", () => {
  it("keeps the text exactly as written inside a named, focusable scroll box", () => {
    const block = mountBlock({ code: payload, language: "JSON" });
    const box = block.get("pre");
    expect(box.get("code").element.textContent).toBe(payload);
    expect(box.attributes("role")).toBe("region");
    expect(box.attributes("tabindex")).toBe("0");
    expect(box.attributes("aria-label")).toBe("JSON");
    expect(block.get(".flare-code-block__language").text()).toBe("JSON");
    expect(block.classes()).not.toContain("is-wrapped");
  });

  it("names the box by its label, else the language, else the kit's word", () => {
    expect(mountBlock({ code: "x", language: "curl", label: "初始化命令" }).get("pre").attributes("aria-label")).toBe("初始化命令");
    expect(mountBlock({ code: "x" }).get("pre").attributes("aria-label")).toBe("代码");
    expect(mountBlock({ code: "x" }, "en-US").get("pre").attributes("aria-label")).toBe("Code");
  });

  it("wraps on request and takes the host's height cap", () => {
    const block = mountBlock({ code: payload, wrap: true, maxHeight: "12rem" });
    expect(block.classes()).toContain("is-wrapped");
    expect(block.get("pre").attributes("style")).toContain("max-height: 12rem");
    expect(mountBlock({ code: payload }).get("pre").attributes("style")).toBeUndefined();
  });

  it("copies the whole text and reports whether the clipboard took it", async () => {
    const writeText = vi.fn().mockResolvedValueOnce(undefined).mockRejectedValueOnce(new Error("denied"));
    vi.stubGlobal("navigator", { clipboard: { writeText } });
    const block = mountBlock({ code: payload, language: "JSON" });
    const key = block.get(".flare-code-block__copy");
    expect(key.attributes("aria-label")).toBe("复制代码");
    await key.trigger("click");
    await flushPromises();
    await key.trigger("click");
    await flushPromises();
    expect(writeText).toHaveBeenCalledWith(payload);
    expect(block.emitted("copy")).toEqual([[true], [false]]);
  });

  it("has no copy key when the host turns it off, and a disabled one with nothing to copy", () => {
    const bare = mountBlock({ code: payload, copyable: false });
    expect(bare.find(".flare-code-block__copy").exists()).toBe(false);
    expect(bare.find(".flare-code-block__head").exists()).toBe(false);
    expect(mountBlock({ code: "" }).get(".flare-code-block__copy").attributes("disabled")).toBeDefined();
  });

  it("reports a missing clipboard as not copied", async () => {
    vi.stubGlobal("navigator", {});
    const block = mountBlock({ code: "npm i @flare-im/vue-ui" });
    await block.get(".flare-code-block__copy").trigger("click");
    expect(block.emitted("copy")).toEqual([[false]]);
  });
});
