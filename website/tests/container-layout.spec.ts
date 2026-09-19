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

/** The avatar gutter is 48px on a wide timeline and 40px on a narrow one (message-bubble.css). */
function gutterOf(workspace: import("@playwright/test").Locator) {
  return workspace.locator(".message-row--avatar-gutter:not(.message-row--system)").first()
    .evaluate((row) => Number.parseFloat(getComputedStyle(row).paddingLeft));
}

test("a chat in a narrow pane is laid out for the pane, not for the window", async ({ page }) => {
  const workspace = await openWorkspace(page);

  // Wide window, wide pane: the desktop gutter.
  await workspace.evaluate((node) => { node.style.width = "1200px"; });
  await expect.poll(() => gutterOf(workspace)).toBe(48);

  // Same wide window, narrow pane: the phone gutter, because the timeline asks its own box.
  await workspace.evaluate((node, width) => { node.style.width = `${width}px`; }, NARROW);
  await expect.poll(() => gutterOf(workspace)).toBe(40);

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
  const shapeOf = () => composer.evaluate((node) => ({
    bar: getComputedStyle(node).borderTopLeftRadius,
    inside: getComputedStyle(node.querySelector(".composer-field-expand")!).display,
  }));

  // Wide pane: a desktop bar, flush with the window, expand living in the toolbar.
  await workspace.evaluate((node) => { node.style.width = "1200px"; });
  await expect.poll(shapeOf).toEqual({ bar: "0px", inside: "none" });

  // Same window, narrow pane: a rounded sheet over the timeline, expand docked in the field.
  await workspace.evaluate((node, width) => { node.style.width = `${width}px`; }, NARROW);
  await expect.poll(shapeOf).toEqual({ bar: "10px", inside: "flex" });

  // The window never moved, so no `@media` rule could have told those two apart.
  expect(await page.evaluate(() => window.innerWidth)).toBe(WIDE);
});
