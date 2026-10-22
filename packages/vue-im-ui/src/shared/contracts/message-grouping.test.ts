import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import type { FlareConversationKind } from "./conversation";
import type { FlareMessageSurface } from "./message-surface";
import { flareTimelineRows, messagesShareGroup, type FlareMessageGroupingOptions } from "./message-grouping";

type Row =
  | { kind: "date"; label: string }
  | { kind: "unread"; count: number }
  | { kind: "message"; id: string; position: string; showAvatar: boolean; showSenderName: boolean; reserveAvatarSpace: boolean; avatarPlacement: string; tail: boolean };
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/message-grouping-vectors.json"), "utf8")) as {
  timeGapMs: number;
  nowMs: number;
  utcOffsetMinutes: number;
  cases: Array<{
    name: string;
    conversationKind: FlareConversationKind;
    currentUserId: string;
    unreadFromId?: string;
    options?: FlareMessageGroupingOptions;
    messages: Array<{ id: string; senderId: string; atMs: number; surface: FlareMessageSurface }>;
    rows: Row[];
  }>;
};

describe("message grouping vectors (C4)", () => {
  it("covers the breaking rules", () => {
    expect(vectors.cases.length).toBeGreaterThanOrEqual(12);
    expect(vectors.timeGapMs).toBe(300_000);
  });
  it.each(vectors.cases)("$name", (c) => {
    const rows = flareTimelineRows(c.messages, {
      currentUserId: c.currentUserId,
      conversationKind: c.conversationKind,
      unreadFromId: c.unreadFromId,
      options: c.options,
      nowMs: vectors.nowMs,
      utcOffsetMinutes: vectors.utcOffsetMinutes,
    });
    expect(rows.map((row): Row => {
      if (row.kind === "date") return { kind: "date", label: row.label };
      if (row.kind === "unread") return { kind: "unread", count: row.count };
      return { kind: "message", id: c.messages[row.index].id, position: row.position, ...row.presentation };
    })).toEqual(c.rows);
  });
  it("joins neighbours with a missing time, as an unsent draft does", () => {
    expect(messagesShareGroup({ id: "a", senderId: "u", atMs: 0, surface: "bubble" }, { id: "b", senderId: "u", atMs: 10, surface: "bubble" })).toBe(true);
  });
});
