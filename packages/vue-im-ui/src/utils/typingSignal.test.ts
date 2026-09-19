import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  FlareTypingSignal,
  flareTypingIdleStopMs,
  flareTypingPeerTtlMs,
  flareTypingRefreshMs,
  type FlareTypingReport,
} from "./typingSignal";

/**
 * The shared typing table (`spec/typing-vectors.json`), `signal` half: the composer's edits in, the
 * reports this client owes the conversation out. The Flutter, SwiftUI and Compose kits run the same file
 * through the same driver, so a rule that is right here is right there or the difference is a failure.
 */
type Step = { at: number; op: "edit" | "send" | "close" | "tick"; conversationId?: string; text?: string };
type Case = { name: string; steps: Step[]; endAt: number; expect: { at: number; conversationId: string; typing: boolean }[] };
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/typing-vectors.json"), "utf8")) as {
  rules: { idleStopMs: number; refreshMs: number; peerTtlMs: number };
  signal: { cases: Case[] };
};

/**
 * `base` moves the whole script to where a real clock is. A table whose times start at zero is comfortably
 * inside a 32-bit int; `Date.now()` is not, and a kit that stored "now" in one would wrap to a negative
 * instant and never stop typing — a defect no zero-based script can see. The Compose kit was written that
 * way first; this is the guard that found it.
 */
const EPOCH_BASE = 1_767_000_000_000;

function run(vector: Case, base: number): FlareTypingReport[] {
  const signal = new FlareTypingSignal();
  const reports: FlareTypingReport[] = [];
  for (const step of vector.steps) {
    const at = base + step.at;
    // Time first, then the step: an idle stop that fell due in between must be reported before it.
    reports.push(...signal.tick(at));
    if (step.op === "edit") reports.push(...signal.edit(step.conversationId ?? "", step.text ?? "", at));
    else if (step.op === "send") reports.push(...signal.send(step.conversationId ?? "", at));
    else if (step.op === "close") reports.push(...signal.close(at));
  }
  reports.push(...signal.tick(base + vector.endAt));
  return reports;
}

describe("what this client says about its own typing", () => {
  it("uses the table's constants, so the four kits cannot drift apart quietly", () => {
    expect(flareTypingIdleStopMs).toBe(table.rules.idleStopMs);
    expect(flareTypingRefreshMs).toBe(table.rules.refreshMs);
    expect(flareTypingPeerTtlMs).toBe(table.rules.peerTtlMs);
  });

  it("refreshes before the peer's belief expires", () => {
    // The invariant the table states. Two apps shipped without it and went silent mid-sentence.
    expect(flareTypingRefreshMs).toBeLessThan(flareTypingPeerTtlMs);
  });

  for (const vector of table.signal.cases) {
    for (const base of [0, EPOCH_BASE]) {
      it(`${vector.name}${base ? " (on a real clock)" : ""}`, () => {
        expect(run(vector, base).map((r) => ({ at: r.atMs - base, conversationId: r.conversationId, typing: r.typing }))).toEqual(
          vector.expect,
        );
      });
    }
  }
});
