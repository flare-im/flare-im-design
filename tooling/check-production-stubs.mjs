#!/usr/bin/env node
// stub-check (docs/release/2.0-release-criteria.md §1 and §6): production source of the
// four kits carries no TODO / FIXME / HACK marker, no not-implemented body and no
// mock / stub / fake code. Tests, previews (design-time sample data) and prose that
// merely uses the word ("never fake an empty list") are not production code.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const roots = [
  ["packages/vue-im-ui/src", [".ts", ".vue"]],
  ["packages/flutter-im-ui/lib", [".dart"]],
  ["packages/android-im-ui/src/main", [".kt"]],
  ["packages/ios-im-ui/Sources", [".swift"]],
  ["tokens", [".mjs", ".js", ".ts"]],
];
const skipDirectories = new Set(["node_modules", "dist", "build", ".build", ".dart_tool", "Resources", "__tests__"]);
const isTest = (name) => /\.(test|spec)\.[jt]s$/.test(name) || /Tests?\.(kt|swift)$/.test(name) || /_test\.dart$/.test(name);
const isPreview = (path) => /(^|\/)Previews\.(kt|swift)$/.test(path);
const MARKER = /\b(TODO|FIXME|HACK|XXX)\b/; // case-sensitive: a marker, not the English word
// A body that refuses to run — not code that classifies such an error from a platform call.
const NOT_IMPLEMENTED = /\bthrow\s+(?:new\s+)?(?:NotImplementedError|UnimplementedError)\b|\bnotImplemented\s*\(|\bTODO\(\s*(?:"[^"]*")?\s*\)|fatalError\(\s*"(?:not implemented|unimplemented)/i;
const STUB_CODE = /\b(mock|stub|fake)(?:[A-Z_]\w*)?\b\s*[:=(<]|\b(?:Mock|Stub|Fake)[A-Z]\w*\b/;

function walk(dir, extensions, files = []) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) { if (!skipDirectories.has(name)) walk(path, extensions, files); }
    else if (extensions.some((extension) => name.endsWith(extension)) && !isTest(name)) files.push(path);
  }
  return files;
}

const errors = [];
let scanned = 0;
for (const [dir, extensions] of roots) {
  for (const file of walk(join(root, dir), extensions)) {
    const path = relative(root, file);
    if (isPreview(path)) continue;
    scanned += 1;
    readFileSync(file, "utf8").split("\n").forEach((line, index) => {
      const comment = /^\s*(\/\/|\*|\/\*|#|<!--)/.test(line);
      if (MARKER.test(line)) errors.push(`${path}:${index + 1}: marker ${line.trim().slice(0, 120)}`);
      else if (NOT_IMPLEMENTED.test(line)) errors.push(`${path}:${index + 1}: not implemented ${line.trim().slice(0, 120)}`);
      else if (!comment && STUB_CODE.test(line)) errors.push(`${path}:${index + 1}: stub code ${line.trim().slice(0, 120)}`);
    });
  }
}
if (errors.length) {
  console.error("production stub check failed:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`production stub check passed: ${scanned} production source files, 0 TODO/FIXME/HACK markers, 0 not-implemented bodies, 0 mock/stub/fake code`);
