import { describe, expect, it } from "vitest";
import type { MessageLike } from "../shared/contracts/messageRow";
import { messageActionAvailability } from "./messageActionAvailability";

const context = { currentUserId: "me", isConnected: true, isPending: false, isPinned: false, isFailed: false, multiSelectMode: false };
function row(content: MessageLike["content"], messageType = 1): MessageLike {
  return {
    serverId: "s-1", clientMsgId: "c-1", senderId: "ivy", senderDisplayName: "Ivy", conversationSeq: 4,
    createdAt: 1, clientCreatedAt: 1, messageType, content, status: "sent", isRecalled: false, isRead: false,
    timelineKey: "server:s-1", timelineSortTs: 1, attributes: {},
  };
}

describe("copy availability", () => {
  it("copies text the core sends flattened, the shape real messages arrive in", () => {
    expect(messageActionAvailability(row({ contentType: "text", text: "Ship it" }), context).canCopy).toBe(true);
  });

  it("still copies a data-bag text body", () => {
    expect(messageActionAvailability(row({ contentType: "text", data: { text: "Ship it" } }), context).canCopy).toBe(true);
  });

  it("offers no copy for media without a body", () => {
    expect(messageActionAvailability(row({ contentType: "image", source: { url: "/a.webp" } }, 2), context).canCopy).toBe(false);
  });
});
