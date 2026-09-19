import { expect, test } from "@playwright/test";

async function openComponent(page: import("@playwright/test").Page, name: string, locale = "en") {
  await page.goto("/" + locale + "/components/" + name);
  const preview = page.locator(".component-preview");
  await expect(preview).toBeVisible();
  await expect(preview.locator(".component-preview__live, iframe")).toBeVisible();
  return preview;
}

const previewFrame = (preview: import("@playwright/test").Locator) => preview.frameLocator("iframe");

test("component page follows the public-first documentation order", async ({ page }) => {
  await openComponent(page, "composer");
  const ids = await page.locator("main h2[id]").evaluateAll((headings) => headings.map((heading) => heading.id));
  const canonical = [
    "preview", "usage", "examples", "configuration", "variants", "density", "states",
    "interaction", "responsive", "accessibility", "api", "tokens", "platform-differences",
    "related", "source-of-truth", "validation", "surface-anatomy",
  ];
  expect(ids).toEqual([...ids].sort((left, right) => canonical.indexOf(left) - canonical.indexOf(right)));
  expect(ids.indexOf("examples")).toBeLessThan(ids.indexOf("api"));
  expect(ids.indexOf("configuration")).toBeLessThan(ids.indexOf("api"));
});

test("single preview is immediate, Vue-only, and follows the website theme", async ({ page }) => {
  const preview = await openComponent(page, "button");
  await expect(preview).toHaveAttribute("data-preview-mode", "single");
  await expect(preview.locator(".component-preview__controls")).toHaveCount(0);
  await expect(preview.locator("select")).toHaveCount(0);
  await expect(preview).not.toContainText("Flutter");
  await expect(preview).not.toContainText("SwiftUI");
  await expect(page.getByRole("heading", { name: "Responsive", exact: true })).toHaveCount(0);
  // No Density section either: FR-050 left the kit without a density scale, so only the components
  // that really take a `density` prop still document one (the next test checks one that does).
  await expect(page.getByRole("heading", { name: "Density", exact: true })).toHaveCount(0);

  const viewport = preview.locator(".component-preview__viewport");
  const initial = await viewport.getAttribute("data-flare-theme");
  await page.locator(".VPSwitchAppearance:visible").first().click();
  await expect(viewport).toHaveAttribute("data-flare-theme", initial === "dark" ? "light" : "dark");
  const primary = await viewport.evaluate((node) => getComputedStyle(node).getPropertyValue("--flare-color-primary").trim());
  expect(primary).not.toBe("");
});

test("a component that really takes a density prop still documents one", async ({ page }) => {
  // The other half of FR-050: the section was not deleted, it was narrowed to what is true. If this
  // goes to 0 the catalogue has stopped reporting a prop that exists; if Button gains one, the
  // promise is back.
  await openComponent(page, "message-meta");
  await expect(page.getByRole("heading", { name: "Density", exact: true })).toBeVisible();
});

test("MessageStatus remains a single preview without unrelated sections", async ({ page }) => {
  const preview = await openComponent(page, "message-status");
  await expect(preview).toHaveAttribute("data-preview-mode", "single");
  await expect(preview.locator(".component-preview__controls")).toHaveCount(0);
  await expect(page.getByRole("heading", { name: "Responsive", exact: true })).toHaveCount(0);
  await expect(page.getByRole("heading", { name: "Density", exact: true })).toHaveCount(0);
});

