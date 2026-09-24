import { expect, test } from "@playwright/test";

/**
 * 粗指针下控件尺寸不许被地板吃掉。
 *
 * `design-system/styles/accessibility.css` 在 `(pointer: coarse)` 下给 `:where(button)`
 * 兜了 44px 的 min-width / min-height。`min-*` 会盖过 `width` / `height`，于是任何
 * **用 width/height 定尺寸**的控件，在触摸端都会被撑到 44 —— FlareIconButton 的 sm(32)
 * 和 md(40) 因此渲染成同一个 44，size 这个 prop 在手机上等于失效。
 *
 * 这个失效只有真引擎看得见：happy-dom 不算媒体查询也不算层叠，组件测试里两档永远是对的；
 * 而桌面预览用的是精确指针，地板根本不生效。所以判据必须是「触摸端、三档互不相同」。
 *
 * 触达区不靠盒子：组件自己有 `::after { width: max(100%, touch-target) }`，盒子缩回
 * 视觉尺寸之后命中区仍然是 48。两件事一起断言，才不会有人用「那就让它撑大」来"修"。
 */
// hasTouch 必须在 context 上开：只改视口尺寸并不会让引擎报告 `pointer: coarse`，
// 那样地板根本不生效，这条用例会因为「测了个寂寞」而变绿。下面的前置断言就是防这个。
test.use({ viewport: { width: 390, height: 800 }, hasTouch: true, isMobile: true });

test("icon button keeps its three sizes on a touch pointer, and still hits 48", async ({ page }) => {
  await page.goto("/embed/component-frame?name=IconButton&viewport=mobile");
  await page.locator(".flare-icon-button").first().waitFor();

  const measured = await page.evaluate(() => {
    const out: Record<string, { box: number[]; hit: string[] }> = {};
    for (const el of document.querySelectorAll<HTMLElement>(".flare-icon-button")) {
      const size = [...el.classList].find((c) => /flare-icon-button--(sm|md|lg)$/.test(c));
      if (!size) continue;
      const key = size.replace("flare-icon-button--", "");
      const r = el.getBoundingClientRect();
      const after = getComputedStyle(el, "::after");
      out[key] ??= { box: [], hit: [] };
      out[key].box.push(Math.round(r.width), Math.round(r.height));
      out[key].hit.push(after.width, after.height);
    }
    return { out, coarse: matchMedia("(pointer: coarse)").matches };
  });

  // 前提：这个视口确实被当成触摸设备，否则地板不生效，这条用例什么也证明不了。
  expect(measured.coarse, "viewport must emulate a coarse pointer").toBe(true);

  const sizes = measured.out;
  for (const key of ["sm", "md", "lg"]) expect(sizes[key], `${key} rendered`).toBeTruthy();

  const box = (k: string) => sizes[k].box[0];
  expect(box("sm"), "sm keeps 32 on touch").toBe(32);
  expect(box("md"), "md keeps 40 on touch").toBe(40);
  expect(box("lg"), "lg keeps 48 on touch").toBe(48);
  // 三档互不相同 —— 地板一旦回来，这一条先红。
  expect(new Set([box("sm"), box("md"), box("lg")]).size).toBe(3);

  // 盒子缩小不等于变难点：命中区仍然是一整个触达单位。
  for (const key of ["sm", "md", "lg"]) {
    for (const v of sizes[key].hit) expect(parseFloat(v), `${key} hit area`).toBeGreaterThanOrEqual(44);
  }
});

/**
 * 同一个夹钳压着的不止图标按钮。这里盯的是**几何被破坏**的那几个:开关的滑块是
 * top:3px 的绝对定位,盒子从 26 变 44 之后滑块卡在顶部;复选框从 20 变成 44 的大方块;
 * 反应条从 26 变 44,时间线里每条带反应的消息都被拉开。
 *
 * 「长到 44」本身不一定是错 —— 下拉触发器、单选行这类整行控件长到 44 正是这条地板
 * 的本意。所以这条用例只断言那些「44 会把自己画坏」的,不去管其余的。
 */
const GEOMETRY = [
  { name: "Switch", sel: ".flare-switch", w: 44, h: 26 },
  { name: "Checkbox", sel: ".flare-checkbox__box", w: 20, h: 20 },
  { name: "ReactionSummary", sel: ".flare-reaction-pill", h: 26 },
] as const;

for (const c of GEOMETRY) {
  test(`${c.name} keeps its drawn geometry on a touch pointer, and still hits 44`, async ({ page }) => {
    await page.goto(`/embed/component-frame?name=${c.name}&viewport=mobile`);
    const el = page.locator(c.sel).first();
    await el.waitFor();

    const m = await el.evaluate((node) => {
      const r = node.getBoundingClientRect();
      const after = getComputedStyle(node, "::after");
      return {
        w: Math.round(r.width),
        h: Math.round(r.height),
        hitW: parseFloat(after.width),
        hitH: parseFloat(after.height),
        coarse: matchMedia("(pointer: coarse)").matches,
      };
    });

    expect(m.coarse, "viewport must emulate a coarse pointer").toBe(true);
    if ("w" in c && c.w) expect(m.w, `${c.name} width`).toBe(c.w);
    expect(m.h, `${c.name} height`).toBe(c.h);
    // 盒子缩回去不等于变难点:纵向命中区仍是一整个触达单位。
    expect(m.hitH, `${c.name} hit height`).toBeGreaterThanOrEqual(44);
  });
}
