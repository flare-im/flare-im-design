#!/usr/bin/env node
/** Validate package ownership and the release version shared by the UI kit. */

import { existsSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const problems = [];

function jsonVersion(relativePath) {
  const file = join(root, relativePath);
  if (!existsSync(file)) {
    problems.push(`${relativePath} is missing.`);
    return null;
  }
  return JSON.parse(readFileSync(file, "utf8")).version ?? null;
}

function androidVersion() {
  const relativePath = "packages/android-im-ui/build.gradle.kts";
  const file = join(root, relativePath);
  if (!existsSync(file)) {
    problems.push(`${relativePath} is missing.`);
    return null;
  }
  return readFileSync(file, "utf8").match(/^version\s*=\s*"([^"]+)"/m)?.[1] ?? null;
}

if (existsSync(join(root, "Package.swift"))) {
  problems.push("Package.swift must live in packages/ios-im-ui, not at repository root.");
}

for (const relativePath of [
  "packages/ios-im-ui/Package.swift",
  "packages/ios-im-ui/Sources",
  "packages/ios-im-ui/Tests",
]) {
  const target = join(root, relativePath);
  if (!existsSync(target)) {
    problems.push(`${relativePath} is required for the self-contained Swift package.`);
  } else if (!relativePath.endsWith(".swift") && !statSync(target).isDirectory()) {
    problems.push(`${relativePath} must be a directory.`);
  }
}

const swiftManifest = join(root, "packages/ios-im-ui/Package.swift");
if (existsSync(swiftManifest)) {
  const source = readFileSync(swiftManifest, "utf8");
  for (const fragment of ['name: "FlareIMUI"', '.library(name: "FlareIMUI"']) {
    if (!source.includes(fragment)) problems.push(`Swift manifest is missing ${fragment}.`);
  }
}

const jitpack = join(root, "jitpack.yml");
if (!existsSync(jitpack)) {
  problems.push("jitpack.yml is required at repository root by the JitPack protocol.");
} else if (!readFileSync(jitpack, "utf8").includes("packages/android-im-ui")) {
  problems.push("jitpack.yml must build packages/android-im-ui.");
}

const versions = new Map([
  ["workspace", jsonVersion("package.json")],
  ["Vue", jsonVersion("packages/vue-im-ui/package.json")],
  ["tokens", jsonVersion("tokens/package.json")],
  ["spec", jsonVersion("spec/package.json")],
  ["Android", androidVersion()],
]);
const resolvedVersions = [...versions.values()].filter(Boolean);
if (resolvedVersions.length !== versions.size) {
  problems.push("Every versioned package must declare a version.");
} else if (new Set(resolvedVersions).size !== 1) {
  problems.push(
    `Release versions differ: ${[...versions]
      .map(([name, version]) => `${name}=${version}`)
      .join(", ")}.`,
  );
}

console.log("UI kit release contract:");
for (const [name, version] of versions) console.log(`  ${name.padEnd(12)} ${version ?? "missing"}`);
console.log("  Swift        self-contained source package (packages/ios-im-ui)");

if (problems.length) {
  console.error("\nDistribution contract failed:");
  for (const problem of problems) console.error(`  - ${problem}`);
  process.exit(1);
}

console.log("\nDistribution contract passed.");
