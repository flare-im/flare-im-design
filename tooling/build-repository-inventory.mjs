#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, lstatSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { extname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(fileURLToPath(new URL("..", import.meta.url)));
const output = join(root, "docs/repository-inventory.md");
const ignored = new Set([
  ".git", ".codegraph", ".build", ".build-xcode", ".dart_tool", ".gradle", ".kotlin", ".swiftpm",
  "node_modules", "build", "dist", "test-results", "playwright-report",
  // Release evidence output, gitignored for the same reason: writing evidence
  // during validation must not make the inventory it validates go stale.
  "artifacts",
]);
const textExtensions = new Set([
  ".css", ".dart", ".html", ".js", ".json", ".kt", ".kts", ".md", ".mjs",
  ".swift", ".ts", ".vue", ".xml", ".yaml", ".yml",
]);

// Paths git ignores on this checkout (collapsed to directories). The inventory must describe
// the repository, not one machine: locally fetched emoji/sticker webp mirrors, build caches
// and editor files would otherwise change the counts from one checkout to the next.
const gitIgnored = execFileSync(
  "git",
  ["ls-files", "--others", "--ignored", "--exclude-standard", "--directory", "-z"],
  { cwd: root, encoding: "utf8" },
).split("\0").filter(Boolean);
function isGitIgnored(rel) {
  return gitIgnored.some((entry) => (entry.endsWith("/") ? rel.startsWith(entry) : rel === entry));
}

function walk(path, files = []) {
  for (const name of readdirSync(path)) {
    const absolute = join(path, name);
    const rel = relative(root, absolute);
    if (absolute === output) continue;
    if (isGitIgnored(rel) || isGitIgnored(`${rel}/`)) continue;
    if (rel === "website/.vitepress/.temp") continue;
    // Vite dependency-optimizer cache: any website preview or Playwright run rewrites it
    // (deps_temp_*), so counting it made design-system go stale when release:check ran the
    // conversation visual gate first — a validation run invalidating its own inventory.
    if (rel === "website/.vitepress/cache") continue;
    if (rel.split("/").some((segment) => ignored.has(segment))) continue;
    const stat = lstatSync(absolute);
    if (stat.isSymbolicLink()) {
      files.push({ absolute, rel, bytes: stat.size, ext: extname(name), link: true });
    } else if (stat.isDirectory()) {
      walk(absolute, files);
    } else {
      files.push({ absolute, rel, bytes: stat.size, ext: extname(name), link: false });
    }
  }
  return files;
}

const files = walk(root);
const topItems = readdirSync(root)
  .filter((name) => ![".git", ".codegraph", ".build", "node_modules", ".DS_Store"].includes(name))
  .filter((name) => !isGitIgnored(name) && !isGitIgnored(`${name}/`))
  .sort();
const rules = [
  [/^tokens(?:\/|$)/, "SOURCE_OF_TRUTH / TOKENS", "Theme primitives, semantics, generators, and published output"],
  [/^spec(?:\/|$)/, "SOURCE_OF_TRUTH / SPEC", "Current component, interaction, accessibility, and scenario contracts"],
  [/^packages\/(?:vue|flutter|android|ios)-im-ui(?:\/|$)/, "PUBLIC_LIBRARY / PLATFORM", "Self-contained platform package, implementation, and tests"],
  [/^website(?:\/|$)/, "WEBSITE / DOCS", "VitePress catalog, live demos, search, and visual tests"],
  [/^examples(?:\/|$)/, "EXAMPLES / PATTERNS", "Runnable platform examples and shared gallery scenarios"],
  [/^tests\/visual(?:\/|$)/, "TESTS / VISUAL", "Cross-platform visual baselines and comparison contract"],
  [/^tests\/consumers(?:\/|$)/, "TESTS / RELEASE", "Outside-in package consumption fixtures"],
  [/^tooling(?:\/|$)/, "BUILD_TOOLING / RELEASE", "Generation, validation, visual, docs, and release gates"],
  [/^docs(?:\/|$)/, "DOCS", "Architecture, design-system, migration, testing, and release records"],
  [/^assets\/design-source(?:\/|$)/, "SOURCE_OF_TRUTH / DESIGN", "Editable design reference artifact"],
  [/^assets(?:\/|$)/, "PUBLIC_LIBRARY / ASSETS", "Shared runtime emoji and sticker assets"],
  [/^(README|CHANGELOG|COMPATIBILITY|CONTRIBUTING|PUBLIC_API|LICENSE)/, "DOCS / RELEASE", "Repository entry point or public maintenance contract"],
  [/^(package\.json|jitpack\.yml|\.github|\.gitignore)/, "BUILD_TOOLING / RELEASE", "Repository-wide orchestration and release configuration"],
];

