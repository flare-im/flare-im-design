#!/usr/bin/env node
import { existsSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const allowedDirectories = new Set([
  ".git", ".github", "assets", "docs", "examples",
  "node_modules", "packages", "spec", "strings", "tests", "tokens", "tooling", "website",
  // Gitignored release evidence output (see docs/repository-scope.md); like
  // node_modules it may exist on disk but is never part of the candidate.
  "artifacts",
  // Gitignored editor/agent configuration; never part of the candidate.
  ".claude",
]);
const allowedFiles = new Set([
  ".gitignore", "CHANGELOG.md", "CHANGELOG.zh-CN.md", "COMPATIBILITY.md", "CONTRIBUTING.md",
  "LICENSE", "PUBLIC_API.md", "README.md", "README.zh-CN.md", "jitpack.yml", "package-lock.json", "package.json",
]);
const required = [
  "packages/vue-im-ui/package.json",
  "packages/flutter-im-ui/pubspec.yaml",
  "packages/android-im-ui/build.gradle.kts",
  "packages/ios-im-ui/Package.swift",
  "tokens/tokens.json",
  "tokens/themes.json",
  "spec/components.json",
  "spec/component-catalog.json",
  "website/package.json",
  "docs/repository-scope.md",
];
const errors = [];
for (const entry of readdirSync(root, { withFileTypes: true })) {
  if (entry.name === ".DS_Store") errors.push("remove root .DS_Store");
  else if (entry.isDirectory() && !allowedDirectories.has(entry.name)) errors.push(`unknown top-level directory: ${entry.name}`);
  else if (entry.isFile() && !allowedFiles.has(entry.name)) errors.push(`unknown top-level file: ${entry.name}`);
}
for (const path of required) if (!existsSync(join(root, path))) errors.push(`missing required scope path: ${path}`);
if (errors.length) {
  console.error("repository scope violations:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`repository scope passed: ${allowedDirectories.size} allowed directories and ${required.length} required anchors`);
