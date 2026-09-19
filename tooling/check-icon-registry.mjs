#!/usr/bin/env node
// Semantic icon registry parity: the four kits expose the same icon names in the same order, and
// every name has a glyph on every platform. `--table` prints the name → glyph table used by
// docs/ICON-LIBRARY.md.
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (path) => readFileSync(join(root, path), "utf8");

const SOURCES = {
  vue: "packages/vue-im-ui/src/shared/icons.ts",
  vueGlyphs: "packages/vue-im-ui/src/shared/icon-glyphs.ts",
  flutter: "packages/flutter-im-ui/lib/src/components/flare_icon.dart",
  ios: "packages/ios-im-ui/Sources/FlareIMUI/Components/IconLibrary.swift",
  compose: "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/IconLibrary.kt",
};

/** The text between `start` and the bracket that closes the first `open` after it. */
function block(source, start, open, close, file) {
  const at = source.indexOf(start);
  if (at < 0) throw new Error(`${file}: cannot find ${start}`);
  const from = source.indexOf(open, at + start.length);
  let depth = 0;
  for (let index = from; index < source.length; index += 1) {
    if (source[index] === open) depth += 1;
    else if (source[index] === close && --depth === 0) return source.slice(from + 1, index);
  }
  throw new Error(`${file}: unbalanced ${start}`);
}

const withoutComments = (text) => text.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");
const strings = (text) => [...withoutComments(text).matchAll(/["']([^"']+)["']/g)].map((match) => match[1]);
/** `key <separator> value` pairs of a map literal, in source order. */
function pairs(text, pattern) {
  return [...withoutComments(text).matchAll(pattern)].map((match) => [match[1], match[2].trim()]);
}

