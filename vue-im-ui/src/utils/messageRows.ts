import type { MessageLike } from "../shared/contracts/messageRow";

function rowTimelineKey(message: MessageLike): string {
  const timelineKey = message.timelineKey.trim();
  if (timelineKey) return timelineKey;
  const clientMsgId = message.clientMsgId.trim();
  if (clientMsgId) return `client:${clientMsgId}`;
  const serverId = message.serverId.trim();
  if (serverId) return `server:${serverId}`;
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
  if (clientMsgId) keys.add(`client:${clientMsgId}`);
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
  const existingLocal = existing.localState ?? {
    sending: false,
    failed: false,
    isLocal: false,
    uploading: false,
    uploadProgress: 0,
    sortTs: 0,
  };
  const incomingLocal = incoming.localState ?? {
    sending: false,
    failed: false,
    isLocal: false,
    uploading: false,
    uploadProgress: 0,
    sortTs: 0,
  };
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
        existingIndex = index;
        break;
      }
    }
    if (existingIndex >= 0) {
      rows[existingIndex] = mergeMessageRow(rows[existingIndex]!, message);
      remember(rows[existingIndex]!, existingIndex);
      continue;
    }
    rows.push(message);
    remember(message, rows.length - 1);
  }

  return rows;
}
