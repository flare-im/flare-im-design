import { expect, test } from "@playwright/test";

async function ready(page: import("@playwright/test").Page) {
  await page.clock.install({ time: new Date("2025-01-15T06:32:00.000Z") });
  await page.goto("/resources/visual-regression");
  await page.locator('[data-vr-ready="true"]').waitFor();
  await page.evaluate(async () => { await document.fonts.ready; });
}

test("RC fixture light", async ({ page }) => {
  await ready(page);
  await expect(page.locator("#rc-visual-fixture")).toHaveScreenshot("rc-light.png");
});

test("RC fixture dark", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await ready(page);
  await page.evaluate(() => document.documentElement.classList.add("dark"));
  await expect(page.locator("#rc-visual-fixture")).toHaveScreenshot("rc-dark.png");
});

for (const mode of ["light", "dark"] as const) {
  test(`RC conversation fixture graphite ${mode}`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: mode, reducedMotion: "reduce" });
    await ready(page);
    await page.evaluate((selectedMode) => {
      document.documentElement.dataset.flareBrand = "graphite";
      document.documentElement.dataset.flareTheme = selectedMode;
      document.documentElement.classList.toggle("dark", selectedMode === "dark");
    }, mode);
    await expect(page.locator("#rc-visual-fixture")).toHaveScreenshot(`rc-graphite-${mode}.png`);
  });
}

test("RC fixture large text", async ({ page }) => {
  await ready(page);
  await page.locator("#rc-visual-fixture").evaluate((node) => {
    node.classList.add("is-large-text");
    node.style.width = "560px";
    node.style.zoom = "2";
  });
  await expect(page.locator("#rc-visual-fixture")).toHaveScreenshot("rc-large-text.png");
});

const brandThemes = ["violet", "ocean", "forest", "sunset", "rose", "graphite"] as const;

async function readyThemeShowcase(page: import("@playwright/test").Page, mode: "light" | "dark" = "light") {
  await page.clock.install({ time: new Date("2025-01-15T06:32:00.000Z") });
  await page.emulateMedia({ colorScheme: mode, reducedMotion: "reduce" });
  await page.goto("/");
  const stage = page.locator(".showcase .window");
  await stage.waitFor();
  await page.evaluate(async () => { await document.fonts.ready; });
  return stage;
}

test("six light themes switch the complete message semantic chain", async ({ page }) => {
  const stage = await readyThemeShowcase(page);
  const values: Record<string, string[]> = {};

  for (const theme of brandThemes) {
    await page.getByRole("button", { name: new RegExp(`^${theme}$`, "i") }).click();
    await expect(stage).toHaveAttribute("data-flare-brand", theme);
    values[theme] = await stage.evaluate((node) => {
      const style = getComputedStyle(node);
      return [
        "--flare-color-primary",
        "--flare-color-bg-selected",
        "--flare-color-focus-ring",
        "--flare-color-message-outgoing-background",
        "--flare-color-message-status-read",
        "--flare-color-message-reaction-selected",
      ].map((name) => style.getPropertyValue(name).trim());
    });
    expect(values[theme].every(Boolean)).toBe(true);
    await expect(stage).toHaveScreenshot(`theme-${theme}-light.png`);
  }

  for (let index = 0; index < values.violet.length; index += 1) {
    expect(new Set(brandThemes.map((theme) => values[theme][index])).size).toBe(brandThemes.length);
  }
});

for (const theme of ["violet", "ocean", "graphite"] as const) {
  test(`${theme} dark theme preserves the branded message chain`, async ({ page }) => {
    const stage = await readyThemeShowcase(page, "dark");
    await page.getByRole("button", { name: new RegExp(`^${theme}$`, "i") }).click();
    await expect(stage).toHaveAttribute("data-flare-brand", theme);
    await expect(stage).toHaveAttribute("data-flare-theme", "dark");
    await expect(stage).toHaveScreenshot(`theme-${theme}-dark.png`);
  });
}

async function readyComposerSurface(
  page: import("@playwright/test").Page,
  mode: "light" | "dark" = "light",
) {
  await page.emulateMedia({ colorScheme: mode, reducedMotion: "reduce" });
  await page.goto("/resources/composer-surface-regression");
  const fixture = page.locator("#composer-surface-regression");
  await fixture.waitFor();
  await page.evaluate((selectedMode) => {
    document.documentElement.dataset.flareTheme = selectedMode;
    document.documentElement.classList.toggle("dark", selectedMode === "dark");
  }, mode);
  await page.evaluate(async () => { await document.fonts.ready; });
  return fixture;
}

