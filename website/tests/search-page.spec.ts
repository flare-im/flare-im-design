import { expect, test } from "@playwright/test";

/**
 * 搜索页(`FlareSearchPanel layout="page"` + 空闲态的 `FlareRecentSearches`)只有真引擎答得出来的几件事:
 *
 * 一、页头(搜索框 + 类型行)不滚:只有它那条 1px 线下面的结果滚,而且滚的是面板自己的正文 —— 不是 sticky
 *    (sticky 要自己刷一块底色、在有内距的宿主里一滚就上移、新结果到达时也没法回顶)。
 * 二、一条页边:搜索框、最近搜索的标题与各行的图标、结果行的头像落在同一条左边缘上,「取消」「清除」落在同一条
 *    右边缘上。改前 app 是 FlareScreen padded(16) 套着结果行自己的 12,行缩进 28、像卡片不像列表。
 * 三、「取消」是搜索框自带的那颗键(宿主监听 cancel 才有),不是 app 另放的按钮。
 * 四、最近搜索是通栏的行:画多大就点多大(48),行上没有会裁掉命中区的 overflow;点一条 = 立即搜这个词。
 * 五、「查看更多 联系人」= 切到「联系人」类型:类型是面板自己的状态,宿主改不了,所以面板自己切;新结果从顶部开始。
 */
const FRAME = "/embed/component-frame?name=RecentSearches&viewport=mobile";

test.use({ viewport: { width: 390, height: 800 }, hasTouch: true, isMobile: true });

