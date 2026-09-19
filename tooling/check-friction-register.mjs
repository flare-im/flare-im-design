#!/usr/bin/env node
/**
 * The friction register's summary is recounted from its own rows.
 *
 * `docs/product/design-system-friction.md` opens with a sentence giving the entry count, the split by
 * priority and the split by resolution. Every round edits rows and then edits that sentence by hand,
 * and on 2026-09-18 the two had drifted: the sentence said 148 FIXED and 1 PARTIAL while the rows said
 * 149 FIXED and no PARTIAL at all — the last partial entry had been finished two rounds earlier and
 * nobody had recounted (FR-159). The feature matrix got this check in Round 10; the register did not.
 *
 * The rule is the matrix's rule: the first number in every cell of the summary is the rows' own count.
 * A status is the first word of an entry's resolution cell, so a cell that opens with "FIXED in Round 12
 * (D3); PARTIAL from Round 7 until then" counts as FIXED — history after the status, never before it.
 */
import { readFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const file = join(root, "docs/product/design-system-friction.md");
const text = readFileSync(file, "utf8");

const PRIORITIES = ["P0", "P1", "P2"];
const STATUSES = ["FIXED", "CLOSED", "DECIDED", "PARTIAL", "RE-TRIAGED", "OPEN"];

const rows = text.split("\n").filter((line) => line.startsWith("| FR-"));
const failures = [];
const priority = Object.fromEntries(PRIORITIES.map((p) => [p, 0]));
const status = Object.fromEntries(STATUSES.map((s) => [s, 0]));

for (const line of rows) {
  const cells = line.trim().replace(/^\||\|$/g, "").split("|").map((cell) => cell.trim());
  const id = cells[0];
  const rowPriority = cells[cells.length - 2];
  const resolution = cells[cells.length - 1];
  if (!PRIORITIES.includes(rowPriority)) {
    failures.push(`${id}: priority is "${rowPriority}", not one of ${PRIORITIES.join(" / ")}`);
  } else priority[rowPriority] += 1;

  const first = /^\*{0,2}([A-Z][A-Z-]+)/.exec(resolution)?.[1];
  if (!first || !STATUSES.includes(first)) {
    failures.push(`${id}: the resolution does not open with a status (${STATUSES.join(" / ")}): "${resolution.slice(0, 60)}"`);
  } else status[first] += 1;
}

/** The summary sentence, wherever it sits in section 2. */
const summary = text.split("\n").find((line) => /^\d+ entries: /.test(line));
if (!summary) {
  console.error(`friction register: no summary line ("<n> entries: …") in ${relative(root, file)}`);
  process.exit(1);
}

function claimed(pattern, label) {
  const match = pattern.exec(summary);
  if (!match) {
    failures.push(`the summary does not say how many are ${label}`);
    return null;
  }
  return Number(match[1]);
}

const totalClaim = claimed(/^(\d+) entries:/, "entries in total");
if (totalClaim !== null && totalClaim !== rows.length) {
  failures.push(`the summary says ${totalClaim} entries; the rows count ${rows.length}`);
}
for (const p of PRIORITIES) {
  const value = claimed(new RegExp(`(\\d+) ${p}\\b`), p);
  if (value !== null && value !== priority[p]) failures.push(`the summary says ${value} ${p}; the rows count ${priority[p]}`);
}
for (const s of STATUSES) {
  // A status with no entries need not be mentioned; one that is mentioned has to be right.
  const match = new RegExp(`(\\d+) ${s}\\b`).exec(summary);
  if (!match) {
    if (status[s]) failures.push(`the summary does not mention ${s}, which ${status[s]} entr${status[s] === 1 ? "y has" : "ies have"}`);
    continue;
  }
  if (Number(match[1]) !== status[s]) failures.push(`the summary says ${match[1]} ${s}; the rows count ${status[s]}`);
}

// "Nothing is left OPEN" is a claim like any other.
if (/Nothing is left OPEN/.test(summary) && status.OPEN) {
  failures.push(`the summary says nothing is left OPEN; the rows count ${status.OPEN} OPEN`);
}

if (failures.length) {
  console.error(`friction register check failed (${relative(root, file)}):`);
  for (const failure of failures) console.error(`  ${failure}`);
  console.error(`\n  The summary is a count of the rows, not a note kept beside them. Recount it.`);
  process.exit(1);
}
const spread = STATUSES.filter((s) => status[s]).map((s) => `${status[s]} ${s}`).join(", ");
console.log(`friction register passed: ${rows.length} entries, summary matches the rows (${spread})`);
