import { expect, test } from "@playwright/test";

const referenceApp = `http://127.0.0.1:${process.env.PLAYWRIGHT_REFERENCE_PORT ?? "4176"}`;

test.beforeEach(async ({ page }) => {
  page.on("pageerror", error => console.error(error.stack ?? error.message));
});

test("desktop reference app composes chats, contacts, search, settings, and send", async ({ page }) => {
  await page.clock.install({ time: new Date("2025-01-15T06:32:00.000Z") });
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(referenceApp);
  const app = page.locator('[data-reference-app="complete-im"]');
  await expect(app).toBeVisible();
  await expect(app.locator('.message-list .message-bubble')).toHaveCount(3);
  await expect(app.locator('.message-row--self .message-bubble')).toHaveCount(1);
  const incoming = await app.locator('.message-row:not(.message-row--self) .message-bubble').first().boundingBox();
  const outgoing = await app.locator('.message-row--self .message-bubble').boundingBox();
  expect(outgoing!.x).toBeGreaterThan(incoming!.x + incoming!.width);
  await expect(app).toHaveScreenshot("reference-im-desktop.png");

  await page.getByRole("button", { name: "Contacts" }).click();
  await expect(page.getByRole("heading", { name: "Contacts" })).toBeVisible();
  await expect(page.getByText("Contact selected")).toBeVisible();

  // Destinations the person has opened stay mounted (hidden) so they keep their state: text that appears in more
  // than one of them is looked up among the visible ones.
  await page.getByRole("button", { name: "Search" }).click();
  await expect(page.getByRole("heading", { name: "Search" })).toBeVisible();
  await page.getByRole("searchbox", { name: "Search messages and people" }).fill("Design");
  await expect(page.getByText("Design Team").filter({ visible: true })).toBeVisible();

  await page.getByRole("button", { name: "Settings" }).click();
  await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible();
  await expect(page.getByText("Notifications")).toBeVisible();

  await page.getByRole("button", { name: "Chats" }).click();
  await page.getByText("Design Team", { exact: true }).filter({ visible: true }).first().click();
  await expect(page.getByText("shipped the new build", { exact: true })).toBeVisible();
  await page.getByRole("textbox", { name: "Type a message" }).fill("Public AppKit works");
  await page.locator(".flare-send").click();
  await expect(page.getByRole("region", { name: "Conversation", exact: true }).getByText("Public AppKit works", { exact: true })).toBeVisible();
});

test("mobile reference app navigates list to chat and back without hidden controls", async ({ page }) => {
  await page.clock.install({ time: new Date("2025-01-15T06:32:00.000Z") });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(referenceApp);
  await expect(page.getByRole("heading", { name: "Chats" })).toBeVisible();
  await expect(page.locator(".im-conv-item").first()).toHaveClass(/--mobile/);
  await expect(page.locator('[data-reference-app="complete-im"]')).toHaveScreenshot("reference-im-mobile.png");

  await page.getByText("Design Team", { exact: true }).click();
  await expect(page.getByText("shipped the new build", { exact: true })).toBeVisible();
  await expect(page.getByRole("textbox", { name: "Type a message" })).toBeVisible();
  // The open conversation is a page beyond the chats root: the shell puts the phone navigation away, and the
  // conversation header carries the way back.
  await expect(page.getByRole("button", { name: "Contacts" })).toHaveCount(0);

  await page.getByRole("button", { name: "Back", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Chats" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Contacts" })).toBeVisible();

  await page.getByRole("button", { name: "Contacts" }).click();
  await expect(page.getByRole("heading", { name: "Contacts" })).toBeVisible();
  // The chats destination stays mounted behind it, with its own "Henry Ford" row.
  await expect(page.getByText("Henry Ford", { exact: true }).filter({ visible: true })).toBeVisible();
});
