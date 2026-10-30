import { expect, test } from "@playwright/test";

// The kit used to lay a chat out for the window: a 380px pane of a 1600px desktop got the desktop
// bubble widths, gutters and composer shape, because every rule asked `@media`. The timeline, the
// chat workspace and the composer are container query containers now (`flare-timeline`,
// `flare-chat`, `flare-composer`), so the same component in a narrow pane reads like a chat on a
// phone while the window stays wide.
//
// This is the test that can tell the two apart: the visual baselines cannot, because there the
// container width and the window width are the same number.

const NARROW = 380;
const WIDE = 1600;

async function openWorkspace(page: import("@playwright/test").Page) {
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.setViewportSize({ width: WIDE, height: 900 });
  await page.goto("/resources/visual-regression");
  const workspace = page.locator(".fixture-workspace .workspace-demo");
  await expect(workspace.locator(".message-row--self")).toBeVisible();
  await expect.poll(() => page.evaluate(() => window.innerWidth)).toBe(WIDE);
  return workspace;
}

/**
 * The timeline's edge gutter: 16px on a wide timeline and 8px on a narrow one (`@container flare-timeline`).
 * The avatar slot next to it is one value at every width — avatar 40 + spacing.sm, the same sum on the four
 * kits (message-bubble.css) — so it is read as well, to show it does not follow the pane.
 */
function guttersOf(workspace: import("@playwright/test").Locator) {
  return workspace.locator(".message-list").first().evaluate((list) => ({
    edge: Number.parseFloat(getComputedStyle(list.querySelector(".message-list-content")!).paddingLeft),
    avatar: Number.parseFloat(getComputedStyle(list.querySelector(".message-row--avatar-gutter:not(.message-row--system)")!).paddingLeft),
  }));
}

test("a chat in a narrow pane is laid out for the pane, not for the window", async ({ page }) => {
  const workspace = await openWorkspace(page);

  // Wide window, wide pane: the desktop gutter.
  await workspace.evaluate((node) => { node.style.width = "1200px"; });
  await expect.poll(() => guttersOf(workspace)).toEqual({ edge: 16, avatar: 48 });

  // Same wide window, narrow pane: the phone gutter, because the timeline asks its own box.
  await workspace.evaluate((node, width) => { node.style.width = `${width}px`; }, NARROW);
  await expect.poll(() => guttersOf(workspace)).toEqual({ edge: 8, avatar: 48 });

  // And the bubble is capped by the pane, not by the window.
  const bubble = await workspace.locator(".message-bubble-host").first().evaluate((host) => ({
    width: host.getBoundingClientRect().width,
    pane: host.closest(".message-list")!.clientWidth,
  }));
  expect(bubble.width).toBeLessThanOrEqual(bubble.pane);
  expect(bubble.pane).toBeLessThan(NARROW + 1);
});

/**
 * The numbers that decide how a chat reads — how wide a bubble may be, how much room the timeline
 * keeps at its edges — were set on `:root` by window width, so converting the rules that *read* them
 * was only half the job: a 380px pane of a wide desktop still got the desktop proportions. The test
 * above could not see it, because a desktop-capped bubble is still narrower than the pane (FR-157).
 */
test("the numbers a bubble is measured by come from the pane, not from the window", async ({ page }) => {
  const workspace = await openWorkspace(page);
  const read = () => workspace.locator(".message-list").first().evaluate((list) => {
    const style = getComputedStyle(list);
    return {
      bubbleMax: style.getPropertyValue("--flare-component-bubble-max-width").trim(),
      gutter: style.getPropertyValue("--flare-component-message-gutter-inline").trim(),
    };
  });

  await workspace.evaluate((node) => { node.style.width = "1200px"; });
  await expect.poll(read).toEqual({ bubbleMax: "min(62%, 640px)", gutter: "16px" });

  await workspace.evaluate((node, width) => { node.style.width = `${width}px`; }, NARROW);
  await expect.poll(read).toEqual({ bubbleMax: "88%", gutter: "8px" });

  // The window never moved, and `:root` still carries the unconditional base — so nothing about
  // this chat was decided by the window.
  expect(await page.evaluate(() => window.innerWidth)).toBe(WIDE);
  expect(await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue("--flare-component-bubble-max-width").trim(),
  )).toBe("min(68%, 640px)");
});

test("the composer in a narrow pane is shaped for the pane while the window stays wide", async ({ page }) => {
  const workspace = await openWorkspace(page);
  const composer = workspace.locator(".composer").first();
  await expect(composer).toBeVisible();

  // Two halves of the same change: the bar itself keys off `composer--wide`, which the composer sets
  // from a ResizeObserver on its own box, and everything inside it asks `@container flare-composer`.
  // A container query cannot style its own container, so both mechanisms have to be checked.
  // The bar is flat at every width (no rounded top, one hairline above it), so what tells the two
  // shapes apart is its inset: spacing.md beside a wide bar, spacing.2xs beside a narrow one.
  const shapeOf = () => composer.evaluate((node) => ({
    wide: node.classList.contains("composer--wide"),
    bar: getComputedStyle(node).paddingLeft,
    inside: getComputedStyle(node.querySelector(".composer-field-expand")!).display,
  }));

  // Wide pane: a desktop bar, expand living in the toolbar.
  await workspace.evaluate((node) => { node.style.width = "1200px"; });
  await expect.poll(shapeOf).toEqual({ wide: true, bar: "12px", inside: "none" });

  // Same window, narrow pane: the phone bar, expand docked in the field.
  await workspace.evaluate((node, width) => { node.style.width = `${width}px`; }, NARROW);
  await expect.poll(shapeOf).toEqual({ wide: false, bar: "6px", inside: "flex" });

  // The window never moved, so no `@media` rule could have told those two apart.
  expect(await page.evaluate(() => window.innerWidth)).toBe(WIDE);
});
