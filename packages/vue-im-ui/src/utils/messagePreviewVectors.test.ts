import { describe, expect, it } from "vitest";
import vectors from "../../../../spec/message-preview-vectors.json";
import { displayTextFromStoredPreview, previewTextFromMessageContent } from "./messagePreview";
import { resolveFlareMessage } from "../shared/i18n/messages";

/**
 * The shared summary table (`spec/message-preview-vectors.json`) is what a conversation row, a
 * reply strip and a bubble's quote say about a message. Vue is the reference implementation; the
 * three native kits read the same file. A case's `fields` become this platform's content shape:
 * `text` at the root, everything else under the type's own payload key, and `count` becomes that
 * many items in the list the type carries.
 */
type Vector = {
  id: string;
  kind: string;
  fields: Record<string, unknown>;
  expected: Record<string, string>;
  replyExpected?: Record<string, string>;
};

const PAYLOAD_KEY: Record<string, string> = {
  link_card: "link_card",
  image_group: "image_group",
};

function listField(kind: string): string {
  return kind === "forward" ? "items" : "images";
}

function contentFor({ kind, fields }: Vector): Record<string, unknown> {
  if (kind === "text") return { contentType: "text", text: fields.text };
  const payload: Record<string, unknown> = { ...fields };
  if (typeof fields.count === "number") {
    delete payload.count;
    payload[listField(kind)] = Array.from({ length: fields.count }, () => ({}));
  }
  return { contentType: kind, [PAYLOAD_KEY[kind] ?? kind]: payload };
}

/** What a reply strip or a quote shows: the summary, or the shared fallback when it is empty. */
function replySummary(content: Record<string, unknown>, locale: string): string {
  return previewTextFromMessageContent(content, locale).trim() || resolveFlareMessage(locale, vectors.fallbackKey);
}

describe("shared message preview vectors", () => {
  for (const vector of vectors.cases as Vector[]) {
    for (const locale of ["zh-CN", "en-US"]) {
      it(`${vector.id} reads the same in ${locale}`, () => {
        const content = contentFor(vector);
        expect(previewTextFromMessageContent(content, locale)).toBe(vector.expected[locale]);
        const reply = vector.replyExpected?.[locale] ?? vector.expected[locale];
        expect(replySummary(content, locale)).toBe(reply);
      });
    }
  }
});

/**
 * `stored` is the same table for the token the core keeps instead of a message (a conversation's last message, a
 * quote, a search hit): each token exactly as `preview_storage.rs` serializes it, and the line it reads as.
 */
type StoredVector = { id: string; token: string; expected: Record<string, string> };

describe("shared stored preview vectors", () => {
  it("covers the tokens the core writes", () => {
    expect((vectors.stored as StoredVector[]).length).toBeGreaterThanOrEqual(40);
  });
  for (const vector of vectors.stored as StoredVector[]) {
    for (const locale of ["zh-CN", "en-US"]) {
      it(`${vector.id} reads the same in ${locale}`, () => {
        expect(displayTextFromStoredPreview(vector.token, locale)).toBe(vector.expected[locale]);
      });
    }
  }
});
