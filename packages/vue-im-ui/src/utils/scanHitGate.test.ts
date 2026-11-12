import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { FlareScanHitGate, type FlareScanHit } from "./scanHitGate";
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/scan-gate-vectors.json"), "utf8"));
function compact(hit: FlareScanHit) {
  if (hit.kind === "lock") return { kind: hit.kind, raw: hit.code.raw, ready: hit.ready };
  if (hit.kind === "choose") return { kind: hit.kind, raws: hit.codes.map(code => code.raw) };
  return hit;
}
describe("scan arbitration shared vectors", () => {
  for (const vector of vectors.cases) it(vector.name, () => {
    const gate = new FlareScanHitGate();
    for (const step of vector.steps) {
      if (step.dismiss) { gate.dismiss(); continue; }
      const result = step.select !== undefined ? gate.select(step.select) : gate.observe({ codes: step.codes.map((raw: string) => ({ raw })), tsMs: step.tsMs });
      expect(compact(result)).toEqual(step.expect);
    }
  });
});
