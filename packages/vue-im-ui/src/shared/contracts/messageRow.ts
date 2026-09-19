import type { FlareMessageContentLike } from "./message";
import type { MessageLifecycle, MessageStatusState } from "./message-lifecycle";

/** Framework-neutral message row consumed by the presentation package. */
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
  content?: FlareMessageContentLike & Record<string, unknown>;
  status: MessageStatusState;
  lifecycle?: MessageLifecycle;
  isRecalled: boolean;
  isEdited?: boolean;
  isRead: boolean;
  timelineKey: string;
  timelineSortTs: number;
  replyTo?: string;
  textPreview?: string;
  quotePreview?: string;
  /** Pinned in the conversation; the bubble shows the pin marker and the menu offers unpin. */
  pinned?: boolean;
  /** Host string metadata the content renderers may read (e.g. `ephemeralState`). */
  attributes?: Readonly<Record<string, string>>;
  reactions?: ReadonlyArray<{ readonly emoji: string; readonly count: number; readonly selected?: boolean }>;
  localState?: Readonly<Record<string, unknown>> & {
    uploading?: boolean;
    uploadProgress?: number;
  };
};

type MessageIdentity = Pick<MessageLike, "clientMsgId" | "serverId">;

/**
 * The id every message intent carries (`reply`, `react`, `recall`, `toggle-select`,
 * `locate-message`, a pinned bar's `focus`) and the id `selectedIds`,
 * `mediaDownloadStates` and `scrollToMessage` expect. The client id comes first:
 * it exists from the optimistic insert on, so a message keeps one identity across
 * its send acknowledgement; rows created without one fall back to the server id.
 */
export function resolveMessageId(message: MessageIdentity): string {
  return message.clientMsgId || message.serverId;
}

/**
 * Does `message` answer to `id`? A locate intent may name the row's own identity or the id the core
 * knows it by: a quote carries the quoted message's core id, which for a message this device sent is
 * not the client id the row is keyed with. Matching both is what keeps a quote of your own message
 * from reading as "that message is gone".
 */
export function messageMatchesId(message: MessageIdentity, id: string): boolean {
  if (!id) return false;
  return resolveMessageId(message) === id || message.serverId === id;
}

/** The row an intent names — the host-side half of {@link resolveMessageId}. */
export function findMessage<T extends MessageIdentity>(messages: readonly T[], id: string): T | undefined {
  return id ? messages.find((message) => resolveMessageId(message) === id) : undefined;
}
