import { expect, test } from "@playwright/test";

for (const width of [1280, 390]) {
  for (const mode of ["light", "dark"] as const) {
    test(`core surfaces at ${width}px in ${mode}`, async ({ page }) => {
      await page.setViewportSize({ width, height: 900 });
      await page.emulateMedia({ colorScheme: mode, reducedMotion: "reduce" });
      await page.goto("/resources/surface-integrity-regression");
      await page.locator("#surface-integrity-fixture").waitFor();
      await page.evaluate(selected => {
        document.documentElement.dataset.flareTheme = selected;
        document.documentElement.classList.toggle("dark", selected === "dark");
      }, mode);
      const fixture = page.locator("#surface-integrity-fixture");
      await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      await page.getByRole("searchbox", { name: "Search messages" }).focus();
      expect(await page.locator(".flare-search").evaluate(node => getComputedStyle(node).boxShadow)).not.toBe("none");
      const textarea = page.locator(".flare-textarea").first();
      const bounds = await textarea.evaluate(node => {
        const field = node.querySelector("textarea")!.getBoundingClientRect();
        const counter = node.querySelector(".flare-textarea__count")!.getBoundingClientRect();
        return { fieldBottom: field.bottom, counterTop: counter.top, fits: node.scrollWidth <= node.clientWidth };
      });
      expect(bounds.counterTop).toBeGreaterThanOrEqual(bounds.fieldBottom);
      expect(bounds.fits).toBe(true);
      await expect(fixture).toHaveScreenshot(`core-surfaces-${width}-${mode}.png`);

      await page.getByRole("button", { name: "Message filter" }).click();
      const option = page.getByRole("option", { name: "Muted conversations" });
      await expect(option).toBeVisible();
      await page.keyboard.press("Tab");
      await option.focus();
      expect(await option.evaluate(node => getComputedStyle(node).outlineStyle)).toBe("solid");
      await option.click();
      await page.getByRole("button", { name: "Attachment preview" }).click();
      const preview = page.locator(".media-composer-preview");
      await expect(preview).toBeVisible();
      const modalBounds = await preview.boundingBox();
      expect(modalBounds!.x).toBeGreaterThanOrEqual(0);
      expect(modalBounds!.x + modalBounds!.width).toBeLessThanOrEqual(width);
      await expect(preview).toHaveScreenshot(`attachment-surface-${width}-${mode}.png`);
      await preview.getByRole("button", { name: "取消", exact: true }).click();
      await page.getByRole("button", { name: "Edit note", exact: true }).click();
      const sheet = page.locator(".flare-sheet");
      await expect(sheet).toBeVisible();
      const sheetBounds = await sheet.boundingBox();
      expect(sheetBounds!.x).toBeGreaterThanOrEqual(0);
      expect(sheetBounds!.x + sheetBounds!.width).toBeLessThanOrEqual(width);
      await expect(sheet).toHaveScreenshot(`sheet-surface-${width}-${mode}.png`);
      await page.keyboard.press("Escape");
      await expect(sheet).toBeHidden();
      await expect(page.getByRole("button", { name: "Edit note", exact: true })).toBeFocused();
    });
  }
}
