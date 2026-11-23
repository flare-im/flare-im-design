import { describe, expect, it } from "vitest";
import { normalizeMessageRowsForVirtualList } from "./messageRows";
import { resolveMessageId, type MessageLike } from "../shared/contracts/messageRow";

const row = (serverId: string, senderId = "alice"): MessageLike => ({
  serverId, clientMsgId: "same-nonce", conversationId: "c", senderId, senderDisplayName: senderId,
  conversationSeq: 10, createdAt: 10, clientCreatedAt: 10, messageType: 1,
  isRecalled: false, isRead: false, status: "sent", timelineKey: `server:${serverId}`, timelineSortTs: 10,
});

describe("canonical message row identity", () => {
  it("keeps different confirmed messages with the same client nonce", () => {
    const rows = normalizeMessageRowsForVirtualList([row("s1"), row("s2", "bob")]);
    expect(rows.map(resolveMessageId)).toEqual(["s1", "s2"]);
  });
  it("reconciles only the same sender's local row, in either order", () => {
    const pending = { ...row("same-nonce"), conversationSeq: 0, timelineKey: "client:same-nonce", localState: { isLocal: true, sending: true } };
    for (const rows of [[pending, row("s1")], [row("s1"), pending]]) {
      expect(normalizeMessageRowsForVirtualList(rows).map(resolveMessageId)).toEqual(["s1"]);
    }
    expect(normalizeMessageRowsForVirtualList([pending, row("s2", "bob")])).toHaveLength(2);
  });
  it("finds the pending row after another sender or conversation reused its client ID", () => {
    const pending = { ...row("same-nonce"), conversationSeq: 0, timelineKey: "client:same-nonce", localState: { isLocal: true, sending: true } };
    const ack = row("own-server");
    for (const foreign of [row("foreign", "bob"), {...row("foreign"), conversationId: "other"}]) {
      for (const input of [[pending, foreign, ack], [ack, foreign, pending], [foreign, pending, ack]]) {
        const result = normalizeMessageRowsForVirtualList(input);
        expect(result).toHaveLength(2);
        expect(result.map(resolveMessageId).sort()).toEqual(["foreign", "own-server"]);
        expect(result.find(value => value.serverId === "own-server")?.localState?.sending).toBe(false);
      }
    }
  });

});
