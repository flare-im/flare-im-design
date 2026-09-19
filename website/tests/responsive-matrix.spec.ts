import { expect, test } from "@playwright/test";

/**
 * The release criterion's responsive matrix: the ten widths × the core surfaces, with zero
 * horizontal overflow (`2.0-release-criteria.md` §1 responsive).
 *
 * Nine of the ten widths were covered incidentally, by whichever test happened to use them, and 834
 * — an iPad in portrait — by nothing at all. "Covered incidentally" also meant no single run could
 * answer the criterion's question, so `release-criteria-coverage.mjs` reported it unmet for as long
 * as it has existed.
 *
 * What it asserts is narrow on purpose: nothing may push the page sideways. That is the failure a
 * person actually sees — a chat they can scroll left and right — and it is the one that kept
 * appearing: a media body capped at `72vw` inside a narrower bubble hung over the edge (FR-157),
 * and before that a preview card sized from the window did the same.
 */
const WIDTHS = [320, 360, 375, 390, 430, 768, 834, 1024, 1280, 1440];

/**
 * The core loop, on the fixtures that are meant to fit their window. `/resources/visual-regression`
 * is deliberately a fixed 1120px board for pixel baselines, so it is not one of these — a board that
 * is wider than a phone on purpose says nothing about whether the product fits one.
 */
const SURFACES = [
  { name: "message bodies", path: "/resources/media-meta-regression", ready: "#media-meta-regression" },
  { name: "composer states", path: "/resources/composer-surface-regression", ready: "#composer-surface-regression" },
  // The conversation fixture takes its width from the query, so it is given the viewport's.
  { name: "conversation list", path: "/resources/conversation-regression?width=", ready: ".conversation-regression" },
  { name: "surfaces and overlays", path: "/resources/surface-integrity-regression", ready: "#surface-integrity-fixture" },
];

/**
 * What pushes the page sideways, if anything, reported by name so a failure says where to look.
 * Content inside a horizontal scroller does not: an upload strip or a code block is allowed to be
 * wider than the window — that is what the scroller is for — and only what escapes one counts.
 */
async function overflow(page: import("@playwright/test").Page) {
  return page.evaluate(() => {
    const room = window.innerWidth;
    const scrolls = (element: HTMLElement) => {
      const overflowX = getComputedStyle(element).overflowX;
      return overflowX === "auto" || overflowX === "scroll";
    };
    const offenders: string[] = [];
    for (const element of Array.from(document.querySelectorAll<HTMLElement>("body *"))) {
      const box = element.getBoundingClientRect();
      if (box.width === 0 && box.height === 0) continue;
      if (box.right <= room + 1 && box.left >= -1) continue;
      let inScroller = false;
      for (let node = element.parentElement; node && node !== document.body; node = node.parentElement) {
        if (scrolls(node)) { inScroller = true; break; }
      }
      if (inScroller) continue;
      const name = `${element.tagName.toLowerCase()}.${String(element.className).trim().split(/\s+/)[0] ?? ""}`;
      offenders.push(`${name} [${Math.round(box.left)}…${Math.round(box.right)}]`);
      if (offenders.length >= 5) break;
    }
    return { scrollWidth: document.documentElement.scrollWidth, room, offenders };
  });
}

for (const surface of SURFACES) {
  test(`${surface.name} never scrolls sideways at any of the ten widths`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
    for (const width of WIDTHS) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto(surface.path.endsWith("width=") ? `${surface.path}${width}` : surface.path);
      await page.locator(surface.ready).first().waitFor();
      // The page agrees it has the width we asked for before anything is measured: a container
      // query re-evaluates after layout, so reading too early reads the previous width (FR-157).
      await expect.poll(() => page.evaluate(() => window.innerWidth)).toBe(width);
      await expect.poll(async () => (await overflow(page)).scrollWidth, {
        message: `${surface.name} at ${width}px`,
      }).toBeLessThanOrEqual(width);

      const measured = await overflow(page);
      expect(measured.offenders, `${surface.name} at ${width}px: ${measured.offenders.join(", ")}`).toEqual([]);
    }
  });
}
