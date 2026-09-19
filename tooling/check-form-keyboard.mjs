#!/usr/bin/env node
// DoD 20 gate — spec/form-keyboard-contract.json is the shared truth:
//   1. every platform defines resolveFormKeyboardIntent;
//   2. every platform test exercises every vector id;
//   3. the IME guard short-circuits before any key is classified, on all four —
//      an implementation that classifies Tab first would move focus out from
//      under a half-typed word;
//   4. a composer decides through the contract instead of reading the
//      composition flag itself, which is how the rule drifts per platform.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const contract = JSON.parse(readFileSync(join(root, "spec/form-keyboard-contract.json"), "utf8"));
const errors = [];
const read = (rel) => {
  try {
    return readFileSync(join(root, rel), "utf8");
  } catch {
    errors.push(`missing file: ${rel}`);
    return "";
  }
};

for (const [platform, entry] of Object.entries(contract.platforms)) {
  const module = read(entry.module);
  if (module && !module.includes(entry.symbol)) {
    errors.push(`${platform}: ${entry.module} does not define ${entry.symbol}`);
  }
  // The composing guard must come first. Match the guard *statement* (not the
  // parameter of the same name, which always sits earlier) against the Tab
  // branch: whichever appears first is the one that decides.
  if (module) {
    const guard = module.search(/if\s*\(?\s*(?:input\.)?composing\s*\)?\s*(?:\{\s*)?return/);
    const tab = module.search(/if\s*\(?\s*(?:normalized|key)\s*={2,3}\s*["']tab["']/);
    if (guard < 0) errors.push(`${platform}: ${entry.module} has no composing guard`);
    else if (tab >= 0 && tab < guard) {
      errors.push(`${platform}: ${entry.module} classifies Tab before the composing guard — the IME must win`);
    }
  }

  const test = read(entry.test);
  for (const vector of contract.vectors) {
    if (test && !test.includes(vector.id)) {
      errors.push(`${platform}: ${entry.test} never exercises vector ${vector.id}`);
    }
  }
}

// A composer that reads the composition flag itself has left the contract.
for (const [platform, entry] of Object.entries(contract.composers)) {
  if (platform === "note") continue;
  const source = read(entry.file);
  // Not just "mentions the contract": the send decision itself must be the
  // contract's `submit` intent.
  if (source && !/resolveFormKeyboardIntent[\s\S]{0,240}?[sS]ubmit/.test(source)) {
    errors.push(`${platform}: ${entry.file} decides Enter on its own — the send path must compare resolveFormKeyboardIntent to the submit intent`);
  }
  const test = read(entry.test);
  if (test && !/composing|isComposing|229/.test(test)) {
    errors.push(`${platform}: ${entry.test} never proves the send path refuses a composing Enter`);
  }
}

if (errors.length) {
  console.error("form keyboard contract check failed:\n  " + errors.join("\n  "));
  process.exit(1);
}
const platforms = Object.keys(contract.platforms).length;
const composers = Object.keys(contract.composers).length - 1;
console.log(`form keyboard contract passed: ${platforms} platforms × ${contract.vectors.length} vectors, ${composers} composers route through the contract`);
