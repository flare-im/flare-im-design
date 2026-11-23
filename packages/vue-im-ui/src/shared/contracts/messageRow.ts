import type { FlareMessageContentLike } from "./message";
import type { MessageLifecycle, MessageStatusState } from "./message-lifecycle";
import type { FlareMessageReadSummary } from "./message-receipt";

/** Framework-neutral message row consumed by the presentation package. */
export type MessageLike = {
  serverId: string;
  clientMsgId: string;
  /** The conversation the row belongs to; custom content renderers receive it (the message list provides its own otherwise). */
  conversationId?: string;
  senderId: string;
  senderDisplayName: string;
  senderAvatar?: string;
  conversationSeq: number;
  createdAt: number;
  clientCreatedAt: number;
  messageType: number;
  content?: FlareMessageContentLike & Record<string, unknown>;
  /** The SDK's receipt status (MessageReceiptView.status). */
  status: MessageStatusState;
  /**
   * The SDK's group read summary of the viewer's own message (MessageReceiptView.readSummary); absent in single chats,
   * for incoming messages, above the large-group threshold and while there is no data.
   */
  readSummary?: FlareMessageReadSummary;
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

type MessageIdentity = Pick<MessageLike, "clientMsgId" | "serverId"> & Partial<Pick<MessageLike, "timelineKey">>;

/**
 * The id every message intent carries (`reply`, `react`, `recall`, `toggle-select`,
 * `locate-message`, a pinned bar's `focus`) and the id `selectedIds`,
 * `mediaDownloadStates` and `scrollToMessage` expect. Confirmed rows use their
 * canonical server id; local rows fall back to their client id.
 */
export function resolveMessageId(message: MessageIdentity): string {
  return message.serverId || message.clientMsgId;
}

/**
 * Does `message` answer to `id`? A locate intent may name the row's own identity or the id the core
 * knows it by: a quote carries the quoted message's core id, which for a message this device sent is
 * not the client id the row is keyed with. Matching both is what keeps a quote of your own message
 * from reading as "that message is gone".
 */
export function messageMatchesId(message: MessageIdentity, id: string): boolean {
  if (!id) return false;
  return resolveMessageId(message) === id || message.clientMsgId === id || message.timelineKey === id;
}

/** The row an intent names — the host-side half of {@link resolveMessageId}. */
export function findMessage<T extends MessageIdentity>(messages: readonly T[], id: string): T | undefined {
  if (!id) return undefined;
  const canonical = messages.find((message) => resolveMessageId(message) === id || message.timelineKey === id);
  if (canonical) return canonical;
  const aliases = messages.filter((message) => message.clientMsgId === id);
  return aliases.length === 1 ? aliases[0] : undefined;
}
