#!/usr/bin/env node
// api-check — the Vue `./components` entry exports exactly the catalog:
//   * every `export { default as X }` is the Vue symbol of a catalog component
//     (or a tracked pending merge in spec/public-api-exceptions.json);
//   * every named export is a type, a catalog symbol, or a declared companion;
//   * every catalog Vue symbol is exported (the facade never lags the contract).
// `--strict` (release-check) also fails while pendingMerge is non-empty.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { publicExports } from "./vue-doc-imports.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const strict = process.argv.includes("--strict");
const spec = JSON.parse(readFileSync(join(root, "spec/components.json"), "utf8"));
const exceptions = JSON.parse(readFileSync(join(root, "spec/public-api-exceptions.json"), "utf8"));
const facade = readFileSync(join(root, "packages/vue-im-ui/src/components/index.ts"), "utf8");

const catalogSymbols = new Set(spec.components.map((c) => c.platforms?.vue?.symbol).filter(Boolean));
const pending = new Map(exceptions.pendingMerge.map((entry) => [entry.symbol, entry]));
const companions = new Set(Object.keys(exceptions.companionExports));

const defaults = [...facade.matchAll(/^export \{ default as (\w+) \} from ["']([^"']+)["'];/gm)].map((m) => ({ symbol: m[1], from: m[2] }));
const named = [];
for (const match of facade.matchAll(/^export (type )?\{([^}]*)\} from ["']([^"']+)["'];/gm)) {
  if (match[1]) continue; // type-only export statement
  for (const raw of match[2].split(",")) {
    const item = raw.trim();
    if (!item || item.startsWith("type ") || item.startsWith("default as ")) continue;
    const symbol = item.includes(" as ") ? item.split(" as ")[1].trim() : item;
    named.push({ symbol, from: match[3] });
  }
}

const errors = [];
const exported = new Set();
for (const { symbol, from } of defaults) {
  exported.add(symbol);
  if (catalogSymbols.has(symbol) || pending.has(symbol)) continue;
  errors.push(`unregistered component export: ${symbol} (${from}) — register it in spec/components.json, internalize it, or track it in spec/public-api-exceptions.json`);
}
for (const { symbol, from } of named) {
  exported.add(symbol);
  if (catalogSymbols.has(symbol) || companions.has(symbol)) continue;
  errors.push(`non-component export on ./components: ${symbol} (${from}) — hooks belong to ./composables, pure helpers to ./utils`);
}
for (const symbol of catalogSymbols) {
  if (!exported.has(symbol)) errors.push(`catalog symbol not exported from ./components: ${symbol}`);
}
for (const [symbol, entry] of pending) {
  if (!exported.has(symbol)) errors.push(`stale pendingMerge entry (no longer exported): ${symbol}`);
  if (catalogSymbols.has(symbol)) errors.push(`pendingMerge entry is already a catalog symbol: ${symbol}`);
  if (!entry.into || !entry.resolveBy) errors.push(`pendingMerge entry for ${symbol} lacks into/resolveBy`);
}

// The registry also promises non-component surface on the other entries
// (docs/release/public-api-2.0.md §5). The checks above read ./components only,
// so a symbol registered for ./contracts but never exported passed here while
// every consumer following the migration guide got an import error.
const registry = readFileSync(join(root, "docs/release/public-api-2.0.md"), "utf8");
const entrySources = { "./contracts": "packages/vue-im-ui/src/shared/contracts", "./composables": "packages/vue-im-ui/src/composables", "./utils": "packages/vue-im-ui/src/utils" };
const entryExports = new Map();
let registered = 0;
for (const row of registry.split("\n").filter((line) => line.startsWith("|"))) {
  const cells = row.split("|").map((cell) => cell.trim());
  const entry = cells.map((cell) => cell.match(/^`(\.\/[a-z-]+)`$/)?.[1]).find((value) => value && entrySources[value]);
  if (!entry) continue;
  if (!entryExports.has(entry)) entryExports.set(entry, publicExports(join(root, entrySources[entry])));
  for (const [, symbol] of cells[1].matchAll(/`([A-Za-z_]\w*)`/g)) {
    registered += 1;
    if (!entryExports.get(entry).has(symbol)) errors.push(`docs/release/public-api-2.0.md registers ${symbol} on ${entry}, but that entry does not export it`);
  }
}

if (errors.length) {
  console.error("public api check failed:\n  " + errors.join("\n  "));
  process.exit(1);
}
const pendingList = [...pending.values()].map((e) => `${e.symbol} → ${e.into} (${e.resolveBy})`);
if (pendingList.length) {
  console[strict ? "error" : "warn"](`public api: ${pendingList.length} export(s) pending merge:\n  ${pendingList.join("\n  ")}`);
  if (strict) process.exit(1);
}
console.log(`public api check passed: ${defaults.length} component exports = ${catalogSymbols.size} catalog symbols + ${pendingList.length} pending; ${named.length} named companion export(s); ${registered} registry symbol(s) on other entries resolve`);
