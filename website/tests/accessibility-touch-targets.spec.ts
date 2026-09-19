import { writeFileSync } from "node:fs";
import { expect, test } from "@playwright/test";
import catalog from "../../spec/component-catalog.json" with { type: "json" };

// DoD 22 — hit areas on a touch surface. A finger hits an area, not a border
// box: a 40px button centred in a padded row is comfortably tappable, and a text
// field is tapped through the box that focuses it. So instead of measuring the
// drawn size, probe the corners of the 44x44 square centred on each control and
// ask the browser where that tap would land.
const MIN = 44;

// Boxes that deliver a tap to the field they wrap (native label, the input shell,
// the composer row that focuses the editor on mousedown).
const FIELD_WRAPPERS = "label, .n-input, .flare-input, .flare-textarea, .composer-input-row";

const INTERACTIVE = [
  "button", "a[href]", "input:not([type=hidden])", "select", "textarea",
  '[role="button"]', '[role="tab"]', '[role="switch"]', '[role="checkbox"]',
  '[role="radio"]', '[role="menuitem"]', '[role="option"]',
].join(", ");

test.use({ hasTouch: true, isMobile: true });

test("@a11y every touch target on a phone is at least 44 by 44", async ({ page }) => {
  test.setTimeout(20 * 60 * 1000);
  await page.setViewportSize({ width: 390, height: 844 });
  const components = catalog.components.filter((entry) => entry.previewViewports.includes("mobile"));
  const failures: { component: string; tag: string; cls: string; w: number; h: number }[] = [];

  for (const entry of components) {
    try {
      await page.goto(`/embed/component-frame?name=${entry.name}&viewport=mobile`, { waitUntil: "domcontentloaded" });
      await page.locator(".component-preview__live > *").first().waitFor({ timeout: 20000 });
    } catch {
      continue; // the axe sweep owns "this preview did not render"
    }
    const small = await page.evaluate(([selector, wrappers, min]) => {
      // Several wrappers can nest (the input shell inside the composer row); the
      // tap lands on the outermost one, so take the largest.
      const targetOf = (node: HTMLElement): HTMLElement => {
        if (node.tagName !== "INPUT" && node.tagName !== "TEXTAREA") return node;
        let best = node;
        for (let cursor: HTMLElement | null = node; cursor; cursor = cursor.parentElement) {
          if (!cursor.matches(wrappers as string)) continue;
          const box = cursor.getBoundingClientRect();
          if (box.height > best.getBoundingClientRect().height) best = cursor;
        }
        return best;
      };
      return [...document.querySelectorAll<HTMLElement>(selector as string)].flatMap((raw) => {
        const node = targetOf(raw);
        const rect = node.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) return [];
        if (rect.width >= (min as number) && rect.height >= (min as number)) return [];
        const cx = rect.left + rect.width / 2;
        const cy = rect.top + rect.height / 2;
        const half = (min as number) / 2 - 1;
        const corners: [number, number][] = [
          [cx - half, cy - half], [cx + half, cy - half],
          [cx - half, cy + half], [cx + half, cy + half],
        ];
        const misses = corners.filter(([x, y]) => {
          if (x < 0 || y < 0 || x > innerWidth || y > innerHeight) return false; // clipped by the frame, not by the control
          const hit = document.elementFromPoint(x, y);
          return !(hit && (hit === node || node.contains(hit) || hit.closest(selector as string) === node));
        });
        if (!misses.length) return [];
        return [{ tag: node.tagName.toLowerCase(), cls: String(node.className).slice(0, 70), w: Math.round(rect.width), h: Math.round(rect.height) }];
      });
    }, [INTERACTIVE, FIELD_WRAPPERS, MIN] as const);
    for (const item of small) failures.push({ component: entry.name, ...item });
  }

  writeFileSync("test-results/touch-targets.json", `${JSON.stringify({ components: components.length, failures }, null, 2)}\n`);
  expect(
    failures.map((f) => `${f.component} · ${f.tag}.${f.cls} ${f.w}x${f.h}`),
    `${components.length} mobile previews probed`,
  ).toEqual([]);
});
