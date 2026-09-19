#!/usr/bin/env node
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { docImports, publicExports } from "./vue-doc-imports.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const vueSourceRoot = join(root, "packages/vue-im-ui/src");
const exports = publicExports(vueSourceRoot);
const errors = [];
function walk(path, files = []) {
  for (const name of readdirSync(path)) {
    const absolute = join(path, name);
    if (statSync(absolute).isDirectory()) walk(absolute, files);
    else if (name.endsWith(".md")) files.push(absolute);
  }
  return files;
}
for (const path of walk(join(root, "website"))) {
  const source = readFileSync(path, "utf8");
  for (const name of docImports(source)) {
    if (!exports.has(name)) errors.push(`${relative(root, path)}: undocumented Vue export ${name}`);
  }
}
// Guidance must not teach a component that no longer exists. The import scan above
// only sees `import { … }` lines on the website; stale guidance also lives in
// docs/**, in template tags (`<FlareFoo`) and in prose ("FlareFoo's nav item …").
// A mention is an error only when the symbol was removed from the Vue kit AND no
// source file on any platform still defines it — so Compose's FlareThemeProvider
// or an internalized FlareGlyph are not reported. Lines inside a `>` blockquote are
// allowed: that is where a page records what the API used to be.
const REMOVED_BY_PUBLIC_API_2 = [ // docs/release/public-api-2.0.md §2
  "FlareAuthScreen", "FlareDiagnosticsConsole", "FlareWorkbenchShell", "FlareConfigProvider",
  "FlareThemeProvider", "FlareStickerPicker", "FlareContentView", "FlareMessageTimeline",
];
const HISTORICAL_DOCS = [ // dated records of past state, not usage guidance
  /^docs\/release\//, /^docs\/repository-inventory\.md$/, /^CHANGELOG/,
  /^docs\/2\.0-public-api-freeze\.md$/, /^docs\/flare-im-ui-2\.0-stable-readiness-report\.md$/,
  /^docs\/optimal-library-architecture-report\.md$/, /^docs\/pixel-level-ui-refinement-report\.md$/,
];
const register = JSON.parse(readFileSync(join(root, "spec/duplication-register.json"), "utf8"));
const removed = new Set(REMOVED_BY_PUBLIC_API_2);
for (const entry of register.entries ?? register) {
  for (const symbols of Object.values(entry.removed ?? {})) for (const symbol of symbols) if (/^Flare[A-Z]/.test(symbol)) removed.add(symbol);
}
const definedSomewhere = new Set();
const sourceRoots = ["packages/vue-im-ui/src", "packages/flutter-im-ui/lib", "packages/android-im-ui/src/main", "packages/ios-im-ui/Sources"];
function collect(path) {
  for (const name of readdirSync(path)) {
    const absolute = join(path, name);
    if (statSync(absolute).isDirectory()) { collect(absolute); continue; }
    if (!/\.(vue|ts|dart|kt|swift)$/.test(name)) continue;
    if (/^Flare[A-Z]\w*\.vue$/.test(name)) definedSomewhere.add(name.slice(0, -4));
    for (const match of readFileSync(absolute, "utf8").matchAll(/\b(?:class|struct|enum|fun|func|object|interface|typealias|const|function|let|var|export)\s+(Flare[A-Z]\w*)/g)) definedSomewhere.add(match[1]);
  }
}
for (const sourceRoot of sourceRoots) collect(join(root, sourceRoot));
const gone = [...removed].filter((symbol) => !definedSomewhere.has(symbol));
const guidance = [...walk(join(root, "website")), ...walk(join(root, "docs"))]
  .filter((path) => !/[\\/](node_modules|\.vitepress[\\/](dist|cache))[\\/]/.test(path))
  .filter((path) => !HISTORICAL_DOCS.some((pattern) => pattern.test(relative(root, path))));
let staleMentions = 0;
for (const path of guidance) {
  const lines = readFileSync(path, "utf8").split("\n");
  lines.forEach((line, index) => {
    if (line.trimStart().startsWith(">")) return;
    for (const symbol of gone) {
      if (new RegExp(`\\b${symbol}\\b`).test(line)) {
        staleMentions += 1;
        errors.push(`${relative(root, path)}:${index + 1}: teaches ${symbol}, which no platform defines any more — update the guidance (see docs/release/migration/2.0-rc-to-2.0.md) or move the note into a > blockquote`);
      }
    }
  });
}

// A documented import must name a subpath the published package actually exposes.
// The kit ships nine explicit entries and no wildcard, so a deep path such as
// `@flare-im/vue-ui/shared/icons` resolves in this monorepo and fails for every
// consumer who copies it.
const exportedEntries = {
  "@flare-im/vue-ui": new Set(Object.keys(JSON.parse(readFileSync(join(root, "packages/vue-im-ui/package.json"), "utf8")).exports ?? {})),
  "@flare-im/tokens": new Set(Object.keys(JSON.parse(readFileSync(join(root, "tokens/package.json"), "utf8")).exports ?? {})),
};
let documentedImports = 0;
for (const path of guidance) {
  for (const match of readFileSync(path, "utf8").matchAll(/["'](@flare-im\/(?:vue-ui|tokens))(\/[^"'\s]*)?["']/g)) {
    const entries = exportedEntries[match[1]];
    if (!entries.size) continue; // a package without an exports map resolves any subpath
    documentedImports += 1;
    const key = match[2] ? `.${match[2]}` : ".";
    if (!entries.has(key)) errors.push(`${relative(root, path)}: imports ${match[1]}${match[2] ?? ""}, which is not a published entry (${[...entries].join(", ")})`);
  }
}

if (errors.length) {
  console.error("documentation code validation failed:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`documentation code passed: ${exports.size} Vue public exports used as source of truth; native symbols covered by spec validation; ${guidance.length} guidance pages free of ${gone.length} removed symbols; ${documentedImports} documented imports resolve to published entries`);
