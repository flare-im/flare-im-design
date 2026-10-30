import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { effectScope, nextTick, ref } from "vue";
import { flushPromises } from "@vue/test-utils";
import {
  useFlareReadReceiptList,
  type FlareReadReceiptMembers,
  type FlareReadReceiptPages,
} from "./useReadReceiptList";
import type { FlareReadReceiptColumn } from "../shared/contracts/read-receipt";

type Page = { people: string[]; nextCursor?: string };
type Answer = Page | null | "throw" | "pending";
interface Step {
  do: string;
  key?: string;
  asks?: Array<[FlareReadReceiptColumn, string | null]>;
  answer?: Answer;
  answers?: Partial<Record<FlareReadReceiptColumn, Answer>>;
  expect: { state: string; read: Page; unread: Page; loadingMore: string | null; loadMoreFailed: string | null } | null;
}
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/read-receipt-list-vectors.json"), "utf8")) as {
  cases: Array<{ id: string; platforms: string[]; steps: Step[] }>;
};

interface Call {
  column: FlareReadReceiptColumn;
  cursor: string | null;
  settled: boolean;
  resolve: (page: FlareReadReceiptMembers | null) => void;
  reject: (error: unknown) => void;
}

function settle(call: Call, answer: Answer | undefined): void {
  if (answer === undefined || answer === "pending") return;
  call.settled = true;
  if (answer === "throw") call.reject(new Error("read list failed"));
  else if (answer === null) call.resolve(null);
  else call.resolve({ people: answer.people.map((id) => ({ id, name: id })), ...(answer.nextCursor ? { nextCursor: answer.nextCursor } : {}) });
}

const plain = (pages: FlareReadReceiptPages | null) => pages && {
  state: pages.state,
  read: { people: pages.read.people.map((person) => person.id), ...(pages.read.nextCursor ? { nextCursor: pages.read.nextCursor } : {}) },
  unread: { people: pages.unread.people.map((person) => person.id), ...(pages.unread.nextCursor ? { nextCursor: pages.unread.nextCursor } : {}) },
  loadingMore: pages.loadingMore,
  loadMoreFailed: pages.loadMoreFailed,
};

describe("useFlareReadReceiptList (spec/read-receipt-list-vectors.json)", () => {
  for (const vector of table.cases.filter((entry) => entry.platforms.includes("vue"))) {
    it(vector.id, async () => {
      const key = ref<string | null>(null);
      const calls: Call[] = [];
      const scope = effectScope();
      const list = scope.run(() => useFlareReadReceiptList(key, (column, cursor) => new Promise<FlareReadReceiptMembers | null>((ok, fail) => {
        calls.push({ column, cursor: cursor ?? null, settled: false, resolve: ok, reject: fail });
      })))!;
      for (const [index, step] of vector.steps.entries()) {
        const before = calls.length;
        if (step.do === "open") key.value = step.key ?? "m1";
        else if (step.do === "close") key.value = null;
        else if (step.do === "retry") void list.retry();
        else if (step.do.startsWith("loadMore:")) void list.loadMore(step.do.slice("loadMore:".length) as FlareReadReceiptColumn);
        else if (step.do.startsWith("settle:")) {
          const column = step.do.slice("settle:".length);
          const call = calls.find((entry) => entry.column === column && !entry.settled);
          expect(call, `${vector.id} step ${index}: an unsettled ${column} call`).toBeDefined();
          settle(call!, step.answer);
        } else throw new Error(`unknown step ${step.do}`);
        await nextTick();
        const made = calls.slice(before);
        if (step.asks) expect(made.map((call) => [call.column, call.cursor]), `${vector.id} step ${index} asks`).toEqual(step.asks);
        if (!step.do.startsWith("settle:")) {
          for (const call of made) settle(call, step.answers ? step.answers[call.column] : step.answer);
        }
        await flushPromises();
        expect(plain(list.pages.value), `${vector.id} step ${index} (${step.do})`).toEqual(step.expect);
      }
      scope.stop();
    });
  }

  it("binds the open list as the sheet's props", async () => {
    const key = ref<string | null>("m1");
    const scope = effectScope();
    const list = scope.run(() => useFlareReadReceiptList(key, async (column) =>
      (column === "read" ? { people: [{ id: "r1", name: "R" }], nextCursor: "rc1" } : { people: [] })))!;
    await flushPromises();
    expect(list.sheet.value).toEqual({
      readers: [{ id: "r1", name: "R" }], unread: [], state: "ready", readHasMore: true, unreadHasMore: false, loadingMore: null, loadMoreFailed: null,
    });
    key.value = null;
    await nextTick();
    expect(list.sheet.value).toBeNull();
    scope.stop();
  });
});
