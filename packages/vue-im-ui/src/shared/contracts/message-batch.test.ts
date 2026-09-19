import { describe, expect, it } from "vitest";
import vectors from "../../../../../spec/message-batch-vectors.json";
import {
  messageBatchActions,
  messageBatchActionsAvailable,
  messageBatchMinimumSelection,
  type MessageBatchAction,
  type MessageBatchCapabilities,
} from "./message-batch";

// FR-034: the message batch toolbar answers the same question the conversation one does — what may a
// host do with this selection right now. `spec/message-batch-vectors.json` is the answer, on four kits.

const capabilitiesOf = (names: string[]): MessageBatchCapabilities =>
  Object.fromEntries(names.map((name) => [name, true])) as MessageBatchCapabilities;
const ids = (count: number) => Array.from({ length: count }, (_, index) => `m${index}`);

describe("message batch availability", () => {
  it("matches the shared table", () => {
    expect(vectors.cases.length).toBeGreaterThanOrEqual(8);
    for (const c of vectors.cases) {
      expect(messageBatchActionsAvailable(ids(c.selected), capabilitiesOf(c.capabilities), c.busy), c.id).toEqual(c.available);
    }
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
