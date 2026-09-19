import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";
const catalog = JSON.parse(readFileSync(new URL("../../spec/component-catalog.json", import.meta.url), "utf8"));

for (const entry of catalog.components.filter(item => item.previewViewports.length > 1)) {
  test(`preview isolates each platform: ${entry.name}`, async ({ page }) => {
    await page.goto("/components/" + entry.slug);
    const outer = page.locator(".component-preview");
    await expect(outer.locator("iframe")).toHaveCount(1);
    const frame = outer.frameLocator("iframe");
    for (const [label, width, kind] of [["桌面", 1024, "pc"], ["移动端", 390, "h5"]] as const) {
      await outer.getByRole("button", { name: label, exact: true }).click();
      await expect(frame.locator(".component-preview__live")).toBeVisible();
      await expect(frame.locator(".component-preview__missing")).toHaveCount(0);
      await expect.poll(() => frame.locator("html").evaluate(() => innerWidth)).toBe(width);
      await expect(frame.locator(".component-preview__controls")).toHaveCount(0);
      await expect(frame.locator("html")).toHaveAttribute("data-flare-viewport", kind);
      await expect(outer.locator(".flare-bottom-sheet")).toHaveCount(0);
    }
  });
}

test("conversation menu switches compact popover to isolated touch sheet", async ({ page }) => {
  await page.goto("/components/conversation-action-sheet");
  const preview = page.locator(".component-preview");
  const frame = preview.frameLocator("iframe");
  await expect(frame.locator('[data-preview-platform="desktop"]')).toBeVisible();
  await expect(frame.locator('[data-preview-platform="mobile"]')).toHaveCount(0);
  await expect(frame.getByRole("menuitem")).toHaveCount(6);
  const outerScale = await preview.locator("iframe").evaluate(node => node.getBoundingClientRect().width / 1024);
  await expect.poll(() => frame.locator(".flare-conv-actions__label").first().evaluate((node, scale) =>
    Number.parseFloat(getComputedStyle(node).fontSize) * Number(getComputedStyle(document.documentElement).zoom) * scale, outerScale),
  ).toBeGreaterThanOrEqual(12.5);
  await preview.getByRole("button", { name: "移动端", exact: true }).click();
  await expect(frame.locator('[data-preview-platform="desktop"]')).toHaveCount(0);
  await expect(frame.getByRole("menu")).toBeVisible();
  await frame.getByRole("menuitem", { name: "置顶", exact: true }).click();
  await expect(frame.getByRole("menu")).not.toBeVisible();
  await expect(frame.locator(".im-conv-item")).toHaveClass(/--pinned/);
  await preview.getByRole("button", { name: "桌面", exact: true }).click();
  await expect(frame.locator(".flare-conv-actions--desktop")).toBeVisible();
});

test("conversation context menu accepts rapid successive state changes", async ({ page }) => {
  await page.goto("/embed/component-frame?name=ConversationList&viewport=desktop");
  const row = page.locator('[data-conversation-id="li"]');
  for (let cycle = 0; cycle < 2; cycle++) {
    for (const [label, state, enabled] of [
      ["置顶", "pinned", true], ["取消置顶", "pinned", false],
      ["标为未读", "unread", true], ["标为已读", "unread", false],
      ["免打扰", "muted", true], ["取消免打扰", "muted", false],
    ] as const) {
      await row.click({ button: "right" });
      await page.getByRole("menu").last().getByRole("menuitem", { name: label, exact: true }).click();
      await expect.poll(() => row.evaluate((node, state) => node.classList.contains(`im-conv-item--${state}`), state)).toBe(enabled);
    }
  }
});

for (const [slug, menu] of [["message-action-sheet", ".msg-ctx-sheet"], ["member-role-sheet", ".flare-mrs"]]) {
  test(`menu demo renders only the chosen platform: ${slug}`, async ({ page }) => {
    await page.goto(`/components/${slug}`);
    const preview = page.locator(".component-preview");
    const frame = preview.frameLocator("iframe");
    await expect(frame.locator('[data-preview-platform="desktop"]')).toBeVisible();
    await expect(frame.locator('[data-preview-platform="mobile"]')).toHaveCount(0);
    await expect(frame.getByRole("dialog")).toHaveCount(0);
    if (slug === "message-action-sheet") await expect(frame.locator(menu)).toHaveCount(0);
    else await expect(frame.locator(".flare-mrs--desktop")).toBeVisible();
    await preview.getByRole("button", { name: "移动端", exact: true }).click();
    await expect(frame.locator('[data-preview-platform="desktop"]')).toHaveCount(0);
    await expect(frame.getByRole("dialog")).toBeVisible();
    await expect(frame.locator(menu)).toHaveCount(1);
    await expect(frame.locator(".flare-mrs--desktop")).toHaveCount(0);
    if (slug === "message-action-sheet") {
      await expect(frame.locator(".msg-ctx-sheet__grabber")).toHaveCount(0);
      await frame.getByRole("button", { name: "回复", exact: true }).click();
    }
    else await frame.getByRole("menuitem", { name: "设为管理员", exact: true }).click();
    await expect(frame.getByRole("dialog")).not.toBeVisible();
    await preview.getByRole("button", { name: "桌面", exact: true }).click();
    await expect(frame.locator('[data-preview-platform="mobile"]')).toHaveCount(0);
    await expect(frame.getByRole("dialog")).toHaveCount(0);
  });
}

