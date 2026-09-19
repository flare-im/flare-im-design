import { describe, expect, it } from "vitest";
import {
  resolveConversationHeaderActions,
  type FlareConversationHeaderAction,
} from "./conversation-header";

const group = { kind: "group" as const };

describe("resolveConversationHeaderActions", () => {
  it("provides opinionated direct and group defaults", () => {
    expect(resolveConversationHeaderActions({ identity: { kind: "single" } }).map((item) => item.id))
      .toEqual(["search", "audioCall", "videoCall", "share", "details"]);
    expect(resolveConversationHeaderActions({ identity: group }).map((item) => item.id))
      .toContain("addMember");
  });

  it("removes, disables, relabels, and reorders defaults", () => {
    const result = resolveConversationHeaderActions({
      identity: group,
      configuration: {
        removeActionIds: ["audioCall"],
        actionOverrides: [
          { id: "search", label: "Find", enabled: false, order: 80 },
          { id: "details", order: 1 },
        ],
      },
    });
    expect(result.map((item) => item.id)).toEqual(["details", "videoCall", "addMember", "share", "search"]);
    expect(result.at(-1)).toMatchObject({ label: "Find", enabled: false });
  });

  it("filters capabilities and merges custom normal and Plus actions", () => {
    const actions: FlareConversationHeaderAction[] = [
      { id: "order", label: "Create order", icon: "add", placement: "add", order: 44 },
      { id: "task", label: "Create task", icon: "check", placement: "primary", order: 2 },
      { id: "search", label: "Search this room", placement: "overflow" },
      { id: "hidden", label: "Hidden", visible: false },
    ];
    const result = resolveConversationHeaderActions({
      identity: group,
      capabilities: { availableActionIds: ["search", "addMember", "share", "details", "task", "order"] },
      actions,
    });
    expect(result.map((item) => item.id)).toEqual(["task", "search", "addMember", "order", "share", "details"]);
    expect(result.find((item) => item.id === "search")?.placement).toBe("overflow");
    expect(result.some((item) => item.id === "audioCall")).toBe(false);
    expect(result.some((item) => item.id === "hidden")).toBe(false);
  });

  it("supports a complete host replacement without duplicate ids", () => {
    const result = resolveConversationHeaderActions({
      identity: group,
      configuration: { replaceDefaults: true },
      actions: [
        { id: "task", label: "Task", order: 20 },
        { id: "task", label: "Task override", order: 10 },
      ],
    });
    expect(result).toEqual([{ id: "task", label: "Task override", order: 10 }]);
  });
});
