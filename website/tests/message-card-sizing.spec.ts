import { expect, test } from "@playwright/test";

for (const width of [180, 390, 1360]) {
  for (const mode of ["light", "dark"] as const) {
    test(`message cards keep their visual width in a ${width}px ${mode} pane`, async ({ page }, testInfo) => {
      await page.setViewportSize({ width: Math.max(390, width), height: 960 });
      await page.emulateMedia({ colorScheme: mode });
      await page.goto("/embed/component-frame?name=RedPacketCard&viewport=mobile");
      await page.locator(".flare-red-packet").first().waitFor();
      await page.evaluate(async ({ width, mode }) => {
        document.documentElement.dataset.flareTheme = mode;
        document.documentElement.classList.toggle("dark", mode === "dark");
        // Vite compiles the same source components consumed by the website and desktop apps.
        const fixture = await import("/tests/fixtures/message-card-sizing.ts");
        fixture.mountCardSizingFixture(width);
      }, { width, mode });

      for (const name of ["packet", "resolved-packet"]) {
        const card = page.locator(`[data-sizing="${name}"] .flare-red-packet`);
        await expect(card).toBeVisible();
        const bounds = await card.boundingBox();
        const sizing = await card.evaluate((node) => {
          const parent = node.parentElement!;
          return { parent: parent.getBoundingClientRect().width, columns: getComputedStyle(parent).gridTemplateColumns };
        });
        expect(bounds!.width, `${name}: ${JSON.stringify(sizing)}`).toBeCloseTo(Math.min(width, 248), 0);
        expect(await card.evaluate((node) => node.scrollWidth <= node.clientWidth)).toBe(true);
      }
      const plugin = page.locator('[data-sizing="plugin"] .flare-plugin-view').first();
      await expect(plugin).toBeVisible();
      expect((await plugin.boundingBox())!.width).toBeLessThanOrEqual(Math.min(width, 320) + 1);
      const call = page.locator('[data-sizing="call"] .flare-call-record');
      await expect(call).toBeVisible();
      expect((await call.boundingBox())!.width).toBeLessThan(Math.min(width, 320));
      for (const side of ["incoming", "outgoing", "incoming-quoted", "outgoing-quoted"]) {
        const row = page.locator(`[data-sizing="timeline-${side}"]`);
        await expect(row.locator(".flare-red-packet")).toBeVisible();
        const geometry = await row.evaluate((node) => {
          const pane = node.getBoundingClientRect();
          const card = node.querySelector(".flare-red-packet")!.getBoundingClientRect();
          const meta = node.querySelector(".message-meta-row")!.getBoundingClientRect();
          return { paneLeft: pane.left, paneRight: pane.right, cardLeft: card.left, cardRight: card.right, cardWidth: card.width, cardBottom: card.bottom, metaTop: meta.top, metaRight: meta.right };
        });
        expect(geometry.cardWidth).toBeLessThanOrEqual(248);
        expect(geometry.cardLeft).toBeGreaterThanOrEqual(geometry.paneLeft);
        expect(geometry.cardRight).toBeLessThanOrEqual(geometry.paneRight + 1);
        expect(geometry.metaTop).toBeGreaterThanOrEqual(geometry.cardBottom);
        expect(Math.abs(geometry.metaRight - geometry.cardRight)).toBeLessThan(1);
        if (side.endsWith("-quoted")) {
          const quote = row.locator("[data-card-quote]");
          await expect(quote).toHaveCount(1);
          expect(await quote.evaluate((node) => Boolean(node.closest(".flare-red-packet")))).toBe(true);
          await expect(row.locator("button button")).toHaveCount(0);
        }
      }
      await page.screenshot({ path: testInfo.outputPath("message-card-sizing.png"), fullPage: true });
    });
  }
}