for (const mode of ["light", "dark"] as const) {
  test(`timeline keeps one edge gutter at every viewport in ${mode}`, async ({ page }, testInfo) => {
    await page.emulateMedia({ colorScheme: mode, reducedMotion: "reduce" });
    await page.goto("/resources/visual-regression");
    const workspace = page.locator(".fixture-workspace .workspace-demo");
    await expect(workspace.locator(".message-row--self")).toBeVisible();
    await page.evaluate(selectedMode => {
      document.documentElement.dataset.flareTheme = selectedMode;
      document.documentElement.classList.toggle("dark", selectedMode === "dark");
    }, mode);

    for (const width of [390, 768, 1024, 1440, 1920]) {
      await page.setViewportSize({ width, height: 900 });
      // The gutter is owned by the timeline's own box now (`@container flare-timeline`), so it
      // moves only once that box has been laid out at its new width. Two waits, both on the thing
      // that is actually being read: the page agrees it has the viewport we asked for (on
      // 2026-09-13, under load, this read the wrong band at a viewport already past 900), and the
      // timeline agrees it has the width we gave it — without the second, every reading in this
      // loop lagged one iteration behind, because a container query re-evaluates after layout.
      await expect.poll(() => page.evaluate(() => window.innerWidth)).toBe(width);
      await workspace.evaluate((node, size) => { node.style.width = `${size - 32}px`; }, width);
      await expect.poll(() => workspace.locator(".message-list").evaluate(list =>
        Math.abs(list.getBoundingClientRect().width - (list.parentElement as HTMLElement).clientWidth),
      )).toBeLessThan(1);
      await expect.poll(() => workspace.locator(".message-list").evaluate(list =>
        Math.round(list.getBoundingClientRect().width),
      )).toBe(width - 32);
      await expect.poll(() => workspace.locator(".message-list").evaluate(list => {
        const content = list.querySelector(".message-list-content")!.getBoundingClientRect();
        return Math.abs(content.width - list.clientWidth);
      })).toBeLessThan(1);
      // And finally the reading itself: under load the box can be the right size a frame before the
      // container query that keys off it has been re-evaluated, so this waits on what it asserts.
      const expectedGutter = width >= 900 ? 16 : width >= 600 ? 10 : 8;
      await expect.poll(() => workspace.locator(".message-list").evaluate(list =>
        parseFloat(getComputedStyle(list.querySelector(".message-list-content")!).paddingLeft),
      )).toBe(expectedGutter);
      const geometry = await workspace.locator(".message-list").evaluate(list => {
        const rect = list.getBoundingClientRect();
        const start = rect.left + list.clientLeft;
        const end = start + list.clientWidth;
        const content = list.querySelector(".message-list-content")!;
        const incoming = list.querySelector(".message-row:not(.message-row--self):not(.message-row--system)")!;
        const markers = [...incoming.querySelectorAll(".message-avatar, .message-bubble")]
          .map(node => node.getBoundingClientRect()).filter(box => box.width > 0);
        const outgoing = list.querySelector(".message-row--self .message-bubble")!.getBoundingClientRect();
        return {
          gutter: parseFloat(getComputedStyle(content).paddingLeft),
          tailSpace: parseFloat(getComputedStyle(list).getPropertyValue("--flare-component-message-tail-space")),
          incomingGap: Math.min(...markers.map(box => box.left)) - start,
          outgoingGap: end - outgoing.right,
          scrollPadding: getComputedStyle(list).paddingLeft,
          overflow: list.scrollWidth - list.clientWidth,
        };
      });
      expect(geometry.gutter).toBe(expectedGutter);
      expect(geometry.scrollPadding).toBe("0px");
      for (const gap of [geometry.incomingGap, geometry.outgoingGap]) {
        expect(gap).toBeGreaterThanOrEqual(geometry.gutter - 1);
        expect(gap).toBeLessThanOrEqual(geometry.gutter + geometry.tailSpace);
      }
      expect(geometry.overflow).toBeLessThanOrEqual(1);
      await testInfo.attach(`timeline-${width}-${mode}`, { body: JSON.stringify(geometry), contentType: "application/json" });
    }
  });

  for (const width of [1280, 390]) {
    test(`compact heading symbols preserve formatting at ${width} in ${mode}`, async ({ page }, testInfo) => {
      await page.setViewportSize({ width, height: 900 });
      const fixture = await readyComposerSurface(page, mode);
      const target = fixture.locator('[data-composer-state="default"]');
      await target.getByRole("button", { name: /^(富文本|Rich text)$/ }).click();
      const heading = target.locator(".composer-heading-select");
      const editor = target.locator('[contenteditable="true"]');
      await expect(heading.locator("option")).toHaveText(["P", "H1", "H2", "H3", "H4", "H5", "H6"]);
      const initial = (await heading.boundingBox())!;
      await editor.fill("Heading selection");
      for (const level of [1, 2, 3, 4, 5, 6]) {
        await editor.press("ControlOrMeta+A");
        await heading.selectOption(String(level));
        await expect(editor.locator(`[data-heading-level="${level}"]`)).toHaveText("Heading selection");
        await expect(heading).toHaveAttribute("title", `标题 ${level}`);
        expect((await heading.boundingBox())!.width).toBe(initial.width);
      }
      await target.screenshot({ path: testInfo.outputPath(`heading-${width}-${mode}.png`), animations: "disabled" });
      await editor.press("ControlOrMeta+A");
      await heading.selectOption("");
      await expect(editor.locator("[data-heading-level]")).toHaveCount(0);
      await expect(editor).toHaveText("Heading selection");
      await expect(heading).toHaveAttribute("title", "正文");
      expect((await heading.boundingBox())!.width).toBe(initial.width);
    });
  }
}

