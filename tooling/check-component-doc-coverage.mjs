#!/usr/bin/env node
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const catalog = JSON.parse(readFileSync(join(root, "spec/component-catalog.json"), "utf8"));
const metadata = JSON.parse(readFileSync(join(root, "spec/catalog-metadata.json"), "utf8"));
const errors = [];
for (const component of catalog.components.filter((entry) => entry.status !== "internal")) {
  for (const locale of ["zh", "en"]) {
    const path = component.docs[locale];
    if (!path || !existsSync(join(root, path))) {
      errors.push(`${component.name}/${locale}: missing page`);
      continue;
    }
    const source = readFileSync(join(root, path), "utf8");
    if (!source.includes(`<ComponentReference name="${component.name}" />`)) errors.push(`${component.name}/${locale}: missing standard component reference`);
    if (!source.includes("outline: [2, 3]")) errors.push(`${component.name}/${locale}: missing product-page outline`);
  }
}
const referenceSource = readFileSync(join(root, "website/.vitepress/theme/demos/ComponentReference.vue"), "utf8");
for (const section of ["preview", "usage", "configuration", "examples", "variants", "states", "interaction", "responsive", "accessibility", "api", "tokens", "platform-differences", "related", "source-of-truth", "validation"]) {
  if (!referenceSource.includes(`id="${section}"`)) errors.push(`ComponentReference: missing ${section} section`);
}
for (const name of metadata.coreComponents) {
  if (!catalog.components.some((component) => component.name === name)) errors.push(`core component metadata references unknown component: ${name}`);
}
if (errors.length) {
  console.error("component documentation coverage failed:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`component docs passed: ${catalog.components.length}/${catalog.components.length} discoverable, bilingual, and normalized`);