for (const brand of ["violet", "ocean", "forest", "sunset", "rose", "graphite"]) {
  for (const theme of ["light", "dark"]) test(`conversation hierarchy ${brand} ${theme}`, async ({ page }) => {
    for (const width of [240, 280, 320, 360]) {
      await page.goto(`/resources/conversation-regression?brand=${brand}&theme=${theme}&width=${width}`);
      const list = page.locator(".im-conv-list");
      await expect(list.locator(".im-conv-item")).toHaveCount(8);
      await expect(list.getByText("999+", { exact: true })).toBeVisible();
      await expect(list.getByText("正在输入…", { exact: true })).toBeVisible();
      await expect(list.getByText("[发送失败]", { exact: true })).toBeVisible();
      await expect(list).not.toContainText("conversation.");
      const bounds = await list.locator(".im-conv-item").evaluateAll(rows => rows.map(row => {
        const content = row.querySelector(".im-conv-item__body")!.getBoundingClientRect();
        const meta = row.querySelector(".im-conv-item__meta")!.getBoundingClientRect();
        const title = row.querySelector(".im-conv-item__title")!.getBoundingClientRect();
        return { overflow: row.scrollWidth - row.clientWidth, gap: meta.left - content.right, title: title.width };
      }));
      for (const bound of bounds) { expect(bound.overflow).toBeLessThanOrEqual(1); expect(bound.gap).toBeGreaterThanOrEqual(7); expect(bound.title).toBeGreaterThan(20); }
      const contrastRatios = await list.locator(".im-conv-item__title, .im-conv-item__preview, .im-conv-item__time, .im-conv-item__prefix, .im-conv-item__unread-pill").evaluateAll(nodes => {
        const rgba = (value: string) => value.match(/[\d.]+/g)!.map(Number);
        const luminance = (rgb: number[]) => rgb.slice(0, 3).map(v => {
          const c = v / 255; return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4;
        }).reduce((sum, c, i) => sum + c * [.2126, .7152, .0722][i], 0);
        return nodes.map(node => {
          const ancestors: Element[] = [];
          for (let parent: Element | null = node; parent; parent = parent.parentElement) ancestors.unshift(parent);
          let bg = [255, 255, 255];
          for (const ancestor of ancestors) {
            const color = rgba(getComputedStyle(ancestor).backgroundColor), alpha = color[3] ?? 1;
            bg = bg.map((c, i) => color[i] * alpha + c * (1 - alpha));
          }
          const values = [luminance(rgba(getComputedStyle(node).color)), luminance(bg)].sort((a, b) => b - a);
          return { role: node.className, ratio: (values[0] + .05) / (values[1] + .05) };
        });
      });
      for (const result of contrastRatios) expect(result.ratio, result.role).toBeGreaterThanOrEqual(4.5);
      if (width === 320 && ["violet", "graphite"].includes(brand)) await expect(list).toHaveScreenshot(`conversation-list-${brand}-${theme}.png`);
    }
  });
}

for (const [slug, trigger, popover] of [
  ["date-picker", ".flare-dp__trigger", ".flare-dp__pop"],
  ["time-picker", ".flare-tp__trigger", ".flare-tp__pop"],
  ["select", ".flare-select__trigger", ".flare-select__menu"],
]) test(`picker uses only its selected platform: ${slug}`, async ({ page }) => {
  await page.goto(`/components/${slug}`);
  const preview = page.locator(".component-preview");
  const frame = preview.frameLocator("iframe");
  await frame.locator(trigger).click();
  await expect(frame.locator(popover)).toBeVisible();
  await expect(frame.locator(".flare-bottom-sheet")).toHaveCount(0);
  await preview.getByRole("button", { name: "移动端", exact: true }).click();
  await frame.locator(trigger).click();
  await expect(frame.getByRole("dialog")).toBeVisible();
  await expect(frame.locator(popover)).toHaveCount(0);
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await preview.getByRole("button", { name: "桌面", exact: true }).click();
  await expect(frame.getByRole("dialog")).toHaveCount(0);
});

test("conversation keyboard and mobile long press use canonical actions", async ({ page }) => {
  await page.goto("/components/conversation-list");
  const preview = page.locator(".component-preview");
  const frame = preview.frameLocator("iframe");
  const row = frame.locator('[data-conversation-id="li"]');
  await row.getByRole("button").focus();
  await row.getByRole("button").press("Shift+F10");
  await expect(frame.getByRole("menu")).toBeVisible();
  await page.keyboard.press("Escape");
  await preview.getByRole("button", { name: "移动端", exact: true }).click();
  await row.dispatchEvent("touchstart", { touches: [{ identifier: 1, clientX: 100, clientY: 200 }] });
  await expect(frame.getByRole("dialog")).toBeVisible();
  await row.dispatchEvent("touchend", { changedTouches: [{ identifier: 1 }] });
  await frame.getByRole("menuitem", { name: "置顶", exact: true }).click();
  await expect(row).toHaveClass(/--pinned/);
  await expect(frame.getByRole("dialog")).not.toBeVisible();
});
