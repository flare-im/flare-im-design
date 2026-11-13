import { expect, test } from "@playwright/test";

// The web bundle host in a real browser (docs/plugin-components.md, Web 包宿主): the page runs in a sandboxed,
// opaque-origin frame, reaches the host only through postMessage, and what the bridge answers comes back; a host
// request (ui.toast) is drawn by the kit outside the frame. The unit tests cannot load a frame.
test("the bundle host runs a sandboxed page over its bridge", async ({ page }) => {
  await page.goto("/components/plugin-bundle-host");
  const frame = page.locator('iframe[data-bundle-frame="true"]').first();
  // The preview mounts on the client after the page hydrates.
  await expect(frame).toBeVisible({ timeout: 20000 });
  await expect(frame).toHaveAttribute("sandbox", "allow-scripts allow-forms");
  await expect(frame).toHaveAttribute("referrerpolicy", "no-referrer");

  const content = page.frameLocator('iframe[data-bundle-frame="true"]').first();
  // host.hello, then plugin.query: the page lists what the local bridge answered.
  await expect(content.getByText("周五下午全员会议")).toBeVisible();
  await expect(content.getByText("新版考勤制度上线")).toBeVisible();
  // The frame's origin is opaque: it cannot read the host's storage.
  const origin = await frame.evaluate((element: HTMLIFrameElement) => {
    try {
      return element.contentWindow?.location.origin ?? "none";
    } catch {
      return "blocked";
    }
  });
  expect(origin).toBe("blocked");

  // A host request: the kit draws the toast in the host page.
  await content.getByRole("button", { name: "发布公告" }).click();
  await expect(page.getByText("已发布").first()).toBeVisible();
});
