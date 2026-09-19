import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flareRichSpoilerCover, parseRichDoc } from "./richDoc";

/**
 * The shared table (`spec/rich-doc-vectors.json`): what a rich-text body draws for a RichDoc v2 document.
 * The table states the rule in the shape `parseRichDoc` returns, so a case compares directly; the three
 * native kits read the same file and convert their models to it.
 */
interface Vector {
  id: string;
  doc?: unknown;
  generate?: { paragraphTextNodes?: number; nestedQuotes?: number };
  blocks?: unknown;
  drawable?: boolean;
}

const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../spec/rich-doc-vectors.json"), "utf8"),
) as { cases: Vector[]; spoilerCovers: { text: string; cover: string }[] };

function generated(spec: NonNullable<Vector["generate"]>): unknown {
  const text = { type: "text", text: "a" };
  if (spec.nestedQuotes !== undefined) {
    let node: unknown = { type: "paragraph", children: [text] };
    for (let level = 0; level < spec.nestedQuotes; level += 1) node = { type: "quote", children: [node] };
    return { type: "doc", version: 2, children: [node] };
  }
  const children = Array.from({ length: spec.paragraphTextNodes ?? 0 }, () => text);
  return { type: "doc", version: 2, children: [{ type: "paragraph", children }] };
}

describe("rich-text documents read into blocks and runs", () => {
  it("keeps the shared table whole", () => {
    expect(table.cases.length).toBeGreaterThanOrEqual(30);
  });

  it("covers a spoiler with blank space, keeping its whitespace", () => {
    expect(table.spoilerCovers.length).toBeGreaterThanOrEqual(5);
    for (const { text, cover } of table.spoilerCovers) expect(flareRichSpoilerCover(text), JSON.stringify(text)).toBe(cover);
  });

  for (const vector of table.cases) {
    it(vector.id, () => {
      if (vector.generate) {
        expect(parseRichDoc(generated(vector.generate)) !== null).toBe(vector.drawable);
      } else {
        expect(parseRichDoc(vector.doc)).toStrictEqual(vector.blocks);
      }
    });
  }
});
