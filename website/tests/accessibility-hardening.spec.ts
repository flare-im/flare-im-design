import { expect, test } from "@playwright/test";

async function ready(page: import("@playwright/test").Page) {
  await page.goto("/resources/visual-regression");
  await page.locator('[data-vr-ready="true"]').waitFor();
  await page.evaluate(async () => { await document.fonts.ready; });
}

test("interactive controls have names and no positive tabindex", async ({ page }) => {
  await ready(page);
  const failures = await page.locator("#rc-visual-fixture").evaluate((root) => {
    const nodes = [...root.querySelectorAll<HTMLElement>('button, input, textarea, select, [role="button"], [tabindex]')];
    return nodes.flatMap((node) => {
      const tabindex = Number(node.getAttribute("tabindex") ?? "0");
      const name = node.getAttribute("aria-label") || node.getAttribute("title") || node.textContent || (node as HTMLInputElement).placeholder || "";
      return tabindex > 0 || !name.trim() ? [`${node.tagName}:${node.className}`] : [];
    });
  });
  expect(failures).toEqual([]);
});

test("keyboard focus is visible", async ({ page }) => {
  await ready(page);
  await page.keyboard.press("Tab");
  const focused = page.locator(":focus-visible");
  await expect(focused).toHaveCount(1);
  const visibleIndicator = await focused.evaluate((node) => {
    const style = getComputedStyle(node);
    return style.outlineStyle !== "none" || style.boxShadow !== "none" || style.borderColor !== "rgba(0, 0, 0, 0)";
  });
  expect(visibleIndicator).toBe(true);
});

test("reduced motion suppresses continuous status animation", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await ready(page);
  const spinner = page.locator("#rc-visual-fixture .rotating").first();
  await expect(spinner).toBeVisible();
  await expect(spinner).toHaveCSS("animation-iteration-count", "1");
});

test("forced colors preserves status and focus affordances", async ({ page }) => {
  await page.emulateMedia({ forcedColors: "active" });
  await ready(page);
  const status = page.locator("#rc-visual-fixture [role=status]").first();
  await expect(status).toBeVisible();
  await page.keyboard.press("Tab");
  await expect(page.locator(":focus-visible")).toHaveCSS("outline-style", "solid");
});