test("composer surface owns one continuous border and a light visible focus state", async ({ page }) => {
  const fixture = await readyComposerSurface(page);
  const focused = fixture.locator('[data-composer-state="focused"]');
  const surface = focused.locator('[data-flare-surface-owner="composer"]');
  await fixture.locator('[data-composer-state="default"] textarea').focus();
  await surface.evaluate(node => Promise.all(node.getAnimations().map(animation => animation.finished)));
  const unfocusedBorder = await surface.evaluate(node => getComputedStyle(node).borderColor);
  await focused.locator("textarea").focus();
  await surface.evaluate(node => Promise.all(node.getAnimations().map(animation => animation.finished)));

  const geometry = await focused.locator('[data-flare-surface-owner="composer"]').evaluate((surface) => {
    const style = getComputedStyle(surface);
    const input = getComputedStyle(surface.querySelector(".composer-input-row")!);
    const toolbar = getComputedStyle(surface.querySelector(".composer-toolbar")!);
    const pseudo = getComputedStyle(surface.querySelector(".composer-input-row")!, "::before");
    return {
      borderWidths: [style.borderTopWidth, style.borderRightWidth, style.borderBottomWidth, style.borderLeftWidth],
      radius: style.borderRadius,
      background: style.backgroundColor,
      shadow: style.boxShadow,
      borderColor: style.borderColor,
      inputBackground: input.backgroundColor,
      inputBorder: input.borderStyle,
      toolbarBackground: toolbar.backgroundColor,
      toolbarBorder: toolbar.borderStyle,
      partialFocusContent: pseudo.content,
    };
  });

  expect(geometry.borderWidths).toEqual(["1px", "1px", "1px", "1px"]);
  expect(geometry.radius).not.toBe("0px");
  expect(geometry.background).not.toBe("rgba(0, 0, 0, 0)");
  expect(geometry.shadow).toBe("none");
  expect(geometry.borderColor).not.toBe(unfocusedBorder);
  expect(geometry.inputBackground).toBe("rgba(0, 0, 0, 0)");
  expect(geometry.inputBorder).toBe("none");
  expect(geometry.toolbarBackground).toBe("rgba(0, 0, 0, 0)");
  expect(geometry.toolbarBorder).toBe("none");
  expect(["none", "normal"]).toContain(geometry.partialFocusContent);
});

