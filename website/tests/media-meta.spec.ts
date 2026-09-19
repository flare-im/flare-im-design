import { expect, test } from "@playwright/test";

function contrast(foreground: string, background: string) {
  const luminance = (color: string) => {
    const linear = color.match(/[\d.]+/g)!.slice(0, 3).map(value => {
      const channel = Number(value) / 255;
      return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
    });
    return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722;
  };
  const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
  return (values[0] + 0.05) / (values[1] + 0.05);
}

for (const mode of ["light", "dark"] as const) {
  for (const width of [320, 390, 768, 1440, 1920]) {
    test(`media footer does not cover content at ${width} in ${mode}`, async ({ page }, testInfo) => {
      await page.setViewportSize({ width, height: 900 });
      await page.emulateMedia({ colorScheme: mode, reducedMotion: "reduce" });
      await page.goto("/resources/media-meta-regression");
      const fixture = page.locator("#media-meta-regression");
      await expect(fixture).toBeVisible();
      await page.evaluate(selected => {
        document.documentElement.dataset.flareTheme = selected;
        document.documentElement.classList.toggle("dark", selected === "dark");
      }, mode);
      await page.evaluate(async () => { await document.fonts.ready; });
      const bubbles = fixture.locator(".message-bubble--chromeless-media");
      await expect(bubbles).toHaveCount(14);
      for (const bubble of await bubbles.all()) {
        await bubble.scrollIntoViewIfNeeded();
        await expect.poll(() => bubble.locator(".message-bubble-body img").evaluateAll(images =>
          images.length > 0 && images.every(image => (image as HTMLImageElement).complete && (image as HTMLImageElement).naturalWidth > 0),
        )).toBe(true);
        const geometry = await bubble.evaluate(node => {
          const body = node.querySelector(".message-bubble-body")!.getBoundingClientRect();
          const meta = node.querySelector(".message-meta-row")!;
          const rect = meta.getBoundingClientRect();
          const style = getComputedStyle(meta);
          return {
            gap: rect.top - body.bottom, right: rect.right, left: rect.left,
            position: style.position, background: style.backgroundColor, color: style.color,
            surface: getComputedStyle(node.closest("main")!).backgroundColor,
            outgoing: !!node.closest(".message-row--self"), bodyLeft: body.left, bodyRight: body.right,
            onOutgoing: meta.classList.contains("message-meta-row--on-outgoing"),
          };
        });
        expect(geometry.gap).toBeGreaterThanOrEqual(3);
        expect(geometry.gap).toBeLessThanOrEqual(5);
        expect(geometry.position).toBe("static");
        expect(geometry.background).toBe("rgba(0, 0, 0, 0)");
        expect(geometry.onOutgoing).toBe(false);
        // #5C6371 / #9AA3B3 —— 亮色值在 P0-7 由 #626978 收深，因为 12px 的时间戳
        // 在 #F1F2F5 底上只有 4.39:1；下面那条断言就是它非过不可的原因。
        expect(geometry.color).toBe(mode === "light" ? "rgb(92, 99, 113)" : "rgb(154, 163, 179)");
        expect(contrast(geometry.color, geometry.surface)).toBeGreaterThanOrEqual(4.5);
        expect(Math.abs(geometry.outgoing ? geometry.right - geometry.bodyRight : geometry.left - geometry.bodyLeft)).toBeLessThan(1);
        expect(geometry.left).toBeGreaterThanOrEqual(0);
        expect(geometry.right).toBeLessThanOrEqual(width);
      }
      await expect(fixture.locator(".message-row:not(.message-row--self) .message-status")).toHaveCount(0);
      const upload = fixture.locator('[data-media-case="upload"] .message-row--self');
      const mediaBox = (await upload.locator(".message-bubble-body").boundingBox())!;
      const progressBox = (await upload.locator(".message-upload-progress--media").boundingBox())!;
      expect(progressBox.y).toBeGreaterThanOrEqual(mediaBox.y);
      expect(progressBox.y + progressBox.height).toBeLessThanOrEqual(mediaBox.y + mediaBox.height);
      const text = fixture.locator('[data-media-case="text"] .message-row--self .message-meta-row');
      await expect(text).toHaveClass(/message-meta-row--on-outgoing/);
      const target = fixture.locator('[data-media-case="sticker"] .message-row--self');
      const initialHeight = (await target.boundingBox())!.height;
      const picker = fixture.getByLabel("Delivery state");
      for (const state of ["pending", "sending", "sent", "delivered", "read", "retrying", "failed"]) {
        await picker.selectOption(state);
        await expect(target.locator(`.message-status--${state}`)).toBeVisible();
        expect((await target.boundingBox())!.height).toBeCloseTo(initialHeight, 1);
      }
      const retry = target.getByRole("button", { name: "发送失败，点击重试" });
      await retry.focus();
      await retry.press("Enter");
      await expect(fixture).toHaveAttribute("data-retries", "1");
      await picker.selectOption("read");
      await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      await page.screenshot({ path: testInfo.outputPath(`media-footer-${mode}-${width}.png`), fullPage: true });
    });
  }
}