function vueRegistry() {
  const source = read(SOURCES.vue);
  const body = block(source, "export const flareIcons", "{", "}", SOURCES.vue);
  const glyphs = read(SOURCES.vueGlyphs);
  const lucide = new Map([...glyphs.matchAll(/export const (\w+) = \/\*#__PURE__\*\/ glyph\("(\w+)"/g)].map((match) => [match[1], match[2]]));
  const entries = pairs(body, /^\s*["']?([a-z][a-z0-9-]*)["']?\s*:\s*(\w+)\s*,?\s*$/gm);
  return { names: entries.map(([name]) => name), glyphs: new Map(entries.map(([name, glyph]) => [name, lucide.get(glyph) ?? glyph])) };
}

function flutterRegistry() {
  const source = read(SOURCES.flutter);
  const names = strings(block(source, "const List<String> flareIconNames", "[", "]", SOURCES.flutter));
  const map = pairs(block(source, "const Map<String, IconData> flareIconMap", "{", "}", SOURCES.flutter), /'([a-z][a-z0-9-]*)'\s*:\s*([\w.]+)/g);
  return { names, glyphs: new Map(map.map(([name, glyph]) => [name, glyph.replace(/^Icons\./, "")])) };
}

function iosRegistry() {
  const source = read(SOURCES.ios);
  const names = strings(block(source, "public let flareIconNames: [String] =", "[", "]", SOURCES.ios));
  const map = pairs(block(source, "public let flareIconMap: [String: String] =", "[", "]", SOURCES.ios), /"([a-z][a-z0-9-]*)"\s*:\s*"([^"]+)"/g);
  return { names, glyphs: new Map(map) };
}

function composeRegistry() {
  const source = read(SOURCES.compose);
  const names = strings(block(source, "val flareIconNames", "(", ")", SOURCES.compose));
  const map = pairs(block(source, "val flareIconMap", "(", ")", SOURCES.compose), /"([a-z][a-z0-9-]*)"\s+to\s+([\w.]+)/g);
  return { names, glyphs: new Map(map.map(([name, glyph]) => [name, glyph.replace(/^Icons\./, "")])) };
}

const registries = { vue: vueRegistry(), flutter: flutterRegistry(), ios: iosRegistry(), compose: composeRegistry() };
const canonical = registries.vue.names;
const failures = [];

if (!canonical.length) failures.push("vue: no icon names found");
for (const name of canonical) {
  if (!/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/.test(name)) failures.push(`vue: "${name}" is not kebab-case`);
}
const duplicates = canonical.filter((name, index) => canonical.indexOf(name) !== index);
if (duplicates.length) failures.push(`vue: duplicate names ${duplicates.join(", ")}`);

for (const [platform, registry] of Object.entries(registries)) {
  const missing = canonical.filter((name) => !registry.names.includes(name));
  const extra = registry.names.filter((name) => !canonical.includes(name));
  if (missing.length) failures.push(`${platform}: names missing from the registry: ${missing.join(", ")}`);
  if (extra.length) failures.push(`${platform}: names not in the Vue registry: ${extra.join(", ")}`);
  if (!missing.length && !extra.length && registry.names.join() !== canonical.join()) {
    const at = registry.names.findIndex((name, index) => name !== canonical[index]);
    failures.push(`${platform}: order differs from the Vue registry at position ${at + 1} ("${registry.names[at]}" where Vue has "${canonical[at]}")`);
  }
  const unmapped = canonical.filter((name) => !registry.glyphs.get(name));
  if (unmapped.length) failures.push(`${platform}: names without a glyph: ${unmapped.join(", ")}`);
  const unnamed = [...registry.glyphs.keys()].filter((name) => !canonical.includes(name));
  if (unnamed.length) failures.push(`${platform}: glyphs for names outside the registry: ${unnamed.join(", ")}`);
}

// ── Bypass ratchet ────────────────────────────────────────────────────────────
// Inside the kits a glyph should come from the registry, not from the underlying library. The
// remaining direct references are counted per kit and may only go down: a new one fails the gate.
// `--baseline` re-locks the counts after a migration.
const BYPASS = {
  vue: {
    root: "packages/vue-im-ui/src",
    skip: ["shared/icon-glyphs.ts", "shared/icons.ts"],
    extensions: [".vue", ".ts"],
    // A test that asserts the shim itself imports from it on purpose; what this counts is components
    // reaching past the registry. The other three platforms keep their tests outside the counted root.
    skipPattern: /\.test\.ts$/,
    count: (text) => [...text.matchAll(/import\s*\{([^}]*)\}\s*from\s*["'][^"']*icon-glyphs["']/g)]
      .reduce((total, match) => total + match[1].split(",").filter((name) => name.trim()).length, 0),
  },
  flutter: {
    root: "packages/flutter-im-ui/lib",
    skip: ["src/components/flare_icon.dart"],
    extensions: [".dart"],
    count: (text) => (text.match(/\bIcons\.[a-z_]/g) ?? []).length,
  },
  ios: {
    root: "packages/ios-im-ui/Sources",
    skip: ["FlareIMUI/Components/IconLibrary.swift"],
    extensions: [".swift"],
    count: (text) => (text.match(/system(?:Name|Image):\s*"/g) ?? []).length,
  },
  compose: {
    root: "packages/android-im-ui/src/main",
    skip: ["kotlin/com/flare/im/ui/IconLibrary.kt"],
    extensions: [".kt"],
    count: (text) => (text.match(/\bIcons\.(?:Filled|Outlined|Rounded|Sharp|TwoTone|Default|AutoMirrored)\./g) ?? []).length,
  },
};

function walk(directory, extensions, files = []) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules" || entry.name.startsWith(".")) continue;
      walk(path, extensions, files);
    } else if (extensions.some((extension) => entry.name.endsWith(extension))) files.push(path);
  }
  return files;
}

const bypassCounts = {};
for (const [platform, config] of Object.entries(BYPASS)) {
  const base = join(root, config.root);
  const skip = new Set(config.skip.map((path) => join(base, path)));
  bypassCounts[platform] = walk(base, config.extensions)
    .filter((path) => !skip.has(path) && !config.skipPattern?.test(path))
    .reduce((total, path) => total + config.count(readFileSync(path, "utf8")), 0);
}

const bypassBaselinePath = join(root, "tooling/icon-bypass-baseline.json");
if (process.argv.includes("--baseline")) {
  writeFileSync(bypassBaselinePath, `${JSON.stringify(bypassCounts, null, 2)}\n`);
  console.log("icon bypass baseline written:", JSON.stringify(bypassCounts));
} else {
  const baseline = JSON.parse(readFileSync(bypassBaselinePath, "utf8"));
  for (const [platform, count] of Object.entries(bypassCounts)) {
    const allowed = baseline[platform];
    if (allowed === undefined) failures.push(`${platform}: no icon bypass baseline; run --baseline`);
    else if (count > allowed) failures.push(`${platform}: ${count} direct glyph references inside the kit, baseline ${allowed}. Use a registry name.`);
  }
}

if (process.argv.includes("--table")) {
  console.log("| Name | Web (Lucide) | Flutter (Icons.) | iOS (SF Symbol) | Compose (Icons.) |");
  console.log("|---|---|---|---|---|");
  for (const name of canonical) {
    const cells = ["vue", "flutter", "ios", "compose"].map((platform) => `\`${registries[platform].glyphs.get(name) ?? "✗"}\``);
    console.log(`| \`${name}\` | ${cells.join(" | ")} |`);
  }
}

if (failures.length) {
  console.error(`icon registry parity failed (${failures.length}):`);
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}
if (!process.argv.includes("--table")) {
  console.log(`icon registry parity passed: ${canonical.length} names in the same order on vue, flutter, ios and compose, each with a glyph; kit-internal glyph references ${Object.entries(bypassCounts).map(([platform, count]) => `${platform} ${count}`).join(", ")} (at or below baseline)`);
}
