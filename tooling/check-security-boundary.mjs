#!/usr/bin/env node
// DoD 32 gate — spec/security-boundary.json is the shared truth:
//   1. raw HTML comes from one renderer, and `v-html` appears only where the
//      contract allows it;
//   2. every component that navigates on its own resolves its href through the
//      URL gate (or builds it from parts it controls);
//   3. the four platforms define the gate and every one exercises every vector.
//
// The point is the first two: a new `v-html`, or a new `:href` bound straight to
// message content, is how this boundary is lost — quietly, in a diff about
// something else.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const contract = JSON.parse(readFileSync(join(root, "spec/security-boundary.json"), "utf8"));
const errors = [];
const read = (rel) => {
  try {
    return readFileSync(join(root, rel), "utf8");
  } catch {
    errors.push(`missing file: ${rel}`);
    return "";
  }
};

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) walk(path, out);
    else if (name.endsWith(".vue") || name.endsWith(".ts")) out.push(path);
  }
  return out;
}

// 1. Raw HTML.
const allowedRawHtml = new Set(contract.html.allowedRawHtml);
const vueRoot = join(root, "packages/vue-im-ui/src");
for (const file of walk(vueRoot)) {
  const rel = relative(root, file);
  if (rel.endsWith(".test.ts")) continue;
  const source = readFileSync(file, "utf8");
  if (!/\bv-html\b|\.innerHTML\s*=/.test(source)) continue;
  if (!allowedRawHtml.has(rel)) {
    errors.push(`${rel}: raw HTML outside the allow list — route message text through ${contract.html.renderer}, or add the file to spec/security-boundary.json with a reason`);
  }
}
for (const rel of allowedRawHtml) {
  const source = read(rel);
  if (source && !/\bv-html\b|\.innerHTML\s*=/.test(source)) {
    errors.push(`${rel}: allow-listed for raw HTML but no longer produces any — drop it from the list`);
  }
}

// The one renderer must keep markdown-it's HTML off.
const renderer = read(contract.html.renderer);
if (renderer && !/html:\s*false/.test(renderer)) {
  errors.push(`${contract.html.renderer}: markdown-it must be constructed with html: false`);
}

// 2. Components that navigate on their own.
const anchors = Object.entries(contract.anchors).filter(([key]) => key !== "note");
for (const file of walk(vueRoot)) {
  const rel = relative(root, file);
  if (rel.endsWith(".test.ts")) continue;
  const source = readFileSync(file, "utf8");
  if (!/:href=/.test(source)) continue;
  if (!contract.anchors[rel]) {
    errors.push(`${rel}: binds :href — a component that navigates on its own must be declared in spec/security-boundary.json#anchors with how it gates the URL`);
  }
}
for (const [rel, how] of anchors) {
  const source = read(rel);
  if (!source) continue;
  if (!/:href=/.test(source)) {
    errors.push(`${rel}: declared as an anchor but no longer binds :href — drop it from the list`);
  } else if (how === "safeExternalUrl" && !source.includes("safeExternalUrl")) {
    errors.push(`${rel}: declared to gate through safeExternalUrl but does not call it`);
  }
}

// 2b. Navigation built in script. Rule 2 reads templates only, so an anchor created
// with document.createElement("a") and clicked from TypeScript was invisible here —
// that is how a hostile image-group URL reached `<a href="javascript:…">.click()`
// (fixed 2026-09-14 in utils/browserDownload.ts). Every such site is declared with
// the function that gates its URL, and must call it.
const SCRIPTED_NAVIGATION = /createElement\(\s*["']a["']\s*\)|\.href\s*=[^=]|window\.open\s*\(|location\.(?:assign|replace)\s*\(/;
const scripted = contract.scriptedNavigation ?? {};
for (const file of walk(vueRoot)) {
  const rel = relative(root, file);
  if (rel.endsWith(".test.ts")) continue;
  if (!SCRIPTED_NAVIGATION.test(readFileSync(file, "utf8"))) continue;
  if (!scripted[rel]) errors.push(`${rel}: navigates or builds an anchor from script — declare it in spec/security-boundary.json#scriptedNavigation with the function that gates the URL`);
}
for (const [rel, gate] of Object.entries(scripted).filter(([key]) => key !== "note")) {
  const source = read(rel);
  if (!source) continue;
  if (!SCRIPTED_NAVIGATION.test(source)) errors.push(`${rel}: declared as scripted navigation but no longer navigates — drop it from the list`);
  else if (!source.includes(gate.split(" ")[0])) errors.push(`${rel}: declared to gate through ${gate.split(" ")[0]} but does not call it`);
}

// 3. The four gates and their vectors.
for (const [platform, entry] of Object.entries(contract.platforms)) {
  const module = read(entry.module);
  if (module && !module.includes(entry.symbol)) {
    errors.push(`${platform}: ${entry.module} does not define ${entry.symbol}`);
  }
  const test = read(entry.test);
  for (const vector of contract.urlVectors) {
    if (test && !test.includes(vector.id)) {
      errors.push(`${platform}: ${entry.test} never exercises vector ${vector.id}`);
    }
  }
}

if (errors.length) {
  console.error("security boundary check failed:\n  " + errors.join("\n  "));
  process.exit(1);
}
console.log(`security boundary passed: ${Object.keys(contract.platforms).length} url gates × ${contract.urlVectors.length} vectors, ${allowedRawHtml.size} raw-html sites, ${anchors.length} self-navigating components, ${Object.keys(scripted).filter((key) => key !== "note").length} scripted navigation sites`);
