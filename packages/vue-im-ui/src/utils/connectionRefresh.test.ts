import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { FlareConnectionRefresh, type FlareReconnectWork } from "./connectionRefresh";
import type { FlareConnectionPhase } from "./connectionNotice";

/**
 * The shared reconnect table (`spec/reconnect-refresh-vectors.json`): connection phases in, the work the
 * transition creates out. The Flutter, SwiftUI and Compose kits run the same file.
 */
type Case = { name: string; phases: FlareConnectionPhase[]; expect: FlareReconnectWork[] };
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/reconnect-refresh-vectors.json"), "utf8")) as {
  cases: Case[];
};

describe("what a client owes the server when the connection comes back", () => {
  for (const vector of table.cases) {
    it(vector.name, () => {
      const refresh = new FlareConnectionRefresh();
      expect(vector.phases.map((phase) => refresh.observe(phase))).toEqual(vector.expect);
    });
  }
});
