#!/usr/bin/env node
import {
  readFileSync,
  readdirSync,
  lstatSync,
} from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const sourceRoots = [
  "packages",
  "tokens",
  "website",
  "examples",
  "spec",
  "tests",
].map((path) => join(root, path));
const legacyPatterns = [
  /--im-[a-z0-9-]+/gi,
  /--wechat-[a-z0-9-]+/gi,
  /--flare-color-bubble-(?:self|other)[a-z0-9-]*/gi,
  /--flare-color-message-status-on-self/gi,
];

function walk(directory) {
  return readdirSync(directory).flatMap((name) => {
    if (["node_modules", "dist", "build", ".build", ".dart_tool"].includes(name)) return [];
    const path = join(directory, name);
    const stat = lstatSync(path);
    if (stat.isSymbolicLink()) return [];
    if (stat.isDirectory()) return walk(path);
    return /\.(vue|css|scss|sass|less|ts|tsx|js|mjs|json|dart|kt|kts|swift|md)$/.test(path) ? [path] : [];
  });
}

const violations = [];
for (const file of sourceRoots.flatMap(walk)) {
  const rel = relative(root, file);
  const text = readFileSync(file, "utf8");
  for (const pattern of legacyPatterns) {
    const matches = [...text.matchAll(pattern)];
    if (matches.length) violations.push(`${rel}: ${matches.map((match) => match[0]).join(", ")}`);
  }
}

// A `var(--flare-…)` that nothing defines silently paints nothing — the property
// is simply dropped. That is how a deleted component token keeps "working" in a
// diff and disappears on screen. So every kit reference must resolve to a
// definition somewhere in the kit's own stylesheets, or carry a fallback.
const kitStyleRoots = [
  join(root, "packages/vue-im-ui/src"),
  join(root, "tokens/dist"),
];
const defined = new Set();
const styleFiles = kitStyleRoots.flatMap(walk).filter((file) => /\.(css|vue|ts)$/.test(file));
for (const file of styleFiles) {
  // A definition is either a CSS declaration or an inline `:style` entry, where the
  // name is a quoted object key: `"--flare-app-detail-width": \`${n}px\``.
  for (const match of readFileSync(file, "utf8").matchAll(/(--flare-[a-z0-9-]+)["']?\s*:/gi)) defined.add(match[1]);
}
const missing = new Map();
for (const file of styleFiles) {
  const text = readFileSync(file, "utf8");
  // `var(--x)` with no comma is unguarded; `var(--x, fallback)` degrades on purpose.
  for (const match of text.matchAll(/var\(\s*(--flare-[a-z0-9-]+)\s*\)/gi)) {
    if (defined.has(match[1])) continue;
    const rel = relative(root, file);
    if (!missing.has(match[1])) missing.set(match[1], new Set());
    missing.get(match[1]).add(rel);
  }
}
for (const [name, files] of missing) {
  violations.push(`${[...files].join(", ")}: var(${name}) has no definition and no fallback`);
}

if (violations.length) {
  console.error("legacy token aliases remain:");
  for (const item of violations) console.error(`  ${item}`);
  process.exit(1);
}

console.log(`legacy token check passed: no --im-*, --wechat-*, self/other bubble, or on-self aliases; ${defined.size} kit tokens defined, every unguarded var() resolves`);
