import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import type { MessageStatusState } from "./message-lifecycle";
import {
  flareMessageMetaPlacement,
  flareMessageMetaTone,
  flareMessageRetryForm,
  flareMessageSurface,
  type FlareMessageSurface,
  type FlareMessageSurfaceInput,
} from "./message-surface";

const spec = (name: string) => JSON.parse(readFileSync(resolve(__dirname, `../../../../../spec/${name}`), "utf8"));
const surfaces = spec("message-surface-vectors.json") as {
  defaults: Record<FlareMessageSurface, string[]>;
  cases: Array<{ id: string; input: FlareMessageSurfaceInput; surface: FlareMessageSurface }>;
};
const placements = spec("message-meta-placement-vectors.json") as {
  cases: Array<{
    id: string;
    surface: FlareMessageSurface;
    contentType: string;
    self: boolean;
    status: MessageStatusState;
    expect: { placement: string; tone: string; retry: string | null };
  }>;
};

describe("message surface vectors (C1)", () => {
  it("has cases for every surface", () => {
    expect(new Set(surfaces.cases.map((c) => c.surface))).toEqual(new Set(["bubble", "bareMedia", "card", "centered"]));
  });
  it.each(surfaces.cases)("$id → $surface", ({ input, surface }) => {
    expect(flareMessageSurface(input)).toBe(surface);
  });
  it("draws every default content type on its table surface", () => {
    for (const [surface, types] of Object.entries(surfaces.defaults)) {
      for (const contentType of types) {
        const expected = contentType === "text" || contentType === "video" ? flareMessageSurface({ contentType }) : surface;
        expect(flareMessageSurface({ contentType }), contentType).toBe(expected);
      }
    }
  });
  it("accepts the wire spellings of the camel-cased spec types", () => {
    expect(flareMessageSurface({ contentType: "rich_text" })).toBe("bubble");
    expect(flareMessageSurface({ contentType: "link_card" })).toBe("card");
    expect(flareMessageSurface({ contentType: "mini_program" })).toBe("card");
    expect(flareMessageSurface({ contentType: "image_group" })).toBe("bubble");
  });
});

describe("message meta placement vectors (C2)", () => {
  it.each(placements.cases)("$id", ({ surface, contentType, self, status, expect: want }) => {
    const placement = flareMessageMetaPlacement(surface, contentType);
    expect(placement).toBe(want.placement);
    expect(flareMessageMetaTone(placement, self, status)).toBe(want.tone);
    expect(flareMessageRetryForm(placement, self, status)).toBe(want.retry);
  });
});