test("the search page keeps its head still, one gutter, and a recent term searches at once", async ({ page }) => {
  await page.goto(FRAME);
  const stage = page.locator("[data-recent-searches-demo]");
  await stage.waitFor();
  const panel = stage.locator(".flare-search-panel");
  await expect(panel).toHaveClass(/flare-search-panel--page/);

  // 空闲态:最近搜索代替了那一行提示;出口是搜索框自带的取消键,恰好一颗。
  const recent = stage.getByRole("region", { name: "最近搜索" });
  await expect(recent).toBeVisible();
  await expect(stage.locator(".flare-search-panel__status")).toHaveCount(0);
  await expect(stage.getByRole("button", { name: "取消" })).toHaveCount(1);
  await expect(stage.locator(".flare-search__cancel")).toHaveText("取消");

  const idle = await stage.evaluate((node) => {
    const box = (selector: string) => node.querySelector(selector)!.getBoundingClientRect();
    const frame = node.getBoundingClientRect();
    const head = node.querySelector<HTMLElement>(".flare-search-panel__head")!;
    const term = node.querySelector<HTMLElement>(".flare-recent-searches__term")!;
    const row = term.getBoundingClientRect();
    const hit = (x: number, y: number) => { const at = document.elementFromPoint(x, y); return at === term || term.contains(at); };
    return {
      head: { position: getComputedStyle(head).position, line: getComputedStyle(head).borderBottomWidth },
      left: [box(".flare-search-panel__head .flare-search").left, box(".flare-recent-searches__title").left, box(".flare-recent-searches__icon").left].map((x) => Math.round(x - frame.left)),
      right: [box(".flare-search__cancel").right, box(".flare-recent-searches__head button").right].map((x) => Math.round(frame.right - x)),
      term: { height: Math.round(row.height), fullWidth: Math.round(row.width) === Math.round(frame.width - 2), overflow: getComputedStyle(term).overflow },
      // 画多大点多大:行的四个角都真落在这一行上。
      corners: [hit(row.left + 2, row.top + 2), hit(row.right - 2, row.top + 2), hit(row.left + 2, row.bottom - 2), hit(row.right - 2, row.bottom - 2)],
    };
  });
  expect(idle.head).toEqual({ position: "static", line: "1px" });
  // 容器自己的 1px 边框算在里面,所以是 16 + 1。
  expect(idle.left, "field, recent title and the rows' icon share the left gutter").toEqual([17, 17, 17]);
  expect(idle.right, "cancel and clear share the right gutter").toEqual([17, 17]);
  expect(idle.term).toEqual({ height: 48, fullWidth: true, overflow: "visible" });
  expect(idle.corners).toEqual([true, true, true, true]);

  // 类型行的胶囊画 30、命中 48 —— 而这一排自己是滚动容器,::after 撑出去的部分曾被它自己裁掉(实际只有
  // 36,还漏出 6px 的纵向滚动)。四个角都要真落在标签上,这一排不能上下拖。
  const types = await stage.evaluate((node) => {
    const row = node.querySelector<HTMLElement>(".flare-filter-tabs")!;
    const corners = Array.from(row.querySelectorAll<HTMLElement>('[role="tab"]')).map((tab) => {
      const box = tab.getBoundingClientRect();
      const cx = box.left + box.width / 2;
      const cy = box.top + box.height / 2;
      const hit = (x: number, y: number) => { const at = document.elementFromPoint(x, y); return at === tab || tab.contains(at); };
      return [hit(cx - 21, cy - 21), hit(cx + 21, cy - 21), hit(cx - 21, cy + 21), hit(cx + 21, cy + 21)].every(Boolean);
    });
    return { drawn: Math.round(row.querySelector('[role="tab"]')!.getBoundingClientRect().height), verticalScroll: row.scrollHeight - row.clientHeight, corners };
  });
  expect(types.drawn).toBeLessThanOrEqual(32);
  expect(types.verticalScroll, "the type row must not scroll vertically").toBe(0);
  expect(types.corners, "every type's 48px hit area is real at its four corners").toEqual([true, true, true, true]);

  // 点一条最近搜索:立即搜(不等 300ms 的停顿),输入框同步成这个词,光标也回到输入框。
  await recent.getByRole("button", { name: "发版协调" }).click();
  await expect(stage.locator("input[type=search]")).toHaveValue("发版协调");
  await expect(stage.locator("input[type=search]")).toBeFocused();
  const people = stage.locator(".flare-search-group").filter({ hasText: "联系人" });
  await expect(people.locator(".flare-search-row")).toHaveCount(2);
  const avatarLeft = await stage.evaluate((node) => Math.round(node.querySelector(".flare-search-results .flare-search-row")!.firstElementChild!.getBoundingClientRect().left - node.getBoundingClientRect().left));
  expect(avatarLeft, "result rows share the head's gutter").toBe(17);

  // 「查看更多」:切到联系人这一类,宿主按这一类给满,这一行随之消失。
  await people.getByRole("button", { name: "查看更多" }).click();
  await expect(stage.getByRole("tab", { name: "联系人" })).toHaveAttribute("aria-selected", "true");
  await expect(stage.locator(".flare-search-results .flare-search-row")).toHaveCount(9);
  await expect(stage.locator(".flare-search-more")).toHaveCount(0);

  // 只有正文滚:滚下去之后搜索框还在原地,容器本身没有滚,也没有横向溢出。
  const scroll = await stage.evaluate((node) => {
    const body = node.querySelector<HTMLElement>(".flare-search-panel__body")!;
    const field = node.querySelector<HTMLElement>("input[type=search]")!;
    const before = field.getBoundingClientRect().top;
    body.scrollTop = 200;
    return { scrolled: body.scrollTop, fieldMoved: Math.round(field.getBoundingClientRect().top - before), outer: node.scrollTop, overflowX: body.scrollWidth > body.clientWidth };
  });
  expect(scroll.scrolled, "the fixture's results must overflow, or nothing here proves anything").toBeGreaterThan(0);
  expect(scroll).toMatchObject({ fieldMoved: 0, outer: 0, overflowX: false });

  // 另一次查询的结果从顶部开始。
  await stage.getByRole("tab", { name: "全部" }).click();
  await expect.poll(() => stage.locator(".flare-search-panel__body").evaluate((node) => node.scrollTop)).toBe(0);
});
