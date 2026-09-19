import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

import {
  messageActionAvailability,
  messageDeliveryState,
  type MessageActionAvailability,
} from "./messageActionAvailability";
import type { MessageLike } from "../shared/contracts/messageRow";
import type { MessageMutationState, MessageStatusState } from "../shared/contracts/message-lifecycle";

/** The UI action policy is pinned by a package-owned cross-platform fixture. */
type Vector = {
  label: string;
  input: {
    isSelf: boolean;
    messageType: number;
    status: MessageStatusState;
    mutation?: MessageMutationState;
    hasText: boolean;
    isPending: boolean;
    isPinned: boolean;
    isConnected: boolean;
    multiSelectMode: boolean;
    isFailed: boolean;
    isRead: boolean;
  };
  expected: MessageActionAvailability;
  deliveryState: string;
};

const vectorsPath = fileURLToPath(
  new URL(
    "../../../../spec/scenarios/message-action-availability.json",
    import.meta.url,
  ),
);
const vectors = JSON.parse(readFileSync(vectorsPath, "utf8")).cases as Vector[];

function messageFrom(input: Vector["input"]): MessageLike {
  return {
    messageId: "m1",
    serverId: "m1",
    clientMsgId: "c1",
    conversationId: "conv",
    senderId: input.isSelf ? "me" : "other",
    isRead: input.isRead,
    messageType: input.messageType,
    status: input.status,
    lifecycle: {
      transfer: "idle",
      send: input.status === "failed" ? "failed" : input.status === "sending" ? "sending" : "sent",
      delivery: input.status === "delivered" ? "delivered" : "serverAccepted",
      read: input.status === "read" ? "read" : "unread",
      mutation: input.mutation ?? "normal",
      ephemeral: "none",
    },
    isRecalled: input.mutation === "recalled",
    content: input.hasText
      ? { contentType: "text", data: { text: "正文" } }
      : { contentType: "image", data: {} },
  } as unknown as MessageLike;
}

describe("message action availability contract", () => {
  it("向量非空——否则这条门禁形同虚设", () => {
    expect(vectors.length).toBeGreaterThanOrEqual(10);
  });

  for (const vector of vectors) {
    it(`matches the shared fixture: ${vector.label}`, () => {
      const actual = messageActionAvailability(messageFrom(vector.input), {
        currentUserId: "me",
        isConnected: vector.input.isConnected,
        isPending: vector.input.isPending,
        isPinned: vector.input.isPinned,
        isFailed: vector.input.isFailed,
        multiSelectMode: vector.input.multiSelectMode,
      });
      expect(actual).toEqual(vector.expected);

      expect(
        messageDeliveryState(messageFrom(vector.input), {
          currentUserId: "me",
          isPending: vector.input.isPending,
          isFailed: vector.input.isFailed,
        }),
      ).toBe(vector.deliveryState);
    });
  }
});
