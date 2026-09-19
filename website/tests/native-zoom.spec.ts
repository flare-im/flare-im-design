import { chromium, expect, test } from "@playwright/test";
import { fileURLToPath } from "node:url";

type ZoomExtension = {
  chrome: {
    tabs: {
      query(query: { active: boolean }): Promise<Array<{ id: number }>>;
      setZoom(tabId: number, factor: number): Promise<void>;
      getZoom(tabId: number): Promise<number>;
    };
  };
};

for (const mode of ["light", "dark"] as const) {
  test(`composer preserves its surface at native browser zoom in ${mode}`, async ({ baseURL }) => {
    test.setTimeout(60_000);
    const extension = fileURLToPath(new URL("./fixtures/native-zoom", import.meta.url));
    const context = await chromium.launchPersistentContext("", {
      channel: "chromium",
      // The persistent headless context allows one target only; the classic-scrollbar
      // launcher's extra argument would open a second one. Zoom does not depend on scrollers.
      executablePath: process.env.FLARE_PLAYWRIGHT_CHROMIUM,
      headless: true,
      viewport: { width: 1280, height: 900 },
      deviceScaleFactor: 1,
      colorScheme: mode,
      reducedMotion: "reduce",
      args: [`--disable-extensions-except=${extension}`, `--load-extension=${extension}`],
    });
    try {
      const worker = context.serviceWorkers()[0] ?? await context.waitForEvent("serviceworker");
      const page = context.pages()[0] ?? await context.newPage();
      await page.goto(`${baseURL}/resources/composer-surface-regression`);
      const focused = page.locator('[data-composer-state="focused"]');
      await expect(focused).toBeVisible();
      await page.evaluate(async (selectedMode) => {
        document.documentElement.dataset.flareTheme = selectedMode;
        document.documentElement.classList.toggle("dark", selectedMode === "dark");
        await document.fonts.ready;
      }, mode);
      const replyColors = await page.locator('[data-composer-state="reply"] .composer-reply-strip').evaluate((node) => {
        const resolveColor = (token: string) => {
          const probe = document.createElement("span");
          probe.style.color = `var(${token})`;
          node.append(probe);
          const color = getComputedStyle(probe).color;
          probe.remove();
          return color;
        };
        return {
          // 回复条的发信人用“文字版”品牌色：边框色当 11px 文字只有 3.98:1。
          accent: resolveColor("--flare-color-primary-text"),
          secondary: resolveColor("--flare-color-text-secondary"),
          title: getComputedStyle(node.querySelector(".flare-reply .who")!).color,
          preview: getComputedStyle(node.querySelector(".flare-reply .sum")!).color,
        };
      });
      expect(replyColors.title).toBe(replyColors.accent);
      expect(replyColors.preview).toBe(replyColors.secondary);

      for (const zoom of [0.9, 1, 1.1, 1.25]) {
        const actualZoom = await worker.evaluate(async (factor) => {
          const { tabs } = (globalThis as unknown as ZoomExtension).chrome;
          const [tab] = await tabs.query({ active: true });
          await tabs.setZoom(tab.id, factor);
          return tabs.getZoom(tab.id);
        }, zoom);
        expect(actualZoom).toBeCloseTo(zoom, 3);
        await expect.poll(() => page.evaluate(() => devicePixelRatio)).toBeCloseTo(zoom, 3);
        await page.locator('[data-composer-state="default"] textarea').focus();
        const surface = focused.locator('[data-flare-surface-owner="composer"]');
        await surface.evaluate(node => Promise.all(node.getAnimations().map(animation => animation.finished)));
        const unfocusedBorder = await surface.evaluate(node => getComputedStyle(node).borderColor);
        await focused.locator("textarea").focus();
        await surface.evaluate(node => Promise.all(node.getAnimations().map(animation => animation.finished)));
        const geometry = await focused.locator('[data-flare-surface-owner="composer"]').evaluate((node) => {
          const style = getComputedStyle(node);
          const rect = node.getBoundingClientRect();
          const toolbar = node.querySelector(".composer-toolbar")!.getBoundingClientRect();
          return {
            widths: [style.borderTopWidth, style.borderRightWidth, style.borderBottomWidth, style.borderLeftWidth],
            radius: style.borderRadius,
            focus: style.boxShadow,
            borderColor: style.borderColor,
            childrenInside: toolbar.left >= rect.left && toolbar.right <= rect.right + 1 && toolbar.bottom <= rect.bottom + 1,
            noHorizontalOverflow: node.scrollWidth <= node.clientWidth + 1,
          };
        });
        expect(new Set(geometry.widths).size).toBe(1);
        expect(Number.parseFloat(geometry.widths[0])).toBeGreaterThan(0);
        expect(geometry.radius).not.toBe("0px");
        expect(geometry.focus).toBe("none");
        expect(geometry.borderColor).not.toBe(unfocusedBorder);
        expect(geometry.childrenInside).toBe(true);
        expect(geometry.noHorizontalOverflow).toBe(true);
        await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
        // A viewport capture avoids locator clipping offsets under native tab zoom.
        await expect(page).toHaveScreenshot(`composer-native-zoom-${Math.round(zoom * 100)}-${mode}.png`);
      }
    } finally {
      await context.close();
    }
  });
}
