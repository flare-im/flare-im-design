import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";
const vectors = JSON.parse(readFileSync(new URL("../../spec/wallet-flow-vectors.json", import.meta.url), "utf8"));

for (const width of [320, 390, 1360]) {
  for (const mode of ["light", "dark"] as const) {
    test(`resolved wallet flows fit ${width}px ${mode}`, async ({ page }, testInfo) => {
      await page.setViewportSize({ width, height: 900 });
      await page.emulateMedia({ colorScheme: mode });
      await page.goto("/embed/component-frame?name=RedPacketCard&viewport=mobile");
      await page.locator(".flare-red-packet").first().waitFor();
      await page.evaluate(mode => {
        document.documentElement.dataset.flareTheme = mode;
        document.documentElement.classList.toggle("dark", mode === "dark");
      }, mode);
      for (let index = 0; index < vectors.cases.length; index++) {
        const item = vectors.cases[index];
        await page.evaluate(async index => {
          const fixture = await import("/tests/fixtures/wallet-flow.ts");
          fixture.mountWalletFixture(index);
        }, index);
        const account = page.locator(".flare-account-view");
        const renderer = item.view.presentation.renderer;
        if (renderer === "account") {
          await expect(account).toBeVisible();
          const bounds = await account.boundingBox();
          expect(bounds!.width, `${item.id}/${item.variant}/${item.locale}`).toBeLessThanOrEqual(880);
          const overflow = await account.evaluate(node => {
            const pane = node.getBoundingClientRect();
            return [...node.querySelectorAll("button[data-action-id]")].filter(button => button.getClientRects().length).filter(button => {
              const rect = button.getBoundingClientRect();
              return rect.left < pane.left - 1 || rect.right > pane.right + 1;
            }).map(button => button.getAttribute("data-action-id"));
          });
          expect(overflow, `${item.id}/${item.variant}/${item.locale}: overflowing actions`).toEqual([]);
          if (item.view.presentation.props.layout === "flow") await expect(page.locator("[data-account-balance], [data-account-empty]")).toHaveCount(0);
          if (item.id === "home") {
            await expect(page.locator(".flare-account-view__wallet-header [data-action-id]")).toHaveCount(3);
            await expect(page.locator(".flare-account-view__date")).toHaveCount(0);
          }
        }
        expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `${item.id}/${item.variant}/${item.locale}: document width`).toBe(true);
        if (item.locale === "zh-CN" && ["home", "recharge", "withdrawal", "payout_profiles", "cashflow_history", "withdrawal_authorization", "security", "openings", "lots", "recovery"].includes(item.id)) {
          await page.screenshot({ path: testInfo.outputPath(`${item.id}-${item.variant}.png`), fullPage: true });
          const inline = page.locator('[data-inline-action-form]');
          if (await inline.count()) {
            await inline.locator('[data-form-submit]').scrollIntoViewIfNeeded();
            await expect(inline.locator('[data-form-submit]')).toBeInViewport();
            await expect(inline.locator('[data-form-cancel]')).toHaveCount(0);
            await page.screenshot({ path: testInfo.outputPath(`${item.id}-${item.variant}-form-actions.png`), fullPage: true });
          }
        }
      }
      await page.evaluate(async () => {
        const fixture = await import("/tests/fixtures/wallet-flow.ts");
        fixture.mountMultipleWalletFixture();
      });
      const cards = page.locator('[data-wallet-card]');
      await expect(cards).toHaveCount(2);
      await expect(page.locator('[data-account-balance]')).toHaveText(['1000.00', '88.50']);
      await expect(page.getByRole('heading', {name: '我的钱包', exact: true})).toHaveCount(1);
      const first = await cards.nth(0).boundingBox(), second = await cards.nth(1).boundingBox();
      if (width > 880) expect(Math.abs(first!.y - second!.y)).toBeLessThan(1);
      else expect(second!.y).toBeGreaterThan(first!.y + first!.height);
      const order = await page.locator('.flare-account-view').evaluate(node => {
        const info = node.querySelector('details')!, services = node.querySelector('.flare-account-view__navigation')!;
        return Boolean(info.compareDocumentPosition(services) & Node.DOCUMENT_POSITION_FOLLOWING);
      });
      expect(order).toBe(true);
      await page.screenshot({path: testInfo.outputPath('multiple-wallets.png'), fullPage: true});
      await page.getByRole('button', {name: '隐藏余额', exact: true}).click();
      await expect(page.locator('[data-account-balance]')).toHaveText(['••••', '••••']);
      await page.locator('details summary').click();
      await expect(page.locator('details')).not.toContainText('900.00');
    });
  }
}
