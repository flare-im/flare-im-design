#!/usr/bin/env node
import { existsSync, lstatSync, readFileSync, readdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { dirname, extname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const errors = [];
function walk(path) {
  for (const entry of readdirSync(path)) {
    if ([".git", ".codegraph", ".build", "node_modules"].includes(entry)) continue;
    const absolute = join(path, entry);
    const stat = lstatSync(absolute);
    if (stat.isSymbolicLink()) continue;
    if (stat.isDirectory()) walk(absolute);
    else if ([".bak", ".old", ".tmp", ".orig"].includes(extname(entry))) errors.push(relative(root, absolute));
  }
}
walk(root);
for (const path of [
  "site", "scripts", "consumer-fixtures", "visual-regression", "design-assets", "gallery",
  "vue-im-ui", "flutter-im-ui", "android-im-ui", "ios-im-ui", "Package.swift", "prototypes",
]) {
  if (existsSync(join(root, path))) errors.push(path);
}

const activeRoots = [".github", "examples", "packages", "spec", "tests", "tokens", "tooling", "website"];
const activeExtensions = new Set([".css", ".dart", ".html", ".js", ".json", ".kt", ".kts", ".mjs", ".mts", ".swift", ".ts", ".vue", ".yaml", ".yml"]);
const forbiddenReferences = [
  /flare-core-packages\/vue-im-ui/,
  /(?:^|["'`(\s])(?:site|consumer-fixtures|visual-regression|design-assets)\//m,
  /packages\/flutter-im-ui\/example\//,
  /(?:^|["'`(\s])(?:\.\.\/)+(?:vue-im-ui|flutter-im-ui|android-im-ui|ios-im-ui)\//m,
];
function scan(path) {
  for (const entry of readdirSync(path)) {
    if (["node_modules", "dist", "build", "cache", ".build", ".dart_tool", ".gradle"].includes(entry)) continue;
    const absolute = join(path, entry);
    const stat = lstatSync(absolute);
    if (stat.isSymbolicLink()) continue;
    if (stat.isDirectory()) scan(absolute);
    else if (activeExtensions.has(extname(entry))) {
      const text = readFileSync(absolute, "utf8");
      if (forbiddenReferences.some((pattern) => pattern.test(text))) errors.push(`${relative(root, absolute)}: old path/import reference`);
    }
  }
}
for (const path of activeRoots) scan(join(root, path));
const trackedBuildOutput = execFileSync("git", ["ls-files", "website/.vitepress/dist"], { cwd: root, encoding: "utf8" }).trim();
if (trackedBuildOutput) errors.push(...trackedBuildOutput.split("\n"));
if (errors.length) {
  console.error("legacy/temporary paths found:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log("legacy path check passed: no superseded prototype, build output, or temporary artifact paths");