test("responsive Composer Desktop and Mobile use one default action contract", async ({ page }) => {
  const preview = await openComponent(page, "composer");
  await expect(preview).toHaveAttribute("data-preview-mode", "responsive");
  const controls = preview.locator(".component-preview__viewports");
  await expect(controls.getByRole("button")).toHaveText(["Desktop", "Mobile"]);

  const live = previewFrame(preview);
  const more = live.locator("button[aria-expanded]").last();
  await more.click();
  // The preview has no voice handler, so the voice tile is not offered (voice needs somewhere to go).
  await expect(live.locator(".flare-action-panel__tile")).toHaveCount(4);
  expect(await live.locator(".flare-action-panel__tile").evaluateAll((nodes) => nodes.map((node) => node.textContent?.trim()))).toEqual([
    "Image", "File", "Location", "Contact card",
  ]);
  await expect(live.locator(".composer-more-surface")).toHaveCSS("position", "absolute");

  await controls.getByRole("button", { name: "Mobile" }).click();
  const viewport = live.locator(".component-preview__viewport");
  await expect(viewport).toHaveClass(/is-mobile/);
  expect(await viewport.evaluate((node) => (node as HTMLElement).offsetWidth)).toBeLessThanOrEqual(390);
  await more.click();
  await expect(live.locator(".flare-action-panel__tile")).toHaveCount(4);
  await expect(live.locator(".composer-more-surface")).toHaveCSS("position", "relative");
});

test("ConversationHeader exposes identity, capability filtering, Plus and responsive More", async ({ page }) => {
  const preview = await openComponent(page, "conversation-header");
  const live = previewFrame(preview);
  const header = live.locator(".flare-conversation-header");
  await expect(header.getByRole("heading", { name: "Product room" })).toBeVisible();
  await expect(header.locator(".im-avatar")).toBeVisible();
  await expect(header.locator('[data-header-action="search"]')).toBeVisible();
  await expect(header.locator('[data-header-action="audioCall"]')).toHaveCount(0);

  const add = header.locator('[data-header-menu="add"]');
  await expect(add).toBeVisible();
  await add.click();
  await expect(live.getByText("Create task", { exact: true }).last()).toBeVisible();
  const disabled = live.getByRole("menuitem", { name: /Create order/ });
  await expect(disabled).toHaveAttribute("aria-disabled", "true");
  await live.getByText("Create task", { exact: true }).last().click();
  await expect(live.getByRole("status")).toContainText("Create task");

  // Details is the only overflow action here, so the More button performs it instead of opening a one-item menu.
  await expect(header.locator('[data-header-menu="more"]')).toHaveCount(0);
  const details = header.locator('[data-header-action="details"]');
  await expect(details).toHaveAttribute("aria-label", "Details");
  await details.click();
  await expect(live.getByRole("status")).toContainText("Conversation details");

  await preview.getByRole("button", { name: "Mobile" }).click();
  await expect(live.locator(".component-preview__viewport")).toHaveClass(/is-mobile/);
  await expect(header.getByRole("heading", { name: "Product room" })).toBeVisible();
  expect(await header.evaluate((node) => node.scrollWidth <= node.clientWidth)).toBe(true);
});

test("ChatWorkspace keeps Context, Header, top-anchored Timeline and Composer in one surface", async ({ page }) => {
  const preview = await openComponent(page, "chat-workspace");
  const live = previewFrame(preview);
  const workspace = live.locator(".flare-chat-workspace");
  await expect(workspace).toBeVisible();
  await expect(workspace.locator(".flare-chat-workspace__context")).toContainText("Demo data");
  await expect(workspace.getByRole("heading", { name: "Product room" })).toBeVisible();
  await expect(workspace.locator('[data-message-id="1"]')).toBeVisible();
  await expect(workspace.locator('[data-message-id="1"] .message-avatar')).toBeVisible();
  await expect(workspace.locator('[data-message-id="1"] .message-meta__name')).toContainText("Ivy Chen");
  await expect(workspace.getByRole("textbox")).toBeVisible();
  const toolbar = workspace.locator(".composer-toolbar");
  await expect(toolbar.getByRole("button")).toHaveCount(3);
  await expect(toolbar.getByRole("button", { name: "Emoji" })).toBeVisible();
  await expect(toolbar.getByRole("button", { name: "More" })).toBeVisible();
  await expect(toolbar.getByRole("button", { name: "Send" })).toBeVisible();
  await expect(toolbar.getByRole("button", { name: "Voice" })).toHaveCount(0);
  await expect(toolbar.getByRole("button", { name: "Image" })).toHaveCount(0);

  const order = await workspace.locator(":scope > div").evaluateAll((nodes) => nodes.map((node) => node.className));
  expect(order.slice(0, 4)).toEqual([
    "flare-chat-workspace__context",
    "flare-chat-workspace__header",
    "flare-chat-workspace__timeline",
    "flare-chat-workspace__composer",
  ]);
  const firstMessage = await workspace.locator('[data-message-id="1"]').boundingBox();
  const timeline = await workspace.locator(".flare-chat-workspace__timeline").boundingBox();
  expect((firstMessage?.y ?? Infinity) - (timeline?.y ?? 0)).toBeLessThan(90);

  await preview.getByRole("button", { name: "Mobile" }).click();
  await expect(live.locator(".component-preview__viewport")).toHaveClass(/is-mobile/);
  expect(await workspace.evaluate((node) => node.scrollWidth <= node.clientWidth)).toBe(true);
});

