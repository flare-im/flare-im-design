#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const errors = [];
function walk(path, files = []) {
  if (!existsSync(path)) return files;
  for (const name of readdirSync(path)) {
    if (["node_modules", ".vitepress", "dist", "archive"].includes(name)) continue;
    const absolute = join(path, name);
    if (statSync(absolute).isDirectory()) walk(absolute, files);
    else if (name.endsWith(".md")) files.push(absolute);
  }
  return files;
}
function targetExists(path) {
  return existsSync(path) || existsSync(`${path}.md`) || existsSync(join(path, "index.md"));
}
const markdown = [
  ...["README.md", "README.zh-CN.md", "CONTRIBUTING.md", "PUBLIC_API.md", "COMPATIBILITY.md"].map((path) => join(root, path)).filter(existsSync),
  ...walk(join(root, "docs")),
  ...walk(join(root, "website")),
];
for (const path of markdown) {
  const source = readFileSync(path, "utf8");
  for (const match of source.matchAll(/!?\[[^\]]*\]\(([^)]+)\)/g)) {
    let href = match[1].trim().replace(/^<|>$/g, "").split(/\s+["']/)[0];
    if (!href || href.startsWith("#") || /^(?:https?:|mailto:|codex:)/.test(href)) continue;
    href = decodeURIComponent(href.split("#")[0].split("?")[0]);
    const target = href.startsWith("/") ? join(root, "website", href) : resolve(dirname(path), href);
    if (!targetExists(target)) errors.push(`${path.slice(root.length + 1)} -> ${href}`);
  }
}
if (errors.length) {
  console.error("broken documentation links:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`documentation links passed: ${markdown.length} Markdown files`);
