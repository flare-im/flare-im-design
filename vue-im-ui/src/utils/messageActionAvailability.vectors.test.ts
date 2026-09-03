import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

import {
  messageActionAvailability,
  messageDeliveryState,
  type MessageActionAvailability,
} from "./messageActionAvailability";
import type { MessageLike } from "../shared/contracts/messageRow";

/**
 * kit 的动作可用性必须与**核心** `domain::message_actions` 逐位一致。
 *
 * kit 的组件是纯展示的、不碰 SDK，所以不能直接调核心；规则允许有第二份实现，
 * 但不允许漂移 —— 向量由核心生成（`cargo test action_availability_vectors`），
 * 规则一改这里就红。
 */
type Vector = {
  label: string;
  input: {
    isSelf: boolean;
    messageType: number;
    status: number;
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
    "../../../../flare-im-core-client-sdk/sdk-spec/message-action-vectors.json",
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
    content: input.hasText
      ? { contentType: "text", data: { text: "正文" } }
      : { contentType: "image", data: {} },
  } as unknown as MessageLike;
}

describe("动作可用性与核心一致", () => {
  it("向量非空——否则这条门禁形同虚设", () => {
    expect(vectors.length).toBeGreaterThanOrEqual(10);
  });

  for (const vector of vectors) {
    it(`与核心一致：${vector.label}`, () => {
      const actual = messageActionAvailability(messageFrom(vector.input), {
        currentUserId: "me",
        isConnected: vector.input.isConnected,
        isPending: vector.input.isPending,
        isPinned: vector.input.isPinned,
        isFailed: vector.input.isFailed,
        multiSelectMode: vector.input.multiSelectMode,
      });
      expect(actual).toEqual(vector.expected);

      // 送达状态同样对齐核心
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
