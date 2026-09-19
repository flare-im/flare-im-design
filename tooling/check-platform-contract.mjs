#!/usr/bin/env node
// Layer 5 gate — spec/platform-contract.json is the shared truth:
//   1. every platform module exists and defines the declared symbols;
//   2. every platform contract test exercises every vector id (operation × outcome);
//   3. no component branches on platform identity outside the allow-listed modules.
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const contract = JSON.parse(readFileSync(join(root, "spec/platform-contract.json"), "utf8"));
const errors = [];

const SYMBOL_PATTERNS = {
  vue: (symbol) => new RegExp(`export (?:function|const|interface|type|class) ${symbol}\\b`),
  flutter: (symbol) => new RegExp(`(?:class|enum|sealed class|abstract class|abstract final class)\\s+${symbol}\\b|^[A-Za-z<>?,\\s]+ ${symbol}<?[A-Za-z]*>?\\(`, "m"),
  compose: (symbol) => new RegExp(`(?:class|interface|object|fun|val)\\s+(?:<[^>]+>\\s+)?${symbol}\\b`),
  ios: (symbol) => new RegExp(`(?:struct|class|enum|protocol|typealias|func)\\s+${symbol}\\b`),
};

for (const [platform, entry] of Object.entries(contract.platforms)) {
  const modulePath = join(root, entry.module);
  if (!existsSync(modulePath)) { errors.push(`${platform}: module missing ${entry.module}`); continue; }
  // A module may be one file or a directory (Vue splits contract / adapter / hooks).
  const source = statSync(modulePath).isDirectory()
    ? readdirSync(modulePath).filter((name) => !/\.test\./.test(name)).map((name) => readFileSync(join(modulePath, name), "utf8")).join("\n")
    : readFileSync(modulePath, "utf8");
  for (const symbol of entry.symbols) {
    if (!SYMBOL_PATTERNS[platform](symbol).test(source)) errors.push(`${platform}: ${entry.module} does not define ${symbol}`);
  }
  const testPath = join(root, entry.test);
  if (!existsSync(testPath)) { errors.push(`${platform}: contract test missing ${entry.test}`); continue; }
  const test = readFileSync(testPath, "utf8");
  for (const vector of contract.vectors) {
    if (!test.includes(vector.id)) errors.push(`${platform}: ${entry.test} does not exercise vector ${vector.id}`);
  }
  for (const code of contract.errorCodes) {
    const spelled = platform === "vue" || platform === "compose" ? code : code.toLowerCase().replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    if (!test.includes(spelled)) errors.push(`${platform}: ${entry.test} never asserts error code ${code}`);
  }
}

// Capability lint: platform sniffing stays inside the platform modules.
const SCAN = [
  { dir: "packages/vue-im-ui/src", ext: [".ts", ".vue"] },
  { dir: "packages/flutter-im-ui/lib", ext: [".dart"] },
  { dir: "packages/android-im-ui/src/main", ext: [".kt"] },
  { dir: "packages/ios-im-ui/Sources", ext: [".swift"] },
];
function walk(dir, ext, out = []) {
  if (!existsSync(dir)) return out;
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) walk(path, ext, out);
    else if (ext.some((e) => name.endsWith(e)) && !/\.test\.ts$/.test(name)) out.push(path);
  }
  return out;
}
const allow = contract.sniffLint.allow.map((prefix) => join(root, prefix));
for (const { dir, ext } of SCAN) {
  for (const file of walk(join(root, dir), ext)) {
    if (allow.some((prefix) => file.startsWith(prefix))) continue;
    const source = readFileSync(file, "utf8");
    for (const pattern of contract.sniffLint.patterns) {
      if (source.includes(pattern)) errors.push(`platform sniffing outside the platform module: ${relative(root, file)} uses ${pattern}`);
    }
  }
}

if (errors.length) {
  console.error("platform contract check failed:\n  " + errors.join("\n  "));
  process.exit(1);
}
console.log(`platform contract passed: ${Object.keys(contract.platforms).length} platforms × ${contract.vectors.length} vectors, ${contract.errorCodes.length} error codes, capability lint clean`);
