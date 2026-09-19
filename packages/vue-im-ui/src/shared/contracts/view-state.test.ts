import { describe, expect, it } from "vitest";
import vectors from "../../../../../spec/view-state-vectors.json";
import { flareViewPresentation, type FlareViewStatus } from "./application";

// FR-057: a failed refresh over rows worth keeping does not wipe what someone was reading.
// `spec/view-state-vectors.json` says what a container draws, on four kits.

describe("view state presentation", () => {
  it("matches the shared table", () => {
    expect(vectors.cases.length).toBeGreaterThanOrEqual(10);
    for (const c of vectors.cases) {
      expect(flareViewPresentation(c.status as FlareViewStatus, c.stale), c.id).toBe(c.presentation);
    }
  });

  it("only knows the three presentations the table names", () => {
    const seen = new Set(vectors.cases.map((c) => c.presentation));
    expect([...seen].sort()).toEqual([...vectors.presentations].sort());
  });
});
