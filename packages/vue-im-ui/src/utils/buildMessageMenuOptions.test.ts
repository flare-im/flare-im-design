import { describe, expect, it } from "vitest";
import type { MessageLike } from "../shared/contracts/messageRow";
import { buildMessageContextSheetModel, buildMessageMenuItems, resolveMessageMenuAction, type MessageMenuExtension } from "./buildMessageMenuOptions";
import { mergeMessageMenuConfig, narrowMessageActionAvailability } from "../shared/config/messageMenu";
import { messageActionAvailability } from "./messageActionAvailability";
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

// The host's snapshot of the core's availability (what FlareMessageMenuSource.availability reads on the native kits)
// narrows the kit's own rule: a plugin card the core will not forward has no single "forward", in the menu or the sheet.
describe("the core's availability snapshot", () => {
  const card: MessageLike = {
    ...message,
    serverId: "server-card",
    clientMsgId: "client-card",
    messageType: 0,
    content: { contentType: "custom", data: { subtype: "flare.plugin.message.v1", text: "红包" } },
  };
  const snapshot = (m: MessageLike) => (m.serverId === "server-card" ? { canForward: false } : undefined);

  it("switches forward off for the message the core says cannot be forwarded, and nothing else", () => {
    const withSnapshot = { actions: { reply: true, forward: true }, availability: snapshot };
    expect(buildMessageMenuItems(card, "me", config).map((item) => item.id)).toContain("forward");
    const items = buildMessageMenuItems(card, "me", withSnapshot).map((item) => item.id);
    expect(items).not.toContain("forward");
    expect(items).toContain("reply");
    expect(buildMessageMenuItems(message, "me", withSnapshot).map((item) => item.id)).toContain("forward");
    expect(buildMessageContextSheetModel(card, "me", withSnapshot).quickActions.map((item) => item.key)).not.toContain("forward");
  });

  it("can only switch an action off, never on", () => {
    const pending = { ...message, status: "sending" } as MessageLike;
    const items = buildMessageMenuItems(pending, "me", { actions: { forward: true }, availability: () => ({ canForward: true }) });
    expect(items.map((item) => item.id)).not.toContain("forward");
    const own = messageActionAvailability(message, {
      currentUserId: "me", isConnected: true, isPending: false, isPinned: false, isFailed: false, multiSelectMode: false,
    });
    expect(narrowMessageActionAvailability(own, { canForward: false, canCopy: true })).toEqual({ ...own, canForward: false });
    expect(narrowMessageActionAvailability(own, null)).toBe(own);
  });

  it("narrows across config layers", () => {
    const merged = mergeMessageMenuConfig({ availability: () => ({ canForward: true, canPin: false }) }, { availability: snapshot });
    expect(merged.availability?.(card)).toEqual({ canForward: false, canPin: false });
    expect(merged.availability?.(message)).toEqual({ canForward: true, canPin: false });
  });
});
