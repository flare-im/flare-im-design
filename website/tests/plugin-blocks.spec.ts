import { expect, test } from "@playwright/test";

// The visual gate of the plugin vocabulary 2 blocks and the upgrade notice (docs/plugin-components.md); the SwiftUI,
// Compose and Flutter kits keep the same page in their own gates.
for (const mode of ["light", "dark"] as const) {
  test(`plugin vocabulary 2 blocks in ${mode}`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: mode, reducedMotion: "reduce" });
    await page.goto("/resources/plugin-blocks-regression");
    const fixture = page.locator("#plugin-blocks-regression");
    await expect(fixture).toBeVisible();
    await page.evaluate((selected) => {
      document.documentElement.dataset.flareTheme = selected;
      document.documentElement.classList.toggle("dark", selected === "dark");
    }, mode);
    await page.evaluate(async () => { await document.fonts.ready; });
    for (const kind of ["hero", "stats", "banner", "section", "chart", "steps", "image", "qr", "timeline"])
      await expect(fixture.locator(`[data-block="${kind}"]`).first()).toBeVisible();
    await expect(fixture.locator('[data-upgrade-notice="card"][data-upgrade-mode="update"]')).toHaveCount(1);
    await expect(fixture.locator('[data-upgrade-notice="card"][data-upgrade-mode="notAvailable"]')).toHaveCount(1);
    await expect(fixture).toHaveScreenshot(`plugin-blocks-${mode}.png`);
  });
}
