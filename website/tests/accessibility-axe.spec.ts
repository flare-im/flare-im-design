import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page } from "@playwright/test";
import catalog from "../../spec/component-catalog.json" with { type: "json" };

// DoD 21 / 22 — axe over every catalog component's embedded preview plus the
// reference application. A component preview is a fragment, not a document, so
// the page-level rules below are switched off: they would report the frame's
// missing landmarks and title, which the host page owns, not the component.
const FRAGMENT_RULES_OFF = [
  "bypass",
  "document-title",
  "html-has-lang",
  "landmark-one-main",
  "page-has-heading-one",
  "region",
];

const TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"];
const BLOCKING_IMPACTS = new Set(["critical", "serious"]);
const reportDir = join(dirname(fileURLToPath(import.meta.url)), "..", "test-results");

type Finding = {
  surface: string;
  rule: string;
  impact: string;
  help: string;
  targets: string[];
  detail?: string[];
};

/**
 * Loads one preview and says how it went, so "this machine was busy" and "this
 * demo is broken" do not arrive as the same result.
 *
 * The timeout here is machinery, not the thing under test: how fast a preview
 * mounts is asserted by the @perf suite. This repo's release chain has been seen
 * running at load 25 (a full release:check next to whatever else the machine is
 * doing), where a first paint well past 20s is ordinary — on 2026-09-13 that made
 * 55 of 148 previews report as critical accessibility violations, and the same
 * sweep passed with zero timeouts at the same load minutes later. So the probe is
 * generous and backs off between attempts. A preview that still never arrives
 * fails the run: it is reported, never skipped.
 */
/**
 * The sweep scans every preview in one page session, and the kit's theme provider reads its initial mode
 * from `localStorage` and writes it back whenever a demo changes it. Left alone, that means a preview which
 * switches the theme decides what every preview after it is scanned in — which is how a 2.47:1 contrast
 * failure in dark mode (FR-117) stayed invisible: the sweep passed when it was run alone, because the page
 * was still light, and failed only when something earlier had turned it dark. Pinning the mode before each
 * navigation makes the result depend on the component, not on the running order.
 */
const THEME_KEYS = {
  mode: "flare-web-theme-mode",
  variant: "flare-web-theme-variant",
  brand: "flare-web-brand-theme",
  vitepress: "vitepress-theme-appearance",
} as const;

async function pinTheme(page: Page, mode: "light" | "dark"): Promise<void> {
  await page.evaluate(
    ([keys, value]) => {
      try {
        localStorage.setItem(keys.mode, value);
        localStorage.setItem(keys.vitepress, value);
        localStorage.removeItem(keys.variant);
        localStorage.removeItem(keys.brand);
      } catch {
        // A browser that refuses storage cannot leak a theme either.
      }
    },
    [THEME_KEYS, mode] as const,
  );
}

/**
 * Some previews are a button until someone presses it: the dialog, sheet or menu the component *is* only
 * exists after a click. The sweep used to render and scan, so for those components it was scanning the
 * trigger and reporting the result as coverage — the `StartConversationDialog` violation B7 fixed was that
 * demo's own trigger, not the dialog (FR-124). The opener is declared per component in
 * `spec/catalog-metadata.json`; clicking it must produce an overlay, or the sweep fails rather than
 * quietly scanning the same button twice.
 */
const OVERLAY = '[role="dialog"], [role="alertdialog"], [role="menu"], [role="listbox"], .flare-bottom-sheet';

async function openOverlay(page: Page, opener: string): Promise<boolean> {
  const control = page.getByRole("button", { name: opener, exact: true }).first();
  try {
    await control.click({ timeout: 5_000 });
    await page.locator(OVERLAY).first().waitFor({ state: "visible", timeout: 5_000 });
    return true;
  } catch {
    return false;
  }
}

const RENDER_ATTEMPTS = 3;
const RENDER_TIMEOUT_MS = 45_000;

type RenderOutcome = { rendered: boolean; attempts: number };

async function render(page: Page, url: string): Promise<RenderOutcome> {
  for (let attempt = 1; attempt <= RENDER_ATTEMPTS; attempt += 1) {
    try {
      await page.goto(url, { waitUntil: "domcontentloaded" });
      // The container mounts first and the demo streams in after: scanning on
      // the container alone would pass an empty box. Wait for real content.
      await page.locator(".component-preview__live > *").first().waitFor({ timeout: RENDER_TIMEOUT_MS });
      return { rendered: true, attempts: attempt };
    } catch {
      if (attempt < RENDER_ATTEMPTS) await page.waitForTimeout(attempt * 1000);
    }
  }
  return { rendered: false, attempts: RENDER_ATTEMPTS };
}

async function scan(page: Page, surface: string, include: string, rulesOff: string[]): Promise<Finding[]> {
  const result = await new AxeBuilder({ page }).include(include).withTags(TAGS).disableRules(rulesOff).analyze();
  return result.violations
    .filter((violation) => BLOCKING_IMPACTS.has(violation.impact ?? ""))
    .map((violation) => ({
      surface,
      rule: violation.id,
      impact: violation.impact ?? "unknown",
      help: violation.help,
      targets: violation.nodes.slice(0, 4).map((node) => node.target.join(" ")),
      detail: violation.nodes.slice(0, 4).map((node) => (node.any ?? []).map((check) => check.message).join("; ")),
    }));
}

