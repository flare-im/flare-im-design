import { describe, expect, it } from "vitest";
import vectors from "../../../../../spec/message-batch-vectors.json";
import {
  messageBatchActionIds,
  messageBatchActions,
  messageBatchActionsAvailable,
  messageBatchForwardActions,
  messageBatchMinimumSelection,
  messageBatchUnforwardableCount,
  type MessageBatchAction,
  type MessageBatchCapabilities,
} from "./message-batch";
import { resolveFlareMessage } from "../i18n/messages";

// FR-034: the message batch toolbar answers the same question the conversation one does — what may a
// host do with this selection right now. `spec/message-batch-vectors.json` is the answer, on four kits.

const capabilitiesOf = (names: string[]): MessageBatchCapabilities =>
  Object.fromEntries(names.map((name) => [name, true])) as MessageBatchCapabilities;
const ids = (count: number) => Array.from({ length: count }, (_, index) => `m${index}`);

type BatchCase = (typeof vectors.cases)[number] & {
  selectedIds?: string[];
  unforwardable?: string[];
  reports?: Partial<Record<MessageBatchAction, string[]>>;
  unforwardableCount?: number;
};
const batchCases = vectors.cases as BatchCase[];
const selectionOf = (c: BatchCase) => c.selectedIds ?? ids(c.selected);

describe("message batch availability", () => {
  it("matches the shared table", () => {
    expect(batchCases.length).toBeGreaterThanOrEqual(14);
    for (const c of batchCases) {
      expect(selectionOf(c), c.id).toHaveLength(c.selected);
      expect(
        messageBatchActionsAvailable(selectionOf(c), capabilitiesOf(c.capabilities), c.busy, c.unforwardable ?? []),
        c.id,
      ).toEqual(c.available);
    }
  });

  it("reports the ids each action works on and counts the unforwardable ones as the table says", () => {
    const checked = batchCases.filter((c) => c.reports);
    expect(checked.length).toBeGreaterThanOrEqual(6);
    for (const c of checked) {
      for (const [action, reported] of Object.entries(c.reports!)) {
        expect(messageBatchActionIds(action as MessageBatchAction, selectionOf(c), c.unforwardable), `${c.id} ${action}`).toEqual(reported);
      }
      expect(messageBatchUnforwardableCount(selectionOf(c), c.unforwardable), c.id).toBe(c.unforwardableCount);
    }
    expect([...messageBatchForwardActions]).toEqual(vectors.forward.actions);
    expect(resolveFlareMessage("en-US", "batch.unforwardable", { count: 1 })).toBe("1 message can't be forwarded");
    expect(resolveFlareMessage("zh-CN", "batch.unforwardable", { count: 2 })).toBe("2 条不支持转发");
  });

  it("declares the same order and minimums as the table", () => {
    expect([...messageBatchActions]).toEqual(vectors.order);
    expect(messageBatchMinimumSelection).toEqual(vectors.minimumSelection);
  });

  it("never mutates what it is given", () => {
    const selected = ids(2);
    const capabilities: MessageBatchCapabilities = { forwardEach: true, delete: true };
    messageBatchActionsAvailable(selected, capabilities);
    expect(selected).toEqual(["m0", "m1"]);
    expect(capabilities).toEqual({ forwardEach: true, delete: true });
  });

  it("treats a missing capability object as nothing allowed", () => {
    expect(messageBatchActionsAvailable(ids(3), null)).toEqual([]);
    expect(messageBatchActionsAvailable(ids(3), undefined)).toEqual([]);
  });
});

describe("the vectors table itself", () => {
  it("only names actions the contract knows", () => {
    const known = new Set<MessageBatchAction>(messageBatchActions);
    for (const c of vectors.cases) {
      for (const name of [...c.capabilities, ...c.available]) expect(known.has(name as MessageBatchAction), `${c.id}: ${name}`).toBe(true);
    }
  });
});
