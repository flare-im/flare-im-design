import { expect, test, type Page } from "@playwright/test";

/**
 * 富文本格式行的三条几何/交互不变量,只有真引擎答得出来:
 *
 * 一、粗指针下键画 36、命中 44。改前组件写着 44,却被 chat/messages.css 里一套更老的全局样式
 *    (`.composer:not(.composer--wide) .composer-format-button { width: 28px }`,特异度更高)压成
 *    28 宽;而 accessibility.css 的 44 地板只管高不管这 28 —— 于是每个键是一根 28×44 的窄条。
 *    那套全局样式已经删掉,组件是唯一的所有者。
 * 二、这一排在窄屏上横向滚,末端真有键藏着时才画渐隐(`useScrollEdges`,与多选工具条同一机制);
 *    起始侧不画,滚过去之后被裁掉一截的键本身就是提示。
 * 三、文本样式按指针分两种呈现:粗指针(手机)就地展开成一行级别键,不开浮层、不夺焦点 —— 底部面板
 *    会让软键盘收起再弹;细指针(桌面)是 kit 的锚定菜单,触发器 pointerdown 上 preventDefault,
 *    编辑器同样不失焦。
 */
const FIXTURE = "/resources/composer-surface-regression";

async function openStrip(page: Page) {
  await page.goto(FIXTURE);
  const target = page.locator('[data-composer-state="default"]');
  await target.waitFor();
  await target.getByRole("button", { name: /^(富文本|Rich text)$/ }).click();
  const strip = target.locator(".composer-format-strip");
  await strip.waitFor();
  return { target, strip };
}

