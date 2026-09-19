import { fileURLToPath } from "node:url";
import { chromium, defineConfig } from "@playwright/test";

const websitePort = process.env.PLAYWRIGHT_WEBSITE_PORT ?? "4175";
const referencePort = process.env.PLAYWRIGHT_REFERENCE_PORT ?? "4176";
const websiteURL = `http://127.0.0.1:${websitePort}`;
const referenceURL = `http://127.0.0.1:${referencePort}`;

// Deterministic scrollers on macOS: see tests/support/chromium-classic-scrollbars.sh.
const classicScrollbars = process.platform === "darwin" && process.env.FLARE_CLASSIC_SCROLLBARS !== "0";
if (classicScrollbars) process.env.FLARE_PLAYWRIGHT_CHROMIUM ??= chromium.executablePath();

export default defineConfig({
  testDir: "./tests",
  // The platform segment is not decoration: a screenshot is a rendering, and
  // macOS and Linux do not rasterise text the same way. One shared folder means
  // CI compares Linux output against macOS pixels and fails on every case that
  // contains a letter. Each platform keeps its own set.
  snapshotPathTemplate: "../tests/visual/vue/baselines/{platform}/{arg}{ext}",
  expect: { toHaveScreenshot: { animations: "disabled", maxDiffPixelRatio: 0.002 } },
  use: {
    baseURL: websiteURL,
    viewport: { width: 1280, height: 1600 },
    colorScheme: "light",
    reducedMotion: "reduce",
    timezoneId: "Asia/Shanghai",
    launchOptions: classicScrollbars
      ? { executablePath: fileURLToPath(new URL("./tests/support/chromium-classic-scrollbars.sh", import.meta.url)) }
      : {},
  },
  webServer: [
    {
      command: `npm run dev -- --host 127.0.0.1 --port ${websitePort} --strictPort`,
      url: `${websiteURL}/resources/visual-regression`,
      reuseExistingServer: !process.env.CI,
      timeout: 120000,
    },
    {
      command: `npm --prefix ../examples/vue run dev -- --host 127.0.0.1 --port ${referencePort} --strictPort`,
      url: referenceURL,
      reuseExistingServer: !process.env.CI,
      timeout: 120000,
    },
  ],
});
