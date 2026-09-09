import { describe, it, expect } from "vitest";
import { conversationActions, type ConversationActionSnapshot } from "./conversation-actions";

const base: ConversationActionSnapshot = { id: "c1", title: "设计评审", unreadCount: 0 };
const all = { pin: true, mute: true, markRead: true, archive: true, hide: true, delete: true };
const ids = (c: ConversationActionSnapshot, caps: Parameters<typeof conversationActions>[1]) =>
  conversationActions(c, caps).map((e) => e.action);

describe("conversationActions", () => {
  it("renders nothing without capabilities", () => {
    expect(ids(base, {})).toEqual([]);
    expect(ids(base, undefined)).toEqual([]);
    expect(ids(base, { pin: false, delete: false })).toEqual([]);
  });

  it("each capability switch reveals exactly its action", () => {
    expect(ids(base, { pin: true })).toEqual(["pin"]);
    expect(ids(base, { mute: true })).toEqual(["mute"]);
    expect(ids(base, { archive: true })).toEqual(["archive"]);
    expect(ids(base, { hide: true })).toEqual(["hide"]);
    expect(ids(base, { delete: true })).toEqual(["delete"]);
  });

  it("inverts pin/mute/archive by state", () => {
    expect(ids({ ...base, pinned: true }, { pin: true })).toEqual(["unpin"]);
    expect(ids({ ...base, muted: true }, { mute: true })).toEqual(["unmute"]);
    expect(ids({ ...base, archived: true }, { archive: true })).toEqual(["unarchive"]);
  });

  it("markRead only when unread > 0", () => {
    expect(ids(base, { markRead: true })).toEqual([]);
    expect(ids({ ...base, unreadCount: undefined }, { markRead: true })).toEqual([]);
    expect(ids({ ...base, unreadCount: 3 }, { markRead: true })).toEqual(["markRead"]);
  });

  it("keeps a stable order with delete last and flagged danger", () => {
    const entries = conversationActions({ ...base, unreadCount: 2 }, all);
    expect(entries.map((e) => e.action)).toEqual(["pin", "mute", "markRead", "archive", "hide", "delete"]);
    expect(entries.filter((e) => e.danger).map((e) => e.action)).toEqual(["delete"]);
    expect(entries.at(-1)?.danger).toBe(true);
  });
});
