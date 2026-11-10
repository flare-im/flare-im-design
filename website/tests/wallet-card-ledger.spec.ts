import { expect, test } from "@playwright/test";

for (const width of [320, 1360]) for (const mode of ["light", "dark"] as const) {
  test(`wallet cards and grouped records fit ${width}px ${mode}`, async ({page}, testInfo) => {
    await page.setViewportSize({width, height: 1000});
    await page.emulateMedia({colorScheme: mode});
    await page.goto("/embed/component-frame?name=RedPacketCard&viewport=mobile");
    await page.locator(".flare-red-packet").first().waitFor();
    const entry = await page.evaluate(async mode => {
      document.documentElement.dataset.flareTheme = mode;
      document.documentElement.classList.toggle("dark", mode === "dark");
      const fixture = await import("/tests/fixtures/wallet-flow.ts");
      const index = fixture.cases.findIndex(item => item.id === "home" && item.locale === "zh-CN");
      fixture.mountWalletFixture(index);
      const view = fixture.cases[index].view;
      const rows = view.blocks.find(block => block.kind === "rows")!;
      if (rows.kind !== "rows") throw new Error("Wallet fixture has no rows");
      return {key: rows.rows[0].key, input: rows.rows[0].actions.find(action => action.id === view.presentation.props.rowEntryAction)!.input};
    }, mode);
    await expect(page.locator("[data-wallet-card]")).toContainText("查看明细");
    await expect(page.locator(".flare-account-view__shortcuts [data-action-id]")).toHaveCount(3);
    const duplicated = await page.locator(".flare-account-view").evaluate(node => {
      const ids = [...node.querySelectorAll("[data-action-id]")].map(item => item.getAttribute("data-action-id"));
      return ids.filter((id, i) => ids.indexOf(id) !== i);
    });
    expect(duplicated).toEqual([]);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    const card = page.locator("[data-wallet-card]").first();
    await card.focus();
    await card.press("Enter");
    expect(await page.evaluate(async () => (await import("/tests/fixtures/wallet-flow.ts")).emittedWalletActions)).toMatchObject([{id: "wallet", payload: {row: {key: entry.key, input: entry.input}}}]);
    await expect(page.locator('[role="dialog"]')).toHaveCount(0);
    await page.screenshot({path: testInfo.outputPath("wallet-home.png"), fullPage: true});
  });
}
