#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (path) => readFileSync(join(root, path), "utf8");
const catalog = JSON.parse(read("spec/component-catalog.json"));
const previewSource = read("website/.vitepress/theme/demos/ComponentPreview.vue");
const errors = [];
const modes = new Set(["single", "responsive", "workspace"]);
const viewports = new Set(["desktop", "mobile"]);

for (const component of catalog.components.filter((item) => item.status === "stable")) {
  if (!modes.has(component.previewMode)) errors.push(`${component.name}: invalid previewMode ${component.previewMode}`);
  if (!Array.isArray(component.previewViewports) || component.previewViewports.length === 0) {
    errors.push(`${component.name}: previewViewports must not be empty`);
    continue;
  }
  if (new Set(component.previewViewports).size !== component.previewViewports.length) {
    errors.push(`${component.name}: previewViewports contains duplicates`);
  }
  for (const viewport of component.previewViewports) {
    if (!viewports.has(viewport)) errors.push(`${component.name}: unsupported ordinary preview viewport ${viewport}`);
  }
  if (component.previewMode === "single" && component.previewViewports.length !== 1) {
    errors.push(`${component.name}: single preview must expose exactly one viewport and no selector`);
  }
  if (component.previewMode === "responsive" && component.previewViewports.join(",") !== "desktop,mobile") {
    errors.push(`${component.name}: responsive preview must expose only Desktop and Mobile`);
  }
  if (component.previewMode === "workspace" && component.previewViewports.length > 2) {
    errors.push(`${component.name}: workspace preview exposes more controls than necessary`);
  }
  if (component.docsSections?.responsive !== (component.previewMode !== "single")) {
    errors.push(`${component.name}: responsive docs must follow preview classification`);
  }
  if (component.docsSections?.density !== component.supportsDensity) {
    errors.push(`${component.name}: density docs metadata is inconsistent`);
  }
  for (const section of ["configuration", "variants", "states", "interaction", "responsive", "keyboard", "density", "slots", "customization"]) {
    if (typeof component.docsSections?.[section] !== "boolean") errors.push(`${component.name}: docsSections.${section} must be boolean`);
  }
}

const expectedModes = {
  Button: "single",
  MessageStatus: "single",
  MessageBubble: "single",
  Composer: "responsive",
  AdaptiveNavigation: "responsive",
  ImagePreviewModal: "responsive",
  SearchPanel: "responsive",
  AppLayout: "workspace",
  ConversationWorkspace: "workspace",
  WorkspaceFrame: "workspace",
  DesktopAppShell: "workspace",
};
for (const [name, mode] of Object.entries(expectedModes)) {
  const component = catalog.components.find((item) => item.name === name);
  if (component?.previewMode !== mode) errors.push(`${name}: expected ${mode} preview`);
}

for (const forbidden of [
  "responsiveCategories", "contextComponents", "components.json", "<select", "Reset",
  "data-preview-control", "wideDesktop", "tablet",
]) {
  if (previewSource.includes(forbidden)) errors.push(`ComponentPreview contains dashboard or hardcoded classification signal: ${forbidden}`);
}
for (const required of ["component-catalog.json", "previewMode", "previewViewports", "previewPresentation", "hasViewportControls"]) {
  if (!previewSource.includes(required)) errors.push(`ComponentPreview missing metadata-driven signal: ${required}`);
}

if (errors.length) {
  console.error("docs preview simplicity check failed:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}

const counts = Object.fromEntries([...modes].map((mode) => [mode, catalog.components.filter((item) => item.previewMode === mode).length]));
console.log(`docs preview simplicity check passed: ${counts.single} single, ${counts.responsive} responsive, ${counts.workspace} workspace`);
