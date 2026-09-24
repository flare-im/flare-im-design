import { expect, test, type Locator, type Page } from "@playwright/test";

/**
 * 多选工具条的两件事,只有真引擎答得出来:
 *
 * 一、退出键永远够得着。非浮动的条在任何宽度都换行(三端原生的那张图);浮动的条浮在时间线上
 *    不能长第二行,键横向滚,退出键用 sticky 钉在末端 —— 滚到哪一头它都在,而且 Tab 聚焦的键
 *    停在它前面,不钻到它的地面底下。改前 ≤599px 的非浮动条是一条隐藏滚动条的横向带,退出键排最后,
 *    手机上刚进多选它就在视野之外。happy-dom 没有布局,sticky / scroll-padding / 溢出全是零。
 *
 * 二、退出的三条路径由工具条自己拥有:Escape、平台返回(网页里是浏览器返回)、页头返回箭头的第一下。
 *    每一条都有一个「不该退」的对面:面板在上、焦点在输入框、批量进行中、藏起来。
 *
 * 靶子是 MessageBatchToolbarDemo:第一舞台是 app 的用法(页头 + 输入框位置的工具条),第二舞台是
 * 360px 的浮动条,五个能力全开才真的溢出 —— 每条断言之前先证明夹具确实溢出,不溢出直接红。
 */
const FRAME = "/embed/component-frame?name=MessageBatchToolbar&viewport=desktop";
const FLOATING = ".flare-batch-toolbar--floating";
const INLINE = ".flare-batch-toolbar:not(.flare-batch-toolbar--floating)";

async function open(page: Page): Promise<void> {
  await page.goto(FRAME);
  await page.locator(FLOATING).waitFor();
  await page.locator(INLINE).waitFor();
}

async function metrics(strip: Locator) {
  return strip.evaluate((node) => ({
    clientWidth: node.clientWidth,
    scrollWidth: node.scrollWidth,
    scrollLeft: node.scrollLeft,
    left: node.getBoundingClientRect().left,
    right: node.getBoundingClientRect().right,
  }));
}

test.describe("the exit key is always reachable", () => {
  test("the floating strip overflows at the end and pins the exit key at both scroll extremes", async ({ page }) => {
    await open(page);
    const strip = page.locator(`${FLOATING} .flare-batch-toolbar__actions`);
    const exit = strip.locator(".flare-batch-toolbar__exit");
    const firstKey = strip.locator(".flare-batch-btn").first();

    // 前提:夹具确实溢出,否则下面什么也证明不了。
    const start = await metrics(strip);
    expect(start.scrollWidth, "the fixture must overflow").toBeGreaterThan(start.clientWidth);
    // 溢出落在末端:起始键在 scrollLeft=0 时够得着(flex-end 会把它推出起始边,永远滚不到)。
    expect((await firstKey.boundingBox())!.x).toBeGreaterThanOrEqual(start.left);
    expect(await strip.getAttribute("data-scroll-end")).toBe("true");

    const exitAtStart = (await exit.boundingBox())!;
    expect(exitAtStart.x + exitAtStart.width).toBeLessThanOrEqual(start.right + 0.5);
    expect(exitAtStart.x).toBeGreaterThanOrEqual(start.left);

    await strip.evaluate((node) => { node.scrollLeft = node.scrollWidth; });
    await expect.poll(() => strip.getAttribute("data-scroll-end")).toBeNull();
    const end = await metrics(strip);
    expect(end.scrollLeft).toBeGreaterThan(0);
    // 第一个键滚出去了,退出键还在同一个位置。
    expect((await firstKey.boundingBox())!.x).toBeLessThan(end.left);
    const exitAtEnd = (await exit.boundingBox())!;
    expect(Math.abs(exitAtEnd.x - exitAtStart.x)).toBeLessThan(1);
  });

  test("a key focused by the keyboard stops short of the pinned exit key", async ({ page }) => {
    await open(page);
    const strip = page.locator(`${FLOATING} .flare-batch-toolbar__actions`);
    const exit = strip.locator(".flare-batch-toolbar__exit");
    await strip.evaluate((node) => { node.scrollLeft = 0; });
    const remove = strip.getByRole("button", { name: "删除" });
    await remove.focus();
    await expect(remove).toBeFocused();
    const key = (await remove.boundingBox())!;
    const ground = (await exit.boundingBox())!;
    // 焦点环 2px offset + 2px outline 也得在地面之外。
    expect(key.x + key.width + 4).toBeLessThanOrEqual(ground.x + 0.5);
  });

  for (const width of [1024, 390]) {
    test(`the inline bar wraps instead of scrolling at ${width}px`, async ({ page }) => {
      await page.setViewportSize({ width, height: 900 });
      await open(page);
      const strip = page.locator(`${INLINE} .flare-batch-toolbar__actions`);
      const m = await metrics(strip);
      expect(m.scrollWidth).toBeLessThanOrEqual(m.clientWidth + 1);
      const exit = strip.locator(".flare-batch-toolbar__exit button");
      await expect(exit).toBeInViewport();
      // 换行了才会比一行高;在窄的那档必须换行,宽的那档允许一行。
      const bar = (await page.locator(INLINE).boundingBox())!;
      if (width === 390) expect(bar.height).toBeGreaterThan(60);
    });
  }
});