for (const mode of ["light", "dark"] as const) {
  for (const width of [1280, 390]) {
    test(`expanded composer has no toolbar divider at ${width} in ${mode}`, async ({ page }) => {
      await page.setViewportSize({ width, height: 900 });
      const fixture = await readyComposerSurface(page, mode);
      const target = fixture.locator('[data-composer-state="default"]');
      await target.getByRole("button", { name: /^(展开输入|Expand input)$/ }).click();
      await expect(target.locator(".composer--input-expanded")).toBeVisible();
      const surface = target.locator('[data-flare-surface-owner="composer"]');
      await target.locator("textarea").focus();
      const integrity = await surface.evaluate(node => {
        const style = getComputedStyle(node);
        const toolbar = node.querySelector(".composer-toolbar")!;
        const divider = getComputedStyle(toolbar, "::before");
        const rect = node.getBoundingClientRect();
        const actions = toolbar.getBoundingClientRect();
        return {
          dividerHidden: divider.display === "none" || ["none", "normal"].includes(divider.content),
          shadow: style.boxShadow,
          actionsInside: actions.left >= rect.left && actions.right <= rect.right + 1 && actions.bottom <= rect.bottom + 1,
        };
      });
      expect(integrity.dividerHidden).toBe(true);
      expect(integrity.shadow).toBe("none");
      expect(integrity.actionsInside).toBe(true);
      await expect(target).toHaveScreenshot(`composer-expanded-${width}-${mode}.png`);
      await target.getByRole("button", { name: /^(收起输入|Collapse input)$/ }).click();
      await expect(target.locator(".composer--input-expanded")).toHaveCount(0);
    });
  }
}

test("conversation header never oscillates around its compact breakpoint", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page.goto("/resources/visual-regression");
  const workspace = page.locator(".fixture-workspace .workspace-demo");
  await workspace.waitFor();
  for (const width of [586, 559, 560, 576, 591, 600]) {
    await workspace.evaluate((node, width) => { (node as HTMLElement).style.width = `${width}px`; }, width);
    const frames = await workspace.evaluate(async node => {
      const rows: Array<{ compact: boolean; height: number }> = [];
      for (let index = 0; index < 45; index += 1) {
        await new Promise<void>(resolve => requestAnimationFrame(() => resolve()));
        const header = node.querySelector(".flare-conversation-header")!;
        rows.push({ compact: header.classList.contains("flare-conversation-header--compact"), height: header.getBoundingClientRect().height });
      }
      return rows.slice(15);
    });
    expect(new Set(frames.map(frame => frame.compact)).size, `${width}px compact mode`).toBe(1);
    expect(new Set(frames.map(frame => frame.height)).size, `${width}px header height`).toBe(1);
    expect(frames.at(-1)!.compact).toBe(width < 560);
  }
});

test("message hover and toolbar focus never move existing bubbles", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page.goto("/resources/visual-regression");
  const workspace = page.locator(".fixture-workspace");
  await workspace.scrollIntoViewIfNeeded();
  await page.evaluate(async () => { await document.fonts.ready; });
  for (const bubble of await workspace.locator(".message-bubble").all()) {
    await page.mouse.move(0, 0);
    const bounds = (await bubble.boundingBox())!;
    await bubble.hover();
    const samples = await bubble.evaluate(async node => {
      const rows: number[][] = [];
      for (let index = 0; index < 45; index += 1) {
        await new Promise<void>(resolve => requestAnimationFrame(() => resolve()));
        const rect = node.getBoundingClientRect();
        rows.push([rect.x, rect.y, rect.width, rect.height]);
      }
      return rows;
    });
    const baseline = [bounds.x, bounds.y, bounds.width, bounds.height];
    for (const row of samples) {
      row.forEach((value, column) => expect(Math.abs(value - baseline[column]), `hover geometry ${column}`).toBeLessThan(0.1));
    }
    const action = bubble.locator("xpath=ancestor::*[contains(@class, 'message-bubble-host')][1]").getByRole("toolbar").getByRole("button").first();
    await action.focus();
    await expect(action).toBeFocused();
    const focused = (await bubble.boundingBox())!;
    expect(focused.y).toBeCloseTo(bounds.y, 1);
  }
});

