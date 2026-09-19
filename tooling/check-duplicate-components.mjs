#!/usr/bin/env node
// duplicate-components — the duplication register (spec/duplication-register.json) is
// enforced, not just documented:
//   * every entry is well-formed (known decision / state, owner for open work);
//   * DONE entries have really landed: removed symbols are gone from the catalog,
//     the Vue facade and the native sources; `into` names catalog components;
//     `requires` evidence holds;
//   * no two catalog components share one Vue source file (alias detection), and
//     the Vue facade never exports one file under two names;
//   * a catalog symbol is defined once per platform.
// `--strict` (release-check) also fails while any entry is PLANNED or DEFERRED.
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const strict = process.argv.includes("--strict");
const read = (rel) => readFileSync(join(root, rel), "utf8");
const spec = JSON.parse(read("spec/components.json"));
const catalog = JSON.parse(read("spec/component-catalog.json"));
const register = JSON.parse(read("spec/duplication-register.json"));
const facade = read("packages/vue-im-ui/src/components/index.ts");

const DECISIONS = new Set(["KEEP", "REFACTOR", "MERGE", "SPLIT", "INTERNALIZE", "DEPRECATE", "REMOVE"]);
const STATES = new Set(["DONE", "PLANNED", "DEFERRED"]);
const PLATFORMS = ["vue", "flutter", "ios", "compose"];
const sourceRoots = {
  vue: "packages/vue-im-ui/src",
  flutter: "packages/flutter-im-ui/lib",
  ios: "packages/ios-im-ui/Sources",
  compose: "packages/android-im-ui/src/main",
};
const extensions = { vue: [".ts", ".vue"], flutter: [".dart"], ios: [".swift"], compose: [".kt"] };

function walk(dir, exts, files = []) {
  if (!existsSync(dir)) return files;
  for (const name of readdirSync(dir)) {
    const absolute = join(dir, name);
    if (statSync(absolute).isDirectory()) walk(absolute, exts, files);
    else if (exts.some((ext) => name.endsWith(ext))) files.push(absolute);
  }
  return files;
}
const sources = Object.fromEntries(PLATFORMS.map((p) => [p, walk(join(root, sourceRoots[p]), extensions[p]).map((file) => ({ file: file.slice(root.length + 1), text: readFileSync(file, "utf8") }))]));

// Where a public symbol is *defined* per platform (declarations only, not usages).
const definitionPatterns = {
  vue: (symbol) => new RegExp(`^export \\{ default as ${symbol} \\}`, "m"),
  flutter: (symbol) => new RegExp(`^(?:abstract\\s+)?class ${symbol}\\b`, "m"),
  ios: (symbol) => new RegExp(`^public (?:struct|final class|class|enum|func) ${symbol}\\b`, "m"),
  compose: (symbol) => new RegExp(`^(?:@Composable\\s+)?fun ${symbol}\\(|^data class ${symbol}\\(|^class ${symbol}\\b|^enum class ${symbol}\\b`, "m"),
};
function definitions(platform, symbol) {
  const pattern = definitionPatterns[platform](symbol);
  const hits = [];
  if (platform === "vue") {
    if (pattern.test(facade)) hits.push("packages/vue-im-ui/src/components/index.ts");
    return hits;
  }
  for (const { file, text } of sources[platform]) if (pattern.test(text)) hits.push(file);
  return hits;
}

const errors = [];
const open = [];
const ids = new Set();
const catalogNames = new Set(spec.components.map((c) => c.name));
const catalogSymbols = Object.fromEntries(PLATFORMS.map((p) => [p, new Set(spec.components.map((c) => c.platforms?.[p]?.symbol).filter(Boolean))]));