function classify(path) {
  return rules.find(([pattern]) => pattern.test(path)) ?? [null, "UNKNOWN", "Requires maintainer review"];
}

function summary(path) {
  const prefix = `${path}/`;
  const members = files.filter((file) => file.rel === path || file.rel.startsWith(prefix));
  const bytes = members.reduce((sum, file) => sum + file.bytes, 0);
  return `${members.length} files / ${(bytes / 1024).toFixed(1)} KiB`;
}

const rows = topItems.map((path) => {
  const [, category, purpose] = classify(path);
  const publicSurface = category.includes("PUBLIC_LIBRARY") || /README|PUBLIC_API|COMPATIBILITY/.test(path);
  const risk = category === "UNKNOWN" ? "REVIEW_REQUIRED" : category.includes("SOURCE_OF_TRUTH") || category.includes("PUBLIC_LIBRARY") ? "High" : "Medium";
  return `| \`${path}\` | ${category} | ${purpose}; ${summary(path)} | ${publicSurface ? "yes" : "no"} | ${risk} | Keep at its current ownership boundary |`;
});

const large = files
  .filter((file) => !file.link && textExtensions.has(file.ext) && file.bytes < 2_000_000)
  .map((file) => ({ ...file, lines: readFileSync(file.absolute, "utf8").split("\n").length }))
  .filter((file) => file.lines > 500)
  .sort((a, b) => b.lines - a.lines);
const largeRows = large.map((file) => {
  const threshold = file.lines > 1000 ? ">1000" : file.lines > 800 ? ">800" : ">500";
  return `| \`${file.rel}\` | ${file.lines} | ${threshold} | Review responsibilities; do not split by size alone |`;
});

const noise = files.filter((file) => /\.(?:bak|old|tmp|orig)$/.test(file.rel) || /(?:^|\/)(?:debug|scratch|temp)(?:\/|\.|-)/i.test(file.rel));
const hashes = new Map();
for (const file of files.filter((item) => !item.link && item.bytes > 0 && item.bytes < 1_000_000 && textExtensions.has(item.ext))) {
  const hash = createHash("sha256").update(readFileSync(file.absolute)).digest("hex");
  const group = hashes.get(hash) ?? [];
  group.push(file.rel);
  hashes.set(hash, group);
}
const duplicates = [...hashes.values()].filter((group) => group.length > 1 && !group.every((path) => /(?:package-lock|pubspec\.lock)/.test(path)));

const markdown = `# Repository Inventory

This inventory is generated by \`tooling/build-repository-inventory.mjs\`. It records ownership rather than optimizing for file count. Build caches and generated distribution folders are excluded.

## Major paths

| Path | Category | Purpose | Public? | Risk | Recommendation |
|---|---|---|:---:|---|---|
${rows.join("\n")}

## Current architecture

| Path | Decision | Rule |
|---|---|---|
| \`tokens/\`, \`spec/\` | Keep | Authoritative current-state contracts; generated outputs remain colocated with their source |
| \`packages/{vue,flutter,android,ios}-im-ui/\` | Keep | Each platform package is self-contained; there is no extra platform directory or root forwarding package |
| \`examples/\` | Keep | Runnable platform examples and shared gallery scenarios are distinct from release fixtures |
| \`website/\` | Keep | VitePress is the component catalog and live design-system reference |
| \`tooling/\` | Keep | Every long-lived script belongs to generation, validation, visual, docs, or release tooling |
| Deprecated roots and adapters | Removed | Current contracts are updated directly; history belongs in changelogs |

## File responsibility audit

Line count is a review signal, not a refactoring instruction.

| Path | Lines | Threshold | Recommendation |
|---|---:|---|---|
${largeRows.length ? largeRows.join("\n") : "| - | - | - | No files above 500 lines |"}

## Noise audit

${noise.length ? noise.map((file) => `- REVIEW_REQUIRED: \`${file.rel}\``).join("\n") : "No temporary or backup artifacts found."}

Exact duplicate text groups found: **${duplicates.length}**. Generated resources and bilingual fixtures can be intentionally identical and still require ownership review.
${duplicates.slice(0, 20).map((group) => `- ${group.map((path) => `\`${path}\``).join(" = ")}`).join("\n")}
`;

if (process.argv.includes("--check")) {
  if (!existsSync(output) || readFileSync(output, "utf8") !== markdown) {
    console.error("repository inventory is stale; run node tooling/build-repository-inventory.mjs");
    process.exit(1);
  }
  console.log(`repository inventory current: ${topItems.length} major paths, ${files.length} files`);
} else {
  writeFileSync(output, markdown);
  console.log(`repository inventory written: ${topItems.length} major paths, ${files.length} files`);
}
