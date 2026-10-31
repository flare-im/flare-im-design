import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  flareLocateMaxPages,
  flareLocateMessage,
  flareLocateMessageAround,
  flareLocateSettleAttempts,
  type FlareLocateAnchor,
} from "./locateMessage";

/**
 * The shared locate table (`spec/locate-orchestration-vectors.json`) is the one trip four kits make when a
 * quote names a message that is not loaded. Each case scripts a run; the expectations count the whole trip,
 * so a kit that asks or pages a different number of times fails even when it lands on the same answer.
 */
type Vector = {
  id: string;
  historyPages: number;
  foundAfterPages: number | null;
  failAtPage?: number;
  cancelAfterShows?: number;
  visibleFromShow?: number;
  expected: { outcome: string; pagesRead: number; showCalls: number };
};

type AroundVector = {
  id: string;
  anchor: FlareLocateAnchor;
  loaded: boolean;
  openAnswer: string | null;
  drawnFromShow: number;
  cancelAfterShows?: number;
  cancelAfterOpen?: boolean;
  expected: { outcome: string; openCalls: number; showCalls: number; askedIds: string[] };
};

const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../spec/locate-orchestration-vectors.json"), "utf8"),
) as { maxPages: number; settleAttempts: number; cases: Vector[]; around: { settleAttempts: number; cases: AroundVector[] } };

describe("the trip a tapped quote takes", () => {
  it("is the budget this kit was built with", () => {
    expect(table.maxPages).toBe(flareLocateMaxPages);
    expect(table.settleAttempts).toBe(flareLocateSettleAttempts);
    expect(table.cases.length).toBeGreaterThanOrEqual(13);
  });

  for (const vector of table.cases) {
    it(`locate run: ${vector.id}`, async () => {
      let pages = 0;
      let shows = 0;
      const visibleFrom = vector.visibleFromShow ?? 1;
      const outcome = await flareLocateMessage({
        isCurrent: () => vector.cancelAfterShows === undefined || shows < vector.cancelAfterShows,
        showInList: () => {
          shows += 1;
          if (vector.foundAfterPages === null) return false;
          return pages >= vector.foundAfterPages && shows >= visibleFrom;
        },
        hasOlder: () => pages < vector.historyPages,
        readOlder: () => {
          pages += 1;
          return vector.failAtPage === undefined || pages !== vector.failAtPage;
        },
        settle: () => {},
      });
      expect({ outcome, pagesRead: pages, showCalls: shows }).toEqual(vector.expected);
    });
  }
});

describe("the trip when the host opens a window around the message", () => {
  it("settles as many times as the table says", () => {
    expect(table.around.settleAttempts).toBe(flareLocateSettleAttempts);
    expect(table.around.cases.length).toBeGreaterThanOrEqual(13);
  });

  for (const vector of table.around.cases) {
    it(`locate around: ${vector.id}`, async () => {
      let opens = 0;
      let opened = false;
      const asked: string[] = [];
      const handed: FlareLocateAnchor[] = [];
      const key = vector.openAnswer?.trim() ?? "";
      const outcome = await flareLocateMessageAround({
        anchor: vector.anchor,
        isCurrent: () =>
          (vector.cancelAfterShows === undefined || asked.length < vector.cancelAfterShows) &&
          !(vector.cancelAfterOpen && opened),
        showInList: (id) => {
          asked.push(id);
          if (vector.loaded && id === vector.anchor.messageId) return true;
          return opened && key !== "" && id === key && asked.length >= vector.drawnFromShow;
        },
        openAround: (anchor) => {
          opens += 1;
          handed.push(anchor);
          opened = true;
          return vector.openAnswer;
        },
        settle: () => {},
      });
      expect({ outcome, openCalls: opens, showCalls: asked.length, askedIds: asked }).toEqual(vector.expected);
      for (const anchor of handed) expect(anchor).toEqual(vector.anchor);
    });
  }
});
