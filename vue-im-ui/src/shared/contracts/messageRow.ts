import type { Message, MessageContent } from "flare-core-typescript-sdk/web";

/** 与 SDK `Message` 对齐，兼容 workbench snapshot 的 readonly 字段 */
export type MessageLike = {
  serverId: string;
  clientMsgId: string;
  senderId: string;
  senderDisplayName: string;
  senderAvatar?: string;
  conversationSeq: number;
  createdAt: number;
  clientCreatedAt: number;
  messageType: number;
  content?: MessageContent;
  status: number;
  isRecalled: boolean;
  isEdited?: boolean;
  isRead: boolean;
  timelineKey: string;
  timelineSortTs: number;
  replyTo?: string;
  textPreview?: string;
  quotePreview?: string;
  attributes: Readonly<Record<string, string>>;
  extensions: Readonly<
    Record<string, Readonly<Uint8Array> | readonly number[]>
  >;
  reactions?: ReadonlyArray<{ readonly emoji: string; readonly count: number }>;
  localState?: Message["localState"];
};
