import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flareThemeIsDark, type FlareThemeMode } from "./use-flare-theme";

/** The shared theme table (`spec/theme-mode-vectors.json`); the three native kits read the same file. */
const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../../spec/theme-mode-vectors.json"), "utf8"),
) as { cases: Array<{ id: string; mode: FlareThemeMode; systemDark: boolean; dark: boolean }> };

describe("the theme a kit draws", () => {
  it("covers every mode against both system settings", () => {
    expect(table.cases).toHaveLength(6);
  });

  for (const vector of table.cases) {
    it(`theme vector: ${vector.id}`, () => {
      expect(flareThemeIsDark(vector.mode, vector.systemDark)).toBe(vector.dark);
    });
  }
});
