import { describe, expect, it } from "vitest";
import type { MessageLike } from "./messageRow";
import { messageGroupPosition, messageRowPresentation } from "./message-grouping";

function message(id: string, senderId: string, createdAt: number, type = "text"): MessageLike {
  return {
    serverId: id,
    clientMsgId: id,
    senderId,
    senderDisplayName: senderId,
    conversationSeq: Number(id),
    createdAt,
    clientCreatedAt: createdAt,
    messageType: 1,
    content: { contentType: type },
    status: "sent",
    isRecalled: false,
    isRead: true,
    timelineKey: id,
    timelineSortTs: createdAt,
    attributes: {},
  };
}

describe("message grouping", () => {
  it("returns first/middle/last for a same-sender run", () => {
    const rows = [message("1", "ivy", 1_000), message("2", "ivy", 2_000), message("3", "ivy", 3_000)];
    expect(rows.map((_, index) => messageGroupPosition(rows, index))).toEqual(["first", "middle", "last"]);
  });

  it("breaks on sender, time gap, and system boundaries", () => {
    const rows = [
      message("1", "ivy", 1_000),
      message("2", "lin", 2_000),
      message("3", "lin", 400_000),
      message("4", "lin", 401_000, "system"),
      message("5", "lin", 402_000),
    ];
    expect(rows.map((_, index) => messageGroupPosition(rows, index))).toEqual([
      "single", "single", "single", "single", "single",
    ]);
  });

  it("derives avatar and sender-name presentation from conversation context", () => {
    const incoming = message("1", "ivy", 1_000);
    expect(messageRowPresentation(incoming, "first", "me", "group")).toMatchObject({
      showAvatar: true,
      reserveAvatarSpace: true,
      showSenderName: true,
      avatarPlacement: "leading",
    });
    expect(messageRowPresentation(incoming, "middle", "me", "group")).toMatchObject({
      showAvatar: false,
      reserveAvatarSpace: true,
      showSenderName: false,
    });
    expect(messageRowPresentation(message("2", "me", 2_000), "single", "me", "single")).toMatchObject({
      showAvatar: false,
      reserveAvatarSpace: false,
      showSenderName: false,
      avatarPlacement: "trailing",
    });
  });
});
