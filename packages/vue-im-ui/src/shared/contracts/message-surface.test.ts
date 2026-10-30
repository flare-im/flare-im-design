import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import type { MessageStatusState } from "./message-lifecycle";
import {
  flareMessageBubbleTone,
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
const palette = (spec("message-surface-vectors.json") as {
  palette: {
    tones: Record<string, { background: string; foreground: string; edge: string | null }>;
    cases: Array<{ id: string; self: boolean; status: MessageStatusState; tone: string }>;
  };
}).palette;
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

describe("bubble palette vectors", () => {
  it.each(palette.cases)("$id → $tone", ({ self, status, tone }) => {
    expect(flareMessageBubbleTone(self, status)).toBe(tone);
  });

  // The kit paints the tones in CSS: each tone's rule takes the table's tokens and only the failure surface has an edge.
  const css = readFileSync(resolve(__dirname, "../../design-system/styles/chat/message-bubble.css"), "utf8");
  const rule = (selector: string) => {
    const start = css.indexOf(`\n${selector} {`);
    expect(start, selector).toBeGreaterThanOrEqual(0);
    const body = css.slice(css.indexOf("{", start) + 1, css.indexOf("}", start));
    return Object.fromEntries(body.split(";").map((line) => line.replace(/\/\*[\s\S]*?\*\//g, "").trim())
      .filter((line) => line.includes(":")).map((line) => [line.slice(0, line.indexOf(":")).trim(), line.slice(line.indexOf(":") + 1).trim()]));
  };
  const variable = (token: string) => `var(--flare-color-${token.replaceAll(".", "-")})`;
  const fill = (declarations: Record<string, string>) =>
    declarations.background === "var(--flare-component-bubble-tail-fill)"
      ? declarations["--flare-component-bubble-tail-fill"] : declarations.background;
  const rules = {
    incoming: { ...rule(".message-bubble"), ...rule(".message-bubble:not(.message-bubble--chromeless-media)") },
    outgoing: rule(".message-bubble.message-bubble-self:not(.message-bubble--chromeless-media)"),
    failed: rule(".message-row--failed .message-bubble:not(.message-bubble--chromeless-media)"),
  };

  it.each(Object.entries(palette.tones))("paints %s with the table's tokens", (tone, tokens) => {
    const declarations = rules[tone as keyof typeof rules];
    expect(fill(declarations)).toBe(variable(tokens.background));
    expect(declarations.color).toBe(variable(tokens.foreground));
    if (tokens.edge) {
      expect(declarations.border).toBe(`1px solid ${variable(tokens.edge)}`);
      expect(declarations["--flare-component-bubble-tail-fill"], "the tail takes the failure fill").toBe(variable(tokens.background));
    } else {
      expect(declarations.border ?? "0").toBe("0");
    }
  });
});