test.describe("keys on a coarse pointer", () => {
  test.use({ viewport: { width: 390, height: 800 }, hasTouch: true, isMobile: true });

  test("draw 36px and hit 44px; the strip is 36px and scrolls with honest fades", async ({ page }) => {
    const { strip } = await openStrip(page);
    const m = await strip.evaluate((node) => {
      const key = node.querySelector<HTMLElement>(".composer-format-button")!;
      const after = getComputedStyle(key, "::after");
      const scroller = node.querySelector<HTMLElement>(".composer-format-strip__scroller")!;
      return {
        coarse: matchMedia("(pointer: coarse)").matches,
        strip: Math.round(node.getBoundingClientRect().height),
        key: { w: Math.round(key.getBoundingClientRect().width), h: Math.round(key.getBoundingClientRect().height), hitW: parseFloat(after.width), hitH: parseFloat(after.height) },
        chip: Math.round(node.querySelector(".composer-heading-select")!.getBoundingClientRect().height),
        overflows: scroller.scrollWidth > scroller.clientWidth,
      };
    });
    expect(m.coarse, "viewport must emulate a coarse pointer").toBe(true);
    expect(m.strip).toBe(36);
    // 条与输入框之间一条 1px 的分隔线,贴在条的底边、通到两边(它分的是两行,不是插进来的内容)。
    const divider = await strip.evaluate((node) => {
      const after = getComputedStyle(node, "::after");
      return { height: after.height, bottom: after.bottom, left: after.left, right: after.right, drawn: after.content !== "none" && after.backgroundColor !== "rgba(0, 0, 0, 0)" };
    });
    expect(divider).toEqual({ height: "1px", bottom: "0px", left: "0px", right: "0px", drawn: true });
    // 手机上组之间照画竖线,只有最后一组(它的起始线会裁在滚动口右缘露半截)改用留白;键的 44 命中区
    // 上下沿都真落在键上(伪元素撑出来的那 4px 不能被滚动口或根裁掉)。
    const touch = await strip.evaluate((node) => {
      const groups = Array.from(node.querySelectorAll<HTMLElement>(".composer-format-group")).slice(1);
      const key = node.querySelector<HTMLElement>(".composer-format-button")!;
      const box = key.getBoundingClientRect();
      const inside = (x: number, y: number) => { const hit = document.elementFromPoint(x, y); return hit === key || key.contains(hit); };
      const cx = box.left + box.width / 2;
      return {
        dividers: groups.map((group) => getComputedStyle(group).borderInlineStartWidth),
        // 上下各伸出 3px 仍归这颗键(左右邻键的命中区互相搭 3px,那是并排目标的常态,不在这里量)。
        edges: [inside(cx, box.top - 3), inside(cx, box.bottom + 3)],
      };
    });
    expect(touch.dividers, "dividers between groups, none before the last (clipped) group").toEqual(["1px", "1px", "0px"]);
    expect(touch.edges, "the 44px hit area is real above and below the 36px key").toEqual([true, true]);
    expect(m.key).toEqual({ w: 36, h: 36, hitW: 44, hitH: 44 });
    expect(m.chip).toBe(36);
    // 前提:夹具确实溢出,否则渐隐断言什么也证明不了。
    expect(m.overflows, "the strip must overflow at 390").toBe(true);

    const fade = () => strip.evaluate((node) => ({
      end: node.getAttribute("data-scroll-end"),
      opacity: getComputedStyle(node.querySelector(".composer-format-strip__fade")!).opacity,
    }));
    expect(await fade()).toEqual({ end: "true", opacity: "1" });
    await strip.locator(".composer-format-strip__scroller").evaluate((node) => { node.scrollLeft = node.scrollWidth; });
    await expect.poll(fade).toEqual({ end: null, opacity: "0" });
  });

  test("the text-style picker expands in place and never takes focus from the editor", async ({ page }) => {
    const { target, strip } = await openStrip(page);
    const editor = target.locator('[contenteditable="true"]');
    await editor.fill("Heading selection");
    await editor.press("ControlOrMeta+A");
    const trigger = target.locator(".composer-heading-select");
    await trigger.click();
    // 就地展开:一行级别键顶掉三个格式组;没有面板、没有菜单浮层,编辑器仍持有焦点。
    const levels = strip.getByRole("radiogroup", { name: "文本样式" });
    await expect(levels).toBeVisible();
    await expect(levels.getByRole("radio")).toHaveCount(7);
    await expect(page.locator(".flare-sheet")).toHaveCount(0);
    await expect(strip.getByRole("button", { name: "加粗" })).toBeHidden();
    expect(await page.evaluate(() => document.activeElement?.getAttribute("contenteditable"))).toBe("true");
    await levels.getByRole("radio", { name: "标题 2" }).click();
    await expect(levels).toBeHidden();
    await expect(strip.getByRole("button", { name: "加粗" })).toBeVisible();
    await expect(editor.locator('[data-heading-level="2"]')).toHaveText("Heading selection");
    await expect(target.locator(".composer-heading-select__value")).toHaveText("H2");
    expect(await page.evaluate(() => document.activeElement?.getAttribute("contenteditable"))).toBe("true");
  });
});

test.describe("keys on a fine pointer", () => {
  test("draw 32px, the strip is 32px and the picker is an anchored menu", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    const { target, strip } = await openStrip(page);
    const m = await strip.evaluate((node) => {
      const key = node.querySelector<HTMLElement>(".composer-format-button")!;
      const scroller = node.querySelector<HTMLElement>(".composer-format-strip__scroller")!;
      return { strip: Math.round(node.getBoundingClientRect().height), key: Math.round(key.getBoundingClientRect().width), overflows: scroller.scrollWidth > scroller.clientWidth, endFade: getComputedStyle(node.querySelector(".composer-format-strip__fade")!).opacity };
    });
    // 细指针:键 32(control-height-sm),条就是键的高度 —— 焦点环留位的内距被负外距抵消,不占高度。
    expect(m).toEqual({ strip: 32, key: 32, overflows: false, endFade: "0" });
    // 不滚动的细指针条保留组与组之间的竖线。
    expect(await strip.locator(".composer-format-group").nth(1).evaluate((node) => getComputedStyle(node).borderInlineStartWidth)).toBe("1px");
    await target.locator(".composer-heading-select").click();
    const menu = page.getByRole("menu", { name: "文本样式" });
    await expect(menu).toBeVisible();
    await expect(page.locator(".flare-sheet")).toHaveCount(0);
    await page.keyboard.press("Escape");
    await expect(menu).toBeHidden();
  });
});
