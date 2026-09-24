import { expect, test } from "@playwright/test";

/**
 * 气泡靠**面的色差**立住,不靠描边 —— 这条用例盯的就是那份色差还在。
 *
 * 改之前进来的一条是「和画布同色 + 1px 发丝线」:浅色 #FFFFFF 的气泡画在 #FFFFFF 的画布上,
 * 暗色 #20232B 的气泡画在 #20232B 的画布上,两边都是 **1.00:1**。那条线不是装饰,是气泡唯一的
 * 轮廓 —— 于是尾巴那块纯填充一盖上去就抹掉一段边,右下角出现豁口:描边和填充本来就在打架。
 *
 * 这件事单测看不见:happy-dom 不解析 CSS 变量的层叠,也不知道气泡上面那一层铺的是什么色。
 * 判据只能在真引擎里取,而且必须是「气泡的底色 vs **它实际画在上面的那张面**」——
 * 不是拿 token 和 token 比:把画布换成别的面(文档 demo 一度就是 bg-secondary),token 没变,
 * 色差却掉到 1.05:1,气泡在页面上几乎消失。所以这里向上找第一层不透明的祖先,量的是真实入眼的对比。
 */

/** WCAG 相对亮度;两张相邻的面之间 1.1:1 已经是肉眼能分辨的最低一档(iMessage 的灰泡约 1.12)。 */
const MIN_SURFACE_RATIO = 1.1;

function luminance(rgb: string): number {
  const [r, g, b] = rgb.match(/[\d.]+/g)!.slice(0, 3).map(Number);
  const channel = (value: number) => {
    const c = value / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

function contrast(a: string, b: string): number {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

/** 气泡、它画在上面的那张面,以及尾巴那块填充 —— 三者一起量才说明问题。 */
function measureBubble(node: HTMLElement) {
  const style = getComputedStyle(node);
  const tail = getComputedStyle(node, "::after");
  let surface = node.parentElement;
  while (surface && getComputedStyle(surface).backgroundColor === "rgba(0, 0, 0, 0)") surface = surface.parentElement;
  return {
    borderWidth: style.borderTopWidth,
    background: style.backgroundColor,
    tail: tail.backgroundColor,
    tailShape: tail.clipPath,
    surface: surface ? getComputedStyle(surface).backgroundColor : null,
  };
}

const INCOMING = ".message-row:not(.message-row--self) .message-bubble";
/** 只有「一组的最后一条 + 留了头像位」的那条画尾巴 —— 尾巴的接缝只能在它身上量。 */
const TAILED = ".message-row--avatar-gutter.message-row--group-end:not(.message-row--self) .message-bubble";

for (const mode of ["light", "dark"] as const) {
  test(`the incoming bubble is drawn by its own surface in ${mode}`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: mode, reducedMotion: "reduce" });
    await page.goto("/resources/visual-regression");
    await page.evaluate((selected) => {
      document.documentElement.dataset.flareTheme = selected;
      document.documentElement.classList.toggle("dark", selected === "dark");
    }, mode);

    // 页面上每一条进来的消息都量一遍:它们画在不同的面上(组件 demo 自己的画布、
    // 工作区里的时间线),任何一张面上塌成同色都该红。
    await page.locator(INCOMING).first().waitFor();
    const all = await page.locator(INCOMING).evaluateAll((nodes, measure) => {
      const run = new Function(`return ${measure}`)() as (node: HTMLElement) => unknown;
      return (nodes as HTMLElement[]).map(run);
    }, measureBubble.toString());
    expect(all.length, "the fixture renders incoming bubbles").toBeGreaterThan(0);

    for (const measured of all as ReturnType<typeof measureBubble>[]) {
      // 一、没有描边。轮廓要是又回到边上,尾巴的豁口就跟着回来。
      expect(measured.borderWidth, "no hairline around the bubble").toBe("0px");
      // 二、底色和它画在上面的那张面确实不同 —— 这才是现在唯一的轮廓。
      expect(measured.surface, "the bubble is painted on an opaque surface").not.toBeNull();
      expect(measured.background).not.toBe(measured.surface);
      expect(
        contrast(measured.background, measured.surface!),
        `${measured.background} on ${measured.surface} reads as its own surface`,
      ).toBeGreaterThanOrEqual(MIN_SURFACE_RATIO);
    }

    // 三、尾巴与气泡同一种填充。两者一旦分头取色,接缝就会在某个主题下露出来。
    const tailed = await page.locator(TAILED).first().evaluate(measureBubble);
    expect(tailed.tailShape, "the group-end bubble draws a tail").not.toBe("none");
    expect(tailed.tail, "the tail is the same fill as the bubble").toBe(tailed.background);
  });
}

/**
 * 把作者的底色拿走、或者用户明说要更强的对比时,轮廓得回到边上 —— 靠色差画的面在这两种
 * 模式下等于没画:forced-colors 会把 background 整片换成系统色,一列长方形分不出谁说的话。
 */
test("a contrast mode that strips or boosts colour gets the outline back", async ({ page }) => {
  await page.goto("/resources/visual-regression");
  const bubble = page.locator(INCOMING).first();
  await bubble.waitFor();
  const borderWidth = () => bubble.evaluate((node) => getComputedStyle(node).borderTopWidth);

  // 前提:常态下确实没有边,否则下面两条断言什么也证明不了。
  expect(await borderWidth()).toBe("0px");

  await page.emulateMedia({ forcedColors: "active" });
  expect(await borderWidth(), "forced colors restores an outline").not.toBe("0px");

  await page.emulateMedia({ forcedColors: "none", contrast: "more" });
  expect(await borderWidth(), "prefers-contrast: more restores an outline").toBe("1px");
});
