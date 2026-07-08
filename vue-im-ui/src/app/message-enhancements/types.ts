import type { Conversation, Message } from "flare-core-typescript-sdk/web";

export type EnhancedMessageKind =
  | "file"
  | "image"
  | "video"
  | "audio"
  | "location"
  | "card"
  | "schedule"
  | "task"
  | "linkCard"
  | "richText"
  | "imageGroup"
  | "miniProgram"
  | "vote"
  | "thread"
  | "notification"
  | "announcement";

export type MessageOperationKey =
  | "react"
  | "reply"
  | "forward"
  | "copy"
  | "edit"
  | "delete"
  | "recall"
  | "pin"
  | "multiSelect";

export type OperationAvailability = {
  enabled: boolean;
  reason?: string;
};

export type MessageCapabilities = Record<
  | "canReact"
  | "canReply"
  | "canForward"
  | "canCopy"
  | "canEdit"
  | "canDelete"
  | "canRecall"
  | "canPin"
  | "canMultiSelect",
  OperationAvailability
>;

export type CapabilityContext = {
  currentUserId: string;
  connected: boolean;
  multiSelectMode?: boolean;
};

export type EnhancedPayloadBase = {
  kind: EnhancedMessageKind;
  payloadVersion: 1;
  ext?: Record<string, unknown>;
};

export type ComposerPayloadRequest = {
  op: string;
  kind: EnhancedMessageKind;
  params: Record<string, unknown>;
  previewText: string;
};

export type ForwardMode = "separate" | "merged";

export type MessagePinScope = "conversation" | "self";

export type ForwardRequest = {
  mode: ForwardMode;
  targetConversationId: string;
  messageIds: string[];
  title?: string;
};

export type BatchOperationResult = {
  total: number;
  succeeded: string[];
  failed: { messageId: string; reason: string }[];
};

export type MediaComposerPreviewItem = {
  id: string;
  kind: EnhancedMessageKind;
  name: string;
  sourcePath?: string;
  previewUrl?: string;
  mimeType?: string;
  size?: number;
  file?: File;
};

export type MessageOperationSdk = {
  activeConversationId: { value: string };
  currentUserId: { value: string };
  conversations: { value: readonly Conversation[] };
  messages: { value: readonly Message[] };
  addReaction(messageId: string, emoji: string): Promise<void>;
  removeReaction(messageId: string, emoji: string): Promise<void>;
  toggleReaction(messageId: string, emoji: string): Promise<void>;
  buildAndSendMessage(op?: string, overrides?: Record<string, unknown>): Promise<void>;
  forwardMessagesToConversation(request: {
    conversationId: string;
    messageIds: string[];
    merge?: boolean;
    title?: string;
  }): Promise<Message>;
  deleteMessageForSelf(messageId: string): Promise<void>;
  setMessagePinned(
    messageId: string,
    pinned: boolean,
    options?: { scope?: MessagePinScope },
  ): Promise<void>;
  refreshActiveChat(): Promise<void>;
};

export function messageStableId(message: Pick<Message, "serverId" | "clientMsgId">): string {
  return message.serverId || message.clientMsgId;
}

export function messageIsPinned(message: Message): boolean {
  return message.attributes?.pinned === "true";
}
