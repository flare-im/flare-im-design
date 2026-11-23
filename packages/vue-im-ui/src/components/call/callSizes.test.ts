import { describe, expect, it } from "vitest";
import { flareCallAvatar } from "./callSizes";

describe("call avatar sizes", () => {
  it("come from the generated tokens as numbers (§3.2–3.5)", () => {
    expect(flareCallAvatar).toEqual({ stage: 96, tile: 56, dock: 40, banner: 48 });
  });
});
