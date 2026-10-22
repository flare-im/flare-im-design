import { describe, expect, it } from "vitest";
import { flareIconNames, flareIcons, type FlareIconName } from "./icons";

describe("semantic icon registry", () => {
  it("holds the 108-name contract shared by the four kits", () => {
    expect(flareIconNames).toHaveLength(108);
    for (const name of ["recall", "unpin", "merge-forward", "multi-select", "read", "mark-unread", "clear-history", "end-call", "remove-member", "transfer-owner", "silence", "report", "mini-app"] as FlareIconName[]) {
      expect(flareIconNames).toContain(name);
    }
    expect(flareIconNames).not.toContain("heart-filled" as FlareIconName);
    expect(flareIconNames).not.toContain("bookmark" as FlareIconName);
    expect(flareIconNames.slice(99)).toEqual(["pin-self", "diagnostics", "card", "id", "join-request", "storage", "red-packet", "plugin", "locate"]);
  });

  it("has the generic plugin glyph, a line puzzle piece", () => {
    expect(flareIconNames.at(-2)).toBe("plugin");
    expect((flareIcons.plugin as { displayName?: string }).displayName).toBe("Puzzle");
  });

  it("ends with the picker's locate key, a crosshair unlike the location pin", () => {
    expect(flareIconNames.at(-1)).toBe("locate");
    expect((flareIcons.locate as { displayName?: string }).displayName).toBe("LocateFixed");
    expect(flareIcons.locate).not.toBe(flareIcons.location);
  });

  it("draws the kit's own red packet glyph, which no icon library has", () => {
    expect(flareIcons["red-packet"]).toBeDefined();
    expect(flareIcons["red-packet"]).not.toBe(flareIcons.card);
    expect((flareIcons["red-packet"] as { displayName?: string }).displayName).toBe("RedPacket");
  });

  it("names are kebab-case", () => {
    for (const name of flareIconNames) expect(name).toMatch(/^[a-z]+(-[a-z]+)*$/);
  });

  it("gives actions that must look different their own glyphs", () => {
    const distinct: Array<[FlareIconName, FlareIconName]> = [
      ["recall", "reply"],
      ["unpin", "pin"],
      ["clear-history", "delete"],
      ["end-call", "phone"],
      ["remove-member", "logout"],
      ["transfer-owner", "star"],
      ["silence", "mute"],
      ["error", "close"],
      ["read", "check"],
      ["group", "people"],
      ["mark-unread", "notification"],
      ["screen-share", "devices"],
      ["language", "translate"],
      // Each concept below was drawn under the second name, which means something else.
      ["pin-self", "pin"],
      ["card", "person"],
      ["id", "info"],
      ["id", "tag"],
      ["join-request", "person"],
      ["join-request", "notification"],
      ["storage", "folder"],
      ["diagnostics", "info"],
    ];
    // Two shim exports can draw one Lucide glyph (ArrowUndoOutline and ReturnUpBackOutline both draw Reply), so the
    // comparison is of the glyph drawn, not of the component.
    const glyph = (name: FlareIconName) => (flareIcons[name] as unknown as { displayName: string }).displayName;
    for (const [a, b] of distinct) expect(glyph(a), `${a} vs ${b}`).not.toBe(glyph(b));
  });
});
