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
      // A focused search field draws its own edge in border-selected and no outer glow (FlareSearchBar: the
      // 2px focus-ring halo around a full-width field made the frame the heaviest thing on screen).
      const search = page.locator(".flare-search");
      const idleEdge = await search.evaluate(node => getComputedStyle(node).borderTopColor);
      const selected = await search.evaluate(node => {
        const probe = document.createElement("span");
        probe.style.color = "var(--flare-color-border-selected)";
        node.append(probe);
        const color = getComputedStyle(probe).color;
        probe.remove();
        return color;
      });
      expect(selected).not.toBe(idleEdge);
      await page.getByRole("searchbox", { name: "Search messages" }).focus();
      // Reduced motion still runs a near-zero transition, so the edge is read once it has settled.
      await expect.poll(() => search.evaluate(node => getComputedStyle(node).borderTopColor)).toBe(selected);
      const focusEdge = await search.evaluate(node => {
        const style = getComputedStyle(node);
        return { width: style.borderTopWidth, shadow: style.boxShadow };
      });
      expect(Number.parseFloat(focusEdge.width)).toBeGreaterThan(0);
      expect(focusEdge.shadow).toBe("none");
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
      // FlareComposerMediaPreview is a kit sheet now (FlareBottomSheet; a FlareModal at desktop width), so it is
      // found the way a person finds it: the dialog named after its title.
      const preview = page.getByRole("dialog", { name: "发送附件" });
      await expect(preview).toBeVisible();
      const modalBounds = await preview.boundingBox();
      expect(modalBounds!.x).toBeGreaterThanOrEqual(0);
      expect(modalBounds!.x + modalBounds!.width).toBeLessThanOrEqual(width);
      await expect(preview).toHaveScreenshot(`attachment-surface-${width}-${mode}.png`);
      await preview.getByRole("button", { name: "取消", exact: true }).click();
      await page.getByRole("button", { name: "Edit note", exact: true }).click();
      // 390 是底部面板,1280 是 BottomSheet auto 交给的 FlareModal;两者都是 role="dialog"。
      const sheet = page.locator('[role="dialog"]');
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
