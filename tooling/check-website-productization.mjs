#!/usr/bin/env node
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { previewDemoName } from "../website/.vitepress/theme/demos/preview-registry.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const catalog = JSON.parse(readFileSync(join(root, "spec/component-catalog.json"), "utf8"));
const errors = [];
const read = (path) => readFileSync(join(root, path), "utf8");
const slug = (name) => name.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const reference = read("website/.vitepress/theme/demos/ComponentReference.vue");
const preview = read("website/.vitepress/theme/demos/ComponentPreview.vue");
const config = read("website/.vitepress/config.mts");

const sectionOrder = [
  "preview", "usage", "examples", "configuration", "variants", "density", "states", "interaction",
  "responsive", "accessibility", "api", "tokens", "platform-differences", "related",
  "source-of-truth", "validation",
];
let previous = -1;
for (const section of sectionOrder) {
  const index = reference.indexOf('id="' + section + '"');
  if (index < 0) errors.push("component product page is missing section: " + section);
  else if (index < previous) errors.push("component product page section is out of order: " + section);
  previous = Math.max(previous, index);
}

for (const signal of [
  "ComponentPreview :name", "reference__code-tabs", "Platform Differences", "screenReaderSemantics",
  "--flare-color-focus-ring", "@flare-im/vue-ui", "package:flare_im_ui", "com.flare.im.ui", "import FlareIMUI",
]) if (!reference.includes(signal)) errors.push("ComponentReference missing product signal: " + signal);

for (const signal of ["component-preview__viewports", "Desktop", "Mobile", "useData", "isDark", "previewMode", "previewViewports", "previewPresentation"]) {
  if (!preview.includes(signal)) errors.push("ComponentPreview missing simple Vue preview signal: " + signal);
}
if (!/width:\s*100%/.test(preview) || !/max-width:\s*390px/.test(preview)) {
  errors.push("ComponentPreview mobile frame must be fluid and capped at 390px");
}
for (const forbidden of [
  "platforms", "data-preview-control", "flare-preview-baselines", "rcScenarios",
  "theme-field", "scenario", "tablet", "wideDesktop",
]) if (preview.includes(forbidden)) errors.push("ComponentPreview contains forbidden dashboard control: " + forbidden);
if (/transform\s*:\s*scale/.test(preview)) errors.push("ComponentPreview must use real container widths, not CSS scale");
if (config.includes("flarePreviewBaselines") || config.includes("/flare-preview-baselines/")) {
  errors.push("website still serves native docs-only preview baselines");
}

const demoRoot = join(root, "website/.vitepress/theme/demos");
const demoFiles = new Set([
  ...readdirSync(demoRoot),
  ...readdirSync(join(demoRoot, "messages/demos")),
].filter((name) => name.endsWith(".vue")).map((name) => name.replace(/\.vue$/, "")));
const stable = catalog.components.filter((component) => component.status === "stable");
for (const component of stable) {
  const demo = previewDemoName(component.name);
  if (!demoFiles.has(demo)) errors.push(component.name + ": missing live preview adapter " + demo);
  for (const locale of ["website/components", "website/en/components"]) {
    const path = join(root, locale, slug(component.name) + ".md");
    if (!existsSync(path)) {
      errors.push(component.name + ": missing " + locale + " route");
      continue;
    }
    const source = readFileSync(path, "utf8");
    if (!source.includes("outline: [2, 3]") || !source.includes("prev: false") || !source.includes("next: false") || !source.includes('<ComponentReference name="' + component.name + '" />')) {
      errors.push(component.name + ": " + locale + " is not a canonical product page");
    }
  }
}

for (const label of ["Guide", "Components", "IM Components", "Patterns", "App Kit", "Platforms", "Resources"]) {
  if (!config.includes('text: "' + label + '"')) errors.push("top navigation missing: " + label);
}
for (const label of ["General Components", "IM Components", "Data Display", "Group", "Platforms"]) {
  if (!config.includes(label)) errors.push("categorized sidebar missing: " + label);
}
if (!read("website/general/index.md").includes('<ComponentGallery scope="general-ui" />')) errors.push("General UI landing page lacks scoped catalog");
if (!read("website/im/index.md").includes('<ComponentGallery scope="im-ui" />')) errors.push("IM UI landing page lacks scoped catalog");

for (const capability of [
  "supportsConfiguration", "supportsCustomActions", "supportsCustomContent", "supportsSlots",
  "supportsCapabilities", "supportsDensity", "supportsResponsive",
]) {
  if (!catalog.components.every((component) => typeof component[capability] === "boolean")) {
    errors.push("catalog capability is missing or not boolean: " + capability);
  }
}
for (const component of catalog.components) {
  if (!["single", "responsive", "workspace"].includes(component.previewMode)) errors.push(component.name + ": invalid previewMode");
  if (!Array.isArray(component.previewViewports) || component.previewViewports.length === 0) errors.push(component.name + ": missing previewViewports");
  if (!component.previewPresentation) errors.push(component.name + ": missing previewPresentation");
  if (!component.docsSections || typeof component.docsSections.responsive !== "boolean") errors.push(component.name + ": missing docsSections metadata");
}
for (const path of [
  "website/customization/index.md", "website/customization/themes.md", "website/customization/capabilities.md",
  "website/customization/actions.md", "website/customization/slots-builders.md", "website/customization/custom-message.md",
  "website/customization/custom-navigation.md", "website/customization/custom-composer.md",
  "website/customization/custom-empty-error.md", "website/customization/app-kit-overrides.md",
  "website/recipes/customize-composer.md", "website/recipes/custom-message.md",
  "website/recipes/custom-navigation.md", "website/recipes/minimal-im.md", "website/recipes/full-im.md",
]) if (!existsSync(join(root, path))) errors.push("missing customization or recipe page: " + path);

if (errors.length) {
  console.error("website productization failed:");
  for (const error of errors) console.error("  " + error);
  process.exit(1);
}
console.log("website productization passed: " + stable.length + " stable pages, " + demoFiles.size + " Vue live adapters, metadata-driven previews");