test("composed workspace stays still while resizing and reading a long timeline", async ({ page }, testInfo) => {
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page.goto("/resources/visual-regression");
  const workspace = page.locator(".fixture-workspace");
  await workspace.scrollIntoViewIfNeeded();
  const list = workspace.locator(".message-list");
  for (let index = 0; index < 5; index += 1) {
    await workspace.locator("textarea").fill(`Layout ${index}: ${"Long conversations should stay still while composing. ".repeat(12)}`);
    await workspace.getByRole("button", { name: /^(发送|Send)$/ }).click();
    await expect(workspace.locator("textarea")).toHaveValue("");
  }
  const longDraft = Array.from({ length: 14 }, (_, index) => `Draft line ${index + 1}`).join("\n");
  for (const [name, draft] of [["multiline", longDraft], ["compact", ""]]) {
    await workspace.locator("textarea").fill(draft);
    const samples = await workspace.evaluate(async node => {
      const rows: number[][] = [];
      for (let index = 0; index < 120; index += 1) {
        await new Promise<void>(resolve => requestAnimationFrame(() => resolve()));
        const composer = node.querySelector(".composer-studio")!.getBoundingClientRect();
        const list = node.querySelector(".message-list")!;
        const last = node.querySelector(".message-row:last-of-type .message-bubble")!.getBoundingClientRect();
        rows.push([composer.y, composer.height, list.clientHeight, list.scrollTop, list.scrollHeight, last.y]);
      }
      return rows;
    });
    await testInfo.attach(`workspace-${name}`, { body: JSON.stringify(samples), contentType: "application/json" });
    const settled = samples.slice(60);
    settled[0].forEach((_, column) => {
      const values = settled.map(row => row[column]);
      expect(Math.max(...values) - Math.min(...values), `layout column ${column}`).toBeLessThan(0.1);
    });
    expect(await list.evaluate(node => node.scrollHeight - node.clientHeight - node.scrollTop)).toBeLessThan(2);
  }
  await list.hover();
  await page.mouse.wheel(0, -360);
  await expect.poll(() => list.evaluate(node => node.scrollHeight - node.clientHeight - node.scrollTop)).toBeGreaterThan(300);
  const beforeExpand = await list.evaluate(node => node.scrollTop);
  await workspace.locator("textarea").fill(longDraft);
  await expect(workspace.locator(".composer-field--multiline")).toBeVisible();
  await expect.poll(() => list.evaluate(node => node.scrollTop)).toBeCloseTo(beforeExpand, 1);
});

for (const deviceScaleFactor of [1, 1.25, 1.5, 2] as const) {
  test(`composer stays pixel-stable at DPR ${deviceScaleFactor} and supported zoom levels`, async ({ browser }) => {
    const context = await browser.newContext({
      deviceScaleFactor,
      viewport: { width: 1280, height: 900 },
    });
    const page = await context.newPage();
    const fixture = await readyComposerSurface(page);
    const target = fixture.locator('[data-composer-state="multiline"]');
    const surface = target.locator('[data-flare-surface-owner="composer"]');

    for (const zoom of [0.9, 1, 1.1, 1.25]) {
      await target.evaluate((node, nextZoom) => {
        (node as HTMLElement).style.zoom = String(nextZoom);
      }, zoom);

      const integrity = await surface.evaluate((node) => {
        const style = getComputedStyle(node);
        const bounds = node.getBoundingClientRect();
        const toolbarBounds = node.querySelector(".composer-toolbar")!.getBoundingClientRect();
        return {
          borderWidths: [style.borderTopWidth, style.borderRightWidth, style.borderBottomWidth, style.borderLeftWidth]
            .map(Number.parseFloat),
          radius: style.borderRadius,
          toolbarInside:
            toolbarBounds.left >= bounds.left &&
            toolbarBounds.right <= bounds.right + 0.5 &&
            toolbarBounds.bottom <= bounds.bottom + 0.5,
          noHorizontalOverflow: node.scrollWidth <= node.clientWidth + 1,
        };
      });

      expect(new Set(integrity.borderWidths).size).toBe(1);
      expect(integrity.borderWidths[0]).toBeGreaterThanOrEqual(0.75);
      expect(integrity.borderWidths[0]).toBeLessThanOrEqual(1.2);
      expect(integrity.radius).not.toBe("0px");
      expect(integrity.toolbarInside).toBe(true);
      expect(integrity.noHorizontalOverflow).toBe(true);
    }

    await context.close();
  });
}

for (const state of ["default", "focused", "multiline", "reply", "upload", "disabled", "readonly"] as const) {
  test(`composer ${state} desktop light surface`, async ({ page }) => {
    const fixture = await readyComposerSurface(page);
    const target = fixture.locator(`[data-composer-state="${state}"]`);
    if (state === "focused") await target.locator("textarea").focus();
    await expect(target).toHaveScreenshot(`composer-${state}-desktop-light.png`);
  });
}

test("composer desktop dark surface", async ({ page }) => {
  const fixture = await readyComposerSurface(page, "dark");
  await expect(fixture.locator('[data-composer-state="default"]')).toHaveScreenshot("composer-default-desktop-dark.png");
});

for (const mode of ["light", "dark"] as const) {
  test(`composer H5 ${mode} surface`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    const fixture = await readyComposerSurface(page, mode);
    await expect(fixture.locator('[data-composer-state="default"]')).toHaveScreenshot(`composer-default-h5-${mode}.png`);
  });
}
