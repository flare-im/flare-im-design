import { describe, expect, it } from "vitest";
import { FLARE_COMPOSER_ACTION_IDS, FLARE_COMPOSER_CORE_ACTION_IDS, composerActionLegacyOp } from "./composer";

describe("composer action table", () => {
  it("uses the unified, prefix-free id table shared with the native kits", () => {
    expect(FLARE_COMPOSER_ACTION_IDS).toEqual([
      "image", "camera", "video", "file", "location", "card", "vote", "task",
      "schedule", "link", "announcement", "notification", "miniProgram", "translate",
    ]);
    for (const id of FLARE_COMPOSER_ACTION_IDS) expect(id.startsWith("create_")).toBe(false);
    expect(FLARE_COMPOSER_ACTION_IDS).not.toContain("poll");
    expect(FLARE_COMPOSER_ACTION_IDS).not.toContain("threadReply");
  });

  it("core default set is the eight the native kits show", () => {
    expect(FLARE_COMPOSER_CORE_ACTION_IDS).toEqual(["image", "camera", "file", "location", "card", "vote", "task", "schedule"]);
    for (const id of FLARE_COMPOSER_CORE_ACTION_IDS) expect(FLARE_COMPOSER_ACTION_IDS).toContain(id);
  });

  it("derives the legacy build(op) name for back-compat and passes host ids through", () => {
    expect(composerActionLegacyOp("file")).toBe("create_file");
    expect(composerActionLegacyOp("vote")).toBe("create_vote");
    expect(composerActionLegacyOp("link")).toBe("create_link_card");
    expect(composerActionLegacyOp("miniProgram")).toBe("create_mini_program");
    expect(composerActionLegacyOp("translate")).toBe("create_text");
    expect(composerActionLegacyOp("tenant_custom")).toBe("tenant_custom");
  });
});
