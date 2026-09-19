import { expect, test } from "@playwright/test";

const routes = [
  ["/", "Flare UI"],
  ["/guide/getting-started", "快速开始"],
  ["/components/", "组件总览"],
  ["/components/message-meta", "MessageMeta"],
  ["/patterns/desktop-app-shell", "DesktopAppShell"],
  ["/platforms/flutter", "Flutter"],
  ["/accessibility/", "Accessibility"],
  ["/foundations/token-explorer", "Token Explorer"],
] as const;

test("documentation information architecture routes are reachable", async ({ page }) => {
  for (const [path, heading] of routes) {
    await page.goto(path);
    await expect(page.getByRole("heading", { level: 1, name: heading })).toBeVisible();
  }
});

test("home and component pages render their live catalog content", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByLabel("Flare UI catalog summary")).toBeVisible();
  await expect(page.locator(".showcase .window")).toBeVisible();

  await page.goto("/components/message-meta");
  await expect(page.locator(".component-preview")).toBeVisible();
  await expect(page.getByRole("heading", { name: "预览" })).toBeVisible();
});

test("component catalog searches aliases and IM concepts", async ({ page }) => {
  await page.goto("/components/");
  const search = page.getByRole("searchbox", { name: "搜索" });
  const content = page.locator("#VPContent");

  await search.fill("read receipt");
  await expect(content.getByRole("link", { name: /^MessageStatus/ })).toBeVisible();
  await expect(content.getByRole("link", { name: /^MessageMeta/ })).toBeVisible();

  await search.fill("three pane");
  await expect(content.getByRole("link", { name: /^DesktopAppShell/ })).toBeVisible();
  await expect(content.getByRole("link", { name: /^AppLayout/ })).toBeVisible();
});

test("component catalog keeps discovery simple and component-first", async ({ page }) => {
  await page.goto("/components/");
  await expect(page.locator(".catalog__segments").getByRole("button")).toHaveText(["全部", "通用", "IM", "Patterns"]);
  await expect(page.locator(".catalog__table")).toHaveCount(0);
  await expect(page.locator(".catalog__item").first()).toBeVisible();
  await page.locator(".catalog__segments").getByRole("button", { name: "Patterns" }).click();
  await expect(page.getByRole("link", { name: /ConversationListContainer/ })).toBeVisible();
});

test("global search resolves IM and adaptive-layout concepts", async ({ page }) => {
  await page.goto("/");
  const openSearch = () => page.getByRole("button", { name: "Search", exact: true }).click();

  await openSearch();
  await page.locator("#localsearch-input").fill("read receipt");
  const readResults = page.locator("#localsearch-list");
  await expect(readResults).toContainText("Message Lifecycle");
  await expect(readResults).toContainText("MessageStatus");
  await expect(readResults).toContainText("MessageMeta");

  await page.keyboard.press("Escape");
  await openSearch();
  await page.locator("#localsearch-input").fill("three pane");
  const layoutResults = page.locator("#localsearch-list");
  await expect(layoutResults).toContainText("Adaptive Layout");
  await expect(layoutResults).toContainText("DesktopAppShell");
});

test("home and catalog avoid page-level mobile overflow", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  for (const path of ["/", "/components/", "/components/message-status", "/recipes/"]) {
    await page.goto(path);
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow, `${path} horizontal overflow`).toBeLessThanOrEqual(1);
  }
});
