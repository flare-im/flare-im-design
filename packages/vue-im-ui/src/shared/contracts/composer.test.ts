import { describe, expect, it } from "vitest";
import {
  FLARE_COMPOSER_ACTION_IDS,
  FLARE_DEFAULT_COMPOSER_ACTION_IDS,
  resolveComposerActions,
  type FlareComposerAction,
} from "./composer";

describe("composer action table", () => {
  it("uses the unified, prefix-free id table shared with the native kits", () => {
    expect(FLARE_COMPOSER_ACTION_IDS).toEqual([
      "image", "camera", "voice", "video", "file", "location", "contact", "card",
      "poll", "vote", "task", "event", "schedule", "link", "announcement",
      "notification", "miniApp", "miniProgram", "translate",
    ]);
    for (const id of FLARE_COMPOSER_ACTION_IDS) expect(id.startsWith("create_")).toBe(false);
    expect(FLARE_COMPOSER_ACTION_IDS).not.toContain("threadReply");
  });

  it("keeps the default set useful and restrained", () => {
    // 视频在里面：composer 自己就能拾取它（PICKER_INTENTS.video），不给就等于这个能力不存在。
    expect(FLARE_DEFAULT_COMPOSER_ACTION_IDS).toEqual(["image", "video", "file", "voice", "location", "contact"]);
    for (const id of FLARE_DEFAULT_COMPOSER_ACTION_IDS) expect(FLARE_COMPOSER_ACTION_IDS).toContain(id);
  });

  it("resolves replacement, visibility, capability, order, disabled and custom actions", () => {
    const defaults: FlareComposerAction[] = FLARE_DEFAULT_COMPOSER_ACTION_IDS.map((id) => ({ id, label: id }));
    const actions: FlareComposerAction[] = [
      { id: "file", label: "File", order: 30 },
      { id: "voice", label: "Voice", visible: false },
      { id: "order", label: "Order", order: 20, intent: "open-order" },
      { id: "image", label: "Image", order: 10, enabled: false, disabledReason: "Upload unavailable" },
      { id: "file", label: "Duplicate file" },
    ];
    expect(resolveComposerActions({
      defaults,
      actions,
      capabilities: { availableActionIds: ["image", "order", "file"] },
    })).toEqual([actions[3], actions[2], actions[0]]);
    expect(resolveComposerActions({ defaults }).map((action) => action.id)).toEqual(FLARE_DEFAULT_COMPOSER_ACTION_IDS);
  });
});
