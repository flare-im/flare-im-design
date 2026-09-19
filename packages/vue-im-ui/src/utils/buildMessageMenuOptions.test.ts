import { describe, expect, it } from "vitest";
import type { MessageLike } from "../shared/contracts/messageRow";
import { buildMessageMenuItems, resolveMessageMenuAction, type MessageMenuExtension } from "./buildMessageMenuOptions";
import { actionMenuEntries } from "../shared/contracts/action-menu";

const message: MessageLike = {
  serverId: "server-1", clientMsgId: "client-1", senderId: "ivy", senderDisplayName: "Ivy",
  conversationSeq: 3, createdAt: 1_736_922_600_000, clientCreatedAt: 1_736_922_600_000, messageType: 1,
  content: { contentType: "text", data: { text: "Release notes are up" } }, status: "read",
  isRecalled: false, isRead: true, timelineKey: "server:server-1", timelineSortTs: 1, attributes: {},
};
const config = { actions: { reply: true, forward: true } };
const keys = (omit?: readonly string[]) =>
  buildMessageMenuItems(message, "me", config, undefined, omit).map((item) => item.id);

describe("buildMessageMenuItems", () => {
  it("offers reply and forward where no other control does (right-click, tablet long-press)", () => {
    expect(keys()).toEqual(expect.arrayContaining(["reply", "forward"]));
  });

  it("leaves out only what the hosting surface already shows", () => {
    const hoverMore = keys(["reply"]);
    expect(hoverMore).not.toContain("reply");
    expect(hoverMore).toContain("forward");
  });

  it("lists host actions: ordinary ones before delete, destructive ones after it, filtered per message", () => {
    const actions: MessageMenuExtension[] = [
      { id: "report", label: "Report", icon: "warning", destructive: true, available: (ctx) => !ctx.isSelf },
      { id: "translate", label: "Translate", icon: "language" },
      { id: "hidden", label: "Hidden", visible: false },
    ];
    const withDelete = { actions: { reply: true, delete: true } };
    const drawn = actionMenuEntries(buildMessageMenuItems(message, "me", withDelete, undefined, [], actions));
    const incoming = drawn.map((entry) => (entry.kind === "item" ? entry.item.id : "|"));
    expect(incoming.indexOf("action:translate")).toBeLessThan(incoming.indexOf("delete"));
    expect(incoming.slice(-3)).toEqual(["|", "delete", "action:report"]);
    expect(incoming.filter((key) => key === "|")).toHaveLength(1);
    expect(incoming).not.toContain("action:hidden");
    const own = buildMessageMenuItems(message, "ivy", withDelete, undefined, [], actions).map((item) => item.id);
    expect(own).not.toContain("action:report");
    expect(resolveMessageMenuAction(message, "action:translate")).toEqual({ type: "emit", event: "action", payload: { id: "client-1", actionId: "translate" } });
  });
});
