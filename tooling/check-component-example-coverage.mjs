#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const catalog = JSON.parse(readFileSync(join(root, "spec/component-catalog.json"), "utf8"));
const metadata = JSON.parse(readFileSync(join(root, "spec/catalog-metadata.json"), "utf8"));
const visual = JSON.parse(readFileSync(join(root, "examples/gallery/gallery-manifest.json"), "utf8"));
const errors = [];
for (const component of catalog.components.filter((entry) => entry.status === "stable")) {
  if (!component.examples.live && !component.examples.code && !component.examples.gallery) errors.push(`${component.name}: no basic example`);
}
const requiredStates = new Set(visual.requiredStates ?? []);
for (const state of ["dark", "largeText", "error"]) if (!requiredStates.has(state)) errors.push(`gallery contract missing complex state: ${state}`);
for (const name of metadata.coreComponents) {
  const component = catalog.components.find((entry) => entry.name === name);
  if (!component) continue;
  if (!component.examples.live && !component.examples.gallery && !component.examples.code) errors.push(`${name}: core component lacks executable or contract example`);
}
if (errors.length) {
  console.error("component example coverage failed:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`component examples passed: ${catalog.counts.stable} stable basics; ${metadata.coreComponents.length} core entries; complex state contract present`);