for (const entry of register.entries) {
  const at = `register ${entry.id}`;
  if (ids.has(entry.id)) errors.push(`${at}: duplicate id`);
  ids.add(entry.id);
  if (!DECISIONS.has(entry.decision)) errors.push(`${at}: decision must be one of ${[...DECISIONS].join("/")}`);
  if (!STATES.has(entry.state)) errors.push(`${at}: state must be DONE / PLANNED / DEFERRED`);
  for (const name of entry.components ?? []) if (!catalogNames.has(name)) errors.push(`${at}: component ${name} is not in the catalog`);
  if (entry.state === "DONE") {
    if (!entry.resolvedBy) errors.push(`${at}: DONE entries record resolvedBy`);
    for (const [platform, symbols] of Object.entries(entry.removed ?? {})) {
      for (const symbol of symbols) {
        if (catalogSymbols[platform]?.has(symbol)) errors.push(`${at}: removed ${platform} symbol ${symbol} is still a catalog symbol`);
        for (const file of definitions(platform, symbol)) errors.push(`${at}: removed ${platform} symbol ${symbol} is still defined in ${file}`);
      }
    }
  } else {
    if (!entry.resolveBy) errors.push(`${at}: open entries name the step that resolves them (resolveBy)`);
    open.push(`${entry.id} ${entry.state} → ${entry.decision} into ${entry.into} (${entry.resolveBy})`);
    // Open entries must still describe a real, present duplicate: symbols slated for removal exist today.
    for (const [platform, symbols] of Object.entries(entry.removed ?? {}))
      for (const symbol of symbols)
        if (!definitions(platform, symbol).length && !catalogSymbols[platform]?.has(symbol)) errors.push(`${at}: ${platform} symbol ${symbol} no longer exists — mark the entry DONE or drop it`);
  }
  for (const evidence of entry.requires ?? []) {
    if (!existsSync(join(root, evidence.file))) { errors.push(`${at}: evidence file missing ${evidence.file}`); continue; }
    const text = read(evidence.file);
    if (evidence.contains && !text.includes(evidence.contains)) errors.push(`${at}: ${evidence.file} no longer contains "${evidence.contains}"`);
    if (evidence.lacks && text.includes(evidence.lacks)) errors.push(`${at}: ${evidence.file} still contains "${evidence.lacks}"`);
  }
}

// Structural duplicate detection on the current catalog.
const byVueSource = new Map();
for (const component of catalog.components) {
  const path = component.sourcePaths?.vue;
  if (!path) continue;
  if (!byVueSource.has(path)) byVueSource.set(path, []);
  byVueSource.get(path).push(component.name);
}
for (const [path, names] of byVueSource) if (names.length > 1) errors.push(`catalog components ${names.join(", ")} are aliases of one Vue source: ${path}`);
const facadeByFile = new Map();
for (const match of facade.matchAll(/^export \{ default as (\w+) \} from ["']([^"']+)["'];/gm)) {
  if (!facadeByFile.has(match[2])) facadeByFile.set(match[2], []);
  facadeByFile.get(match[2]).push(match[1]);
}
for (const [file, names] of facadeByFile) if (names.length > 1) errors.push(`components facade exports ${file} under ${names.length} names: ${names.join(", ")}`);
for (const platform of PLATFORMS) {
  if (platform === "vue") continue;
  for (const symbol of catalogSymbols[platform]) {
    const hits = definitions(platform, symbol);
    if (hits.length > 1) errors.push(`${platform} symbol ${symbol} is defined ${hits.length} times: ${hits.join(", ")}`);
  }
}

if (errors.length) {
  console.error("duplicate components check failed:\n  " + errors.join("\n  "));
  process.exit(1);
}
if (open.length) {
  console[strict ? "error" : "warn"](`duplicate components: ${open.length} register entr${open.length === 1 ? "y" : "ies"} still open:\n  ${open.join("\n  ")}`);
  if (strict) process.exit(1);
}
const done = register.entries.filter((entry) => entry.state === "DONE").length;
console.log(`duplicate components check passed: ${done}/${register.entries.length} register entries closed, ${byVueSource.size} distinct Vue sources for ${catalog.components.length} catalog components`);