test("workspace preview exposes only meaningful Desktop and Mobile widths", async ({ page }) => {
  const preview = await openComponent(page, "conversation-workspace");
  await expect(preview).toHaveAttribute("data-preview-mode", "workspace");
  const controls = preview.locator(".component-preview__viewports");
  await expect(controls.getByRole("button")).toHaveText(["Desktop", "Mobile"]);
  await expect(controls.getByRole("button")).toHaveCount(2);
  await controls.getByRole("button", { name: "Mobile" }).click();
  await expect(previewFrame(preview).locator(".component-preview__viewport")).toHaveClass(/is-mobile/);
});

test("Composer host configuration hides, disables, reorders, and adds business actions", async ({ page }) => {
  await openComponent(page, "composer");
  const example = page.locator(".reference__composer-example");
  await example.locator("button[aria-expanded]").last().click();
  const actions = example.locator(".flare-action-panel__tile");
  await expect(actions).toHaveCount(4);
  await expect(actions).toHaveText(["图片", "订单", "文件", "位置"]);
  await expect(actions.filter({ hasText: "位置" })).toBeDisabled();
  await expect(example.getByText("语音", { exact: true })).toHaveCount(0);
});

test("Usage keeps platform code separate from the Vue visual preview", async ({ page }) => {
  const preview = await openComponent(page, "composer");
  await expect(preview.locator(".component-preview__baseline")).toHaveCount(0);
  const tabs = page.locator(".reference__code-tabs [role=tab]");
  await expect(tabs).toHaveText(["Vue", "Flutter", "Android Compose", "SwiftUI"]);
  await tabs.filter({ hasText: "Flutter" }).click();
  await expect(page.locator(".reference__code pre")).toContainText("FlareComposer");
  await expect(page.getByRole("heading", { name: "Platform Differences" }).locator("..")).toContainText("does not simulate native screenshots");
});

test("mobile docs keep preview, code tabs, and API inside the page width", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const preview = await openComponent(page, "composer");
  await preview.getByRole("button", { name: "Mobile" }).click();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(1);
  await expect(page.locator(".reference__code-tabs")).toBeVisible();
  await expect(page.getByRole("heading", { name: "API", exact: true })).toBeVisible();
});

test("component pages provide category-ordered previous and next navigation", async ({ page }) => {
  await openComponent(page, "message-status");
  const pager = page.locator(".reference__pager");
  await expect(pager.getByRole("link")).toHaveCount(2);
  await expect(page.locator(".VPDocFooter")).toHaveCount(0);
  await expect(pager.locator('a[rel="prev"]')).toHaveAttribute("href", /\/en\/components\//);
  await expect(pager.locator('a[rel="next"]')).toHaveAttribute("href", /\/en\/components\//);
});
