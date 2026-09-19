#!/usr/bin/env node
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const slugs = ["button", "input", "dialog", "drawer", "tabs", "conversation-item", "message-bubble", "message-list", "composer", "thread", "reaction", "upload", "desktop-app-shell", "command-palette"];
const headings = ["Overview", "When to use", "When not to use", "Anatomy", "Variants", "Sizes", "States", "Interactions", "Keyboard", "Accessibility", "Responsive", "Platform differences", "Code examples", "Do / Don't"];
const errors = [];
for (const slug of slugs) {
  const path = join(root, `docs/components/${slug}.md`);
  if (!existsSync(path)) { errors.push(`${slug}: missing guide`); continue; }
  const source = readFileSync(path, "utf8");
  for (const heading of headings) if (!source.includes(`## ${heading}`)) errors.push(`${slug}: missing ${heading}`);
}
if (errors.length) {
  console.error("component guide errors:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`component guides passed: ${slugs.length} complete guides`);
