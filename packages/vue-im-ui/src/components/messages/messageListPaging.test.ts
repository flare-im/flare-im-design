import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  FLARE_MESSAGE_LIST_NEWER_WITHIN_PX,
  FLARE_MESSAGE_LIST_OLDER_WITHIN_PX,
  flareMessageListEdge,
  flareMessageListLatestEntry,
  flareMessageListRequests,
  type FlareMessageListEnd,
} from "./messageListPaging";

/**
 * The shared paging table (`spec/message-list-paging-vectors.json`): what the two ends of the list draw, when the
 * list asks for a page by itself, and what the floating key at the bottom does. The four kits read the same table.
 */
type End = FlareMessageListEnd & { error: string | null };
const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../../spec/message-list-paging-vectors.json"), "utf8"),
) as {
  autoRequest: { olderWithin: number; newerWithin: number };
  edges: Array<End & { id: string; expected: { spinner: boolean; error: boolean; button: boolean } }>;
  requests: Array<{ id: string; fromTop: number; fromBottom: number; older: End; newer: End; expected: { older: boolean; newer: boolean } }>;
  jumpToLatest: Array<{
    id: string; hasNewer: boolean; handled: boolean; belowCount: number;
    expected: { shown: boolean; count: number; action: string | null };
  }>;
};

describe("the two ends of the message list", () => {
  it("asks within the distances the table names", () => {
    expect(FLARE_MESSAGE_LIST_OLDER_WITHIN_PX).toBe(table.autoRequest.olderWithin);
    expect(FLARE_MESSAGE_LIST_NEWER_WITHIN_PX).toBe(table.autoRequest.newerWithin);
    expect(table.edges.length).toBeGreaterThanOrEqual(11);
    expect(table.requests.length).toBeGreaterThanOrEqual(21);
    expect(table.jumpToLatest.length).toBeGreaterThanOrEqual(8);
  });

  for (const vector of table.edges) {
    it(`draws: ${vector.id}`, () => {
      expect(flareMessageListEdge(vector)).toEqual(vector.expected);
    });
  }

  for (const vector of table.requests) {
    it(`asks: ${vector.id}`, () => {
      expect(flareMessageListRequests(vector, vector.older, vector.newer)).toEqual(vector.expected);
    });
  }

  for (const vector of table.jumpToLatest) {
    it(`back to latest: ${vector.id}`, () => {
      expect(flareMessageListLatestEntry(vector)).toEqual(vector.expected);
    });
  }
});
