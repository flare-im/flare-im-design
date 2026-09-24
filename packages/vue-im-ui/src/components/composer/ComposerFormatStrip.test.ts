// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import ComposerFormatStrip from "./ComposerFormatStrip.vue";
import type { RichMarkdownFormatState } from "./ComposerRichMarkdownInput.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import type { FlarePointerKind } from "../../shared/platform/contract";

/**
 * 文本样式拾取器按指针种类分两种呈现,键的尺寸也跟着同一个信号(根上的 data-pointer):
 * 粗指针就地展开一行级别键、不开浮层、不夺焦点;其余一律是锚定菜单。'mixed'(触屏笔记本)
 * 与宿主覆写都要落在同一条轴上,不能出现「粗的键 + 弹层」或「细的键 + 内联行」。
 */
const state: RichMarkdownFormatState = { headingLevel: null, inline: { bold: false, italic: false, strike: false, underline: false, code: false } } as RichMarkdownFormatState;

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; document.body.innerHTML = ""; });

function mountStrip(pointer: FlarePointerKind, onHeading: (level: number | null) => void = () => undefined) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { pointer } });
      return () => h(ComposerFormatStrip as Component, { state, onHeading });
    },
  }), { attachTo: document.body });
  return host.findComponent(ComposerFormatStrip);
}

describe("ComposerFormatStrip — text-style picker by pointer kind", () => {
  it("on a coarse pointer the trigger expands an in-place level row and picks without any overlay", async () => {
    const levels: Array<number | null> = [];
    const strip = mountStrip("coarse", (level) => levels.push(level));
    expect(strip.attributes("data-pointer")).toBe("coarse");
    const trigger = strip.get(".composer-heading-select");
    expect(trigger.attributes("aria-haspopup")).toBeUndefined();
    expect(trigger.attributes("aria-expanded")).toBe("false");
    expect(strip.find('[role="radiogroup"]').exists()).toBe(false);

    await trigger.trigger("pointerdown");
    await trigger.trigger("click");
    const row = strip.get('[role="radiogroup"]');
    expect(trigger.attributes("aria-expanded")).toBe("true");
    expect(trigger.attributes("aria-controls")).toBe(row.attributes("id"));
    const radios = row.findAll('[role="radio"]');
    expect(radios.map((radio) => radio.attributes("aria-label"))).toEqual(["正文", "标题 1", "标题 2", "标题 3", "标题 4", "标题 5", "标题 6"]);
    expect(radios[0].attributes("aria-checked")).toBe("true");
    // 级别行占掉了格式组的位置。
    expect(strip.get('[aria-label="加粗"]').isVisible()).toBe(false);
    expect(document.body.querySelector('[role="menu"], .flare-sheet')).toBeNull();

    await radios[2].trigger("pointerdown");
    await radios[2].trigger("click");
    expect(levels).toEqual([2]);
    expect(strip.find('[role="radiogroup"]').exists()).toBe(false);
    expect(strip.get('[aria-label="加粗"]').isVisible()).toBe(true);
  });

  it.each<FlarePointerKind>(["fine", "mixed", "unknown"])("on a %s pointer the trigger opens the anchored menu", async (pointer) => {
    const levels: Array<number | null> = [];
    const strip = mountStrip(pointer, (level) => levels.push(level));
    expect(strip.attributes("data-pointer")).toBe(pointer);
    const trigger = strip.get(".composer-heading-select");
    expect(trigger.attributes("aria-haspopup")).toBe("menu");
    await trigger.trigger("click");
    await flushPromises();
    const items = Array.from(document.body.querySelectorAll<HTMLElement>("[data-action-menu-item]"));
    expect(items.map((item) => item.textContent?.trim())).toEqual(["正文", "标题 1", "标题 2", "标题 3", "标题 4", "标题 5", "标题 6"]);
    expect(strip.find('[role="radiogroup"]').exists()).toBe(false);
    items[3].click();
    await flushPromises();
    expect(levels).toEqual([3]);
  });
});
