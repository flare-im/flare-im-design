import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { FLARE_IMAGE_GROUP_MAX_VISIBLE, flareImageGroupLayout } from "./imageGroupLayout";

/** The shared table (`spec/image-group-layout-vectors.json`); the three native kits read the same file. */
const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../spec/image-group-layout-vectors.json"), "utf8"),
) as { maxVisible: number; cases: { count: number; columns: number; visible: number; more: number }[] };

describe("image-group layout", () => {
  it("draws at most the table's number of tiles", () => {
    expect(FLARE_IMAGE_GROUP_MAX_VISIBLE).toBe(table.maxVisible);
    expect(table.cases.length).toBeGreaterThanOrEqual(13);
  });

  for (const { count, ...expected } of table.cases) {
    it(`${count} image(s)`, () => {
      expect(flareImageGroupLayout(count)).toEqual(expected);
    });
  }
});
