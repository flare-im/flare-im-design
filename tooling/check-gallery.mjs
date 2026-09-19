#!/usr/bin/env node
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const manifest = JSON.parse(readFileSync(join(root, "examples/gallery/gallery-manifest.json"), "utf8"));
const scenarios = JSON.parse(readFileSync(join(root, "spec/scenarios/rc.json"), "utf8")).scenarios;
const themeScenario = JSON.parse(readFileSync(join(root, "spec/scenarios/theme-switching.json"), "utf8"));
const spec = JSON.parse(readFileSync(join(root, "spec/components.json"), "utf8"));
const publicNames = new Set(spec.components.map((component) => component.name));
const requiredStates = [
  "default", "hoverOrPressed", "focus", "disabled", "loading", "longContent",
  "dark", "largeText", "reducedMotion", "rtl", "error", "touch",
];
const errors = [];
for (const [platform, path] of Object.entries(manifest.platformSources)) {
  if (!existsSync(join(root, path))) errors.push(`${platform}: missing gallery source ${path}`);
}
for (const [platform, path] of Object.entries(manifest.featuredScenarioSources ?? {})) {
  const fullPath = join(root, path);
  if (!existsSync(fullPath)) {
    errors.push(`${platform}: missing featured scenario source ${path}`);
  } else if (!readFileSync(fullPath, "utf8").includes("CommandPalette")) {
    errors.push(`${platform}: featured scenario does not render CommandPalette`);
  }
}
if (Object.keys(manifest.featuredScenarioSources ?? {}).length !== 4) {
  errors.push("featured CommandPalette scenario must exist on all four platforms");
}
const scenarioFields = manifest.scenarioSchema?.required ?? [];
for (const scenario of scenarios) {
  for (const field of scenarioFields) if (!(field in scenario)) errors.push(`${scenario.id ?? "scenario"}: missing ${field}`);
  if (!publicNames.has(scenario.component)) errors.push(`${scenario.id}: ${scenario.component} is not public`);
}
if (manifest.themeScenario !== "spec/scenarios/theme-switching.json") errors.push("gallery must consume the shared theme-switching scenario");
if (themeScenario.id !== "theme-switching") errors.push("theme scenario id must be theme-switching");
if (themeScenario.themes.length !== 6 || themeScenario.modes.length !== 2) errors.push("theme scenario must cover six themes and two modes");
for (const viewport of ["largeDesktop", "desktop", "tablet", "mobile"]) {
  if (!manifest.viewports?.[viewport]) errors.push(`missing viewport: ${viewport}`);
}
for (const state of requiredStates) {
  if (!manifest.requiredStates.includes(state)) errors.push(`missing gallery state: ${state}`);
}
for (const [group, entries] of Object.entries({ general: manifest.general, im: manifest.im })) {
  for (const [fixture, component] of Object.entries(entries)) {
    if (!publicNames.has(component)) errors.push(`${group}.${fixture}: ${component} is not a public component`);
  }
}
if (errors.length) {
  console.error("gallery errors:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`gallery passed: 4 platforms, ${Object.keys(manifest.general).length} General and ${Object.keys(manifest.im).length} IM scenarios, ${scenarios.length} shared fixtures plus theme-switching, ${requiredStates.length} state dimensions`);
