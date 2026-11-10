import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";
const vectors = JSON.parse(readFileSync(new URL("../../spec/account-layout-vectors.json", import.meta.url), "utf8")) as {
  viewports: Array<{ width: number; outerWidth: number; walletColumns: number; formWidth: number }>;
  cases: Array<{ id: string; layout: string; expected: { urgentTexts: string[]; informationTexts: string[]; exactAmounts: string[] } }>;
};

for (const viewport of vectors.viewports) for (const mode of ["light", "dark"] as const) {
  test(`shared account layouts ${viewport.width}px ${mode}`, async ({ page }, testInfo) => {
    await page.setViewportSize({ width: viewport.width, height: 1200 });
    await page.emulateMedia({ colorScheme: mode });
    await page.goto("/embed/component-frame?name=RedPacketCard&viewport=mobile");
    await page.locator(".flare-red-packet").first().waitFor();
    await page.evaluate(mode => {
      document.documentElement.dataset.flareTheme = mode;
      document.documentElement.classList.toggle("dark", mode === "dark");
    }, mode);
    for (let index = 0; index < vectors.cases.length; index++) {
      const item = vectors.cases[index];
      await page.evaluate(async index => (await import("/tests/fixtures/account-layout.ts")).mountAccountLayoutFixture(index), index);
      const header = page.locator(".flare-screen__header"), body = page.locator(".flare-screen__body");
      const headerBox = (await header.boundingBox())!, bodyBox = (await body.boundingBox())!;
      expect(headerBox.width, item.id).toBeCloseTo(viewport.outerWidth, 0);
      expect(bodyBox.x, item.id).toBeCloseTo(headerBox.x, 0);
      expect(bodyBox.width, item.id).toBeCloseTo(headerBox.width, 0);
      expect((await page.locator(".flare-screen__back").boundingBox())!.width).toBe(48);
      const padding = await page.locator(".flare-plugin-page__scroll").evaluate(node => {
        const style = getComputedStyle(node);
        return [style.paddingTop, style.paddingLeft, style.paddingBottom];
      });
      expect(padding).toEqual(["12px", "16px", "20px"]);
      if (item.layout !== "flow") {
        for (const text of item.expected.urgentTexts) await expect(page.getByText(text, { exact: true })).toBeVisible();
        for (const text of item.expected.informationTexts) await expect(page.getByText(text, { exact: true })).toBeHidden();
        const toggle = page.locator("details summary");
        expect((await toggle.boundingBox())!.height).toBeGreaterThanOrEqual(48);
      }
      if (item.layout === "wallet") {
        const cards = page.locator("[data-wallet-card]");
        const first = (await cards.nth(0).boundingBox())!, second = (await cards.nth(1).boundingBox())!;
        expect(Math.abs(first.y - second.y) < 1, item.id).toBe(viewport.walletColumns === 2);
        if (viewport.walletColumns === 2) expect(first.height, `${item.id}: long content sets its own card height`).toBeGreaterThan(second.height);
        await expect(page.locator("[data-account-balance]").first()).toHaveText(item.expected.exactAmounts[0]);
        const meta = await page.locator(".flare-account-view__wallet-card-details").first().evaluate(node => {
          const style = getComputedStyle(node), value = getComputedStyle(node.querySelector("dd")!);
          return { columns: style.gridTemplateColumns.split(" ").length, fontSize: value.fontSize, weight: value.fontWeight };
        });
        expect(meta).toEqual({ columns: 2, fontSize: "14px", weight: "500" });
      }
      if (item.layout === "flow") {
        expect((await page.locator("[data-inline-action-form]").boundingBox())!.width, item.id).toBeCloseTo(viewport.formWidth, 0);
      }
      const overflow = await page.locator(".flare-account-view").evaluate(node => {
        const box = node.getBoundingClientRect();
        return [...node.querySelectorAll("button, input, textarea, select, [data-account-balance], dd")].filter(el => el.getClientRects().length).filter(el => {
          const rect = el.getBoundingClientRect();
          return rect.left < box.left - 1 || rect.right > box.right + 1;
        }).map(el => el.className);
      });
      expect(overflow, item.id).toEqual([]);
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), item.id).toBe(true);
      if ([390, 1360].includes(viewport.width)) await page.screenshot({ path: testInfo.outputPath(`${item.id}.png`) });
    }
  });
}

test("page frame is stable across states and respects explicit widths", async ({ page }) => {
  await page.setViewportSize({ width: 1360, height: 1200 });
  await page.goto("/embed/component-frame?name=RedPacketCard&viewport=mobile");
  await page.locator(".flare-red-packet").first().waitFor();
  for (const state of ["loading", "error", "unavailable", "document", "loaded"]) for (const width of [undefined, 640, null]) {
    await page.evaluate(async ({ state, width }) => (await import("/tests/fixtures/account-layout.ts")).mountAccountLayoutFixture(0, state, width), { state, width });
    const expected = width === null ? 1360 : width ?? 880;
    for (const selector of [".flare-screen__header", ".flare-screen__body"]) expect((await page.locator(selector).boundingBox())!.width, `${state}/${width}`).toBeCloseTo(expected, 0);
    if (state === "loaded") expect((await page.locator(".flare-account-view").boundingBox())!.width).toBeCloseTo(expected - 32, 0);
  }
});

test("safe areas add to the normal header and page spacing", async ({ page, context }) => {
  await page.setViewportSize({ width: 390, height: 1200 });
  const session = await context.newCDPSession(page);
  await session.send("Emulation.setDeviceMetricsOverride", { mobile: true, width: 390, height: 1200, deviceScaleFactor: 1 });
  await page.goto("/embed/component-frame?name=RedPacketCard&viewport=mobile");
  await page.locator(".flare-red-packet").first().waitFor();
  await page.evaluate(async () => (await import("/tests/fixtures/account-layout.ts")).mountAccountLayoutFixture(0));
  await page.evaluate(() => {
    const meta = document.querySelector('meta[name="viewport"]') ?? document.head.appendChild(document.createElement("meta"));
    meta.setAttribute("name", "viewport");
    meta.setAttribute("content", "width=device-width, initial-scale=1, viewport-fit=cover");
  });
  await session.send("Emulation.setSafeAreaInsetsOverride", { insets: { top: 34, bottom: 34, left: 0, right: 0 } });
  await expect.poll(() => page.evaluate(() => ({
    top: getComputedStyle(document.querySelector(".flare-screen__header")!).paddingTop,
    bottom: getComputedStyle(document.querySelector(".flare-plugin-page__scroll")!).paddingBottom,
  }))).toEqual({ top: "42px", bottom: "54px" });
});
