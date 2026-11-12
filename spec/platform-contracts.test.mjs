import assert from "node:assert/strict";
import { test } from "node:test";
import { platformContractIssues } from "./platform-contracts.mjs";
const platforms = ["vue", "flutter", "ios", "compose"];
test("a Vue-only component that names why each native platform does not apply is complete", () => {
  const reason = "HTML image drop is a web host capability.";
  const component = { platforms: { vue: { package: "@flare-im/vue-ui", symbol: "FlareDropZone" } }, notApplicablePlatforms: { flutter: reason, ios: reason, compose: reason } };
  assert.deepEqual(platformContractIssues(component, platforms), { errors: [], missing: [] });
});
test("N/A cannot conceal incomplete, contradictory or unknown implementation bindings", () => {
  const reason = "Native capture uses the operating system's own image picker instead of HTML drag and drop.";
  assert.equal(platformContractIssues({ platforms: { flutter: { package: "kit" } } }, platforms).errors.length, 1);
  assert.equal(platformContractIssues({ platforms: { flutter: { package: "kit", symbol: "Drop" } }, notApplicablePlatforms: { flutter: reason } }, platforms).errors.length, 1);
  assert.equal(platformContractIssues({ notApplicablePlatforms: { flutter: "skip", unknown: reason } }, platforms).errors.length, 2);
  assert.deepEqual(platformContractIssues({}, platforms).missing, platforms);
});
