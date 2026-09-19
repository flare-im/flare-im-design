#!/usr/bin/env node
/**
 * Every `var(--flare-x, fallback)` in packages/vue-im-ui must name either a generated
 * semantic token or a declared component/local token. Generated and canonical component
 * tokens also keep their light fallback aligned with the source declaration.
 *
 * Why this needs a gate: the fallback is not decoration. Components are usable
 * standalone, and on that path a fallback can become the rendered value. This gate
 * prevents misspelled tokens and stale duplicated defaults without treating the
 * component semantic layer as an intentional local indirection.
 *
 * A misspelled variable is the same defect with the volume turned up: it can
 * never resolve, so those components sit permanently on the fallback and ignore
 * the token system entirely.
 *
 * Run: node tooling/check-token-fallbacks.mjs
 */
import { readFileSync, readdirSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, relative } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const srcRoot = join(root, "packages/vue-im-ui/src");

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
const componentCss = readFileSync(join(srcRoot, "design-system/styles/component-tokens.css"), "utf8");
for (const [, name, rawValue] of componentCss.matchAll(/(--flare-component-[\w-]+)\s*:\s*([^;]+);/g)) {
  const value = rawValue.trim();
  const alias = /^var\((--flare-[\w-]+)\)$/.exec(value);
  light.set(name, alias && light.has(alias[1]) ? light.get(alias[1]) : value);
}

const norm = (s) => String(s ?? "").trim().toLowerCase().replace(/\s+/g, "");
const VAR = /var\(\s*(--flare-[\w-]+)\s*,\s*([^()]*?)\s*\)/g;

const files = [];
(function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) walk(p);
    else if (/\.(vue|css|ts)$/.test(entry)) files.push(p);
  }
})(srcRoot);

// 无兜底形态 var(--flare-x)：变量名也必须存在。库内自己声明的局部变量（`--flare-x:`）
// 算存在——StatusBanner 的 --flare-tone、示例壳的 --flare-app-* 都是这一类。
const NOFB = /var\(\s*(--flare-[\w-]+)\s*\)/g;
const declared = new Set();
for (const file of files) for (const [, name] of readFileSync(file, "utf8").matchAll(/(--flare-[\w-]+)\s*["']?\s*:/g)) declared.add(name);

const drifted = [];
const unknown = [];
for (const file of files) {
  const rel = relative(root, file);
  for (const [, name] of readFileSync(file, "utf8").matchAll(NOFB)) {
    if (!light.has(name) && !declared.has(name)) unknown.push(`${rel}: var(${name}) — no such token and never declared`);
  }
  for (const [, name, fallback] of readFileSync(file, "utf8").matchAll(VAR)) {
    if (!light.has(name) && !declared.has(name)) {
      unknown.push(`${rel}: var(${name}, …) — no such token`);
    } else if (light.has(name) && fallback && norm(fallback) !== norm(light.get(name))) {
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
console.log(`✓ ${files.length} 个源文件只引用已声明的 var(--flare-*)；主题 token 无重复 fallback`);
