import { expect, test } from "@playwright/test";

/**
 * The like/comment popover a moment card slides out of its ··· button.
 *
 * It shipped 30px wide — the width of the ··· button — with 赞 and 评论 drawn on top of each other.
 * The popover had `max-width: 100%`, and the thing that 100% resolved against was the 30px wrapper
 * the card anchors it to, so it was told to be 30px and obeyed; `min-width: 0` on its buttons then
 * decided what "obeyed" looked like, letting each button shrink past its own label until the labels
 * overlapped instead of the popover overflowing (FR-164).
 *
 * None of the existing suites could see it. The component test mounts in happy-dom, which has no
 * layout — `getBoundingClientRect()` is all zeros there, so a popover of any width passes. The
 * surface-integrity fixture renders this popover in normal flow at a width that always fit. Only a
 * real engine answers the question, and only geometry answers it: the DOM is identical either way.
 */
const WIDTHS = [1280, 390];

interface Box { left: number; right: number; width: number }
interface Geometry {
  card: Box;
  more: Box;
  pop: Box;
  buttons: (Box & { label: string; overflows: boolean })[];
}

async function openPopover(page: import("@playwright/test").Page, index: number): Promise<Geometry> {
  await page.locator(".flare-moment__more").nth(index).click();
  const card = page.locator(".flare-moment").nth(index);
  await card.locator(".flare-moment__pop").waitFor();
  return card.evaluate((node) => {
    const box = (element: Element): Box => {
      const rect = element.getBoundingClientRect();
      return { left: rect.left, right: rect.right, width: rect.width };
    };
    const pop = node.querySelector<HTMLElement>(".flare-moment__pop")!;
    return {
      card: box(node),
      more: box(node.querySelector(".flare-moment__more")!),
      pop: box(pop),
      buttons: Array.from(pop.querySelectorAll("button")).map((button) => ({
        label: (button.textContent ?? "").trim(),
        ...box(button),
        // The symptom, measured: a label wider than the button that owns it spills over its
        // neighbour. Button rectangles alone cannot see this — they stay tidy and side by side
        // while the glyphs pile up on each other.
        overflows: button.scrollWidth > button.clientWidth + 1,
      })),
    };
  });
}

function labelsAreLegible(geometry: Geometry, where: string): void {
  const ordered = [...geometry.buttons].sort((left, right) => left.left - right.left);
  for (const button of ordered) {
    expect(button.overflows, `${where}: "${button.label}" is wider than its button`).toBe(false);
    expect(button.width, `${where}: "${button.label}" has no width`).toBeGreaterThan(0);
  }
  for (let i = 1; i < ordered.length; i += 1) {
    expect(
      ordered[i - 1].right,
      `${where}: "${ordered[i - 1].label}" overlaps "${ordered[i].label}"`,
    ).toBeLessThanOrEqual(ordered[i].left + 1);
  }
}

for (const width of WIDTHS) {
  test(`a moment's action popover opens at its own width (${width}px)`, async ({ page }) => {
    await page.setViewportSize({ width, height: 1000 });
    await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
    await page.goto("/en/components/moment-card");
    await expect(page.locator(".flare-moment").first()).toBeVisible({ timeout: 15000 });

    // The first card is someone else's (like, comment); the second is your own, so it adds delete —
    // two and three buttons, the narrowest and the widest the popover gets.
    for (const [index, expected] of [[0, 2], [1, 3]] as const) {
      const geometry = await openPopover(page, index);
      const where = `card ${index} at ${width}px`;

      expect(geometry.buttons, `${where}: buttons`).toHaveLength(expected);

      // The defect, stated as what a person saw: a popover no wider than the button it came from.
      expect(geometry.pop.width, `${where}: popover width`).toBeGreaterThan(geometry.more.width);
      labelsAreLegible(geometry, where);

      // Having its own width must not cost it its anchor: it still sits just left of the ··· button,
      // and still inside the card, which at 390px means overhanging the avatar column by a few
      // pixels rather than giving up a label.
      expect(geometry.pop.right, `${where}: popover hangs over the ··· button`)
        .toBeLessThanOrEqual(geometry.more.left + 1);
      expect(geometry.more.left - geometry.pop.right, `${where}: gap to the ··· button`)
        .toBeLessThanOrEqual(12);
      expect(geometry.pop.left, `${where}: popover escapes the card on the left`)
        .toBeGreaterThanOrEqual(geometry.card.left - 1);
      expect(geometry.pop.right, `${where}: popover escapes the card on the right`)
        .toBeLessThanOrEqual(geometry.card.right + 1);

      await page.locator(".flare-moment__more").nth(index).click();
      await expect(page.locator(".flare-moment").nth(index).locator(".flare-moment__pop")).toBeHidden();
    }
  });
}

/**
 * And if something does squeeze it, it must fail the readable way.
 *
 * The buttons keep `min-width: auto`, so a popover given less room than its labels need overflows
 * its own rounded box and is clipped by `overflow: hidden` — a cut-off action, which reads as "too
 * narrow". With `min-width: 0` the same squeeze is absorbed by the buttons instead: their
 * rectangles stay neatly side by side, at a third of the width their labels need, and the labels
 * are painted over each other. That is the screenshot this bug was reported with, and button
 * rectangles cannot see it — only each label against the button that owns it can.
 *
 * The constraint is applied from here rather than from a fixture because no host imposes one today;
 * what is being pinned is how the component behaves if one ever does.
 */
test("a squeezed popover clips an action rather than stacking them", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 1000 });
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.goto("/en/components/moment-card");
  await expect(page.locator(".flare-moment").first()).toBeVisible({ timeout: 15000 });
  await page.addStyleTag({ content: ".flare-moment__pop { max-width: 120px; }" });

  const geometry = await openPopover(page, 1);
  expect(geometry.pop.width, "squeezed to the width it was given").toBeLessThanOrEqual(121);
  labelsAreLegible(geometry, "squeezed to 120px");
});
