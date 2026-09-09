import { describe, expect, it } from "vitest";
import {
  batchActionsAvailable,
  batchSelectionExceeded,
  summarizeBatchResult,
  type ConversationBatchResult,
} from "./conversation-batch";

const caps = { markRead: true, mute: true, archive: false, delete: true };

describe("batchActionsAvailable", () => {
  it("returns capability-enabled actions in canonical order", () => {
    expect(batchActionsAvailable(["a", "b"], { delete: true, markRead: true }, false)).toEqual(["markRead", "delete"]);
    expect(batchActionsAvailable(["a"], caps)).toEqual(["markRead", "mute", "delete"]);
  });
  it("is empty with no selection, while busy, or without capabilities", () => {
    expect(batchActionsAvailable([], caps, false)).toEqual([]);
    expect(batchActionsAvailable(["a"], caps, true)).toEqual([]);
    expect(batchActionsAvailable(["a"], {}, false)).toEqual([]);
    expect(batchActionsAvailable(["a"], undefined, false)).toEqual([]);
  });
  it("is empty when the selection exceeds maxSelection; limit at boundary still allows", () => {
    expect(batchActionsAvailable(["a", "b", "c"], caps, false, 2)).toEqual([]);
    expect(batchActionsAvailable(["a", "b"], caps, false, 2)).toEqual(["markRead", "mute", "delete"]);
    expect(batchActionsAvailable(["a", "b", "c"], caps, false, 0)).toEqual(["markRead", "mute", "delete"]);
    expect(batchActionsAvailable(["a", "b", "c"], caps, false, null)).toEqual(["markRead", "mute", "delete"]);
  });
  it("does not mutate inputs", () => {
    const ids = ["a"];
    const capabilities = { ...caps };
    batchActionsAvailable(ids, capabilities, false, 1);
    expect(ids).toEqual(["a"]);
    expect(capabilities).toEqual(caps);
  });
});

describe("batchSelectionExceeded", () => {
  it("only trips for positive finite limits", () => {
    expect(batchSelectionExceeded(3, 2)).toBe(true);
    expect(batchSelectionExceeded(2, 2)).toBe(false);
    expect(batchSelectionExceeded(3, 0)).toBe(false);
    expect(batchSelectionExceeded(3, -1)).toBe(false);
    expect(batchSelectionExceeded(3, Number.NaN)).toBe(false);
    expect(batchSelectionExceeded(3, undefined)).toBe(false);
  });
});

describe("summarizeBatchResult", () => {
  it("counts both outcomes and keeps successes alongside failures", () => {
    const result: ConversationBatchResult = {
      succeeded: ["a", "b", "c"],
      failed: [
        { id: "d", title: "设计群", reason: "无权限" },
        { id: "e", title: "客服", reason: "网络中断" },
      ],
    };
    expect(summarizeBatchResult(result)).toEqual({ succeededCount: 3, failedCount: 2, retryIds: ["d", "e"] });
  });
  it("deduplicates retry ids and skips blank ids while counting every failure", () => {
    const result: ConversationBatchResult = {
      succeeded: [],
      failed: [
        { id: "d", title: "x", reason: "r1" },
        { id: "d", title: "x", reason: "r2" },
        { id: "", title: "y", reason: "r3" },
      ],
    };
    expect(summarizeBatchResult(result)).toEqual({ succeededCount: 0, failedCount: 3, retryIds: ["d"] });
  });
  it("is all zeros for null/undefined", () => {
    expect(summarizeBatchResult(null)).toEqual({ succeededCount: 0, failedCount: 0, retryIds: [] });
    expect(summarizeBatchResult(undefined)).toEqual({ succeededCount: 0, failedCount: 0, retryIds: [] });
  });
});
