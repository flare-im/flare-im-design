#!/usr/bin/env node
// feature matrix — docs/product/im-feature-matrix.md grades 135 IM features across seven columns and sums them in a
// Tally table. Nothing tied the two together: rounds 6 to 8 moved rows without moving the table, and it fell behind by
// up to nine cells per column before anyone noticed. This gate recounts the rows and holds each row to the
// matrix's own written rules:
//   * every status cell uses the vocabulary (C, P, M, NS, NA);
//   * the Tally's current figures (the first number in each cell) are the rows' own count, and "N features per
//     column" is the number of rows;
//   * Result is the weakest of SDK, Design System, Web and iOS by the Result rule;
//   * Blocking layer is "—" exactly when Result is C, and otherwise names known layers, lowest first.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const path = process.argv[2] ?? join(root, "docs/product/im-feature-matrix.md");
const text = readFileSync(path, "utf8");
const errors = [];

const section = (start, end) => {
  const from = text.indexOf(`\n## ${start}\n`);
  const to = text.indexOf(`\n## ${end}\n`, from + 1);
  if (from < 0 || to < 0) throw new Error(`${path}: sections "## ${start}" and "## ${end}" not found`);
  return text.slice(from, to);
};
const cells = (line) => line.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").map((cell) => cell.trim());

const STATUSES = ["C", "P", "M", "NS", "NA"];
const COLUMNS = ["SDK", "Design System", "Web", "Tauri", "Flutter", "iOS", "Android", "Result"];
const HEADER = ["Feature", ...COLUMNS, "Blocking layer", "Tests", "Evidence / note"];
const LAYERS = ["SERVER", "SDK", "PLATFORM", "DESIGN_SYSTEM", "APP"];

// ── the rows ────────────────────────────────────────────────────────────────
const rows = [];
let header = null;
let group = "";
for (const line of section("Feature matrix", "Tally").split("\n")) {
  if (line.startsWith("### ")) { group = line.slice(4).trim(); header = null; continue; }
  if (!line.startsWith("|")) continue;
  const row = cells(line);
  if (row[0] === "Feature") {
    header = row;
    if (row.join("|") !== HEADER.join("|")) errors.push(`${group}: the table header is not ${HEADER.join(" | ")}`);
    continue;
  }
  if (row.every((cell) => /^-+$/.test(cell))) continue;
  if (!header) { errors.push(`${group}: a row outside a table: ${line.slice(0, 60)}`); continue; }
  if (row.length !== HEADER.length) { errors.push(`${group} / ${row[0]}: ${row.length} cells, expected ${HEADER.length}`); continue; }
  const record = { group, feature: row[0], blocking: row[9] };
  COLUMNS.forEach((column, index) => { record[column] = row[index + 1]; });
  rows.push(record);
}

// ── vocabulary, Result rule, Blocking layer rule ─────────────────────────────
const strength = { M: 0, NS: 1, P: 2, C: 3 };
/** The matrix's Result rule, as written under "Result rule". */
function expectedResult(row) {
  const appNotSupported = row.Web === "NS" || row.iOS === "NS";
  const counted = [];
  for (const column of ["SDK", "Design System", "Web", "iOS"]) {
    let status = row[column];
    if (status === "NA") continue;
    // An app NS caused by the SDK is NS only when the SDK column is M (which then counts as NS too); else it counts as P.
    if ((column === "Web" || column === "iOS") && status === "NS") status = row.SDK === "M" ? "NS" : "P";
    if (column === "SDK" && status === "M" && appNotSupported) status = "NS";
    counted.push(status);
  }
  return counted.reduce((weakest, status) => (strength[status] < strength[weakest] ? status : weakest), "C");
}

for (const row of rows) {
  const at = `${row.group} / ${row.feature}`;
  const bad = COLUMNS.filter((column) => !STATUSES.includes(row[column]));
  if (bad.length) { errors.push(`${at}: ${bad.map((column) => `${column} "${row[column]}"`).join(", ")} is not one of ${STATUSES.join(", ")}`); continue; }
  const result = expectedResult(row);
  if (row.Result !== result) errors.push(`${at}: Result is ${row.Result}, but the Result rule over SDK ${row.SDK}, Design System ${row["Design System"]}, Web ${row.Web} and iOS ${row.iOS} gives ${result}`);
  if (row.blocking === "—") {
    if (row.Result !== "C") errors.push(`${at}: Result is ${row.Result}, so Blocking layer must name what keeps it below C, not "—"`);
  } else {
    const layers = row.blocking.split(",").map((layer) => layer.trim());
    const unknown = layers.filter((layer) => !LAYERS.includes(layer));
    if (unknown.length) errors.push(`${at}: Blocking layer ${unknown.join(", ")} is not one of ${LAYERS.join(", ")}`);
    else if (layers.some((layer, index) => index > 0 && LAYERS.indexOf(layer) <= LAYERS.indexOf(layers[index - 1]))) errors.push(`${at}: Blocking layer "${row.blocking}" is not lowest first (${LAYERS.join(", ")}) without repeats`);
    if (row.Result === "C") errors.push(`${at}: Result is C, so Blocking layer must be "—", not "${row.blocking}"`);
  }
}

// ── the Tally ───────────────────────────────────────────────────────────────
const tally = section("Tally", "Top gaps by blocking layer");
const declared = /(\d+) features per column\./.exec(tally);
if (!declared) errors.push(`Tally: no "N features per column." sentence`);
else if (Number(declared[1]) !== rows.length) errors.push(`Tally says ${declared[1]} features per column; the matrix has ${rows.length} rows`);
const counted = Object.fromEntries(COLUMNS.map((column) => [column, Object.fromEntries(STATUSES.map((status) => [status, rows.filter((row) => row[column] === status).length]))]));
const tallied = new Set();
for (const line of tally.split("\n")) {
  if (!line.startsWith("|")) continue;
  const row = cells(line);
  if (row[0] === "Column") {
    if (row.slice(1).join("|") !== STATUSES.join("|")) errors.push(`Tally: header must be Column | ${STATUSES.join(" | ")}`);
    continue;
  }
  if (!COLUMNS.includes(row[0])) continue;
  tallied.add(row[0]);
  STATUSES.forEach((status, index) => {
    const figure = /^(\d+)/.exec(row[index + 1] ?? "");
    if (!figure) { errors.push(`Tally ${row[0]} ${status}: "${row[index + 1]}" does not start with the current figure`); return; }
    const count = counted[row[0]][status];
    if (Number(figure[1]) !== count) errors.push(`Tally ${row[0]} ${status} says ${figure[1]}; the rows count ${count}`);
  });
}
for (const column of COLUMNS) if (!tallied.has(column)) errors.push(`Tally: no row for ${column}`);

if (errors.length) {
  console.error(`feature matrix check failed (${path}):\n  ${errors.join("\n  ")}`);
  process.exit(1);
}
const result = counted.Result;
console.log(`feature matrix passed: ${rows.length} features, Tally matches the rows in ${COLUMNS.length} columns, every Result follows the Result rule (Result C ${result.C} · P ${result.P} · M ${result.M} · NS ${result.NS})`);
