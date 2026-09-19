import { expect, test } from "@playwright/test";

const mobileViewports = [
  { width: 375, height: 667 },
  { width: 390, height: 844 },
  { width: 430, height: 932 },
] as const;

for (const viewport of mobileViewports) {
  test(`H5 image preview renders a decoded image at ${viewport.width}x${viewport.height}`, async ({ page }) => {
    await page.setViewportSize(viewport);
    // Exercise the isolated mobile renderer at each real device viewport.
    await page.goto("/embed/component-frame?name=ImagePreviewModal&viewport=mobile");

    const trigger = page.getByRole("button", { name: "打开图片预览" });
    await trigger.click();

    const dialog = page.getByRole("dialog");
    const stage = dialog.locator(".image-preview-modal__stage");
    const image = dialog.locator("img.image-preview-modal__img");
    await expect(stage).toHaveAttribute("data-image-state", "ready");
    await expect(image).toHaveClass(/is-ready/);
    await expect(image).toHaveCSS("opacity", "1");
    await expect(image).toBeVisible();

    const geometry = await image.evaluate((node) => {
      const image = node as HTMLImageElement;
      const rect = image.getBoundingClientRect();
      const viewport = window.visualViewport;
      return {
        naturalWidth: image.naturalWidth,
        naturalHeight: image.naturalHeight,
        opacity: getComputedStyle(image).opacity,
        width: rect.width,
        height: rect.height,
        left: rect.left,
        top: rect.top,
        viewportWidth: viewport?.width ?? window.innerWidth,
        viewportHeight: viewport?.height ?? window.innerHeight,
      };
    });

    expect(geometry.naturalWidth).toBe(480);
    expect(geometry.naturalHeight).toBe(320);
    expect(geometry.opacity).toBe("1");
    expect(geometry.width).toBeGreaterThan(0);
    expect(geometry.height).toBeGreaterThan(0);
    expect(geometry.left).toBeGreaterThanOrEqual(0);
    expect(geometry.top).toBeGreaterThanOrEqual(0);
    expect(geometry.left + geometry.width).toBeLessThanOrEqual(geometry.viewportWidth + 1);
    expect(geometry.top + geometry.height).toBeLessThanOrEqual(geometry.viewportHeight + 1);

    await page.getByRole("button", { name: "关闭预览" }).click();
    await expect(dialog).toBeHidden();
    await expect(trigger).toBeFocused();
  });
}
