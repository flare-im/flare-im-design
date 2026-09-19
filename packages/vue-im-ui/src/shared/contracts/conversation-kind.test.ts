import { describe, expect, it } from "vitest";
import vocabulary from "../../../../../spec/conversation-kind.json";
import type { FlareConversationKind } from "./conversation";
import { resolveConversationHeaderActions } from "./conversation-header";

// FR-056: the header and the timeline used to name the same concept differently ("direct" vs "single",
// "bot" vs "ai"). `spec/conversation-kind.json` is the vocabulary now, and all four kits read it.

const every: FlareConversationKind[] = ["single", "group", "channel", "ai", "system"];

describe("the conversation kind vocabulary", () => {
  it("is the shared list, and the type admits exactly it", () => {
    expect(vocabulary.kinds).toEqual(every);
    // @ts-expect-error a word outside the vocabulary is not a kind
    const wrong: FlareConversationKind = "direct";
    expect(wrong).toBe("direct");
  });

  it("is what the header reasons about: the many-person kinds get the group actions", () => {
    const actionsFor = (kind: FlareConversationKind) =>
      resolveConversationHeaderActions({ identity: { kind } }).map((action) => action.id);
    const groupActions = actionsFor("group");
    expect(every.filter((kind) => String(actionsFor(kind)) === String(groupActions))).toEqual(["group", "channel"]);
  });
});
