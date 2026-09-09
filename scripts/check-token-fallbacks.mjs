#!/usr/bin/env node
/**
 * Every `var(--flare-x, fallback)` in vue-im-ui must carry the token's own light
 * value as its fallback, and must name a token that exists.
 *
 * Why this needs a gate: the fallback is not decoration. Components are usable
 * standalone (see scripts/check-optional-sdk-consumer.mjs), and on that path no
 * tokens.css is loaded, so the fallback IS the rendered value. When the palette
 * was retuned — the neutral ramp moved from warm violet-greys to cool greys and
 * primary settled on #7047D6 — the tokens changed and ~690 inline fallbacks did
 * not. The kit then rendered one palette with the theme loaded and the previous
 * palette without it, and nothing failed.
 *
 * A misspelled variable is the same defect with the volume turned up: it can
 * never resolve, so those components sit permanently on the fallback and ignore
 * the token system entirely.
 *
 * Run: node scripts/check-token-fallbacks.mjs
 */
import { readFileSync, readdirSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, relative } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const srcRoot = join(root, "vue-im-ui/src");

const css = readFileSync(join(root, "tokens/dist/tokens.css"), "utf8");
// Only the first :root block — the later ones are the dark overrides, and a
// fallback is by definition the light default.
const lightBlock = /:root\s*\{([\s\S]*?)\}/.exec(css);
if (!lightBlock) {
  console.error("✗ tokens/dist/tokens.css has no :root block — run node tokens/build.mjs");
  process.exit(1);
}
const light = new Map();
for (const [, name, value] of lightBlock[1].matchAll(/(--flare-[\w-]+)\s*:\s*([^;]+);/g)) {
  light.set(name, value.trim());
}

const norm = (s) => s.trim().toLowerCase().replace(/\s+/g, "");
const VAR = /var\(\s*(--flare-[\w-]+)\s*,\s*([^()]*?)\s*\)/g;

const files = [];
(function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) walk(p);
    else if (/\.(vue|css|ts)$/.test(entry)) files.push(p);
  }
})(srcRoot);

const drifted = [];
const unknown = [];
for (const file of files) {
  const rel = relative(root, file);
  for (const [, name, fallback] of readFileSync(file, "utf8").matchAll(VAR)) {
    if (!light.has(name)) {
      unknown.push(`${rel}: var(${name}, …) — no such token`);
    } else if (fallback && norm(fallback) !== norm(light.get(name))) {
      drifted.push(`${rel}: var(${name}, ${fallback}) — token is ${light.get(name)}`);
    }
  }
}

const problems = [...unknown, ...drifted];
if (problems.length) {
  console.error(`✗ token fallbacks out of sync (${problems.length}):`);
  // One line per site would drown the signal on a large drift; show a sample.
  for (const p of problems.slice(0, 25)) console.error("  - " + p);
  if (problems.length > 25) console.error(`  … and ${problems.length - 25} more`);
  console.error("\n  A fallback renders whenever the kit is used without tokens.css.");
  console.error("  Make it equal the token's light value, or fix the variable name.");
  process.exit(1);
}
console.log(`✓ ${files.length} 个源文件里的 var(--flare-*) 兜底值与 token 一致`);
