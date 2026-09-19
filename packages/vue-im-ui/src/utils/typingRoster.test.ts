import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { FlareTypingRoster, flareTypingPeerTtlMs } from "./typingSignal";

/**
 * The shared typing table (`spec/typing-vectors.json`), `roster` half: facts about peers in, the people
 * typing out. The Flutter, SwiftUI and Compose kits run the same file through the same driver.
 */
type Step = { at: number; op: string; conversationId?: string; userId?: string; userIds?: string[]; senderId?: string };
type Case = {
  name: string;
  watch: string;
  steps: Step[];
  endAt: number;
  expect: { at: number; typers: string[] }[];
  nextExpiryAtEnd?: number | null;
};
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/typing-vectors.json"), "utf8")) as {
  rules: { peerTtlMs: number };
  roster: { selfId: string; cases: Case[] };
};

const EPOCH_BASE = 1_767_000_000_000;

function run(vector: Case, base: number): { seen: { at: number; typers: string[] }[]; nextExpiry: number | null } {
  const roster = new FlareTypingRoster(table.roster.selfId);
  const seen: { at: number; typers: string[] }[] = [];
  let last = JSON.stringify([]);
  const record = (at: number) => {
    const typers = roster.typers(vector.watch);
    const key = JSON.stringify(typers);
    if (key === last) return;
    last = key;
    seen.push({ at: at - base, typers });
  };
  const advance = (to: number) => {
    // Beliefs expire at their own deadline, so the record carries that instant, not the step's. The
    // bound is not decoration: this loop asks the rule when to prune next, so a rule that stops making
    // progress — one that never actually drops an expired belief — would spin here forever, and a
    // harness that hangs is worse than one that fails. It happened on the first reverse-validation run.
    for (let guard = 0; ; guard += 1) {
      if (guard > vector.steps.length + 64) throw new Error(`${vector.name}: prune made no progress at ${roster.nextExpiry}`);
      const next = roster.nextExpiry;
      if (next === null || next > to) break;
      const before = JSON.stringify([...new Set(vector.steps.map((s) => s.conversationId ?? ""))].map((id) => roster.typers(id)));
      roster.prune(next);
      if (JSON.stringify([...new Set(vector.steps.map((s) => s.conversationId ?? ""))].map((id) => roster.typers(id))) === before) {
        throw new Error(`${vector.name}: prune at ${next} dropped nothing`);
      }
      record(next);
    }
  };
  for (const step of vector.steps) {
    const at = base + step.at;
    advance(at);
    if (step.op === "started") roster.started(step.conversationId ?? "", step.userId ?? "", at);
    else if (step.op === "stopped") roster.stopped(step.conversationId ?? "", step.userId ?? "");
    else if (step.op === "replaced") roster.replaced(step.conversationId ?? "", step.userIds ?? [], at);
    else if (step.op === "sent") roster.sent(step.conversationId ?? "", step.senderId ?? "");
    record(at);
  }
  advance(base + vector.endAt);
  const next = roster.nextExpiry;
  return { seen, nextExpiry: next === null ? null : next - base };
}

describe("what this client believes about its peers", () => {
  it("expires a belief on the table's ttl", () => {
    expect(flareTypingPeerTtlMs).toBe(table.rules.peerTtlMs);
  });

  for (const vector of table.roster.cases) {
    for (const base of [0, EPOCH_BASE]) {
      it(`${vector.name}${base ? " (on a real clock)" : ""}`, () => {
        const { seen, nextExpiry } = run(vector, base);
        expect(seen).toEqual(vector.expect);
        if ("nextExpiryAtEnd" in vector) expect(nextExpiry).toEqual(vector.nextExpiryAtEnd);
      });
    }
  }
});