/** `harness` is deliberately outside the axe counts: a preview that never loaded
 *  produced no accessibility result at all, neither a pass nor a violation. */
function writeReport(
  name: string,
  findings: Finding[],
  surfaces: number,
  harness: { scanned: number; unrendered: string[]; retried: string[] } = { scanned: surfaces, unrendered: [], retried: [] },
): void {
  mkdirSync(reportDir, { recursive: true });
  writeFileSync(
    join(reportDir, `axe-${name}.json`),
    `${JSON.stringify({
      surfaces,
      critical: findings.filter((f) => f.impact === "critical").length,
      serious: findings.filter((f) => f.impact === "serious").length,
      findings,
      harness,
    }, null, 2)}\n`,
  );
}

function describeFindings(findings: Finding[]): string[] {
  return findings.map((finding) => `${finding.surface} · ${finding.impact} · ${finding.rule} — ${finding.targets[0] ?? ""}`);
}

for (const viewport of ["desktop", "mobile"] as const) {
  const components = catalog.components.filter((entry) => entry.previewViewports.includes(viewport));

  // Both themes on both viewports. Dark mode is half the product, and the phone layout is not simply the
  // desktop one made narrow: it has surfaces of its own (sheets, the mobile shell, phone-width variants),
  // so a colour can be wrong there and nowhere else. The mobile catalogue is a quarter the size of the
  // desktop one, so the second pass costs seconds.
  const themes = ["light", "dark"] as const;

  test(`@a11y component previews have no critical or serious axe violations (${viewport})`, async ({ page }) => {
    test.setTimeout(30 * 60 * 1000);
    await page.setViewportSize(viewport === "mobile" ? { width: 390, height: 844 } : { width: 1280, height: 900 });
    const findings: Finding[] = [];
    const unrendered: string[] = [];
    const retried: string[] = [];
    const unopened: string[] = [];
    let scanned = 0;
    // A page on the origin, so the theme can be pinned before the first preview loads.
    await page.goto("/embed/component-frame", { waitUntil: "domcontentloaded" });
    for (const theme of themes) {
      for (const entry of components) {
        const surface = `${entry.name}@${viewport}:${theme}`;
        await pinTheme(page, theme);
        const outcome = await render(page, `/embed/component-frame?name=${entry.name}&viewport=${viewport}`);
        if (outcome.attempts > 1) retried.push(`${surface} (${outcome.attempts} attempts)`);
        if (!outcome.rendered) {
          // Still a failure — a component must never drop out of the sweep — but it
          // is a harness failure, so it is not filed as an accessibility finding.
          unrendered.push(surface);
          continue;
        }
        findings.push(...(await scan(page, surface, ".component-preview", FRAGMENT_RULES_OFF)));
        scanned += 1;
        const opener = (entry as { previewOpener?: string | null }).previewOpener;
        if (opener) {
          if (await openOverlay(page, opener)) {
            // The overlay covers the page, so it is scanned as a page rather than as the preview fragment.
            findings.push(...(await scan(page, `${surface}+open`, OVERLAY, FRAGMENT_RULES_OFF)));
            scanned += 1;
          } else {
            unopened.push(`${surface} (opener: ${opener})`);
          }
        }
      }
    }
    const openers = components.filter((entry) => (entry as { previewOpener?: string | null }).previewOpener).length;
    const sweeps = (components.length + openers) * themes.length;
    writeReport(viewport, findings, sweeps, { scanned, unrendered, retried });
    // Two different failures, asserted as two different things. The harness one
    // comes first so a loaded machine cannot masquerade as an a11y regression.
    expect(
      unrendered,
      `${unrendered.length} preview(s) never loaded after ${RENDER_ATTEMPTS} attempts — this is the harness, not an accessibility result; check machine load and the demo itself before reading anything into it`,
    ).toEqual([]);
    expect(
      unopened,
      `${unopened.length} declared opener(s) produced no overlay — the component's demo or its opener in spec/catalog-metadata.json has moved`,
    ).toEqual([]);
    expect(describeFindings(findings), `${scanned} of ${sweeps} preview scans`).toEqual([]);
    // Guards the loop above: a future `continue` must not quietly shrink the sweep.
    expect(scanned, "every catalog preview must be scanned in every theme this viewport covers").toBe(sweeps);
  });
}

test("@a11y reference application has no critical or serious axe violations", async ({ page }) => {
  test.setTimeout(5 * 60 * 1000);
  const referenceApp = `http://127.0.0.1:${process.env.PLAYWRIGHT_REFERENCE_PORT ?? "4176"}`;
  await page.clock.install({ time: new Date("2025-01-15T06:32:00.000Z") });
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(referenceApp);
  await page.locator('[data-reference-app="complete-im"]').waitFor();

  const findings: Finding[] = [];
  findings.push(...(await scan(page, "reference-app@chats", "body", [])));
  for (const section of ["Contacts", "Search", "Settings"]) {
    await page.getByRole("button", { name: section }).click();
    await expect(page.getByRole("heading", { name: section })).toBeVisible();
    findings.push(...(await scan(page, `reference-app@${section.toLowerCase()}`, "body", [])));
  }
  writeReport("reference-app", findings, 4);
  expect(describeFindings(findings)).toEqual([]);
});
