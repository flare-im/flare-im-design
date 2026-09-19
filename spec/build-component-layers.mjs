#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";

const specPath = new URL("./components.json", import.meta.url);
const outputPath = new URL("./component-layers.json", import.meta.url);
const spec = JSON.parse(readFileSync(specPath, "utf8"));

const generalComposite = new Set([
  "CapabilityBoundary",
  "ConfigProvider",
  "DangerConfirm",
  "DatePicker",
  "PermissionPrompt",
  "ResponsiveLayout",
  "ScreenHeader",
  "SearchDateRangeFilter",
  "TimePicker",
]);
const generalCategories = new Set([
  "General",
  "Layout",
  "Navigation",
  "Form",
  "Feedback",
  "Overlay",
]);
const imExceptions = new Set([
  "AnnouncementReadBar",
  "MessageStatus",
  "SearchPanel",
]);

const components = {};
for (const component of spec.components) {
  let layer = "im-ui";
  if (component.category === "AppKit") layer = "appkit";
  else if (component.category === "Workspaces" || component.name === "ConversationWorkspace") layer = "workspaces";
  else if (component.category === "Patterns") layer = "patterns";
  else if (
    generalComposite.has(component.name) ||
    (generalCategories.has(component.category) && !imExceptions.has(component.name))
  ) layer = "general-ui";
  components[component.name] = layer;
}

const output = `${JSON.stringify({
  schemaVersion: 1,
  dependencyDirection: ["foundation", "general-ui", "im-ui", "patterns", "workspaces", "appkit", "host-application"],
  allowedDependencies: {
    foundation: [],
    "general-ui": ["foundation"],
    "im-ui": ["foundation", "general-ui"],
    patterns: ["foundation", "general-ui", "im-ui"],
    workspaces: ["foundation", "general-ui", "im-ui", "patterns"],
    appkit: ["foundation", "general-ui", "im-ui", "patterns", "workspaces"],
    "host-application": ["foundation", "general-ui", "im-ui", "patterns", "workspaces", "appkit"],
  },
  components,
}, null, 2)}\n`;

if (process.argv.includes("--check")) {
  if (readFileSync(outputPath, "utf8") !== output) {
    console.error("component layer map is stale; run node spec/build-component-layers.mjs");
    process.exit(1);
  }
  console.log(`component layer map current: ${Object.keys(components).length} components`);
  process.exit(0);
}

writeFileSync(outputPath, output);

console.log(`component layer map written: ${Object.keys(components).length} components`);