test.describe("leaving the selection", () => {
  test("Escape exits; while busy it is consumed and nothing exits", async ({ page }) => {
    await open(page);
    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await page.getByRole("button", { name: "模拟批量进行中" }).click();
    await page.keyboard.press("Escape");
    await expect(page.locator(INLINE)).toBeVisible();
    await expect(page.locator(`${INLINE} [aria-label="退出多选"]`)).toBeDisabled();
    await page.getByRole("button", { name: "结束批量" }).click();
    await page.keyboard.press("Escape");
    await expect(page.locator(".flare-batch-toolbar")).toHaveCount(0);
    await expect(page.locator("[data-demo-status]")).toHaveText("已退出多选。");
  });

  test("a sheet on top takes Escape first; the selection stays until the next press", async ({ page }) => {
    await open(page);
    await page.getByRole("button", { name: "打开面板" }).click();
    const sheet = page.locator(".flare-sheet");
    await expect(sheet).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(sheet).toBeHidden();
    await expect(page.locator(".flare-batch-toolbar")).toHaveCount(2);
    await page.keyboard.press("Escape");
    await expect(page.locator(".flare-batch-toolbar")).toHaveCount(0);
  });

  test("Escape inside an editable control belongs to the control", async ({ page }) => {
    await open(page);
    const draft = page.getByRole("textbox", { name: "草稿" });
    await draft.click();
    await page.keyboard.type("draft");
    await page.keyboard.press("Escape");
    await expect(page.locator(".flare-batch-toolbar")).toHaveCount(2);
    await expect(draft).toHaveValue("draft");
    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await page.keyboard.press("Escape");
    await expect(page.locator(".flare-batch-toolbar")).toHaveCount(0);
  });

  test("the header's back arrow leaves the selection first, then the page", async ({ page }) => {
    await open(page);
    // 用舞台自己定位:第一下之后工具条就卸载了,从它出发的定位器再也解析不到。
    const back = page.locator('[aria-label="换行形态"]').getByRole("button", { name: "返回" });
    await back.click();
    await expect(page.locator(".flare-batch-toolbar")).toHaveCount(0);
    await expect(page.locator("[data-demo-backs]")).toHaveText("返回次数 0");
    await back.click();
    await expect(page.locator("[data-demo-backs]")).toHaveText("返回次数 1");
  });

  test("the platform back (the browser's back here) leaves the selection without leaving the page", async ({ page }) => {
    await open(page);
    // 前提:适配器把当前历史条目标记成了「有层在听」,否则 goBack 只是把页面导航走 —— 那是假绿。
    await expect.poll(() => page.evaluate(() => Boolean((history.state as Record<string, unknown> | null)?.flareNativeBack))).toBe(true);
    const url = page.url();
    await page.goBack();
    await expect(page.locator(".flare-batch-toolbar")).toHaveCount(0);
    expect(page.url()).toBe(url);
  });

  test("a hidden toolbar does not take Escape", async ({ page }) => {
    await open(page);
    await page.evaluate(() => {
      for (const stage of document.querySelectorAll<HTMLElement>(".stage")) stage.style.display = "none";
    });
    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await page.keyboard.press("Escape");
    await expect(page.locator("[data-demo-status]")).not.toHaveText("已退出多选。");
    await expect(page.locator(".flare-batch-toolbar")).toHaveCount(2);
  });
});
