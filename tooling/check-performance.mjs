#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const contract = JSON.parse(readFileSync(join(root, "spec/performance-contract.json"), "utf8"));
const errors = [];
for (const [name, proof] of Object.entries(contract.platformProof)) {
  let source = "";
  try { source = readFileSync(join(root, proof.path), "utf8"); }
  catch { errors.push(`${name}: missing ${proof.path}`); continue; }
  for (const term of proof.terms) if (!source.includes(term)) errors.push(`${name}: missing proof term ${term}`);
}
for (const required of ["conversation1k", "conversation10k", "message10k", "message100kEstimated", "manyImages", "uploadQueue"]) {
  if (!contract.scenarios[required]?.budget) errors.push(`${required}: missing performance budget`);
}

// Source terms prove a lazy container exists; they cannot prove it engages. The
// numeric half lives in measuredBudgets and is checked by
// website/tests/performance-budget.spec.ts, which mounts the real load.
const measured = contract.measuredBudgets ?? {};
for (const [name, required] of [
  ["conversationList", ["items", "maxRenderedRows", "windows"]],
  ["messageList", ["items", "maxNodesPerRow", "hostMaxLoadedMessages", "windows"]],
  ["mount", ["maxMs"]],
]) {
  const budget = measured[name];
  if (!budget) { errors.push(`measuredBudgets.${name}: missing`); continue; }
  for (const field of required) {
    if (budget[field] === undefined) errors.push(`measuredBudgets.${name}.${field}: missing`);
  }
  if (budget.windows === false && !budget.why) {
    errors.push(`measuredBudgets.${name}: a component that does not window must say why`);
  }
}
if (errors.length) {
  console.error("performance contract errors:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`performance passed: ${Object.keys(contract.scenarios).length} scenarios, ${Object.keys(contract.platformProof).length} platform proofs, ${Object.keys(measured).length - 1} measured budgets`);
