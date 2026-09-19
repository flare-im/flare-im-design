#!/usr/bin/env node
// DoD 41 gate — the final report is the one document a release decision is made
// from, so it must not drift:
//   1. it exists and states a verdict;
//   2. it names every gate release-check runs — a gate added without a line here
//      means the report understates what is (or is not) covered;
//   3. every outstanding manual-evidence id appears in it, so nothing that still
//      needs a device can be quietly dropped from the blocker list;
//   4. it links the per-topic documents rather than restating them.
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const reportPath = "docs/release/2.0-final-report.md";
const errors = [];

if (!existsSync(join(root, reportPath))) {
  console.error(`release report check failed:\n  ${reportPath}: missing`);
  process.exit(1);
}
const report = readFileSync(join(root, reportPath), "utf8");

// 1. A verdict, not a summary.
if (!/READY|rc\.2|stable/i.test(report)) {
  errors.push(`${reportPath}: states no verdict — say whether the candidate is READY, and if not, what it is`);
}

// 2. Every release-check gate is accounted for.
const releaseCheck = readFileSync(join(root, "tooling/release-check.mjs"), "utf8");
// Two spellings: the declared `checks` entries, and gates the runner pushes onto
// `results` itself (candidate-integrity). A full run of release:check reported 43
// named gates while this counted 42 — the pushed one was invisible here, which is
// exactly the drift this rule exists to catch.
const gates = [
  ...[...releaseCheck.matchAll(/^\s+\['([a-z0-9-]+)',/gm)].map((match) => match[1]),
  ...[...releaseCheck.matchAll(/results\.push\(\{\s*id:\s*'([a-z0-9-]+)'/g)].map((match) => match[1]),
];
if (!gates.length) errors.push("tooling/release-check.mjs: no gates found — the parser needs updating");
if (new Set(gates).size !== gates.length) errors.push("tooling/release-check.mjs: duplicate gate id");
const gateCount = gates.length;
if (!new RegExp(`${gateCount}\\s*项`).test(report) && !report.includes(`${gateCount} gates`)) {
  errors.push(`${reportPath}: does not state the release-check gate count (${gateCount})`);
}

// 3. Nothing that still needs a device drops off the blocker list.
const evidence = JSON.parse(readFileSync(join(root, "spec/manual-evidence.json"), "utf8"));
const outstanding = [...evidence.required, ...evidence.automated].filter((entry) => !entry.evidence);
for (const entry of outstanding) {
  if (!report.includes(entry.id)) {
    errors.push(`${reportPath}: outstanding evidence ${entry.id} is not named — an unmet gate must stay visible in the report`);
  }
}
if (outstanding.length && !/manual-evidence\.json/.test(report)) {
  errors.push(`${reportPath}: must point at spec/manual-evidence.json, the ledger those ids live in`);
}

// 4. The per-topic documents are linked, not restated.
for (const doc of [
  "2.0-gap-analysis.md",
  "public-api-2.0.md",
  "migration/2.0-rc-to-2.0.md",
  "performance.md",
  "security-boundary.md",
  "visual-baselines.md",
  "native-capability-matrix.md",
]) {
  if (!report.includes(doc)) errors.push(`${reportPath}: does not link ${doc}`);
  if (!existsSync(join(root, "docs/release", doc))) errors.push(`docs/release/${doc}: linked by the report but missing`);
}

if (errors.length) {
  console.error("release report check failed:\n  " + errors.join("\n  "));
  process.exit(1);
}
console.log(`release report passed: verdict stated, ${gateCount} release-check gates accounted for, ${outstanding.length} outstanding evidence id(s) still named`);
