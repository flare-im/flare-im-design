import type { MessageLike } from "../shared/contracts/messageRow";

export function localRow(row: MessageLike): boolean {
  return row.conversationSeq === 0 && (Boolean(row.localState?.isLocal) || !row.serverId || row.serverId === row.clientMsgId);
}

function rowTimelineKey(message: MessageLike): string {
  const timelineKey = message.timelineKey.trim();
  if (timelineKey) return timelineKey;
  const serverId = message.serverId.trim();
  if (serverId) return `server:${serverId}`;
  const clientMsgId = message.clientMsgId.trim();
  if (clientMsgId) return `client:${clientMsgId}`;
  const seq = Math.max(0, Number(message.conversationSeq) || 0);
  if (seq > 0) return `seq:${seq}`;
  return `ts:${Math.max(
    0,
    Number(message.timelineSortTs) ||
      Number(message.createdAt) ||
      Number(message.clientCreatedAt) ||
      0,
  )}`;
}

function identityKeys(message: MessageLike): string[] {
  const keys = new Set<string>();
  const timelineKey = rowTimelineKey(message);
  if (timelineKey) keys.add(`timeline:${timelineKey}`);
  const clientMsgId = message.clientMsgId.trim();
  if (clientMsgId) keys.add(`client:${JSON.stringify([message.conversationId, message.senderId, clientMsgId])}`);
  const serverId = message.serverId.trim();
  if (serverId) keys.add(`server:${serverId}`);
  const seq = Math.max(0, Number(message.conversationSeq) || 0);
  if (seq > 0) keys.add(`seq:${seq}`);
  return [...keys];
}

function mergeMessageRow(existing: MessageLike, incoming: MessageLike): MessageLike {
  const existingSeq = Math.max(0, Number(existing.conversationSeq) || 0);
  const incomingSeq = Math.max(0, Number(incoming.conversationSeq) || 0);
  const incomingAuthoritative = incomingSeq > 0 || incoming.serverId.trim() !== "";
  const existingLocal = existing.localState ?? {};
  const incomingLocal = incoming.localState ?? {};
  const sortTs =
    Number(existingLocal.sortTs) ||
    Number(incomingLocal.sortTs) ||
    Number(incoming.timelineSortTs) ||
    Number(existing.timelineSortTs) ||
    Number(incoming.clientCreatedAt) ||
    Number(incoming.createdAt) ||
    Number(existing.clientCreatedAt) ||
    Number(existing.createdAt) ||
    0;

  return {
    ...existing,
    ...incoming,
    serverId: incoming.serverId.trim() || existing.serverId,
    clientMsgId: incoming.clientMsgId.trim() || existing.clientMsgId,
    conversationSeq: incomingSeq || existingSeq,
    createdAt: Number(incoming.createdAt) || Number(existing.createdAt) || 0,
    clientCreatedAt:
      Number(incoming.clientCreatedAt) || Number(existing.clientCreatedAt) || 0,
    timelineKey: rowTimelineKey(incoming) || rowTimelineKey(existing),
    timelineSortTs:
      Number(incoming.timelineSortTs) || Number(existing.timelineSortTs) || sortTs,
    localState: {
      ...existingLocal,
      ...incomingLocal,
      sending: incomingAuthoritative
        ? false
        : Boolean(incomingLocal.sending || existingLocal.sending),
      failed: incomingAuthoritative
        ? false
        : Boolean(incomingLocal.failed || existingLocal.failed),
      isLocal: Boolean(incomingLocal.isLocal || existingLocal.isLocal),
      uploading: incomingAuthoritative
        ? false
        : Boolean(incomingLocal.uploading || existingLocal.uploading),
      uploadProgress: incomingAuthoritative
        ? 100
        : Math.max(
            Number(incomingLocal.uploadProgress) || 0,
            Number(existingLocal.uploadProgress) || 0,
          ),
      sortTs,
    },
  };
}

export function normalizeMessageRowsForVirtualList(
  messages: readonly MessageLike[],
): MessageLike[] {
  const rows: MessageLike[] = [];
  const indexByIdentity = new Map<string, number>();

  const remember = (message: MessageLike, index: number) => {
    for (const key of identityKeys(message)) {
      indexByIdentity.set(key, index);
    }
  };

  for (const message of messages) {
    const keys = identityKeys(message);
    let existingIndex = -1;
    for (const key of keys) {
      const index = indexByIdentity.get(key);
      if (index !== undefined) {
        const stored = rows[index]!;
        const sameServer = message.serverId && message.serverId === stored.serverId && !localRow(message) && !localRow(stored);
        const sameSend = message.clientMsgId && message.clientMsgId === stored.clientMsgId
          && message.senderId === stored.senderId && message.conversationId === stored.conversationId;
        if (!sameServer && !(sameSend && (localRow(message) || localRow(stored)))) continue;
        existingIndex = index;
        break;
      }
    }
    if (existingIndex >= 0) {
      const stored = rows[existingIndex]!;
      rows[existingIndex] = localRow(message) && stored.conversationSeq > 0
        ? mergeMessageRow(message, stored) : mergeMessageRow(stored, message);
      remember(rows[existingIndex]!, existingIndex);
      continue;
    }
    rows.push(message);
    remember(message, rows.length - 1);
  }

  return rows;
}
