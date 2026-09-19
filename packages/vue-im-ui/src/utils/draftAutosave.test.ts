import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { FlareDraftAutosave, flareDraftSaveDelayMs, type FlareDraftSave } from "./draftAutosave";

/**
 * The shared draft table (`spec/draft-vectors.json`): the composer's edits in, the writes this client
 * owes the core out. The Flutter, SwiftUI and Compose kits run the same file through the same driver.
 */
type Step = { at: number; op: string; conversationId?: string; text?: string };
type Case = { name: string; steps: Step[]; endAt: number; expect: { at: number; conversationId: string; text: string }[] };
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/draft-vectors.json"), "utf8")) as {
  rules: { saveDelayMs: number };
  cases: Case[];
};

const EPOCH_BASE = 1_767_000_000_000;

function run(vector: Case, base: number): FlareDraftSave[] {
  const drafts = new FlareDraftAutosave();
  const saves: FlareDraftSave[] = [];
  for (const step of vector.steps) {
    const at = base + step.at;
    saves.push(...drafts.tick(at));
    if (step.op === "seed") drafts.seed(step.conversationId ?? "", step.text ?? "");
    else if (step.op === "edit") saves.push(...drafts.edit(step.conversationId ?? "", step.text ?? "", at));
    else if (step.op === "send") saves.push(...drafts.send(step.conversationId ?? "", at));
    else if (step.op === "restore") saves.push(...drafts.restore(step.conversationId ?? "", step.text ?? "", at));
    else if (step.op === "leave") saves.push(...drafts.leave(at));
  }
  saves.push(...drafts.tick(base + vector.endAt));
  return saves;
}

describe("when a draft is written down", () => {
  it("uses the table's delay, so the four kits cannot drift apart quietly", () => {
    expect(flareDraftSaveDelayMs).toBe(table.rules.saveDelayMs);
  });

  for (const vector of table.cases) {
    for (const base of [0, EPOCH_BASE]) {
      it(`${vector.name}${base ? " (on a real clock)" : ""}`, () => {
        expect(run(vector, base).map((s) => ({ at: s.atMs - base, conversationId: s.conversationId, text: s.text }))).toEqual(
          vector.expect,
        );
      });
    }
  }
});
