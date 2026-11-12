import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { platformContractIssues } from "./platform-contracts.mjs";
const platforms = ["vue", "flutter", "ios", "compose"];
test("the actual Vue-only scan drop zone explicitly excludes native HTML drag/drop", () => {
  const spec = JSON.parse(readFileSync(new URL("./components.json", import.meta.url), "utf8"));
  const component = spec.components.find(value => value.name === "ScanDropZone");
  assert.deepEqual(platformContractIssues(component, platforms), { errors: [], missing: [] });
});
test("N/A cannot conceal incomplete, contradictory or unknown implementation bindings", () => {
  const reason = "Native capture uses the operating system's own image picker instead of HTML drag and drop.";
  assert.equal(platformContractIssues({ platforms: { flutter: { package: "kit" } } }, platforms).errors.length, 1);
  assert.equal(platformContractIssues({ platforms: { flutter: { package: "kit", symbol: "Drop" } }, notApplicablePlatforms: { flutter: reason } }, platforms).errors.length, 1);
  assert.equal(platformContractIssues({ notApplicablePlatforms: { flutter: "skip", unknown: reason } }, platforms).errors.length, 2);
  assert.deepEqual(platformContractIssues({}, platforms).missing, platforms);
});
