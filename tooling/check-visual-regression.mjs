#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const manifest = JSON.parse(readFileSync(join(root, "tests/visual/manifest.json"), "utf8"));
const scenarios = JSON.parse(readFileSync(join(root, "spec/scenarios/rc.json"), "utf8")).scenarios;
const themeScenario = JSON.parse(readFileSync(join(root, "spec/scenarios/theme-switching.json"), "utf8"));
const errors = [];
for (const [platform, target] of Object.entries(manifest.platforms)) {
  const requiredPath = target.status === "active" ? target.test : target.strategy;
  if (!requiredPath || !existsSync(join(root, requiredPath))) errors.push(`${platform}: missing ${target.status} runner contract`);
  if (target.status === "active" && (!target.baseline || !existsSync(join(root, target.baseline)))) errors.push(`${platform}: active baseline missing`);
}
for (const baseline of manifest.platforms.vue.themeBaselines ?? []) {
  if (!existsSync(join(root, manifest.platforms.vue.baseline, baseline))) errors.push(`vue: missing theme baseline ${baseline}`);
}
for (const baseline of manifest.platforms.vue.applicationBaselines ?? []) {
  if (!existsSync(join(root, manifest.platforms.vue.baseline, baseline))) errors.push(`vue: missing application baseline ${baseline}`);
}
for (const baseline of manifest.platforms.vue.composerSurfaceBaselines ?? []) {
  if (!existsSync(join(root, manifest.platforms.vue.baseline, baseline))) errors.push(`vue: missing composer surface baseline ${baseline}`);
}
for (const baseline of manifest.platforms.vue.coreSurfaceBaselines ?? []) {
  if (!existsSync(join(root, manifest.platforms.vue.baseline, baseline))) errors.push(`vue: missing core surface baseline ${baseline}`);
}
// DoD 23 — the inventory runs both ways. A baseline nobody declared is a
// re-baseline nobody reviewed; a declared baseline with no file means the next
// run writes a fresh one and compares against nothing.
function pngsIn(rel) {
  const dir = join(root, rel);
  if (!existsSync(dir)) return null;
  return readdirSync(dir).filter((name) => name.endsWith(".png")).sort();
}
function inventory(label, rel, declared) {
  const actual = pngsIn(rel);
  if (actual === null) {
    if (declared.length) errors.push(`${label}: ${rel} does not exist but ${declared.length} baseline(s) are declared`);
    return 0;
  }
  const known = new Set(declared);
  for (const name of actual) {
    if (!known.has(name)) errors.push(`${label}: ${join(rel, name)} has no entry in tests/visual/manifest.json — an undeclared baseline is a re-baseline nobody reviewed`);
  }
  for (const name of declared) {
    const path = join(root, rel, name);
    if (!existsSync(path)) errors.push(`${label}: declared baseline ${join(rel, name)} is missing`);
    else if (statSync(path).size === 0) errors.push(`${label}: ${join(rel, name)} is empty`);
  }
  return actual.length;
}

let declaredBaselines = 0;
const vuePlatforms = manifest.platforms.vue.platforms ?? {};
if (!Object.keys(vuePlatforms).length) errors.push("vue: no platform has any baseline");
for (const [platform, files] of Object.entries(vuePlatforms)) {
  declaredBaselines += inventory(`vue/${platform}`, `tests/visual/vue/baselines/${platform}`, files);
}
// A screenshot is a rendering: one shared folder means CI compares Linux pixels
// against macOS ones, and every case containing a letter fails.
for (const stray of pngsIn("tests/visual/vue/baselines") ?? []) {
  errors.push(`vue: ${stray} sits outside a platform folder`);
}
if (!readFileSync(join(root, "website/playwright.config.ts"), "utf8").includes("{platform}")) {
  errors.push("website/playwright.config.ts: snapshotPathTemplate must carry {platform}, or every platform overwrites the same baselines");
}
declaredBaselines += inventory("flutter", "packages/flutter-im-ui/test/goldens/baselines", manifest.platforms.flutter.baselineFiles ?? []);
declaredBaselines += inventory("ios", "tests/visual/ios/baselines", manifest.platforms.ios.baselineFiles ?? []);
declaredBaselines += inventory("compose", "packages/android-im-ui/src/androidTest/assets/goldens", manifest.platforms.compose.baselineFiles ?? []);

// Re-baselining is how a real regression gets waved through, so the review
// process has to be written down.
if (!manifest.process || !existsSync(join(root, manifest.process))) {
  errors.push(`${manifest.process ?? "manifest.process"}: the EXPECTED / REGRESSION process must be documented`);
}

if (themeScenario.themes.length !== 6 || themeScenario.modes.length !== 2) errors.push("theme-switching visual contract must cover six themes and two modes");
const fixtures = new Set(scenarios.map((scenario) => scenario.component));
for (const component of ["Button", "Input", "MessageBubble", "Composer", "DesktopAppShell", "CommentThread", "ReactionSummary", "CommandPalette"]) {
  if (!fixtures.has(component)) errors.push(`${component}: missing shared visual fixture`);
}
if (errors.length) {
  console.error("visual regression errors:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
const active = Object.values(manifest.platforms).filter((target) => target.status === "active").length;
const strategies = Object.values(manifest.platforms).filter((target) => target.status !== "active").length;
console.log(`visual regression passed: ${active} active runners, ${strategies} explicit runner contracts, ${scenarios.length} shared fixtures, ${manifest.platforms.vue.themeBaselines.length} theme baselines, ${manifest.platforms.vue.applicationBaselines.length} application baselines, ${(manifest.platforms.vue.composerSurfaceBaselines ?? []).length} composer surface baselines, ${declaredBaselines} declared baseline files across four platforms`);
