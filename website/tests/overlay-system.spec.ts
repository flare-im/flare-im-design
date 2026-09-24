import { expect, test } from "@playwright/test";

/**
 * 浮层体系的两条几何不变量 —— 两条都只有真引擎答得出来。
 *
 * 一、一条阶梯,不是七个各自长出来的数。`tokens.json` 一直有 z-index 这组 token,但没有
 *     一张浮层用它:面板写死 3000、命令面板 1000、图片/视频查看器 10000,naive 的锚定层
 *     在 2000,而必须盖在所有东西上面的 toast 是 1400 —— 排下来 toast 在最底下。
 *     单测看不见这个:happy-dom 不算层叠,组件各自 mount 时也没有别的浮层跟它比。
 *
 * 二、封了高度的面自己会滚。`.flare-sheet` 有 max-height 却是 overflow: visible,内容一旦
 *     比上限高,底下那几行谁也够不着(消息长按操作表的「删除」、会话操作表的最后一档)。
 *     DOM 两种情况完全一样,只有 scrollHeight / clientHeight 分得开。
 */

/** 文档化的次序:越靠后越在上面。 */
const LADDER = ["base", "sticky", "overlay", "modal", "media", "dropdown", "toast"] as const;

test("the overlay layers are one ordered scale that every surface reads from", async ({ page }) => {
  await page.goto("/embed/component-frame?name=DangerConfirm&viewport=desktop");
  await page.getByRole("button", { name: "打开确认" }).click();
  await page.locator(".flare-sheet").waitFor();

  const { layers, scrim } = await page.evaluate((names) => {
    const style = getComputedStyle(document.documentElement);
    return {
      layers: names.map((name) => Number(style.getPropertyValue(`--flare-z-index-${name}`).trim())),
      scrim: getComputedStyle(document.querySelector(".flare-sheet-scrim")!).zIndex,
    };
  }, LADDER as unknown as string[]);

  // 每一层都定义过,而且严格递增 —— 少一层或者次序乱了,叠起来就会有人被埋在下面。
  for (const [index, value] of layers.entries()) {
    expect(Number.isFinite(value), `--flare-z-index-${LADDER[index]} is defined`).toBe(true);
    if (index > 0) expect(value, `${LADDER[index]} sits above ${LADDER[index - 1]}`).toBeGreaterThan(layers[index - 1]);
  }
  // 模态面取的是阶梯上的 modal 那一层,不是自己想的一个数。
  expect(scrim).toBe(String(layers[LADDER.indexOf("modal")]));
});

test("a sheet that caps its height scrolls to its last row", async ({ page }) => {
  // 390x400:内容一定超过 72vh 的上限,这正是会把最后几档藏起来的那种窗口。
  await page.setViewportSize({ width: 390, height: 400 });
  // 这个预览开场就把面板打开了,不用先点什么。
  await page.goto("/embed/component-frame?name=ConversationActionSheet&viewport=mobile");
  const sheet = page.locator(".flare-sheet");
  await sheet.waitFor();
  await page.locator(".flare-conv-actions__row").last().waitFor();

  const geometry = await sheet.evaluate((node) => {
    node.scrollTop = 0;
    const rows = Array.from(node.querySelectorAll<HTMLElement>("[role='menuitem']"));
    const last = rows.at(-1)!;
    const beforeBottom = last.getBoundingClientRect().bottom;
    node.scrollTop = node.scrollHeight;
    return {
      scrollHeight: node.scrollHeight,
      clientHeight: node.clientHeight,
      scrolledTo: node.scrollTop,
      lastRowBottomBefore: beforeBottom,
      lastRowBottomAfter: last.getBoundingClientRect().bottom,
      sheetBottom: node.getBoundingClientRect().bottom,
    };
  });

  // 前提:这张面确实装不下自己的内容。装得下就证明不了什么,换个更矮的窗口。
  expect(geometry.scrollHeight).toBeGreaterThan(geometry.clientHeight);
  // 它自己滚得动,而且滚到底之后最后一行真的落进了面里 —— 不是停在外面。
  expect(geometry.scrolledTo).toBeGreaterThan(0);
  expect(geometry.lastRowBottomBefore).toBeGreaterThan(geometry.sheetBottom);
  expect(geometry.lastRowBottomAfter).toBeLessThanOrEqual(geometry.sheetBottom + 1);
});
