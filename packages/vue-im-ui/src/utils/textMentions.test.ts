import { describe, expect, it } from "vitest";
import { segmentTextByMentions, textMentionSpans } from "./textMentions";
import type { ContentElem } from "./contentElem";

describe("text mention spans", () => {
  it("maps core character offsets to string indices and marks self and all", () => {
    const text = "@林夏 看一下 @所有人";
    const spans = textMentionSpans({
      contentType: "text",
      text,
      mentions: [
        { type: 1, userId: "u_me", start: 0, length: 3 },
        { type: 2, start: 8, length: 4 },
      ],
    }, text, "u_me");
    expect(spans).toEqual([
      { start: 0, length: 3, self: true, all: false },
      { start: 8, length: 4, self: false, all: true },
    ]);
    expect(segmentTextByMentions(text, spans).map((s) => [s.text, Boolean(s.mention)])).toEqual([
      ["@林夏", true], [" 看一下 ", false], ["@所有人", true],
    ]);
  });

  it("counts characters, not UTF-16 units, before a mention", () => {
    const text = "👍 @周屿";
    const spans = textMentionSpans({ contentType: "text", text, mentions: [{ type: 1, userId: "u_zhou", start: 2, length: 3 }] }, text, "u_me");
    expect(text.slice(spans[0].start, spans[0].start + spans[0].length)).toBe("@周屿");
    expect(spans[0].self).toBe(false);
  });

  it("drops spans that do not land on an @ token or overlap", () => {
    const text = "hello @a";
    expect(textMentionSpans({ contentType: "text", text, mentions: [{ type: 1, userId: "x", start: 0, length: 3 }] }, text)).toEqual([]);
    expect(textMentionSpans({ contentType: "text", text, mentions: [
      { type: 1, userId: "a", start: 6, length: 2 },
      { type: 1, userId: "b", start: 6, length: 2 },
    ] }, text)).toHaveLength(1);
  });
  it("keeps a span that only overlaps a span already dropped", () => {
    const text = "@ab@cd@ef";
    const content = { contentType: "text", text, mentions: [
      { type: 1, userId: "a", start: 0, length: 3 },
      { type: 1, userId: "b", start: 1, length: 3 },
      { type: 1, userId: "c", start: 3, length: 3 },
    ] } as unknown as ContentElem;
    expect(textMentionSpans(content, text).map((span) => span.start)).toEqual([0, 3]);
  });
});
