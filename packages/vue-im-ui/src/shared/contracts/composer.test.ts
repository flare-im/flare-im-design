import { describe, expect, it } from "vitest";
import {
  FLARE_COMPOSER_ACTION_ICONS,
  FLARE_COMPOSER_ACTION_IDS,
  FLARE_COMPOSER_TOOL_IDS,
  FLARE_DEFAULT_COMPOSER_ACTION_IDS,
  composerToolAvailable,
  labelComposerActions,
  resolveComposerActionIcon,
  resolveComposerActions,
  type FlareComposerAction,
} from "./composer";
import { flareIcons } from "../icons";

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

  it("defaults to the built-in features, in the order and with the glyphs every platform shows", () => {
    // 位置不在默认集里：没有真实的位置来源。名片是 card，图标是注册表的 card（Lucide Contact）。
    expect(FLARE_DEFAULT_COMPOSER_ACTION_IDS).toEqual(["image", "video", "file", "voice", "card", "poll"]);
    expect(FLARE_DEFAULT_COMPOSER_ACTION_IDS.map((id) => FLARE_COMPOSER_ACTION_ICONS[id]))
      .toEqual(["image", "video", "file", "mic", "card", "poll"]);
    for (const id of FLARE_DEFAULT_COMPOSER_ACTION_IDS) expect(FLARE_COMPOSER_ACTION_IDS).toContain(id);
    for (const icon of Object.values(FLARE_COMPOSER_ACTION_ICONS)) expect(Object.keys(flareIcons)).toContain(icon);
  });

  it("labels unified ids from the kit strings and keeps a host label", () => {
    const labelled = labelComposerActions<FlareComposerAction>([
      { id: "video" },
      { id: "poll", label: "  " },
      { id: "card", label: "Send card" },
      { id: "plugin:acme.form" },
    ], (key) => `t(${key})`);
    expect(labelled.map((action) => action.label)).toEqual(["t(composer.video)", "t(composer.poll)", "Send card", "plugin:acme.form"]);
  });

  it("falls back to the plugin glyph for an icon name the registry does not know", () => {
    const known = (name: string) => name in flareIcons;
    expect(resolveComposerActionIcon({ id: "plugin:flare.redpacket.send", kind: "plugin", icon: "red-packet" }, known)).toBe("red-packet");
    expect(resolveComposerActionIcon({ id: "plugin:acme.form", kind: "plugin", icon: "clipboard-form" }, known)).toBe("plugin");
    expect(resolveComposerActionIcon({ id: "plugin:acme.form", kind: "plugin" }, known)).toBe("plugin");
    expect(resolveComposerActionIcon({ id: "plugin:acme.form", kind: "plugin", icon: "🧾" }, known)).toBe("plugin");
    // 四端同一条规则：不是注册表名就画 plugin，内置项也一样。
    expect(resolveComposerActionIcon({ id: "file", kind: "feature", icon: "folder" }, known)).toBe("folder");
    expect(resolveComposerActionIcon({ id: "file", kind: "feature", icon: "folder-open" }, known)).toBe("plugin");
    // Vue 额外：没给图标的内置 id 用它的 Kit 图标；emoji 留给 FlareGlyph 当文字画。
    expect(resolveComposerActionIcon({ id: "voice" }, known)).toBe("mic");
    expect(resolveComposerActionIcon({ id: "order" }, known)).toBe("plugin");
    expect(resolveComposerActionIcon({ id: "order", icon: "🧾" }, known)).toBe("🧾");
  });

  it("shows every toolbar tool until the host names the ones it allows", () => {
    expect(FLARE_COMPOSER_TOOL_IDS).toEqual(["emoji", "mention", "voice", "image", "richText", "attachments"]);
    for (const tool of FLARE_COMPOSER_TOOL_IDS) {
      expect(composerToolAvailable(undefined, tool)).toBe(true);
      expect(composerToolAvailable({ availableActionIds: [] }, tool)).toBe(true);
      expect(composerToolAvailable({ availableToolIds: [] }, tool)).toBe(false);
    }
    expect(composerToolAvailable({ availableToolIds: ["emoji", "attachments"] }, "attachments")).toBe(true);
    expect(composerToolAvailable({ availableToolIds: ["emoji", "attachments"] }, "richText")).toBe(false);
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
